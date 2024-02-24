use crate::{file::file_data::FileData, server::link::ResolvedHost};

#[derive(Debug, Clone, serde::Deserialize, serde::Serialize)]
pub struct RemoteFile {
    path: String,
    data: FileData,
    remote: ResolvedHost,
}

impl RemoteFile {
    pub fn new(
        remote_url: &str,
        data: Vec<u8>,
        is_binary: bool,
    ) -> Result<Self, Box<dyn std::error::Error>> {
        //TODO: fix, unreliable parsing, wrong:
        let (name, suffix) = remote_url.rsplit_once('.').unwrap_or((remote_url, ""));
        let link = crate::server::link::WitLink::from_url(remote_url)?;
        let name = link.file;
        let remote = link.host.to_host();
        let data = {
            if is_binary {
                FileData::Binary(data)
            } else {
                match (&name, suffix) {
                    (_, "md") => FileData::Markdown(data),
                    (_, "html") => FileData::HTML(data),
                    (_, "txt") => FileData::OtherTxt(data),
                    _ => FileData::Markdown(data),
                }
            }
        };
        return Ok(Self {
            remote,
            path: name,
            data,
        });
    }
    pub fn path(&self) -> &str {
        &self.path
    }
    pub fn remote(&self) -> &ResolvedHost {
        &self.remote
    }
}
