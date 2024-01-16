use axum::response::IntoResponse;
use http::{uri::PathAndQuery, StatusCode, Uri};
use std::{convert::Infallible, error::Error, str::FromStr};
use tower::ServiceExt as TowerExt;
use tower_cgi::CgiResponse;

use super::ServerState;

#[derive(thiserror::Error, Debug)]
#[error("failed to proxy git transport communication")]
struct ProxyError;

impl From<Box<dyn Error + Send + Sync + 'static>> for ProxyError {
    fn from(_: Box<dyn Error + Send + Sync + 'static>) -> Self {
        Self
    }
}

pub fn new_proxy(
    strip_prefix: impl AsRef<str> + 'static + Send + Sync + Clone,
) -> axum::routing::MethodRouter<ServerState> {
    let git_http_impl_path = String::from_utf8(
        std::process::Command::new("which")
            .arg("git-http-backend")
            .output()
            .unwrap()
            .stdout,
    )
    .unwrap();

    let git_http_impl_path = git_http_impl_path.trim();

    let proxy = tower_cgi::Cgi::new(git_http_impl_path)
        .env_clear(false)
        .boxed_clone();
    let proxy = proxy
        .map_request(move |mut req: axum::extract::Request<axum::body::Body>| {
            let uri = req.uri_mut();
            if let Some(stripped_path) = uri.path().strip_prefix(strip_prefix.as_ref()) {
                let query = uri.query();
                let path_and_query_str = "/".to_owned()
                    + stripped_path
                    + &(if let Some(query) = query {
                        "?".to_owned() + &query
                    } else {
                        "".to_owned()
                    });
                let mut uri_parts = uri.clone().into_parts();
                uri_parts.path_and_query =
                    Some(PathAndQuery::from_str(&path_and_query_str).unwrap());
                *uri = Uri::from_parts(uri_parts).unwrap();
                req
            } else {
                req
            }
        })
        .map_result(
            |res: Result<CgiResponse, Box<dyn Error + Sync + Send>>| match res {
                Ok(response) => {
                    let (parts, body) = response.into_parts();
                    Result::<_, ProxyError>::Ok(axum::response::Response::from_parts(
                        parts,
                        axum::body::Body::from_stream(body),
                    ))
                }
                Err(_) => Result::<_, ProxyError>::Ok({
                    (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        "failed to receive git transport responses from cgi proxy",
                    )
                        .into_response()
                }),
            },
        )
        .map_err(|_: ProxyError| -> Infallible { panic!() });

    axum::routing::any_service(proxy)
}
