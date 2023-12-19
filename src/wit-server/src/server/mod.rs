use std::{path::Path, sync::Arc};
use tokio::sync::Mutex;

pub mod get;

pub fn run(storage_path: &str) {
    let git_repo = git2::Repository::open(&storage_path).expect(
        format!(
            "failed to open a git repository contained within wit storage at {}, use 'init' command to create one",
            storage_path
        )
        .as_str(),
    );
    let storage_path = Path::new(storage_path);
    let full_path = storage_path.canonicalize().unwrap();

    println!("Running at {}", full_path.to_str().unwrap());
    start_server(git_repo);
}

#[derive(Clone, axum::extract::FromRef)]
pub struct ServerState {
    git_repo: Arc<Mutex<git2::Repository>>,
}

pub fn start_server(git_repo: git2::Repository) {
    let state = ServerState {
        git_repo: Arc::new(Mutex::new(git_repo)),
    };

    let main_router = axum::Router::new()
        .route("/favicon.ico", axum::routing::any(|| async { "not set" }))
        .route("/:file_path", axum::routing::get(get::get))
        .with_state(state);

    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .unwrap()
        .block_on(async {
            let tcp_listener = tokio::net::TcpListener::bind("localhost:3000")
                .await
                .unwrap();

            axum::serve(tcp_listener, main_router).await.unwrap();
        })
}
