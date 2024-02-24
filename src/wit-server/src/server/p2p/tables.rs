use super::*;
use std::str::FromStr;

#[derive(Clone, Debug)]
pub struct EntryKey {
    bytes: Vec<u8>,
}

impl From<FileAndVer> for EntryKey {
    fn from(value: FileAndVer) -> Self {
        Self::new(value.file_path, value.version)
    }
}

impl EntryKey {
    // How many bytes were reserved to store `version_start_idx`:
    const FILE_PATH_START_IDX: usize = 2;

    pub fn new(file_path: String, version: String) -> Self {
        let bytes_len = Self::FILE_PATH_START_IDX as usize + file_path.len() + version.len();
        let mut bytes = Vec::<u8>::with_capacity(bytes_len);
        bytes.resize(bytes_len, 0u8);

        let version_start_idx = file_path.len() as u16 + Self::FILE_PATH_START_IDX as u16;

        bytes[0..Self::FILE_PATH_START_IDX].copy_from_slice(&u16::to_be_bytes(version_start_idx));
        bytes[Self::FILE_PATH_START_IDX..].copy_from_slice(&(file_path + &version).into_bytes());

        Self { bytes }
    }
    fn version_start_idx(&self) -> u16 {
        u16::from_be_bytes(self.bytes[0..Self::FILE_PATH_START_IDX].try_into().unwrap())
    }
    pub fn file_path(&self) -> &str {
        let version_start_idx =
            u16::from_be_bytes(self.bytes[0..Self::FILE_PATH_START_IDX].try_into().unwrap());
        unsafe {
            std::str::from_utf8_unchecked(
                &self.bytes[Self::FILE_PATH_START_IDX..(version_start_idx as usize)],
            )
        }
    }
    pub fn version(&self) -> &str {
        let version_start_idx =
            u16::from_be_bytes(self.bytes[0..Self::FILE_PATH_START_IDX].try_into().unwrap());
        unsafe { std::str::from_utf8_unchecked(&self.bytes[(version_start_idx as usize)..]) }
    }
    pub fn bytes(&self) -> &[u8] {
        &self.bytes
    }
    /// # Safety
    /// Make sure that everything is correctly packed into bytes on your own. No guarantees here.
    pub unsafe fn from_bytes(input: &[u8]) -> Self {
        Self {
            bytes: input.to_owned(),
        }
    }
    /// # Safety
    /// Make sure that everything is correctly packed into bytes on your own. No guarantees here.
    pub unsafe fn from_bytes_vec(input: Vec<u8>) -> Self {
        Self { bytes: input }
    }
}

impl From<libp2p::kad::RecordKey> for EntryKey {
    fn from(value: libp2p::kad::RecordKey) -> Self {
        unsafe { Self::from_bytes_vec(value.to_vec()) }
    }
}

impl Into<libp2p::kad::RecordKey> for EntryKey {
    fn into(self) -> libp2p::kad::RecordKey {
        libp2p::kad::RecordKey::new(&self)
    }
}

#[derive(Debug)]
pub struct EntryVal {
    pub host: String,
}

pub struct FileRevEntry {
    pub key: EntryKey,
    pub val: EntryVal,
}

impl Into<libp2p::kad::Record> for FileRevEntry {
    fn into(self) -> libp2p::kad::Record {
        libp2p::kad::Record::new(self.key, self.val.host.into_bytes())
    }
}

impl From<libp2p::kad::Record> for FileRevEntry {
    fn from(value: libp2p::kad::Record) -> Self {
        Self {
            key: unsafe { EntryKey::from_bytes_vec(value.key.to_vec()) },
            val: EntryVal {
                host: String::from_utf8(value.value).unwrap(),
            },
        }
    }
}

impl From<(EntryKey, EntryVal)> for FileRevEntry {
    fn from(value: (EntryKey, EntryVal)) -> Self {
        Self {
            key: value.0,
            val: value.1,
        }
    }
}

#[derive(Debug)]
pub struct KadProviderEntryValue {
    bytes: Vec<u8>,
}

impl KadProviderEntryValue {
    pub fn new(peer_id: libp2p::PeerId, addresses: Vec<libp2p::Multiaddr>) -> Self {
        let peer_id = peer_id.to_bytes();
        let peer_id_len = peer_id.len() as u8;
        let addresses_num = addresses.len() as u8;

        let bytes_len = 1 + peer_id_len as usize + 1;
        let mut bytes = Vec::with_capacity(bytes_len);
        bytes.resize(bytes_len, 0u8);

        bytes[0] = peer_id_len;
        bytes[1..(peer_id_len as usize + 1)].copy_from_slice(&peer_id);
        bytes[peer_id_len as usize + 1] = addresses_num;

        for addr in addresses {
            let mut addr = addr.to_vec();
            bytes.push(addr.len() as u8);
            bytes.append(&mut addr);
        }

        Self { bytes }
    }
    pub fn bytes(&self) -> &[u8] {
        &self.bytes
    }
    pub fn peer_id(&self) -> libp2p::PeerId {
        let peer_id_len = self.bytes[0];
        let peer_id = &self.bytes[1..(peer_id_len as usize + 1)];
        libp2p::PeerId::from_bytes(peer_id).unwrap()
    }
    pub fn addresses(&self) -> Vec<libp2p::Multiaddr> {
        let peer_id_len = self.bytes[0];
        let vec_len = self.bytes[(peer_id_len as usize) + 1];

        let mut addresses = Vec::with_capacity(vec_len as usize);

        let mut remaining_bytes = &self.bytes[(peer_id_len as usize + 1)..];

        for _ in 0..vec_len {
            let addr_len = remaining_bytes[0];
            let addr = &remaining_bytes[1..(addr_len as usize + 1)];
            let addr = libp2p::Multiaddr::from_str(std::str::from_utf8(addr).unwrap()).unwrap();
            addresses.push(addr);
            remaining_bytes = &remaining_bytes[(addr_len as usize + 1)..];
        }
        addresses
    }
    /// # Safety
    /// Make sure that everything is correctly packed into bytes on your own. No guarantees here.
    pub unsafe fn from_bytes(input: &[u8]) -> Self {
        Self {
            bytes: input.to_owned(),
        }
    }
    /// # Safety
    /// Make sure that everything is correctly packed into bytes on your own. No guarantees here.
    pub unsafe fn from_bytes_vec(input: Vec<u8>) -> Self {
        Self { bytes: input }
    }
}

pub struct ProviderEntry {
    pub key: EntryKey,
    pub val: KadProviderEntryValue,
}

impl Into<libp2p::kad::ProviderRecord> for ProviderEntry {
    fn into(self) -> libp2p::kad::ProviderRecord {
        libp2p::kad::ProviderRecord::new(self.key, self.val.peer_id(), self.val.addresses())
    }
}

impl From<libp2p::kad::ProviderRecord> for ProviderEntry {
    fn from(value: libp2p::kad::ProviderRecord) -> Self {
        Self {
            key: unsafe { EntryKey::from_bytes_vec(value.key.to_vec()) },
            val: KadProviderEntryValue::new(value.provider, value.addresses),
        }
    }
}

impl From<(EntryKey, KadProviderEntryValue)> for ProviderEntry {
    fn from(value: (EntryKey, KadProviderEntryValue)) -> Self {
        Self {
            key: value.0,
            val: value.1,
        }
    }
}

pub type RedbRecordTable<'a> = redb::TableDefinition<'a, EntryKey, EntryVal>;
pub type RedbProviderTable<'a> = redb::TableDefinition<'a, EntryKey, KadProviderEntryValue>;

pub const RECORD_TABLE_NAME: &'static str = "file_rev_records";
pub const PROVIDER_TABLE_NAME: &'static str = "providers";
