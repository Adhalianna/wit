use super::tables::*;
use redb::ReadableTable;
use std::borrow::Cow;
use std::error::Error;
use std::path::Path;

#[derive(Debug)]
pub struct RedbStorage {
    db: redb::Database,
}

impl AsRef<[u8]> for EntryKey {
    fn as_ref(&self) -> &[u8] {
        self.bytes()
    }
}

impl redb::RedbValue for EntryKey {
    type SelfType<'a> = Self;
    type AsBytes<'a> = &'a [u8];
    fn as_bytes<'a, 'b: 'a>(value: &'a Self::SelfType<'b>) -> Self::AsBytes<'a>
    where
        Self: 'a,
        Self: 'b,
    {
        value.bytes()
    }
    fn fixed_width() -> Option<usize> {
        None
    }
    fn from_bytes<'a>(data: &'a [u8]) -> Self::SelfType<'a>
    where
        Self: 'a,
    {
        // SAFETY: we expect that only valid data was stored in the db and
        // retrieved through this trait.
        unsafe { Self::from_bytes(data) }
    }
    fn type_name() -> redb::TypeName {
        redb::TypeName::new("wit-server::p2p::EntryKey")
    }
}

impl redb::RedbKey for EntryKey {
    fn compare(data1: &[u8], data2: &[u8]) -> std::cmp::Ordering {
        unsafe {
            let k1 = Self::from_bytes(data1);
            let k2 = Self::from_bytes(data2);
            (k1.file_path(), k1.version()).cmp(&(k2.file_path(), k2.version()))
        }
    }
}

impl redb::RedbValue for EntryVal {
    type SelfType<'a> = Self;
    type AsBytes<'a> = Vec<u8>;
    fn as_bytes<'a, 'b: 'a>(value: &'a Self::SelfType<'b>) -> Self::AsBytes<'a>
    where
        Self: 'a,
        Self: 'b,
    {
        value.host.clone().into_bytes()
    }
    fn fixed_width() -> Option<usize> {
        None
    }
    fn from_bytes<'a>(data: &'a [u8]) -> Self::SelfType<'a>
    where
        Self: 'a,
    {
        Self {
            host: String::from_utf8(data.to_owned()).unwrap(),
        }
    }
    fn type_name() -> redb::TypeName {
        redb::TypeName::new("string")
    }
}

impl redb::RedbValue for KadProviderEntryValue {
    type SelfType<'a> = Self;
    type AsBytes<'a> = &'a [u8];
    fn fixed_width() -> Option<usize> {
        None
    }
    /// # Safety
    /// Only use to deserialize valid data from redb, do not try using it in a different context.
    /// See [`KadProviderEntryValue::from_bytes()`] for more details.
    fn from_bytes<'a>(data: &'a [u8]) -> Self::SelfType<'a>
    where
        Self: 'a,
    {
        unsafe { Self::from_bytes(data) }
    }
    fn as_bytes<'a, 'b: 'a>(value: &'a Self::SelfType<'b>) -> Self::AsBytes<'a>
    where
        Self: 'a,
        Self: 'b,
    {
        value.bytes()
    }
    fn type_name() -> redb::TypeName {
        redb::TypeName::new("wit-server::p2p::ProviderValue")
    }
}

impl RedbStorage {
    #[tracing::instrument(level = tracing::Level::DEBUG, name = "building redb storage", err, fields(db_file = ?file_path))]
    pub fn new(
        file_path: impl AsRef<Path> + std::fmt::Debug,
    ) -> Result<Self, Box<dyn Error + Send + Sync>> {
        let db = redb::Database::create(file_path)?;
        Ok(Self { db })
    }
}

pub struct FileRevRecordsIter<'a> {
    // DO NOT CHANGE FIELDS ORDER
    // it will mess up the drop order which might lead to problems
    tx: redb::ReadTransaction<'a>,
    tbl: redb::ReadOnlyTable<'a, EntryKey, EntryVal>,
    iter: redb::Range<'a, EntryKey, EntryVal>,
    db: &'a redb::Database,
}

impl<'a> FileRevRecordsIter<'a> {
    #[tracing::instrument(level = tracing::Level::TRACE, name = "creating iterator over {table} entries", fields(table = RECORD_TABLE_NAME))]
    pub fn new(db: &'a redb::Database) -> Self {
        let tx: redb::ReadTransaction<'a> =
            unsafe { std::mem::transmute(db.begin_read().unwrap()) }; // TODO
        let tbl: redb::ReadOnlyTable<'a, _, _> = unsafe {
            std::mem::transmute(
                tx.open_table(RedbRecordTable::new(RECORD_TABLE_NAME))
                    .unwrap(),
            )
        };
        let range: redb::Range<'a, _, _> = unsafe { std::mem::transmute(tbl.iter().unwrap()) };
        Self {
            db,
            tx,
            tbl,
            iter: range,
        }
    }
}

impl<'a> Iterator for FileRevRecordsIter<'a> {
    type Item = Cow<'a, libp2p::kad::Record>;
    fn next(&mut self) -> Option<Self::Item> {
        self.iter.next().map(|res| {
            let (key, val) = res.unwrap();
            let (key, val) = (key.value(), val.value());
            let entry = FileRevEntry::from((key, val));
            Cow::Owned(entry.into())
        })
    }
}

pub struct ProviderRecordsIter<'a> {
    // DO NOT CHANGE FIELDS ORDER
    // it will mess up the drop order which might lead to problems
    tx: redb::ReadTransaction<'a>,
    tbl: redb::ReadOnlyTable<'a, EntryKey, KadProviderEntryValue>,
    iter: redb::Range<'a, EntryKey, KadProviderEntryValue>,
    db: &'a redb::Database,
}

impl<'a> ProviderRecordsIter<'a> {
    #[tracing::instrument(level = tracing::Level::TRACE, name = "creating iterator over {table} entries", fields(table = PROVIDER_TABLE_NAME))]
    pub fn new(db: &'a redb::Database) -> Self {
        let tx: redb::ReadTransaction<'a> =
            unsafe { std::mem::transmute(db.begin_read().unwrap()) }; // TODO
        let tbl: redb::ReadOnlyTable<'a, _, _> = unsafe {
            std::mem::transmute(
                tx.open_table(RedbProviderTable::new(PROVIDER_TABLE_NAME))
                    .unwrap(),
            )
        };
        let range: redb::Range<'a, _, _> = unsafe { std::mem::transmute(tbl.iter().unwrap()) };
        Self {
            db,
            tx,
            tbl,
            iter: range,
        }
    }
}

impl<'a> Iterator for ProviderRecordsIter<'a> {
    type Item = Cow<'a, libp2p::kad::ProviderRecord>;
    fn next(&mut self) -> Option<Self::Item> {
        self.iter.next().map(|res| {
            let (key, val) = res.unwrap();
            let (key, val) = (key.value(), val.value());
            let entry = ProviderEntry::from((key, val));
            Cow::Owned(entry.into())
        })
    }
}
impl libp2p::kad::store::RecordStore for RedbStorage {
    type RecordsIter<'a> = FileRevRecordsIter<'a>;
    type ProvidedIter<'a> = ProviderRecordsIter<'a>;

    #[tracing::instrument(level = tracing::Level::TRACE, ret)]
    fn get(&self, k: &libp2p::kad::RecordKey) -> Option<std::borrow::Cow<'_, libp2p::kad::Record>> {
        let db = &self.db;
        let tx = match db.begin_read() {
            Ok(tx) => Some(tx),
            Err(_) => None,
        }?;
        let key = EntryKey::from(k.to_owned());
        let tbl = match tx.open_table(RedbRecordTable::new(RECORD_TABLE_NAME)) {
            Ok(tbl) => Some(tbl),
            Err(_) => None,
        }?;
        let res = match tbl.get(&key) {
            Ok(item) => Some(item?),
            Err(_) => None,
        }?;
        let val = res.value();

        let entry = FileRevEntry::from((key, val));
        Some(Cow::Owned(entry.into()))
    }

    #[tracing::instrument(level = tracing::Level::TRACE, ret, err)]
    fn put(&mut self, r: libp2p::kad::Record) -> libp2p::kad::store::Result<()> {
        let db = &self.db;
        let entry = FileRevEntry::from(r);
        let (key, value) = (entry.key, entry.val);

        let tx = db
            .begin_write()
            .map_err(|_| libp2p::kad::store::Error::ValueTooLarge)?; // NOTE: this error conversion makes no sense, but libp2p is limiting the choice here

        let mut tbl = tx
            .open_table(RedbRecordTable::new(RECORD_TABLE_NAME))
            .map_err(|_| libp2p::kad::store::Error::ValueTooLarge)?; // NOTE: also awkward err

        tbl.insert(key, value)
            .map_err(|_| libp2p::kad::store::Error::ValueTooLarge)?;

        Ok(())
    }

    #[tracing::instrument(level = tracing::Level::TRACE)]
    fn remove(&mut self, k: &libp2p::kad::RecordKey) {
        let db = &self.db;
        let key = EntryKey::from(k.to_owned());
        let tx = db.begin_write().unwrap(); // No error handling possible, eh
        let mut tbl = tx
            .open_table(RedbRecordTable::new(RECORD_TABLE_NAME))
            .unwrap();
        tbl.remove(key).unwrap();
    }

    fn records(&self) -> Self::RecordsIter<'_> {
        let iter = FileRevRecordsIter::new(&self.db);
        iter
    }

    #[tracing::instrument(level = tracing::Level::TRACE, ret, err)]
    fn add_provider(
        &mut self,
        record: libp2p::kad::ProviderRecord,
    ) -> libp2p::kad::store::Result<()> {
        let db = &self.db;
        let entry = ProviderEntry::from(record);
        let (key, value) = (entry.key, entry.val);
        let tx = db
            .begin_write()
            .map_err(|_| libp2p::kad::store::Error::ValueTooLarge)?; // NOTE: this error conversion makes no sense, but libp2p is limiting the choice here

        let mut tbl = tx
            .open_table(RedbProviderTable::new(PROVIDER_TABLE_NAME))
            .map_err(|_| libp2p::kad::store::Error::ValueTooLarge)?; // NOTE: also awkward err

        tbl.insert(key, value)
            .map_err(|_| libp2p::kad::store::Error::ValueTooLarge)?;

        Ok(())
    }

    #[tracing::instrument(level = tracing::Level::TRACE, ret)]
    fn providers(&self, key: &libp2p::kad::RecordKey) -> Vec<libp2p::kad::ProviderRecord> {
        let db = &self.db;
        let Ok(tx) = db.begin_read() else {
            return vec![];
        };

        let key = EntryKey::from(key.to_owned());
        let Ok(tbl) = tx.open_table(RedbProviderTable::new(PROVIDER_TABLE_NAME)) else {
            return vec![];
        };

        let Ok(res) = tbl.get(&key) else {
            return vec![];
        };
        let Some(res) = res else {
            return vec![];
        };

        let entry = ProviderEntry::from((key, res.value()));

        vec![entry.into()]
    }

    fn provided(&self) -> Self::ProvidedIter<'_> {
        let iter = ProviderRecordsIter::new(&self.db);
        iter
    }

    #[tracing::instrument(level = tracing::Level::TRACE)]
    fn remove_provider(&mut self, k: &libp2p::kad::RecordKey, p: &libp2p::PeerId) {
        let db = &self.db;
        let key = EntryKey::from(k.to_owned());
        let tx = db.begin_write().unwrap(); // No error handling possible, eh
        let mut tbl = tx
            .open_table(RedbProviderTable::new(PROVIDER_TABLE_NAME))
            .unwrap();
        tbl.remove(key).unwrap();
    }
}
