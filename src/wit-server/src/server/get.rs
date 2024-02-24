use super::{p2p::FileAndVer, ServerState};
use crate::git_storage::get_current_rev_file_from_odb;
use axum::{
    extract::{Path, State},
    response::IntoResponse,
};
use http::StatusCode;
use libp2p::futures::TryFutureExt;

#[tracing::instrument(level = tracing::Level::INFO, name = "handling GET request", err(Debug), ret(level = tracing::Level::DEBUG, Debug), skip(server_state))]
pub async fn get(
    Path(file_path): Path<String>,
    State(mut server_state): State<ServerState>,
) -> impl IntoResponse {
    let repo = server_state.git_repo.as_ref().lock().await;
    let file = match get_current_rev_file_from_odb(&repo, &file_path) {
        Ok(local_file) => local_file.take_data(),
        Err(_) => {
            let providers = server_state
                .s2s_client
                .get_providers(FileAndVer {
                    file_path,
                    version: "0".to_owned(),
                })
                .await;

            //unimplemented!()
            return Err((StatusCode::NOT_FOUND, "no such file on the local server"));
        }
    };

    Ok(crate::server::render(file, &server_state.address))
}
