mod kad_client;
mod kad_store;
mod tables;

use crate::{config::WikiConfig, file::remote::RemoteFile, server::p2p::kad_client::Event};
use git2::Remote;
use kad_store::*;
use libp2p::identity::Keypair;
use libp2p::Multiaddr;
use redb::ReadableTable;
use std::{borrow::Cow, error::Error, path::Path, str::FromStr, time::Duration};
use tokio::sync::mpsc;
use tokio_stream::{Stream, StreamExt};

pub use kad_client::KadClient;
pub use kad_client::P2pEventLoop;

#[tracing::instrument(level = tracing::Level::DEBUG, skip(p2p_keys))]
pub fn new_s2s_network(
    storage_path: &Path,
    p2p_keys: Keypair,
    registered_peers: &[Multiaddr],
) -> Result<(KadClient, impl Stream<Item = Event>, P2pEventLoop), Box<dyn Error>> {
    let peer_id = p2p_keys.public().to_peer_id();

    let mut swarm = libp2p::SwarmBuilder::with_existing_identity(p2p_keys.clone())
        .with_tokio()
        .with_tcp(
            libp2p::tcp::Config::default(),
            libp2p::noise::Config::new,
            libp2p::yamux::Config::default,
        )?
        .with_behaviour(|key| Behaviour::new(storage_path.join("storage.redb"), key))?
        .with_swarm_config(|c| c.with_idle_connection_timeout(Duration::from_secs(60)))
        .build();

    swarm
        .behaviour_mut()
        .kademlia
        .set_mode(Some(libp2p::kad::Mode::Server));

    let (command_sender, commannd_receiver) = mpsc::channel(64);
    let (event_sender, event_receiver) = mpsc::channel(64);

    let client = KadClient::new(command_sender, 8, p2p_keys.public(), registered_peers);

    Ok((
        client,
        tokio_stream::wrappers::ReceiverStream::new(event_receiver),
        P2pEventLoop::new(swarm, commannd_receiver, event_sender),
    ))
}

#[derive(libp2p::swarm::NetworkBehaviour)]
pub struct Behaviour {
    kademlia: libp2p::kad::Behaviour<RedbStorage>,
    req_resp: libp2p::request_response::cbor::Behaviour<FileAndVer, RemoteFile>,
}

impl Behaviour {
    #[tracing::instrument(level = tracing::Level::DEBUG, skip(key))]
    pub fn new(
        storage_file: impl AsRef<Path> + std::fmt::Debug,
        key: &libp2p::identity::Keypair,
    ) -> Result<Self, Box<dyn Error + Send + Sync>> {
        let store = match RedbStorage::new(storage_file) {
            Ok(store) => store,
            Err(err) => return Err(err),
        };
        Ok(Self {
            kademlia: libp2p::kad::Behaviour::new(key.public().to_peer_id(), store),
            req_resp: libp2p::request_response::cbor::Behaviour::new(
                [(
                    libp2p::StreamProtocol::new("/wit/server-to-server/0.0.1"),
                    libp2p::request_response::ProtocolSupport::Full,
                )],
                libp2p::request_response::Config::default(),
            ),
        })
    }
}

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, serde::Serialize, serde::Deserialize)]
pub struct FileAndVer {
    pub file_path: String,
    pub version: String,
}

impl FileAndVer {
    pub fn into_key(self) -> tables::EntryKey {
        self.into()
    }
}
