# Repository dependencies and recommended software

## Build dependencies

- [`just`](https://github.com/casey/just) command runner, inspired by `make`, convienient automation of 
  mundane tasks.
- [`typst`](https://github.com/typst/typst) a LaTeX alternative, the free CLI application can be used
  to render the documents with `.typ` extension to PDF files.
- [`d2`](https://github.com/terrastruct/d2) simple diagram scripting language and a compiler.
- [`Rust`](https://www.rust-lang.org/) the programming language used in the implementation, as a result
    of proper instalation multiple binaries should be available including: `rustup`, `cargo`.
    
## Recommended software

- [`watchexec`](https://github.com/watchexec/watchexec)
    ```sh
    # Example. Run in the root of the repository.
    watchexec just render-design
    ```
- [`Sioyek`](https://github.com/ahrm/sioyek) a minimalistic PDF viewer which reloads content on changes. 
    When used in combination with `watchexec` and proper `just` command it allows for "hot-reloading" 
    the PDFs as they get edited.
    
# Repository structure

```txt
.
├── doc       # thesis paper and any related to project documents
├── src       # source code of the implementation
├── (target)  # __generated__ by cargo, contains compilation artifacts
└── test      # test files
justfile      # defines commands available through just
(Cargo.lock)  # __generated__ by cargo, lists resolved dependencies
Cargo.toml    # Rust project manifest
...
```