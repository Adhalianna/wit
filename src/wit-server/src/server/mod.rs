use libp2p::{identity::Keypair, Multiaddr};
use std::{borrow::Cow, path::Path, sync::Arc};
use tokio::sync::Mutex;

pub mod connected_peers;
pub mod get;
pub mod git_proxy;
pub mod link;
pub mod p2p;
pub mod render;

pub use render::render;

use self::p2p::{KadClient, P2pEventLoop};

pub fn run(
    storage_path: &str,
    address: Option<String>,
    domain: Option<String>,
    p2p_keys: Keypair,
    registered_peers: &[Multiaddr],
) {
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .with_span_events(tracing_subscriber::fmt::format::FmtSpan::ENTER)
        .with_line_number(true)
        .without_time()
        .compact()
        .init();

    // Assert there is only one instance of server running in the provided path:
    let unique_server_instance = single_instance::SingleInstance::new(storage_path).unwrap();
    assert!(unique_server_instance.is_single());

    // Open the git repository:
    let git_repo = git2::Repository::open(&storage_path).expect(
        format!(
            "failed to open a git repository contained within wit storage at {}, use 'init' command to create one",
            storage_path
        )
        .as_str(),
    );
    let storage_path = Path::new(storage_path);
    let full_path = storage_path.canonicalize().unwrap();

    // Resolve addresses:
    let address = address.unwrap_or("localhost:3000".to_owned());
    let static_address: &'static str = Box::leak(address.into_boxed_str());
    let url_authority: &'static str = match domain {
        None => static_address,
        Some(domain) => Box::leak(domain.into_boxed_str()),
    };

    // Init global var:
    crate::server::link::CURRENT_HOST.get_or_init(|| url_authority);

    // Needed for git-http-backend, which is executed to handle git traffic coming through HTTP
    std::env::set_var("GIT_PROJECT_ROOT", &storage_path);

    // Launch server-to-server comms
    let Ok((s2s_client, event_stream, p2p_loop)) =
        crate::server::p2p::new_s2s_network(storage_path, p2p_keys, registered_peers)
    else {
        panic!("failed to create server-to-server client");
    };

    // Build api router connecting shared state:
    let api_router = build_api_server(git_repo, static_address, s2s_client);

    execute_async_context(api_router, static_address, p2p_loop)
}

#[derive(Clone, axum::extract::FromRef)]
pub struct ServerState {
    git_repo: Arc<Mutex<git2::Repository>>,
    address: Cow<'static, String>,
    s2s_client: crate::server::p2p::KadClient,
}

pub fn execute_async_context(
    api_router: axum::Router<()>,
    tcp_address: &str,
    p2p_event_loop: P2pEventLoop,
) {
    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .unwrap()
        .block_on(async {
            let tcp_listener = tokio::net::TcpListener::bind(tcp_address).await.unwrap();

            tokio::spawn(p2p_event_loop.run());
            axum::serve(tcp_listener, api_router).await.unwrap();
        })
}

/// Should pack ready to use state and connect routes.
pub fn build_api_server(
    git_repo: git2::Repository,
    address: &str,
    s2s_client: KadClient,
) -> axum::Router<()> {
    let state = ServerState {
        git_repo: Arc::new(Mutex::new(git_repo)),
        address: Cow::Owned(address.to_owned()),
        s2s_client,
    };

    let router = axum::Router::new()
        .route("/favicon.ico", axum::routing::any(|| async { "not set" }))
        .route(
            "/connected-peers.json",
            axum::routing::get(connected_peers::get).post(connected_peers::add_new),
        )
        .route("/git", git_proxy::new_proxy("/git"))
        .route("/git/*path", git_proxy::new_proxy("/git/"))
        .route("/:file_path", axum::routing::get(get::get))
        .with_state(state);

    router
}
