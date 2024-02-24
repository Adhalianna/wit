use std::ops::Deref;

use git2::Repository;

use crate::file::local::StoredFile;

const MAIN_REF: &'static str = "refs/main/HEAD";

#[derive(thiserror::Error, Debug)]
pub enum GitFetchError {
    #[error("failed to extract from the repository the rev matching `{MAIN_REF}`")]
    RevExtractionFailure(#[source] git2::Error),
    #[error("provided git rev or path was invalid, resulting refname was `{reference}`")]
    InvalidRefname {
        source: git2::Error,
        reference: String,
    },
    #[error("failed to access git repository's ODB")]
    OdbError(#[source] git2::Error),
}

/// Reads a file from git's ODB matching the current rev which is equivalent to
/// `refs/main/HEAD`.
pub fn get_current_rev_file_from_odb(
    repo: &impl Deref<Target = Repository>,
    path: &str,
) -> Result<StoredFile, GitFetchError> {
    let current_head = repo
        .head()
        .and_then(|reference| reference.peel_to_commit())
        .and_then(|commit| Ok(commit.id().to_string()))
        .map_err(|e| GitFetchError::RevExtractionFailure(e))?;

    let file = get_file_from_odb(repo, &current_head, path)?;
    Ok(file)
}

/// Reads a file from git's object database.
pub fn get_file_from_odb(
    repo: &impl Deref<Target = Repository>,
    rev: &str,
    path: &str,
) -> Result<StoredFile, GitFetchError> {
    let reference = rev.to_owned() + ":" + path;
    let oid = repo
        .revparse_ext(&reference)
        .and_then(|(object, _)| Ok(object.id()))
        .map_err(|e| GitFetchError::InvalidRefname {
            source: e,
            reference,
        })?;
    let blob = repo
        .find_blob(oid)
        .map_err(|e| GitFetchError::OdbError(e))?;

    let data = blob.content().to_owned();
    let file = StoredFile::new(path, data, blob.is_binary());

    Ok(file)
}
