use super::ServerState;
use crate::local::get_current_rev_file_from_odb;
use axum::extract::{Path, State};

#[axum::debug_handler]
pub async fn get(Path(file_path): Path<String>, State(server_state): State<ServerState>) -> String {
    let repo = server_state.git_repo.as_ref().lock().await;
    let file = get_current_rev_file_from_odb(&repo, &file_path).unwrap();
    dbg!(file.name());

    String::from_utf8(file.data().bytes().to_owned()).unwrap()
}
