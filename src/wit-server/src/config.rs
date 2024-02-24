use base64::Engine;
use libp2p::Multiaddr;

/// Name of the file storing metadata of the wit wiki
pub const CONFIG_FILENAME: &'static str = "WitConfig.toml";

pub fn read_config_file(storage_path: &str) -> Result<WikiConfig, Box<dyn std::error::Error>> {
    use std::io::Read;

    let config_file_path = storage_path.to_owned() + "/" + crate::config::CONFIG_FILENAME;
    let mut file = std::fs::File::open(config_file_path)?;
    let mut bytes = Vec::<u8>::with_capacity(2048 * 8);
    let len = file.read_to_end(&mut bytes)?;
    let string = std::str::from_utf8(&bytes[..len])?;
    let config: WikiConfig = toml::from_str(string)?;
    Ok(config)
}

pub fn update_config_file(
    storage_path: &str,
    config: WikiConfig,
) -> Result<(), Box<dyn std::error::Error>> {
    use std::io::Write;

    let config_file_path = storage_path.to_owned() + "/" + crate::config::CONFIG_FILENAME;
    let mut file = std::fs::OpenOptions::new()
        .truncate(true)
        .write(true)
        .open(&config_file_path)?;

    file.write_all(toml::to_string(&config)?.as_bytes())?;
    file.sync_all()?;
    Ok(())
}

#[derive(serde::Deserialize, serde::Serialize, Debug)]
pub struct WikiConfig {
    id: String,
    #[serde(default)]
    description: Option<String>,
    // TODO: add key/password required to connect to the wiki and admin it remotely
    #[serde(default)]
    password: Option<String>,
    // TODO: add possibility of setting a favicon
    #[serde(default)]
    favicon: Option<String>,
    #[serde(default)]
    domain: Option<String>,
    private_p2p_key: String,
    public_p2p_key: String, // might not be needed
    #[serde(default)]
    peers: Vec<Multiaddr>,
}

impl WikiConfig {
    pub fn new() -> Self {
        let id = uuid::Uuid::new_v4();
        let mut buf = [0u8; 32];
        let id = id.as_simple().encode_lower(&mut buf).to_owned();

        let p2p_networking_keys = libp2p::identity::ed25519::Keypair::generate();
        let private_p2p_key =
            base64::prelude::BASE64_STANDARD.encode(p2p_networking_keys.secret().as_ref());
        let public_p2p_key =
            base64::prelude::BASE64_STANDARD.encode(p2p_networking_keys.public().to_bytes());

        Self {
            id,
            description: None,
            password: None,
            favicon: None,
            domain: None,
            private_p2p_key,
            public_p2p_key,
            peers: vec![],
        }
    }
    pub fn domain(&self) -> Option<&str> {
        (&self.domain).as_deref()
    }
    // Use owned domain if available instead of IP address when resolving links
    pub fn set_domain(mut self, domain: Option<String>) -> Self {
        self.domain = domain;
        self
    }
    pub fn push_peer(&mut self, address: Multiaddr) {
        self.peers.push(address)
    }
    pub fn peers(&self) -> &[Multiaddr] {
        &self.peers
    }
    /// # Panics
    /// Panics if any of the keys cannot be decoded back to build a [`KeyPair`](libp2p::identity::ed25519::KeyPair)
    pub fn keys(&self) -> libp2p::identity::Keypair {
        let private = libp2p::identity::ed25519::SecretKey::try_from_bytes(
            base64::prelude::BASE64_STANDARD
                .decode(self.private_p2p_key.as_str())
                .unwrap(),
        )
        .expect("failed to decode private key for wiki-to-wiki networking");

        libp2p::identity::ed25519::Keypair::from(private).into()
    }
}

#[derive(serde::Deserialize, serde::Serialize)]
pub struct Remotes(Vec<Remote>);

#[derive(serde::Deserialize, serde::Serialize)]
pub struct Remote {
    local_name: String,
    url: String,
}
