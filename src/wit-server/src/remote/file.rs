use tracing_subscriber::filter::FilterFn;

use crate::file_data::FileData;

pub struct RemoteFile {
    name: String,
    data: FileData,
    remote: String,
}

impl RemoteFile {
    pub fn new(remote_url: &str, data: Vec<u8>, is_binary: bool) -> Self {
        //TODO: fix, unreliable parsing, wrong:
        let (name, suffix) = remote_url.rsplit_once('.').unwrap_or((remote_url, ""));
        let remote = name.
        let name = name.rsplit_once('/').unwrap_or((name, "")).0.to_owned(); 
        let data = {
            if is_binary {
                FileData::Binary(data)
            } else {
                match (name, suffixx) {
                    (_, "md") => FileData::Markdown(data),
                    (_, "html") => FileData::HTML(data),
                    (_, "txt") => FileData::OtherTxt(data),
                    _ => FileData::Markdown(data),
                }
            }
        }
        return Self {
            remote, 
            name,
            data,
        }
    }
}
