#import "presentation-template.typ": slides, transition


#show: slides.with(
    title: "Wiki on top of Git",
    author: "Natalia Goc",
    date: "2023-10-24",
)

= Why git?

- core element of work environment for many software developers
- ready VCS solution

= Existing wiki software based on git

- GitHub Wiki Pages
- GitLab Wiki 
- gollum

= Existing wiki software based on git (+extra)

#show table: set text(size: 5pt)
#table(
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto, auto),
    align: horizon,
    [], [render global ToC], [web UI], [editor UI], [direct access to repository contents], [viewing branches], [supported formats], [validate links], [distribution level], [implementation language],
    [GitHub], [yes, managed with file], [yes], [yes], [yes], [no], [AsciiDoc, GitHub Markdown, MediaWiki, and more], [no], [git], [?],
    [GitLab], [yes, managed with file], [yes], [yes], [yes], [no], [GitLab Markdown], [no], [git], [Ruby],
    [gollum], [file tree], [yes], [yes], [no], [no], [custom, AsciiDoc], [no], [git], [Ruby],
    [wit], [maybe], [yes], [no], [yes], [maybe], [Markdown], [yes], [git + federated], [Rust],
    [fedwiki], [no], [yes], [yes], [not applicable], [similar mechanism available], [custom, mixed content], [?], [federated], [CoffeScript]
    
)

#transition()[Distributed Wiki]

= Design goals

- interface similar to git
- use of git submodules hidden from the user
- wiki links checked before commit
- web server for viewing wiki contents
    - URL scheme allowing viewing content of specific version

= Utilized git features

- VCS
- submodules
- git hooks (pre-commit)

= Architecture

#figure(image("./architecture-simple.svg", height: 80%))

= Architecture

#figure(image("./web-interaction.svg", height: 80%))

= CLI client design goals

- *`git status` → `wit status`* - show uncommitted changes to the wiki 
    (while being in the project git repository operates as if within the submodule)
- *`git log` → `wit log`* - show history of changes to the wiki including available
    changes from other servers (pulls more information than `git log` run within submodule,
    utilizes the distributed nature of the servers)
- *`git commit` → `wit commit`* - saves changes in a commit in both the submodule and the
    project git repository and the submodule (default mode of operation)
- *`git init` → `wit init`* - starts a new wiki submodule in the git repository storing the project
- *`git add` → `wit add`*
- *`git pull` → `wit pull`* 

= Wiki links

#align(center)[
    ```
    @@[<server-name>:]<file-path>[#<section>]@@
    ```
]

- the in-file format
- should be easy to extract from any file format
- reference content in external or local server
- translated on render by the HTTP web server component

= URL scheme

#align(center)[
    ```
    www.my-own-wiki.com/[<version>/]<file-path>
    0.0.0.0:3000/[<version>/]<file-path>
    ```
]

Problems:
- branches (most likely) not supported
- escaping within each supported file format to avoid breaking
    syntax highlighting tools
- the version string?

= Versioning in distributed context

*Version vector*
- initially all vector counters are zero
- each time a replica experiences an update, it increments its own counter in
    the vector by one
- each time replicas synchronize, they set elements in their copy of the
    vector to the maximum of the element across both counters:
    $V_a [x] = V_b [x] = max(V_a [x], V_b [x])$

#align(center)[#image("./extra-images/version-vector.png", height: 28%)]

= Versioning in distributed context

Limitations of version vector:
- adding and removing dynamically replicas could invalidate previously
    existing version vectors

Alternatives:
- version stamps
    - assumes replicas join and fork
    - representation can reduce on join
    - tracks causality
- interval tree clocks
    - assumes replicas joind and fork
    - no global identifiers => version string not universal between servers
    
= Versioning in git repositories

- `601a610120ac669abaa1022996b616ceeab282dd` #linebreak()
    SHA1 uniquely identifying commit in a repository.
- `601a610` #linebreak()
    The same commit reference abbreviated to uniquely identifying prefix.
    (Variable length, Linux kernel needs 12 characters now.)
- causality is not reflected in the representation

= New layer of versioning

Possible solutions to explore:
- keep a database mapping global version to a local (git) version
- limit versions to work for a single remote only
- use a solution based on distributed ledger (not-a-crypto-currency blockchain)
- create a distributed snapshot on each commit (Chandy-Lamport algorithm) and collect it before operation finishes

= Paper goals

- evaluate the overhead introduced by using a distributed wiki as
    opposed to other wiki software based on git (benchmarks)
- find a good string representation of a version in the distributed context