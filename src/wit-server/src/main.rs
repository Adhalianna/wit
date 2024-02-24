#![allow(unused)] // this is prototype software, those warnings are unproductive

// General TODOs/improvements that should be realised to make this anyhow release worthy:
// - replace as much of Box<dyn Error + Send ...> with `anyhow` or concrete error types
// - try to refactor CURRENT_HOST to be passed around instead of being used as a global variable

use axum::Json;
use clap::{Parser, Subcommand};

pub mod config;

pub mod init;
use init::init;

pub mod server;
use server::run;

pub mod file;
pub mod git_storage;
pub mod version;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Option<Command>,

    /// Path to the storage directory containing the wit wiki files
    #[arg(short, long, value_name = "PATH", global = true, default_value_t = {".".to_owned()} )]
    storage_path: String,

    /// IP address and port to which the server should bind its HTTP traffic
    #[arg(short, long, value_name = "HTTP_ADDRESS")]
    address: Option<String>,
}

#[derive(Subcommand)]
enum Command {
    /// Initialize a wiki server.
    Init {
        /// Perform just the initialization and do not run the server afterwards.
        #[arg(short = 'n', long)]
        do_not_run: bool,
        /// Force initialization of a new wiki even when files indicating existence of other wiki exist.
        #[arg(short = 'f', long)]
        force: bool,

        /// Username used in commits made by the wit server. If not provided the application will attempt to set one from the default git configuration on the system.
        #[arg(short = 'U', long, value_name = "USERNAME")]
        git_user_name: Option<String>,
        /// Email used in commits made by the wit server. If not provided the application will attempt to set one from the default git configuration on the system.
        #[arg(short = 'E', long, value_name = "EMAIL")]
        git_user_email: Option<String>,

        /// The domain to be used when resolving links pointing to this wiki
        #[arg(short, long, value_name = "DOMAIN")]
        domain: Option<String>,
    },
    /// Create a network with another server available at provided address.
    Connect {
        /// The address under which another server is available.
        #[arg(value_name = "SERVER_ADDRESS")]
        address: String,
    },
    /// Disconnect selected address from server-to-server network.
    Disconnect { address: String },
}

pub fn main() {
    let cli = Cli::parse();

    match cli.command {
        None => {
            let storage_path = cli.storage_path;
            let http_address = cli.address;

            let config = crate::config::read_config_file(&storage_path).unwrap();
            let domain = config.domain().map(|s| s.to_owned());
            let p2p_keys = config.keys();
            let registered_peers = config.peers();

            run(
                &storage_path,
                http_address,
                domain,
                p2p_keys,
                registered_peers,
            );
        }
        Some(command) => match command {
            Command::Init {
                do_not_run,
                force,
                git_user_name,
                git_user_email,
                domain,
            } => {
                let storage_path = cli.storage_path;
                let address = cli.address;

                init(force, &storage_path, git_user_name, git_user_email, domain).unwrap();

                if !do_not_run {
                    let config = crate::config::read_config_file(&storage_path).unwrap();
                    let domain = config.domain().map(str::to_owned);
                    let p2p_keys = config.keys();
                    let registered_peers = config.peers();

                    run(&storage_path, address, domain, p2p_keys, registered_peers);
                }
            }
            Command::Connect { address } => {
                let mut config = crate::config::read_config_file(&cli.storage_path).unwrap();
                let server_address = cli.address;
                let domain = config.domain().map(str::to_owned);

                let request_address =
                    domain.unwrap_or(server_address.unwrap_or(String::from("localhost:3000")));

                let address: libp2p::Multiaddr = address.parse().unwrap();
                let signature = config.keys().sign(&address.to_vec()).unwrap();

                config.push_peer(address.clone());
                crate::config::update_config_file(&cli.storage_path, config);

                let reqwest_client = reqwest::Client::new();

                reqwest_client
                    .post(request_address + "/connected-peers.json")
                    .json(&crate::server::connected_peers::ConnectNewRequest::new(
                        address, signature,
                    ));
            }
            Command::Disconnect { address } => unimplemented!(),
        },
    }
}
