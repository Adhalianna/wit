pub mod markdown;
use axum::http::{header, HeaderMap, StatusCode};

use crate::local::StoredFile;

pub enum RenderedFile {
    Html(String),
    Binary { bytes: Vec<u8>, content: String },
}

impl axum::response::IntoResponse for RenderedFile {
    fn into_response(self) -> axum::response::Response {
        let response_headers = {
            let mut headers = HeaderMap::new();
            headers.insert(
                header::CONTENT_TYPE,
                match &self {
                    RenderedFile::Html(_) => "text/html".try_into().unwrap(),
                    RenderedFile::Binary { bytes: _, content } => content.try_into().unwrap(),
                },
            );
            headers
        };
        (
            StatusCode::OK,
            response_headers,
            match self {
                RenderedFile::Html(page) => page.into_bytes(),
                RenderedFile::Binary { bytes, content: _ } => bytes,
            },
        )
            .into_response()
    }
}

#[derive(thiserror::Error, Debug)]
pub enum RenderError {
    #[error("file has invalid encoding")]
    InvalidUTF8,
}

impl axum::response::IntoResponse for RenderError {
    fn into_response(self) -> axum::response::Response {
        (StatusCode::INTERNAL_SERVER_ERROR, self.to_string()).into_response()
    }
}

pub fn render(file: StoredFile, current_address: &str) -> Result<RenderedFile, RenderError> {
    match file.take_data() {
        crate::local::file::FileData::Binary(_) => todo!(),
        crate::local::file::FileData::Markdown(data) => Ok(RenderedFile::Html(markdown::render(
            data.clone(),
            current_address,
        )?)),
        crate::local::file::FileData::HTML(data) => Ok(RenderedFile::Html(
            String::from_utf8(data).map_err(|_| RenderError::InvalidUTF8)?,
        )),
        crate::local::file::FileData::OtherTxt(data) => Ok(RenderedFile::Html(
            String::from_utf8(data).map_err(|_| RenderError::InvalidUTF8)?,
        )),
    }
}
