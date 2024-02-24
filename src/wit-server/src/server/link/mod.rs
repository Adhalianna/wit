use std::{fmt::Display, str::FromStr};

/// Should be initialized at start of the program.
pub static CURRENT_HOST: std::sync::OnceLock<&'static str> = std::sync::OnceLock::new();

#[derive(Debug, Default)]
pub struct WitLink {
    pub version: CurrentOrVersioned,
    pub host: LocalOrRemote,
    pub file: String,
    pub fragment: Option<String>,
}

impl ToString for WitLink {
    fn to_string(&self) -> String {
        todo!()
    }
}

#[derive(Debug, PartialEq, Eq, Clone, serde::Serialize, serde::Deserialize)]
pub struct ResolvedHost(String);

impl Display for ResolvedHost {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(&self.0)
    }
}

#[derive(Debug, Default, PartialEq, Eq, Clone)]
pub enum LocalOrRemote {
    #[default]
    Local,
    Remote(String),
}

impl LocalOrRemote {
    pub fn to_host(self) -> ResolvedHost {
        match self {
            LocalOrRemote::Local => ResolvedHost(
                CURRENT_HOST
                    .get()
                    .expect("CURRENT_HOST global var set")
                    .to_string(),
            ),
            LocalOrRemote::Remote(host) => ResolvedHost(host),
        }
    }
}

impl FromStr for LocalOrRemote {
    type Err = std::convert::Infallible;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "" => Ok(Self::Local),
            "local" => Ok(Self::Local),
            s => Ok(Self::Remote(s.to_owned())),
        }
    }
}

#[derive(Debug, Default, PartialEq, Eq)]
pub enum CurrentOrVersioned {
    #[default]
    Current,
    Version(String),
}

#[derive(thiserror::Error, Debug)]
pub enum LinkParsingErr {
    #[error("expected a valid URL")]
    InvalidURL,
    #[error("scheme {scheme} is not supported")]
    UnsupportedScheme { scheme: String },
}

impl WitLink {
    pub fn from_url(url: &str) -> Result<Self, LinkParsingErr> {
        let url = url::Url::parse(url).map_err(|_| LinkParsingErr::InvalidURL)?;

        fn host_from_url(url: &url::Url) -> LocalOrRemote {
            match url.host_str() {
                Some(h) => (h.to_owned()
                    + &url
                        .port()
                        .map(|n| ":".to_owned() + &n.to_string())
                        .unwrap_or("".to_owned()))
                    .parse()
                    .unwrap(),
                None => LocalOrRemote::Local,
            }
        }

        match url.scheme() {
            "http" | "https" => {
                let host = host_from_url(&url);

                todo!()
            }
            "wit" => {
                let version = if url.username() == "" {
                    CurrentOrVersioned::Current
                } else {
                    CurrentOrVersioned::Version(url.username().to_owned())
                };
                let host = host_from_url(&url);
                let file = url.path().to_owned();

                let fragment = url.fragment().map(|s| s.to_owned());

                Ok(Self {
                    version,
                    host,
                    file,
                    fragment,
                })
            }
            scheme => Err(LinkParsingErr::UnsupportedScheme {
                scheme: scheme.to_owned(),
            }),
        }
    }
    /// # Panics
    /// Panics if [`CURRENT_HOST`] is not initialized.
    pub fn to_http(&self) -> String {
        format!(
            "http://{}/{}{}",
            CURRENT_HOST
                .get()
                .expect("CURRENT_HOST not initialized yet"),
            self.file,
            match &self.fragment {
                Some(frag) => "#".to_owned() + frag,
                None => "".to_owned(),
            }
        )
    }
    /// # Portability
    /// Wit URIs are valid only on the server they were created at. Use HTTP
    /// URI to achieve portability.
    pub fn to_wit(&self) -> String {
        format!(
            "wit://{}/{}{}",
            match &self.host {
                LocalOrRemote::Local => "",
                LocalOrRemote::Remote(remote) => remote,
            },
            self.file,
            match &self.fragment {
                Some(frag) => "#".to_owned() + frag,
                None => "".to_owned(),
            }
        )
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn relative_path_current_local_file() {
        let link = WitLink::from_url("wit:test.md").unwrap();
        assert_eq!(&link.file, "test.md");
        assert_eq!(link.host, LocalOrRemote::Local);
        assert_eq!(link.version, CurrentOrVersioned::Current);

        let link = WitLink::from_url("wit:dir/test.md").unwrap();
        assert_eq!(&link.file, "dir/test.md");
    }

    #[test]
    fn local_current_file() {
        let link = WitLink::from_url("wit:///dir/test.md").unwrap();
        assert_eq!(&link.file, "/dir/test.md");
        assert_eq!(link.host, LocalOrRemote::Local);
        assert_eq!(link.version, CurrentOrVersioned::Current);
    }

    #[test]
    fn local_versioned_file() {
        let link = WitLink::from_url("wit://versionStr@local/test.md").unwrap();
        assert_eq!(&link.file, "/test.md");
        assert_eq!(link.host, LocalOrRemote::Local);
        assert_eq!(
            link.version,
            CurrentOrVersioned::Version("versionStr".to_owned())
        )
    }

    #[test]
    fn current_remote_file() {
        let link = WitLink::from_url("wit://remotehost.com/test.md").unwrap();

        assert_eq!(&link.file, "/test.md");
        assert_eq!(
            link.host,
            LocalOrRemote::Remote("remotehost.com".to_owned())
        );
        assert_eq!(link.version, CurrentOrVersioned::Current);

        let link = WitLink::from_url("wit://localhost:3000/dir/test.md#welcome").unwrap();

        assert_eq!(
            link.host,
            LocalOrRemote::Remote("localhost:3000".to_owned())
        );
    }

    #[test]
    fn file_fragment() {
        let link = WitLink::from_url("wit://remotehost.com/test.md#welcome").unwrap();
        assert_eq!(link.fragment, Some("welcome".to_owned()));

        let link = WitLink::from_url("wit://versionStr@local/test.md#hi-there").unwrap();
        assert_eq!(link.fragment, Some("hi-there".to_owned()));

        let link = WitLink::from_url("wit://test.md").unwrap();
        assert_eq!(link.fragment, None);
    }
}
