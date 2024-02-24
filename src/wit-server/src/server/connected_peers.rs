use axum::{extract::State, response::IntoResponse, Json};
use libp2p::Multiaddr;
use serde::{Deserialize, Serialize};
use serde_with::{base64::Base64, serde_as};

use super::ServerState;

#[serde_as]
#[derive(Serialize, Deserialize)]
pub struct ConnectNewRequest {
    #[serde_as(as = "Base64")]
    signature: Vec<u8>,
    address: Multiaddr,
}

pub struct ValidatedRequest(ConnectNewRequest);

#[derive(thiserror::Error, Debug)]
#[error("unauthorized request")]
pub struct AuthorizationFailure;

impl IntoResponse for AuthorizationFailure {
    fn into_response(self) -> axum::response::Response {
        axum::http::StatusCode::UNAUTHORIZED.into_response()
    }
}

impl ConnectNewRequest {
    pub fn new(address: Multiaddr, signature: Vec<u8>) -> Self {
        Self { address, signature }
    }
    pub fn validate(
        self,
        public_key: &libp2p::identity::PublicKey,
    ) -> Result<ValidatedRequest, AuthorizationFailure> {
        let authorized = public_key.verify(&self.address.to_vec(), &self.signature);
        if !authorized {
            Err(AuthorizationFailure)
        } else {
            Ok(ValidatedRequest(self))
        }
    }
}

impl ValidatedRequest {
    pub fn address(self) -> Multiaddr {
        self.0.address
    }
}

pub async fn get(State(server_state): State<ServerState>) -> Json<Vec<Multiaddr>> {
    let peers = server_state.s2s_client.peers().await;
    Json(peers)
}
pub async fn add_new(
    State(server_state): State<ServerState>,
    Json(req): Json<ConnectNewRequest>,
) -> Result<Json<Vec<Multiaddr>>, AuthorizationFailure> {
    let mut s2s_client = server_state.s2s_client;
    let client_key = s2s_client.public_key();

    let address = req.validate(client_key)?.address();
    s2s_client.start_listening(address.clone());
    s2s_client.add_peer(address);

    Ok(Json(s2s_client.peers().await))
}
