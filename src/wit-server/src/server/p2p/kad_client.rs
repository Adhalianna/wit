use super::{tables::FileRevEntry, *};
use crate::file::remote::RemoteFile;
use axum::Form;
use core::fmt;
use libp2p::{
    futures::TryFutureExt,
    request_response::ResponseChannel,
    swarm::{NetworkBehaviour, SwarmEvent},
    Multiaddr, PeerId, StreamProtocol, Swarm,
};
use std::{
    collections::{HashMap, HashSet},
    error::Error,
    sync::Arc,
};
use tokio::sync::{
    broadcast::error::RecvError,
    mpsc::{self, error::SendError},
    oneshot, RwLock,
};
use tokio_stream::{Stream, StreamExt};

#[derive(thiserror::Error, Debug)]
pub enum KadClientError {
    #[error(
        "client command receiver has been dropped, client lost connection to Kademlia network"
    )]
    LostContactWithReceiver(#[from] SendError<Command>),
    #[error("client failed to receive response because of dropped response channel")]
    ResponseChannelDropped(#[source] tokio::sync::oneshot::error::RecvError),
    #[error("timeout occured before client got response")]
    Timeout(#[from] tokio::time::error::Elapsed),
}

#[derive(Debug, Clone)]
pub struct KadClient {
    sender: mpsc::Sender<Command>,
    pub timeout: u64,
    peer_addresses: Arc<RwLock<Vec<Multiaddr>>>,
    public_key: libp2p::identity::PublicKey,
}

#[derive(Debug)]
pub enum Command {
    StartListening {
        addr: Multiaddr,
        sender: oneshot::Sender<Result<(), Box<dyn Error + Send + Sync>>>,
    },
    Dial {
        peer_id: PeerId,
        peer_addr: Multiaddr,
        sender: oneshot::Sender<Result<(), Box<dyn Error + Send + Sync>>>,
    },
    StartProviding {
        key: FileAndVer,
        sender: oneshot::Sender<()>,
    },
    GetProviders {
        key: FileAndVer,
        sender: oneshot::Sender<HashSet<PeerId>>,
    },
    RequestFile {
        key: FileAndVer,
        peer: PeerId,
        sender: oneshot::Sender<Result<RemoteFile, Box<dyn Error + Send + Sync>>>,
    },
    RespondFile {
        file: RemoteFile,
        channel: libp2p::request_response::ResponseChannel<RemoteFile>,
    },
}

#[derive(Debug)]
pub enum Event {
    InbountRequest {
        channel: ResponseChannel<RemoteFile>,
        req: FileAndVer,
    },
}

impl KadClient {
    pub fn new(
        sender: mpsc::Sender<Command>,
        timeout: u64,
        public_key: libp2p::identity::PublicKey,
        known_peers: &[Multiaddr],
    ) -> Self {
        let mut client = Self {
            sender,
            timeout,
            public_key,
            peer_addresses: Arc::new(RwLock::new(known_peers.to_vec())),
        };

        for peer in known_peers {
            client.start_listening(peer.clone());
        }

        client
    }
    pub fn public_key(&self) -> &libp2p::identity::PublicKey {
        &self.public_key
    }
    pub async fn peers(&self) -> Vec<Multiaddr> {
        let peers = self.peer_addresses.read().await;
        peers.clone()
    }
    pub async fn add_peer(&self, address: Multiaddr) {
        let mut peers = self.peer_addresses.write().await;
        (*peers).push(address)
    }
    pub fn timeout_dur(&self) -> Duration {
        Duration::from_secs(self.timeout)
    }
    #[tracing::instrument(level = tracing::Level::INFO, skip(self), err)]
    pub async fn start_listening(
        &mut self,
        addr: Multiaddr,
    ) -> Result<(), Box<dyn Error + Send + Sync>> {
        tokio::time::timeout(self.timeout_dur(), async {
            let (sender, receiver) = oneshot::channel();
            self.sender
                .send(Command::StartListening { addr, sender })
                .await?;
            receiver.await?
        })
        .await
        .map_err(KadClientError::Timeout)?
    }
    #[tracing::instrument(level = tracing::Level::INFO, skip(self), err)]
    pub async fn dial(
        &mut self,
        peer_id: PeerId,
        peer_addr: Multiaddr,
    ) -> Result<(), Box<dyn Error + Send + Sync>> {
        tokio::time::timeout(self.timeout_dur(), async {
            let (sender, receiver) = oneshot::channel();
            self.sender
                .send(Command::Dial {
                    peer_id,
                    peer_addr,
                    sender,
                })
                .await?;
            receiver.await?
        })
        .await
        .map_err(KadClientError::Timeout)?
    }
    #[tracing::instrument(level = tracing::Level::INFO, skip(self), err)]
    pub async fn start_providing(
        &mut self,
        file_and_ver: FileAndVer,
    ) -> Result<(), Box<dyn Error + Send + Sync>> {
        tokio::time::timeout(self.timeout_dur(), async {
            let (sender, receiver) = oneshot::channel();
            self.sender
                .send(Command::StartProviding {
                    key: file_and_ver,
                    sender,
                })
                .await
                .map_err(KadClientError::LostContactWithReceiver)?;
            receiver.await?;
            Ok(())
        })
        .await
        .map_err(KadClientError::Timeout)?
    }
    #[tracing::instrument(level = tracing::Level::DEBUG, name = "asking for providers through Kademlia client", skip(self), err)]
    pub async fn get_providers(
        &mut self,
        file_and_ver: FileAndVer,
    ) -> Result<HashSet<PeerId>, Box<dyn Error + Send + Sync>> {
        tokio::time::timeout(self.timeout_dur(), async {
            let (sender, receiver) = oneshot::channel();
            self.sender
                .send(Command::GetProviders {
                    key: file_and_ver,
                    sender,
                })
                .await
                .map_err(KadClientError::LostContactWithReceiver)?;
            let res = receiver
                .await
                .map_err(KadClientError::ResponseChannelDropped)?;
            Ok(res)
        })
        .await
        .map_err(KadClientError::Timeout)?
    }
    #[tracing::instrument(level = tracing::Level::INFO, skip(self), err)]
    pub async fn request_file(
        &mut self,
        peer_id: PeerId,
        file_and_ver: FileAndVer,
    ) -> Result<RemoteFile, Box<dyn Error + Send + Sync>> {
        tokio::time::timeout(self.timeout_dur(), async {
            let (sender, receiver) = oneshot::channel();
            self.sender
                .send(Command::RequestFile {
                    key: file_and_ver,
                    peer: peer_id,
                    sender,
                })
                .await?;
            let res = receiver.await??;
            Ok(res)
        })
        .await
        .map_err(KadClientError::Timeout)?
    }
    #[tracing::instrument(level = tracing::Level::INFO, skip(self), err)]
    pub async fn respond_file(
        &mut self,
        file: RemoteFile,
        channel: ResponseChannel<RemoteFile>,
    ) -> Result<(), Box<dyn Error + Send + Sync>> {
        self.sender
            .send(Command::RespondFile { file, channel })
            .await?;
        Ok(())
    }
}

pub struct P2pEventLoop {
    swarm: libp2p::Swarm<super::Behaviour>,
    command_receiver: mpsc::Receiver<Command>,
    event_sender: mpsc::Sender<Event>,
    pending_dial: HashMap<PeerId, oneshot::Sender<Result<(), Box<dyn Error + Send + Sync>>>>,
    pending_start_providing: HashMap<libp2p::kad::QueryId, oneshot::Sender<()>>,
    pending_get_providers: HashMap<libp2p::kad::QueryId, oneshot::Sender<HashSet<PeerId>>>,
    pending_request_file: HashMap<
        libp2p::request_response::OutboundRequestId,
        oneshot::Sender<Result<RemoteFile, Box<dyn Error + Send + Sync>>>,
    >,
}

impl P2pEventLoop {
    pub fn new(
        swarm: Swarm<Behaviour>,
        command_receiver: mpsc::Receiver<Command>,
        event_sender: mpsc::Sender<Event>,
    ) -> Self {
        Self {
            swarm,
            command_receiver,
            event_sender,
            pending_dial: Default::default(),
            pending_start_providing: Default::default(),
            pending_get_providers: Default::default(),
            pending_request_file: Default::default(),
        }
    }
    #[tracing::instrument(level = tracing::Level::TRACE, name = "executing server-to-server interaction loop", skip(self))]
    pub async fn run(mut self) {
        loop {
            tokio::select! {
                event = self.swarm.next() => match self.handle_event(event.expect("stream should be infinite")).await {
                    Ok(_) => continue,
                    Err(err) => tracing::error!(error = ?err)
                },
                command = self.command_receiver.recv() => match command {
                    Some(c) => match self.handle_command(c).await {
                      Ok(_) => continue,
                      Err(err) => tracing::error!(error = ?err)
                    },
                    None => continue
                }
            }
        }
    }
    #[tracing::instrument(level = tracing::Level::INFO, err, skip(self))]
    pub async fn handle_event(
        &mut self,
        event: libp2p::swarm::SwarmEvent<BehaviourEvent>,
    ) -> Result<(), Box<dyn Error + Send + Sync>> {
        match event {
            SwarmEvent::Behaviour(BehaviourEvent::Kademlia(
                libp2p::kad::Event::OutboundQueryProgressed {
                    id,
                    result: libp2p::kad::QueryResult::StartProviding(_),
                    ..
                },
            )) => {
                let sender = self
                    .pending_start_providing
                    .remove(&id)
                    .expect("completed query to be previosly registered and known as pending");
                sender
                    .send(())
                    .map_err(|_| String::from("failed to inform about new providers"))?;
                Ok(())
            }
            SwarmEvent::Behaviour(BehaviourEvent::Kademlia(
                libp2p::kad::Event::OutboundQueryProgressed {
                    id,
                    result:
                        libp2p::kad::QueryResult::GetProviders(Ok(
                            libp2p::kad::GetProvidersOk::FoundProviders { providers, .. },
                        )),
                    ..
                },
            )) => {
                if let Some(sender) = self.pending_get_providers.remove(&id) {
                    sender
                        .send(providers)
                        .map_err(|providers| format!("failed to send {providers:?}"))?;
                    self.swarm
                        .behaviour_mut()
                        .kademlia
                        .query_mut(&id)
                        .unwrap()
                        .finish();
                }
                Ok(())
            }
            SwarmEvent::Behaviour(BehaviourEvent::Kademlia(
                libp2p::kad::Event::OutboundQueryProgressed {
                    result:
                        libp2p::kad::QueryResult::GetProviders(Ok(
                            libp2p::kad::GetProvidersOk::FinishedWithNoAdditionalRecord { .. },
                        )),
                    ..
                },
            )) => Ok(()),
            SwarmEvent::Behaviour(BehaviourEvent::Kademlia(_)) => {
                Ok(()) //ignore other
            }
            SwarmEvent::Behaviour(BehaviourEvent::ReqResp(
                // handle messages of request_response protocol
                libp2p::request_response::Event::Message { message, .. },
            )) => match message {
                libp2p::request_response::Message::Request {
                    request, channel, ..
                } => {
                    self.event_sender
                        .send(Event::InbountRequest {
                            channel,
                            req: request,
                        })
                        .await?;
                    Ok(())
                }
                libp2p::request_response::Message::Response {
                    request_id,
                    response,
                } => {
                    match self
                        .pending_request_file
                        .remove(&request_id)
                        .expect("request still known as pending")
                        .send(Ok(response))
                    {
                        Ok(_) => Ok(()),
                        Err(res) => match res {
                            Ok(file) => Err(format!("failed to send file {}", file.path()).into()),
                            Err(err) => Err(err),
                        },
                    }
                }
            },
            SwarmEvent::Behaviour(BehaviourEvent::ReqResp(
                libp2p::request_response::Event::OutboundFailure {
                    request_id, error, ..
                },
            )) => match self
                .pending_request_file
                .remove(&request_id)
                .expect("request still known as pending")
                .send(Err(error.into()))
            {
                Ok(_) => Ok(()),
                Err(res) => match res {
                    Ok(file) => Err(format!("failed to send file {}", file.path()).into()),
                    Err(err) => Err(err),
                },
            },
            SwarmEvent::Behaviour(BehaviourEvent::ReqResp(
                libp2p::request_response::Event::ResponseSent { .. },
            )) => Ok(()),
            SwarmEvent::NewListenAddr { address, .. } => {
                let local_peer_id = self.swarm.local_peer_id();
                tracing::info!(
                    p2p.local_peer_id =
                        ?address.with(libp2p::multiaddr::Protocol::P2p(*local_peer_id)),
                    "local p2p node is listening on {:?}",
                    local_peer_id,
                );
                Ok(())
            }
            SwarmEvent::IncomingConnection { .. } => Ok(()),
            SwarmEvent::ConnectionEstablished {
                peer_id, endpoint, ..
            } => {
                if endpoint.is_dialer() {
                    if let Some(sender) = self.pending_dial.remove(&peer_id) {
                        match sender.send(Ok(())) {
                            Ok(_) => Ok(()),
                            Err(res) => match res {
                                Ok(_) => Err(String::from("unexpected swarm event error").into()),
                                Err(err) => Err(err),
                            },
                        }
                    } else {
                        Ok(())
                    }
                } else {
                    Ok(())
                }
            }
            SwarmEvent::ConnectionClosed { .. } => Ok(()),
            SwarmEvent::OutgoingConnectionError { peer_id, error, .. } => {
                if let Some(peer_id) = peer_id {
                    if let Some(sender) = self.pending_dial.remove(&peer_id) {
                        match sender.send(Err(error.into())) {
                            Ok(_) => Ok(()),
                            Err(res) => match res {
                                Ok(_) => Err(String::from("unexpected swarm event error").into()),
                                Err(err) => Err(err),
                            },
                        }
                    } else {
                        Ok(())
                    }
                } else {
                    Ok(())
                }
            }
            SwarmEvent::IncomingConnectionError { error, .. } => Err(error.into()),
            SwarmEvent::Dialing {
                peer_id: Some(peer_id),
                ..
            } => Ok(()),
            unknown => Err(format!("unkown swarm event: {unknown:?}").into()),
        }
    }
    #[tracing::instrument(level = tracing::Level::INFO, err, skip(self))]
    pub async fn handle_command(
        &mut self,
        command: Command,
    ) -> Result<(), Box<dyn Error + Send + Sync>> {
        match command {
            Command::StartListening { addr, sender } => {
                let res = match self.swarm.listen_on(addr) {
                    Ok(_) => sender.send(Ok(())),
                    Err(err) => sender.send(Err(err.into())),
                };
                match res {
                    Ok(_) => Ok(()),
                    Err(res) => match res {
                        Ok(_) => {
                            Err(String::from("failed to handle StartListening command").into())
                        }
                        Err(err) => Err(err),
                    },
                }
            }
            Command::Dial {
                peer_id,
                peer_addr,
                sender,
            } => {
                if let std::collections::hash_map::Entry::Vacant(e) =
                    self.pending_dial.entry(peer_id)
                {
                    self.swarm
                        .behaviour_mut()
                        .kademlia
                        .add_address(&peer_id, peer_addr.clone());
                    match self
                        .swarm
                        .dial(peer_addr.with(libp2p::multiaddr::Protocol::P2p(peer_id)))
                    {
                        Ok(_) => {
                            let _ = e.insert(sender);
                            Ok(())
                        }
                        Err(err) => {
                            let res = sender.send(Err(err.into()));
                            match res {
                                Ok(_) => Ok(()),
                                Err(res) => match res {
                                    Ok(_) => {
                                        Err(String::from("failed to handle Dial command").into())
                                    }
                                    Err(err) => Err(err),
                                },
                            }
                        }
                    }
                } else {
                    unimplemented!("already dialing peer");
                }
            }
            Command::StartProviding { key, sender } => {
                let query_id = match self
                    .swarm
                    .behaviour_mut()
                    .kademlia
                    .start_providing(key.into_key().into())
                {
                    Ok(query_id) => query_id,
                    Err(err) => {
                        return Err(err.into());
                    }
                };
                let _ = self.pending_start_providing.insert(query_id, sender);
                Ok(())
            }
            Command::GetProviders { key, sender } => {
                let query_id = self
                    .swarm
                    .behaviour_mut()
                    .kademlia
                    .get_providers(key.into_key().into());
                let _ = self.pending_get_providers.insert(query_id, sender);
                Ok(())
            }
            Command::RespondFile { file, channel } => match self
                .swarm
                .behaviour_mut()
                .req_resp
                .send_response(channel, file)
            {
                Ok(_) => Ok(()),
                Err(err) => Err(format!("failed to respond with file {}", err.path()).into()),
            },
            Command::RequestFile { key, peer, sender } => {
                let request_id = self.swarm.behaviour_mut().req_resp.send_request(&peer, key);
                let _ = self.pending_request_file.insert(request_id, sender);
                Ok(())
            }
        }
    }
}
