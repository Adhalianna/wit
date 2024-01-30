use std::{error::Error, path::Path};

pub async fn new_network(
    wiki_meta_dir_path: String,
    private_key_seed: u8, //?
) -> Result<(), Box<dyn Error>> {
    let mut bytes = [0u8; 32];
    bytes[0] = private_key_seed;
    let keys = libp2p::identity::Keypair::ed25519_from_bytes(bytes).unwrap();

    let peer_id = keys.public().to_peer_id();

    let mut swarm = libp2p::SwarmBuilder::with_existing_identity(keys)
        .with_tokio()
        .with_tcp(
            libp2p::tcp::Config::default(),
            libp2p::noise::Config::new,
            libp2p::yamux::Config::default,
        )?
        .with_behaviour(|key| Behaviour { kademlia: todo!() });
    todo!()
}

#[derive(libp2p::swarm::NetworkBehaviour)]
struct Behaviour {
    kademlia: libp2p::kad::Behaviour<RedbStorage>,
}

struct RedbStorage {
    db: redb::Database,
}

struct TableKey {
    pub file_path: String,
    pub version: String,
}

struct TableEntry {
    pub host: String,
}

impl RedbStorage {
    pub fn new(file_path: impl AsRef<Path>) -> Result<Self, Box<dyn Error>> {
        let db = redb::Database::create(file_path);

        Self {}
    }
}

impl libp2p::kad::store::RecordStore for RedbStorage {
    type RecordsIter<'a>
    where
        Self: 'a;

    type ProvidedIter<'a>
    where
        Self: 'a;

    fn get(&self, k: &libp2p::kad::RecordKey) -> Option<std::borrow::Cow<'_, libp2p::kad::Record>> {
        todo!()
    }

    fn put(&mut self, r: libp2p::kad::Record) -> libp2p::kad::store::Result<()> {
        todo!()
    }

    fn remove(&mut self, k: &libp2p::kad::RecordKey) {
        todo!()
    }

    fn records(&self) -> Self::RecordsIter<'_> {
        todo!()
    }

    fn add_provider(
        &mut self,
        record: libp2p::kad::ProviderRecord,
    ) -> libp2p::kad::store::Result<()> {
        todo!()
    }

    fn providers(&self, key: &libp2p::kad::RecordKey) -> Vec<libp2p::kad::ProviderRecord> {
        todo!()
    }

    fn provided(&self) -> Self::ProvidedIter<'_> {
        todo!()
    }

    fn remove_provider(&mut self, k: &libp2p::kad::RecordKey, p: &libp2p::PeerId) {
        todo!()
    }
}
