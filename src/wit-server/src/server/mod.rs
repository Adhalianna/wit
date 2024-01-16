use std::{borrow::Cow, path::Path, sync::Arc};
use tokio::sync::Mutex;

pub mod get;
pub mod git_proxy;
pub mod link;
pub mod render;

pub use render::render;

pub fn run(storage_path: &str, address: Option<String>) {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .with_span_events(tracing_subscriber::fmt::format::FmtSpan::ENTER)
        .without_time()
        .compact()
        .init();

    let git_repo = git2::Repository::open(&storage_path).expect(
        format!(
            "failed to open a git repository contained within wit storage at {}, use 'init' command to create one",
            storage_path
        )
        .as_str(),
    );
    let storage_path = Path::new(storage_path);
    let full_path = storage_path.canonicalize().unwrap();
    let address = address.unwrap_or("localhost:3000".to_owned());

    std::env::set_var("GIT_PROJECT_ROOT", &storage_path);

    tracing::info!(
        storage_path = full_path.to_str().unwrap(),
        address = address,
        "running wiki server",
    );
    run_axum_server(git_repo, address);
}

#[derive(Clone, axum::extract::FromRef)]
pub struct ServerState {
    git_repo: Arc<Mutex<git2::Repository>>,
    address: Cow<'static, String>,
}

pub fn run_axum_server(git_repo: git2::Repository, address: String) {
    let state = ServerState {
        git_repo: Arc::new(Mutex::new(git_repo)),
        address: Cow::Owned(address.clone()),
    };

    let main_router = axum::Router::new()
        .route("/favicon.ico", axum::routing::any(|| async { "not set" }))
        .route("/git", git_proxy::new_proxy("/git"))
        .route("/git/*path", git_proxy::new_proxy("/git/"))
        .route("/:file_path", axum::routing::get(get::get))
        .with_state(state);

    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .unwrap()
        .block_on(async {
            let tcp_listener = tokio::net::TcpListener::bind(address).await.unwrap();

            axum::serve(tcp_listener, main_router).await.unwrap();
        })
}
