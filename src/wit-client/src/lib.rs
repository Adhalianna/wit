use std::io::{Read, Write};
use std::path::Path;

static WIT_MODULE_NAME: &'static str = "WitWikiModule";
pub static DEFAULT_WIT_DIR: &'static str = ".wit";

/// # Safety
/// In case of `file://` URLs perform only on paths to existing files and directories
// TODO: handle the error that happens when file:// url points to non-existing
// place. The error should be returned for the user to handle.
fn canonicalize_url(url: &str) -> String {
    let mut canonical = url.to_string();
    match url {
        url if url.starts_with("file://") => {
            let from_str = url.strip_prefix("file://").unwrap();
            let p = Path::new(&from_str);
            let pb = p.canonicalize().unwrap();
            canonical = pb.to_str().unwrap().to_owned();
            canonical = String::from("file://") + &canonical;
        }
        _ => {}
    };
    return canonical;
}

pub fn init_submodule(repo_at: &str, wit_dir: Option<&str>, from: &str) {
    let git_repo = git2::Repository::discover(repo_at).unwrap();

    let submodule_remote_url = canonicalize_url(&from);
    let wit_dir = wit_dir.unwrap_or(DEFAULT_WIT_DIR);
    let mut submodule = git_repo
        .submodule(&submodule_remote_url, Path::new(wit_dir), false)
        .unwrap();

    submodule.init(false).unwrap();
    let sub_repo = submodule
        .clone(Some(git2::SubmoduleUpdateOptions::new().allow_fetch(true)))
        .unwrap();

    sub_repo.set_head("refs/heads/main").unwrap();

    // Change the submodule name so that it is always known to the tool no matter which directory was chosen to store the module
    // 1. In .gitmodules
    {
        let mut gitmodules_file = std::fs::OpenOptions::new()
            .read(true)
            .open(git_repo.workdir().unwrap().join(".gitmodules"))
            .unwrap();

        let mut file_contents = String::new();
        gitmodules_file.read_to_string(&mut file_contents).unwrap();
        // find and replace the line
        let pattern_to_replace = format!("[submodule \"{wit_dir}\"]");
        let mut lines: Vec<String> = file_contents
            .split('\n')
            .map(|str| str.to_owned())
            .collect();
        let to_modify = lines
            .iter_mut()
            .find(|line| line.contains(&pattern_to_replace))
            .unwrap();
        *to_modify = format!("[submodule \"{WIT_MODULE_NAME}\"]");

        // reopen and truncate previous contents
        let mut gitmodules_file = std::fs::OpenOptions::new()
            .write(true)
            .truncate(true)
            .open(git_repo.workdir().unwrap().join(".gitmodules"))
            .unwrap();

        gitmodules_file
            .write_all(
                // SAFETY: the contents won't be actually changing (no UTF-8 violations), we just need the buffer to be mut
                unsafe { lines.join("\n").as_bytes_mut() },
            )
            .unwrap();
    }
    // 2. In .git/config
    {
        let mut config = git_repo.config().unwrap();

        let key_prefix_to_replace = format!("submodule.{wit_dir}");
        let new_key_prefix = format!("submodule.{WIT_MODULE_NAME}");

        let old_url_key = key_prefix_to_replace.clone() + ".url";

        let old_url_val = {
            let url_entry = config.get_entry(&old_url_key).unwrap();
            url_entry.value().unwrap().to_owned()
        };
        config.remove(&old_url_key).unwrap();

        config
            .set_str(&(new_key_prefix.clone() + ".url"), &old_url_val)
            .unwrap();
        config
            .set_str(&(new_key_prefix + ".path"), &wit_dir)
            .unwrap();
    }
    submodule.add_finalize().unwrap();
}

pub fn add_files(repo_at: &str, files: &[&str]) {
    let git_repo = git2::Repository::discover(repo_at).unwrap();
    let submodule = git_repo.find_submodule(WIT_MODULE_NAME).unwrap();
    let submodule_repo = submodule.open().unwrap();

    let mut index = submodule_repo.index().unwrap();
    index
        .add_all(files, git2::IndexAddOption::DEFAULT, None)
        .unwrap();
    index.write().unwrap();
}

pub fn commit(repo_at: &str, msg: &str) {
    let git_repo = git2::Repository::discover(repo_at).unwrap();
    let mut submodule = git_repo.find_submodule(WIT_MODULE_NAME).unwrap();
    let submodule_repo = submodule.open().unwrap();

    // Prepare commit
    let signature = submodule_repo
        .signature()
        .unwrap_or_else(|_| git_repo.signature().unwrap());
    let commit_tree_oid = submodule_repo.index().unwrap().write_tree().unwrap();
    let commit_tree = submodule_repo.find_tree(commit_tree_oid).unwrap();
    let previous_commit_oid = submodule_repo
        .resolve_reference_from_short_name("HEAD")
        .unwrap()
        .peel_to_commit()
        .unwrap();

    // Create a commit within the submodule
    submodule_repo
        .commit(
            Some("HEAD"),
            &signature,
            &signature,
            msg,
            &commit_tree,
            &[&previous_commit_oid],
        )
        .unwrap();
    // Add changes to HEAD of submodule into index of changes of parent repo
    submodule.add_to_index(true).unwrap();

    // TODO: create a commit in the parent repo in a smart way
}

pub fn push(repo_at: &str) {
    let git_repo = git2::Repository::discover(repo_at).unwrap();
    let submodule = git_repo.find_submodule(WIT_MODULE_NAME).unwrap();
    let submodule_repo = submodule.open().unwrap();
    let mut remote = submodule_repo.find_remote("origin").unwrap();

    remote.connect(git2::Direction::Push).unwrap();
    let mut callbacks = git2::RemoteCallbacks::new();

    callbacks.push_update_reference(|reference, status| match status {
        Some(status) => {
            panic!("failed to push to ref {reference} with {status}");
        }
        None => Ok(()),
    });

    remote
        .push(
            &["refs/heads/main"],
            Some(git2::PushOptions::new().remote_callbacks(callbacks)),
        )
        .unwrap();
}

pub fn main() {}
