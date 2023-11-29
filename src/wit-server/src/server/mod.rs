use axum::Router;
use std::path::Path;

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
    start_server();
}

pub fn start_server() {
    let main_router = Router::new();

    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .unwrap()
        .block_on(async {
            let tcp_listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await.unwrap();
            
            axum::serve(tcp_listener, main_router).await.unwrap();
        })
}
