use clap::{Parser, Subcommand};

pub mod wiki_meta;

pub mod init;
use init::init;

pub mod server;
use server::run;

#[derive(Parser)]
#[command(author, version, about, long_about = None)]
struct Cli {
    #[command(subcommand)]
    command: Option<Command>,

    /// Path to the storage directory containing the wit wiki files
    #[arg(short, long, value_name = "PATH", global = true, default_value_t = {".".to_owned()} )]
    storage_path: String,

    #[arg(short, long, value_name = " ")]
    address: Option<String>,
}

#[derive(Subcommand)]
enum Command {
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
    },
}

pub fn main() {
    // 1. Check if there is a repo in the working directory
    // - None => create one and create metadata file
    // - Some => go on
    // 2. Check for metadata used by wit
    // - None => create one and warn that the repository might not be a wit wiki
    // - Some => go on

    let cli = Cli::parse();

    match cli.command {
        None => {
            let storage_path = cli.storage_path;
            run(&storage_path);
        }
        Some(command) => match command {
            Command::Init {
                do_not_run,
                force,
                git_user_name,
                git_user_email,
            } => {
                let storage_path = cli.storage_path;

                init(force, &storage_path, git_user_name, git_user_email).unwrap();

                if !do_not_run {
                    run(&storage_path);
                }
            }
        },
    }
}
