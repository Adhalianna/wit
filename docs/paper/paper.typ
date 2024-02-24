#import "diploma_template.typ": diploma

// ------ GLOBAL VARIABLES ------
#let paper_title = "Distributed Wiki on top of Git for inter-project knowledge sharing targeting software developers as users"
#let pl_paper_title = "Rozproszona Wiki oparta o Git do wymiany informacji między projektami skupiająca się na programistach jako użytkownikach"

#let wit() = [
```wit```
]
#let Wit() = [
```Wit```
]

// ------ GLOBAL STYLE ------
#set text(
  size: 12pt, fallback: true, lang: "en", region: "GB", slashed-zero: true, font: (
    "Times New Roman", "Times", "Liberation Serif", "Linux Libertine", "serif", "sans-serif", "Courier New", "Courier", "Source Code Pro", "monospace",
  ),
)
// personal preferred style for code blocks:
#import "@preview/codelst:2.0.0": sourcecode
#show raw.where(block: true): sourcecode.with(frame: (code) => {
  block(inset: 1em, stroke: 1pt + luma(200), fill: luma(260), code)
})
#show raw.where(block: true): set text(size: 1.125em) // slightly enlarge text
#show raw.where(block: false): set text(weight: 550)

// ------ UTILS ------

// Just a quick patch for how d2 renders SVGs
#show image: img => {
  if img.path.ends-with(".svg") {
    let img_data = read(img.path)
    img_data = img_data.replace(
      regex("font-family: \"d2-\d+-font-regular\";"), "font-family: sans-serif, serif;",
    )
    img_data = img_data.replace(
      regex("font-family: \"d2-\d+-font-bold\";"), "font-family: sans-serif, serif; font-weight: bold;",
    )
    img_data = img_data.replace(
      regex("font-family: \"d2-\d+-font-italic\";"), "font-family: sans-serif, serif; font-style: italic;",
    )
    img_data = img_data.replace(
      regex("font-family: \"d2-\d+-font-semibold\";"), "font-family: sans-serif, serif; font-weight: 600;",
    )
    img_data = img_data.replace(
      regex("font-family: \"d2-\d+-font-mono\";"), "font-family: Source Code Pro, Courier New, monospace, mono;",
    )
    img_data = img_data.replace(
      regex("font-family: \"d2-\d+-font-mono-bold\";"), "font-family: Source Code Pro, Courier New, monospace, mono; font-weight: bold;",
    )
    img_data = img_data.replace(
      regex("font-family: \"d2-\d+-font-mono-bold\";"), "font-family: Source Code Pro, Courier New, monospace, mono; font-style: italic;",
    )
    img_data = img_data.replace(regex("@font-face \{.*}"), "") // the nasty bit that's not supported
    image.decode(
      img_data, height: img.at("height", default: auto), width: img.at("width", default: auto),
    )
  } else {
    img
  }
}

// quickly create list-like table:
#let list_table(header: none, ..content_lines) = {
  show table: set block(breakable: true)
  show grid: set block(breakable: true)

  let lines = if type(content_lines) == arguments {
    content_lines.pos()
  } else if type(content_lines) == array {
    content_lines
  } else if type(content_lines) == content {
    (content_lines)
  } else {
    panic("passed wrong type of arguments, expected content")
  }
  let lines = lines.enumerate(start: 1).map(((idx, item)) => ([#idx.], item)).flatten()
  let li = table(
    columns: (auto, auto), align: (center + horizon, start), fill: luma(300), ..lines,
  )
  if type(header) == none or header == none {
    li
  } else if type(header) == content {
    grid(
      rows: (auto, auto), {
        rect(
          inset: 0.66em, fill: luma(240), stroke: 1pt, width: 100%, strong(header),
        )
      }, li,
    )
  } else {
    panic(
      "expected the header argument to be of type content, got: " + type(header),
    )
  }
}

// ------ CODE SNIPPETS ------

// importing them here because otherwise typstfmt messses up formatting
// see https://github.com/astrale-sharp/typstfmt/issues/141

#let snippet_1 = ```rs
#[test]
pub fn client_connects_to_remote_repo() {
  //...
  let server = InitializedTestServer::new();
  let mut client = ClientRepositoryWithWiki::new(server.storage_path_url());
  client.commit_push_txt_file("empty.md", None, "test commit");
}
```

#let snippet_2 = ```rs
#[test]
pub fn server_responds_with_local_files() {
  //...
  let server = InitializedTestServer::new().run();
  //...
  let mut client = ClientRepositoryWithWiki::new(server.git_url());
  client.commit_push_txt_file("empty.md", None, "test commit");
  //...
  reqwest::blocking::get(
    format!("http://{}/empty.md", server.address_str())
  ).unwrap();
}
```

#let snippet_3 = ```rs
#[test]
pub fn server_renders_markdown_files() {
  //...
  let server = InitializedTestServer::new().run();
  //...
  let mut client = ClientRepositoryWithWiki::new(server.git_url());
  client.commit_push_txt_file(
    "welcome.md",
    Some("# Welcome!\ncheckout [this link](www.google.com)!"),
    "test commit",
    );
  //...
  let response = reqwest::blocking::get(
    format!("http://{}/welcome.md", server.address_str())
  ).unwrap();

  assert_eq!(
    response.headers()
      .get("content-type")
      .unwrap(),
    "text/html",
  );
  assert_eq!(
    response.text().unwrap(),
    "<h1 id=\"welcome-\">Welcome!</h1>\n<p>checkout <a href=\"www.google.com\">this link</a>!</p>\n"
  );
}
```

#let snippet_4 = ```rs
#[test]
pub fn server_renders_markdown_files_and_translates_wit_links() {
    //...
    let server = InitializedTestServer::new().run();
    //...
    let mut client = ClientRepositoryWithWiki::new(server.git_url());
    client.commit_push_txt_file(
        "welcome.md",
        Some("# Welcome!\ncheckout [this link](wit:test.txt)!"),
        "test commit",
    );
    //...
    let response = reqwest::blocking::get(
      format!("http://{}/welcome.md", server.address_str())
    ).unwrap();
    assert_eq!(
      response
        .headers()
        .get("content-type")
        .unwrap(),
      "text/html",
    );
    assert_eq!(
        response.text().unwrap(),
        format!("<h1 id=\"welcome-\">Welcome!</h1>\n<p>checkout <a href=\"{}/test.txt\">this link</a>!</p>\n", server.http_url())
    )
}
```

#let snippet_5 = ```rs
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
```

#let snippet_6 = ```rs
#[test]
pub fn server_adds_an_address_to_configuration() {
    //...
    let server = InitializedTestServer::new().run();
    add_new_peer_to(server.storage_path(), "/dns4/example.org");

    let config = wit_server::read_config_file(server.storage_path()).unwrap();
    assert_eq!(
        config.peers().first().unwrap().to_string(),
        "/dns4/example.org"
    );
}
```

#let snippet_7 = ```sh
# To execute the server binary
cargo run --package wit-server
# To learn more about available parameters
cargo run --package wit-server -- --help
# To use execute the server at a different directory than the working directory
cargo run --package wit-server -- -s my_directory/server
# To initialize the server and run it
cargo run --package wit-server -- init
# To initialize the server storage without running it
cargo run --package wit-server -- init -n
# To launch server binding it to an address different than localhost:3000
cargo run --package wit-server -- -a 0.0.0.0:4000
```

#let snippet_8 = ```md
<!-- tmp/test/repos/repository122/welcome.md -->

# Welcome!
checkout [this link](wit:test.txt)!
```

#let snippet_9 = ```toml
# tmp/test/servers/server251/WitConfig.toml

id = "4ff373304d6a4b54a340c8a2b2c1db97"
private_p2p_key = "qGpQw9PW9+WvGL9Ow64mGuu+e7I7gsm1vW+eX8jaggc="
public_p2p_key = "EkHwSZM4t1GcyZHN1IUy2p818BOBwSo044m1WqRK/iM="
peers = []
```

#let snippet_10 = ```md
# Welcome!
To see what groceries need to be done check [this link](wit:list.md).
```

#let snippet_11 = ```md
# Veggies

- 3 small carrots
- 1 beetroot
- 2 potatoes

# Fruits

- 5 apples
- 6 bananas
```

// ------ CONTENT ------
#diploma(
  university_logo_file: "AGH.svg", university: "AGH University of Krakow", faculty: "Faculty of Electrical Engineering, Automatics, Computer Science and Biomedical Engineering", titles: (paper_title, pl_paper_title), short_title: "Distributed Wiki on top of Git", author: (first_name: "Natalia", second_name: "Kinga", surname: "Goc"), degree_programme: "Computer Science", supervisor: "dr. inż. Krzysztof Kluza", location: "Kraków", acknowledgement: [
    I would love to say 'Thank you' to anyone who keeps making and promoting free
    and open source software, plenty of which I have used to write this paper.
  ], abstracts: [
    = Summary
    Contributing to the domain of applications offering a distributed wiki, the
    project defines and presents the initial steps for implementing software that
    enables the creation of a wiki using data stored in multiple separate
    repositories. The goal is to support collaboration between projects and teams
    which do not operate in conditions encouraging the construction of a shared,
    centralized knowledge store. Taking into account the increasing popularity of
    Git for version control the project chooses to aim for a tight integration with
    the Git version control system and to focus on an audience which is most likely
    to use it. The described software introduces unique challenges which are
    elaborated upon in the paper. Additionally, the paper describes the
    implementation and the development of which led to discovering the challenges.

    = Streszczenie
    Uzupełniając szczególną niszę jaką są aplikacje oferujące rozproszoną wiki,
    projekt definiuje i przedstawia pierwsze kroki ku implementacji oprogramowania,
    które pozwala na utworzenie wiki z danych przechowywanych w kilku oddzielnych
    repozytoriach. Celem jest wsparcie współpracy między projektami i zespołami,
    które nie funkcjonują w warunkach sprzyjających rozwojowi wspólnego,
    zcentralizowanego zasobu informacji. Biorąc pod uwagę rosnącą popularność
    zastosowania programu Git do kontroli wersji, zdecydowano się na możliwie jak
    najściślejszą integrację z tym systemem kontroli wersji i skupienie się na
    grupie użytkowników, która najczęściej z niego korzysta. Opisane oprogramowanie
    wymaga rozwiązania unikalnych dla niego problemów, których omówienie zawarto w
    pracy. Ponadto dokumentuje ona implementację oprogramowania, której rozwój
    doprowadził do odkrycia opisanych trudności.
  ], bibliography_file: "bibliography.yml",
)[

= Introduction

Enforcing knowledge consistency in an environment of frequent changes which can
be observed during the development of a software product is still an area seeing
plenty of attention and financial investment. One of the approaches taken by
some organizations that can be seen as sufficiently efficient for a single
project is to store all documentation and design documents in the same Git
repository that is used for the developed software. Whether this approach is
successful for that single repository depends on factors such as the utilised
tools checking the consistency and the developers’ discipline in keeping the
documentation up to date. The task becomes more difficult when consistency has
to be enforced between multiple projects which may be managed by multiple teams.
In such a case there is no single version control system that would synchronize
the knowledge base with each of the code bases. For many use cases, a separate
centralized solution might be sufficient but for those who cannot allow the
relevant data to be stored in a centralized manner, there is little to no open
tooling available.

The thesis goal is to research the possibility of developing tools composing a
distributed wiki system that the software developers working on multiple git
repositories could apply to create links between those repositories that would
maintain referential integrity in a version-conscious manner. Such software
could later be used to compare the effects of a federated approach to
documentation distribution on knowledge sharing efficiency with centralized
solutions such as Jira and many other wikis based on Git VCS.

== Project Naming

#figure(image("img/wit-mnemonic.svg", height: 20%), caption: [
Graphical presentation of the `wit` name origin.
]) <fig_wit_mnemonic>

For the project to be usable it needed a name that would be used for the
executable artifacts. The name #wit has been selected in the spirit of Unix-like
short command names and as a mnemonic or portmanteau referring to the words _wiki_ and _git_.
@fig_wit_mnemonic presents the mnemonic on a graphic.

== Motivation

This project has been inspired by a general academic curiosity and discussions
with colleagues about problems of corporations working with subcontractors on
engineering projects frequently involving data which needs to be kept
confidential. The discussions were often motivated by a frustration resulting
from a mismatch between followed by different teams practices and the
imperfections of used by a company's knowledge-sharing platforms.

The nature of those conversation was confidential and they cannot be further
detailed. Instead, the following list of scenarios in which the #wit project has
an ambition to help has been derived from them:
+ When two teams within a single company or two companies choose to cooperate
  through a wiki while coordinating multiple related projects, because of the
  centralized nature of most wikis, a transfer of knowledge to a new platform is
  necessary. That transfer might turn out not to be successful and as a result,
  some users might prefer to keep using their internal solutions thus making the
  knowledge sharing between involved parties more difficult.
+ A significant amount of companies performs knowledge transfer through file
  transfers with their employees sending required documents on demand or hosting
  them in cloud storage. This solution suffers from a lack of version control and
  it makes creating links between files either hard or impossible. One of the
  collaborating parties might find themselves with outdated documents which might
  even lead to tension between the parties.
+ Providing access to an internal platform of a team or company might not be
  possible or preferable because of sensitive information stored on those
  platforms. Decoupling the knowledge to share from sensitive documents can be
  difficult.
+ Using different platforms and storage solutions for a single project increases
  the burden on its creators who need to switch context and tools frequently to
  move the work forward. In the context of software development, storing all the
  data within a single code repository has the benefit of reducing the amount of
  context switches a programmer has to perform to work on a project.

Interest in web services operating as a federation has also caused further
curiosity about the architecture. Fedwiki is a project most similar in nature to
the topic of this document but with different goals behind its hyperlinks
implementation. While fedwiki aims to empower collaboration through "profligate
copying" @fedwiki_profiligate_copying, the #wit project aims to enable
collaboration in cases when it is desired to maintain distinct ownership of the
data composing a wiki. In such a scenario it might not be desirable to copy data
for modification, like fedwiki does, as that would, at least on a conceptual
level, imply a new authority controlling the data.

Furthermore, #wit builds on top of git to achieve tight integration into
git-based developer workflows. As it is meant to span over multiple
repositories, the work done on the paper might bring some insight into the
development of systems which aim for an extra layer of version control between
independent systems like the ones researched by Schnöhoff et. al
@version_in_federated_database.

== Content of the Thesis

The @theory-intro-chapter introduces the terminology related to the problem
domain. @implementation-chapter desribes the implementation details, starting
from the software architecture and continuing to specific problems unique to the
project. The results of the project are elaborated upon in the @results-chapter.
The @summary-chapter both summarizes the project and explores the potential for
further research.

= Wikis, Version Control Systems, and Distributed Systems <theory-intro-chapter>

Some concepts such as wikis, and distributed systems should be made apparent to
clearly communicate the project's requirements. In particular, the term _wiki_ already
entails a certain amount of expected functionality of the tool. The selection of _git_ as
a part of the implementation and integration target introduces further
constraints. Finally, the _distributed_ property of a system can be realised to
a varying degree, and as such, it is crucial to understand the ideas behind
distributed systems to be able to describe them legibly.

== Definitions

According to Wikipedia, the most popular instance of a wiki, it is a form of
online hypertext publication collaboratively edited and managed by its audience
directly through a web browser @wikipedia_definition. The server software making
up a wiki is referred to as a wiki engine and it offers functionality similar to
a content management system.

Git with which #wit project is meant to be integrated and on which it builds
upon is an example of a Version Control System (VCS, also known as revision
control) @history_of_version_control. A VCS encourages collaboration by
recording each change made to content in such a way that it can be managed e.g.
get reverted. Those systems can be split into two categories: Centralized
Version Control Systems (CVCS), and Distributed Version Control Systems (DVCS)
@version_control_systems_review. DVSCs are characterised as 'distributed'
because they distribute the history of changes between participants. CVCSs on
the other hand keep the history of changes centralised on a single server.

More generally, a distributed system is a collection of autonomous computing
elements that appears to its users as a single coherent system
@distributed_systems_book_def. Such is a definition used by the distributed
computing field. Strictly in this sense git is not a distributed system as its
users do not share computing elements. It does not even align with the typical
goals of a distributed system which usually include:
- supporting resource sharing,
- making distribution transparent,
- providing scalability @distributed_systems_book_design_goals.
Rather than being called a distributed system git should be considered a
decentralized system but the term 'distributed' is a common descriptor used as a
contrast to 'centralized' among VCSs.

== Wikis and Software Development

At present there is an abundance of implementations of a wiki and the form has
been adapted to serve as software documentation. Popular repository-hosting web
services such as GitHub and GitLab offer simple wikis to be hosted alongside
code repositories they would be documenting.

To track changes, revisions, and to avoid a loss of data caused by malicious
editors wikis usually feature some sort of VCS. Conviniently the same VCSs that
are used by software developers can be also employed to create wikis. As such
GitHub and GitLab both use git, the primary technology they offer as a service,
in their wiki implementations @gitlab_wiki_docs @github_wiki_docs.

Git presently is the most popular VCS for source code with a stable trend of
growth. In 2023 GitHub only reported the number of users increasing by 26%
resulting in over 100 million users total @github_octoverse_report_2023. Git
URIs are also showing up more frequently in academic publications
@prevalence_of_git_uri_in_scholar_publications. This trend makes the possibility
to comfortably integrate a wiki with git quite favourable.

= Requirements <requirements-chapter>

Modern software development projects have grown to require collaboration not
only between team members but also between distinct teams within a single
instutution or even across multiple organizations. As such software developers
are likely to need tools facilitating inter-project collaboration. They have
been selected as a the first group of users the application should target and
support in inter-project collaboration.

This section presents various forms of software requirements declaration which
are finally summarised as a list of statements composing a specification. Using
different formats inspires much more precise requirements for the system.

== Use Case Diagram

#figure(image("img/use-case-diagram.svg"), caption: [
  A use case diagram for the suggested system.
]) <fig_use_case_diagram>

@fig_use_case_diagram presents a use case diagram for the system that could be
composed of a CLI client and a server application. The web browser included as
the only inanimate actor operates de facto as another client application. The
diagram provides minimal insight into requirements. A very similar diagram could
be drawn for any arbitrary wiki software as most features unique to #wit are
non-functional requirements.

== User Personas

#figure(
  list_table(
    header: [User Personas], [
      The software developer wants to work on a wiki in a state appropriate to the
      version of their project. it is important to them as they might be at the moment
      amending an older version of the product and it is not desired, for example, to
      apply newer requirements to it. they plan to achieve that by setting their git
      repository to the appropiate version.
    ], [
      The software developer wants to make sure that when they create links they are
      valid references to the parts of the wiki maintained as part of other projects.
      They want it in such a way because they need to be aware of important changes
      like the removal of a page as those might invalidate what they were about to
      write on pages managed by them. They would like to be informed of invalid links
      each time they are about to publish changes preferably by an IDE extension but
      optionally by the execution of a CLI utility that can be included in CI/CD
      pipelines or invoked on demand.
    ], [
      The software developer wants to manage wiki files alongside the git repository
      they are working on. They want it so because their IDE is the most familiar and
      comfortable working environment for them and having a wiki in the same
      repository as the code will reduce the burden of a context switch between source
      code and documentation. They plan to achieve that by keeping the wiki files in a
      subdirectory of their source code repository.
    ], [
      The freshly employed engineer wants to be able to browse the wiki in a graphical
      form. It is important to them that the pages are presentable because it makes
      learning from them a much more pleasant experience. They plan to browse the
      pages rendered to HTML through their web browser of choice as that is the most
      intuitive way of exploring wikis for them.
    ], [
      The network systems administrator wants to be able to shut down any wiki server
      they host without affecting other projects' wikis. It is important to them that
      they cause no data loss to other collaborating parties and that they can do so
      without the need to coordinate the operation with other wiki administrators.
      They expect that shutting down permanently the wiki server process will not
      affect other wikis which might be owned by other organizations.
    ],
  ), caption: [
    A small set of user personas defined to make sure that the application provides
    a good user experience to its target audience.
  ],
) <fig_user_personas>

Since the software is meant to be dedicated to a relatively limited target
audience, a definition of a user persona might prove helpful in defining
interfaces that are clear for that specific group. A user persona, or a _minimal collaborative persona_ @minimal_collaborative_persona,
is an alternative to user stories form of expressing requirements with a focus
on user experience.

The personas in this document are expressed as statements describing three
aspects:
- *Goals* -- answering the question "What do they want?".
- *Purpose* -- expressing the motivation of a user, answering "Why they want it?".
- *Approach* -- suggesting a means a user would take to achieve their goal. It is
  best to support this part with data from the users but having no access to such
  it will be speculated.
Those descriptions consist of multiple free-form sentences and they have been
aggregated in @fig_user_personas. This is a very simple model of a user persona,
similar to a user story. They are not intended to guide all expected features of
the implemented application but instead, they serve as an extra tool for
improving the quality of user experience.

== #Wit as a Distributed System

Besides utilizing a DVCS #wit is expected to have some properties expected of
well-designed distributed system. The distributed resource in this case is
storage. The application should provide an interface which hides this
distribution of resources from a user browsing through the wiki. Servers are
expected to communicate with each other to present the required data as if it
came from a single device.

== Requirements Specification for a Proof-of-Concept Application

Within the selected domain various viable products with different priorities and
approaches could be specified. As the project is developed independently with no
particular users available to interact with its creator has full freedom to
select their priorities. The expression of those priorities is a specification
of a proof-of-concept application split into functional requirements (listed in
@fig_functional_requirements) and non-functional requirements
(@fig_non_functional_requirements).

Most notably those requirements do not include features such as:
- Authentication and authorization -- it is assumed that the implementation of
  those would be similar in its architecture to that of e.g. GitLab.
- Web editor interface -- since the possibility of editing from an IDE or editor
  is required one of the most notable features of wikis has been considered to be
  of lower priority for a proof-of-concept specifically.
Those features while not being included in the proof-of-concept should be
implemented in an application that would be a Minimal Viable Product (MVP).

#figure(
  list_table(
    header: [Functional Requirements], [Wiki should support text files in the following formats: plain text, Markdown,
      HTML], [Supported by the wiki files in a text format should be rendered to graphical
      HTML pages which can be displayed by the following web browsers: Firefox v122.0,
      Microsoft Edge v121.0.2277.83, Google Chrome v121.0.6167.85, Chromium
      v121.0.6167.135.], [Files in binary formats should be served to the browser _as is_ with correct
      MIME type specified in the Content-Type header.], [Pages and content can be made secret or not to other wikis invloved in
      collaboration], [A single wiki server can become connected to other wiki servers through an
      access to that server's machine. When wikis are connected they create a network
      and hyperlinks can be created between non-secret pages stored at those wikis.], [A page that is not secret should be available for browsing through other
      connected wiki servers.], [A wiki editor (a user editing a wiki) should be able to select a specific
      version of wiki content to edit through interaction with a git repository cloned
      from the wiki server], [The wiki and the files available from a single server should be available for
      editing from a sub-directory within an arbitrary git repository.], [Changing version of the currently managed by a user content should be possible
      through an interaction with the git repository, in which sub-directory the wiki
      files are stored, in such a manner that the reversion of the git repository is
      always connected with a specific version of the wiki content], [A user browsing the wiki through a web browser should not be required to be
      aware of the fact that the files might be hosted on multiple wiki servers.], [The application must support within files links in a dedicated scheme which
      point to a page through selection of:
      - a specific wiki server,
      - a wiki revision,
      - a file path.], [Revisions of a wiki should be uniquely identifiable with uniqness maintained
      between different servers. The identificator must be usable in URLs.], [The server software should produce log lines printed to the standard output.], [The server software should double as a host for the git repository storing the
      wiki files and offer the access through its HTTP interface using a single port
      for all its operations.], [The server should support running it under an IP address selected by the user
      and error if it cannot attach itself to it], [The server should support verifying existence of link targets (link integrity)
      through an HTTP API.], [A CLI client application with an interface similar to git should be provided.], [A CLI client should be capable of initializing a submodule storing wiki files in
      a git repository.],
  ), caption: [
    A list of functional requirements for the software.
  ],
) <fig_functional_requirements>

#figure(
  list_table(
    header: [Non-functional Requirements], [The wiki files cannot be copied between servers and exist at any point in
      operating memory of other wikis unless explicitly marked as not secret.], [Terminating the wiki server process manually or due to a hosting hardware
      failure must not cause a failure of other connected wiki servers.], [The software must be executable on a Linux system with kernel v6.6.3 and libgit2
      library v1.7.1 installed.], [The executable should not allow multiple processes to run in a single directory.], [The server should store its configuration in a TOML file.],
  ), caption: [
    A list of non-functional requirements for the software.
  ],
) <fig_non_functional_requirements>

= First Implementation Steps <implementation-chapter>

This section describes how #wit implementation started, what decisions were made
in the process and what unique challenges have been discovered.

== Implementation Language

#Wit has been implemented in the Rust programming language. The language comes
with some tools that are considered a standard and its own terminology. The
following are the terms used later in the paper:

/ Cargo: A package manager as well as a build tool for Rust. Available as a CLI program
  which facilitates other utilities such as tests' compilation, and documentation
  generation.
/ crate: A package, a unit of dependency, managed by Cargo.
/ feature: In the context of projects built with Cargo, a declaration of conditionally
  compiled features of a package. Enabling a feature when building a package may
  include or exclude some dependencies and fragments of code.
/ manifest: A description of a package listing its dependencies, targets, features, and
  more. Saved in a file named `Cargo.toml`.
/ target directory: A directory within a workspace or a package source used to store artifacts
  created by Cargo. Those include test executables, documentation, and
  dependencies and binaries.
/ workspace: A collection of packages sharing common elements described by a `Cargo.toml`
  file. It enables executing Cargo commands that operate on multiple packages,
  e.g. ```sh cargo test --workspace``` to run all tests within the workspace.

This choice provides several benefits for the project including:
- Compiled binaries with no additional runtime requirements besides dynamically
  linked libraries and target-specific interfaces (e.g. glibc, musl).
- Linking against libraries using C ABI can be as simple as adding a dependency to
  a manifest file.
- Low memory footprint and "C-like performance" @runtime_performance_of_rust but
  increased in comparison to C language developer productivity
  @rust_performance_productivity_in_hpc.
- Built-in tools for unit and integration testing through Cargo.
- Built-in tools for code documentation which make documentation of every
  published Rust crate follow the same format. This improves the speed of learning
  about new dependencies for programmers already familiar with Rust's tooling.

== Technology Stack

As a prototype software #wit relies heavily on external libraries and
components. Besides dependencies pulled with cargo - a builder and package
manager for Rust programming language - the most important elements which belong
to a web browser and git version control system are expected to already be
present on the target user's system. The source code of the implementation
attached with the thesis is however a purely Rust-based project as the tooling
provided with the language allows easy linking of dynamic libraries through
crates - cargo's dependency units.

@fig_tech_stack presents a stack-like representation of technologies utilised by
the server and client executables. The stack has been divided into 3 tiers to
visually explain the roles of each utilised technology but the software does not
aim to achieve a multitier architecture with each tier being an independent
module. Aiming for such decoupling, especially through the development of new
abstractions, could be seen as unproductive in the implementation of a
proof-of-concept application. The presented #wit implementation has its business
logic tightly coupled with the data and its interfaces.

The source code does not reference libgit2 - "pure C implementation of the Git
core methods" @libgit2_desc - directly but instead, it relies on a wrapper crate
named git2. This allows for a single-language codebase and reduces the project
complexity.

#figure(
  image("img/implementation-components.svg", height: 80%), caption: [
    The technology stack of implemented solution. The direct, most significant
    dependencies of the have been mapped conceptually to the 3-tier architecture
    model. The diagram is meant to make understanding the roles of each dependency
    easier but the software does not adhere to multi-tier architecture.
  ],
) <fig_tech_stack>

#pagebreak(weak: true)

Other significant, direct dependencies added as Rust crates include:
/ axum: A web application framework.
/ clap: Command-line argument parser.
/ libp2p: A modular peer-to-peer networking framework. It facilitates server-to-server
  communication and provides an abstract implementation of Kademlia DHT.
/ markdown-it: Markdown parser with support for syntax extensions.
/ redb: Portable, ACID, embedded key-value store. It is used to store distributed hash
  table data managed through the Kademlia protocol.
/ tower-cgi: A crate forked for the project. Provides a service implementing the CGI 1.1
  protocol.
To see a full list of direct dependencies one may wish to investigate the
manifest files available in the source code.

== Communication Protocols

#Wit operates on multiple application-level communication protocols to utilise
as extensively as possible the components on which it relies. Those protocols
are used on a high level of abstraction and all of them can be considered
application layer protocols (according to the OSI model) with the way they are
used within the software.

The specific underlying protocol selected for transferring data between local
and remote git repositories depends on the submodule configuration present in
the local to the developer's environment git repository and is fully managed by
libgit2. Because of that reliance on libgit2 and the abstraction it provides,
the network traffic it facilitates is further referred to as _libgit2 transport_.
The source code of libgit2 also refers to underlying protocols it supports as _transports_ @libgit2_transports_src.

The primary protocol over which #wit offers its unique features to users is HTTP
-- Hypertext Transfer Protocol. The use of the protocol for serving APIs is well
established and there are many high-quality libraries available for working with
it.

#figure(
  image("img/user-interaction-outline.svg"), caption: [
    A diagram presenting a high-level overview of data transfers triggered by user's
    interaction with the software.
  ],
) <fig_interaction_outline>

#pagebreak(weak: true)

Common Gateway Interface (CGI) is a protocol allowing the execution of scripts
stored on a server and transporting their output over HTTP. To improve the
comfort of #wit server hosting it also serves as a proxy to a CGI implementation
called _git-http-backend_ allowing the hosting of the underlying git repository
with the same command that launches #wit wiki server. The executable for _git-http-backend_ is
assumed to be available with every successful installation of _git_ on a system
which is usually bundled with a libgit2 dynamically linked library.

@fig_interaction_outline presents #wit using _libp2p_ a peer-to-peer (P2P)
networking framework and specification to implement a Kademlia Distributed Hash
Table. The Rust crate offers support for multiple transport layer protocols as
package features. This is a part of one of two suggested solutions for managing
the further distributed version control that #wit aims for.

== Distributed Version Control Solution Design <distributed_version_control_chapter>

While DVCSs usually enable distributed workflow through data copying #wit does
not allow similar cloning of all of the data available in the network of wikis
but only that which is available in accessible to the user server. Maintaining
the integrity of modification history or at least recording the causality of
changes in such an environment requires a new strategy.

During development, two distinct strategies were designed. One of them relies
heavily on a libp2p crate and can be perceived as more complex in implementation
because of the required integration with a new dependency. The source code
attached to the paper contains a partial implementation of this strategy. The
other one introduces a dedicated data structure and comes with its downsides but
it limits the number of dependencies significantly.

Injecting its hooks into a git-based workflow provides the system a chance to
record the observed state as changes are applied. Git hooks are scripts run at
specific steps of program execution. They are split into client-side hooks and
server-side hooks. Using server-side hooks #wit can reliably react to committed
changes.

To avoid forcing on a user a necessity to check version identifiers of each
linked file before committing a file of their own each strategy must also
support a URI scheme that allows leaving the revision specification to be
implied as the most recent one. The idea is to have the server handle resolving
the URIs in hyperlinks into HTTP URLs that leave no parts implied when a file is
rendered to HTML.

It is expected that a version identifier would be a decomposable combination of
a server identifier and a git SHA-1 revision hash. In particular, the SHA-1
revision identifier must be maintained to be able to retrieve appropriate files
from a git repository.

=== Strategy 1: Using Kademlia DHT <strategy_1_chapter>

Distributed Hash Table (DHT) is a distributed system which provides a lookup
service similar to a hash table. Key-value pairs are distributed over multiple
nodes in a network. The technology has seen application in P2P software, e.g.
BitTorrent.

Kademlia is a protocol and an implementation of a DHT which performs "distance"
calculation using _exclusive or_ (XOR) of node IDs to the defined neighbourhood
in a network. For $n$ nodes in a network, Kademlia's search algorithm has the
complexity of $O(log_2(n))$ @kademlia_dht.

The strategy relying on Kademlia has been designed as the first one.

==== Resolving a Page From an URI

The network of wikis operating in a decentralized manner is in a way similar to
peer-to-peer file sharing and because of that similarity #wit chooses to use the
same methods that P2P file-sharing applications use for locating a specific
file. Using Kademlia DHT #wit stores and shares between peers the information
required to locate the host of a specific page at a specific revision.
@fig_uri_resolution_flow presents the algorithm used by #wit to resolve a URI
where "PageHosts" is a table in redb, the embedded database used as a backbone
of the DHT.

#figure(image("img/uri-resolution.svg", height: 95%), caption: [
  A flowchart of the URI resolution algorithm.
]) <fig_uri_resolution_flow>

==== Committing Changes

Each change that is intended to be published should be directed through a
server-side `pre-receive` git hook that triggers the following actions:
+ Retrieval and dereferencing of the pushed contents from the hook arguments to
  scan them for the presence of links.
+ Verification of each link by communication with peers to discover any broken
  links. Any broken link stops the process.
+ Insertion of new entries to the "PageHosts" table with appropriate file names
  and version identifiers.
+ Acceptance of a new tip of the local git branch with the committed changes
  applied.

==== Tracking the History of Changes

The suggested strategy makes it difficult to inspect the history of changes
across all connected servers. The DHT is not an ordered collection so a separate
table might be required allow constructing a complete history of changes with a
reasonable time complexity.

==== Advantages and Disadvantages

@fig_strategy_1_pros_cons lists briefly the identified advantages and
disadvantages of the described strategy. Most notably, the design lacks a
solution for rendering a list-like history of changes that git users could
expect based on their experience with `git log` command.

#figure(
  table(
    columns: (1fr, 1fr), rows: (auto, auto), gutter: 0pt, inset: (left: 0em, rest: 1em), align: left, {
      v(-1em)
      box(
        width: 100%, fill: luma(240), outset: (right: 1em - 0.5pt), inset: 1em, "Advantages",
      )
      v(-1em)
    }, {
      v(-1em)
      box(
        width: 100%, fill: luma(240), outset: (right: 1em - 0.5pt), inset: 1em, "Disadvantages",
      )
      v(-1em)
    }, [
      - Provides a platform for sharing data with peers which could facilitate future
        developement.
      - Builds on a well-researched and described protocol. #hide(lorem(10))
    ], [
      - It takes as much as up to two request-response exchanges over the network for
        each URI that needs resolving.
      - Assmebling a view into the whole history of changes requires further work on the
        strategy. It is possible that the complexity would increase because of that.
    ],
  ), caption: [ A brief analysis of the strategy for managing a changes history in the
    distributed context within which #wit operates based on the Kademlia DHT. ],
) <fig_strategy_1_pros_cons>

=== Strategy 2: a Dedicated Data Structure <strategy_2_chapter>

A strategy that was designed when the implementation of the strategy based on
Kademlia was identified as difficult to complete. It prefers files local to each
server as storage for history tracking. Both implementations can use redb, the
embedded key-value database to realise their needs. This new strategy has the
potential to reduce the complexity of URI resolution and as such also of
accepting commits. It assumes the developement of a dedicated data structure.

Using a structure that can map to a tree plays well with redb's implementation
which relies on B-trees to store data @redb_design.
@fig_strategy_2_semantic_tree presents a high-level overview of the data
hierarchy that the strategy would utilize. It assumes that the entries would
maintain the order of insertions. To achieve that in a B-Tree-based key-value
database the version identifier that would serve as a key needs to provide an
ordering that would match with the order of insertions. Redb allows custom
definition of a `compare()` method applied to keys which would facilitate
implementation of this property.

#import "@preview/treet:0.1.0": *
#figure(
  block(
    fill: luma(240), inset: 1em, stroke: black + 1pt, align(left, tree-list(marker-font: "Noto Sans Mono")[
      - version identifier
        - file name
          - linked file url with version identifier encoded
    ]),
  ), caption: [
    An overview of level of data in the suggest structure supporting the second
    strategy.
  ],
) <fig_strategy_2_semantic_tree>

The data would be populated on each commit through the server-side hook. A
server relying on it would effectively maintain locally a view only into the
part of history relevant to the files accessible from it. Rendering a complete
history of changes spanning multiple servers would require further work but
depending on the user feedback having a view into a state relevant to a single
server might be even preferable.

@fig_strategy_2_example provides a visualisation of how the final structure
could be implemented with the example data provided. The exact data types are
subject to change and the final implementation is likely to take a significantly
different shape.

#figure(
  block(
    fill: luma(240), inset: 1em, breakable: false, stroke: black + 1pt, align(
      left, tree-list(
        marker-font: "Noto Sans Mono",
      )[
        - (1708713211, 844a6fd4504041f39134e4ddaab00d70)
          - welcome.md
            - wit:/\/0af47ae832754549b784d7e4c4e70a71\@best-practices.md
        - (1708713211, 0af47ae832754549b784d7e4c4e70a71)
          - best-practices.md
            - wit:/\/e1098e2ba17e48c0ad5542e72310e894\@example.org/best-practices.md
            - wit:/\/e1098e2ba17e48c0ad5542e72310e894\@example.org/code-style.md
        - (1708713839, e1098e2b-a17e-48c0-ad55-42e72310e894)
          - services.txt
      ],
    ),
  ), caption: [
    Following the hierarchy introduced in @fig_strategy_2_semantic_tree example
    values have been arranged into a tree.
  ],
) <fig_strategy_2_example>

=== HTTP Routing

The API offered by the server software is very simple and all its surface is
expressed in the snippet present on @fig_router_src.

#let src = raw(
  "let router = axum::Router::new()
                 .route(\"/favicon.ico\", axum::routing::any(|| async { \"not set\" }))
                 .route(\"/git\", git_proxy::new_proxy(\"/git\")) // CGI proxy
                 .route(\"/git/*path\", git_proxy::new_proxy(\"/git/\")) // CGI proxy
                 .route(\"/@:version/:file_path\", axum::routing::get(get::get_versioned))
                 .route(\"/:file_path\", axum::routing::get(get::get))
                 .with_state(state);
                 ", block: true, lang: "rs",
)

#figure(src, caption: [
  Source code snippet presenting server's HTTP router definition.
]) <fig_router_src>

It is worth noting that such layering of routes comes with some limitations
regarding the filenames and paths accepted by the application. More specifically
paths starting with the `git` or `@` symbol are not allowed as well as a `favicon.ico` file
in the root of #wit's repository. The `favicon.ico` file is expected to be
configurable through the server's configuration file.

= Project Results <results-chapter>

This sections describes the results of work on the implementation of the
application. The results of research done are discussed in @summary-chapter.

== Integration Tests

The completed aspects of the implementation can be inspected through integration
tests included in the project. They can be executed using standard tooling for
Rust, that is through ```sh cargo test --workspace```. The tests residing within
the `tests` directory are grey box tests. The server side of the application is
invoked through its CLI API with methods for config file manipulation and
reading leaked from the server binary crate into a library crate. The
client-side is invoked through a library crate and does not use a CLI.

To allow parallel execution of tests and reduce the amount of code required in
each test case dedicated utilities were developed. Their definitions can be
found in the `tests/common.rs` file. Those utilities include:
- ```rs fn TEST_INIT()``` - The function asserts that for each execution of tests,
  a dedicated directory within the target directory is cleared and prepared to
  store git repository contents. The operation is performed exactly once, no
  matter how many of the test cases get executed. To function properly it has to
  be added at the start of each test. Because of its repetition within the source
  it has been stripped from code snippets in the following listings.
- ```rs struct InitializedTestServer``` - Responsible for spawning separate server
  processes through `cargo run`. Unlike the client crate, the server does not
  expose its interface as a library. The creation of a struct through `new()` results
  in the execution of an `init` subcommand and storing passed arguments in the
  structure. The `run()` method creates a new structure `RunningTestServer` which
  holds a handle to a long-running process that is the HTTP server. The port
  assigned to the process is random (any free port assigned by the OS) and saved
  within the `RunningTestServer` structure for later use through its methods. Once
  the structure gets out of scope the process is terminated.
- ```rs struct ClientRepositoryWithWiki``` - Encapsulates the creation of a git
  repository within which, as a submodule, the wiki files are available to the
  client. It uses the methods exposed by the client package directly rather than
  through the command-line interface.

The utilities abstract the details that make it possible for the tests to be run
in parallel, creating files and using networking protocols as they would be used
in a released application.

Additionally, some `sleep()` functions have been removed from listings. The
concurrent nature of components used within tests (the libgit2, spawning new
processes to execute server software) demanded a certain delay in some cases.
The tests use a very conservative amount of 1 second. Because of their parallel
execution, it can be barely noticeable. It is assumed that any required delay
would occur naturally in practical application. The users are not expected to
connect to freshly initialized and running servers without any delay having both
client and server on the same machine. Doing so causes any changes introduced by
a client not to be immediately available through the server.

=== Local File Retrieval

The listings @fig_test_1[], @fig_test_2[], and @fig_test_3[] test the utility of
GET requests to a path directly translating to a file path, e.g. "`https://example.org/empty.md`".
They do not check if the server is capable of resolving URLs referencing
specific versions of files at specific servers and serving the files from remote
servers.

#figure(snippet_1, caption: [
  Test case checking connectivity between a CLI client and the server by
  attempting to commit an empty file.
]) <fig_test_1>

#figure(
  snippet_2, caption: [
  Test expanding on @fig_test_1. `reqwest` here is an http client library used to
  retrieve back the `empty.md` file.
  ],
) <fig_test_2>

#figure(
  snippet_3, caption: [
    Further extending @fig_test_2, the test verifies that the server is capable of
    rendering Markdown files to HTML.
  ],
) <fig_test_3>

Presented test scenarios verify functional requirements listed in
@fig_functional_requirements with numbers 8, and 14.

=== Resolving URIs

When a file is compiled to HTML it is expected that the server resolves the URIs
stored within in a revision-aware manner. The process has been detailed in
@distributed_version_control_chapter. Because the implementation process reached
only the functionality of serving local files at the most recent version, only
the corresponding type of links is checked within the integration tests.

#figure(
  snippet_4, caption: [
  The snippet testing the resolution of a link `wit:test.txt` pointing to locally
  available file `test.txt` in most recent version to an HTTP scheme.
  ],
) <fig_test_4>

More exhaustive unit tests are available within the server's source code,
specifically under `src/wit-server/src/server/link/mod.rs`.

#figure(
  snippet_5, caption: [
  An example unit test checking parsing correctness of a #wit link. Other unit
  tests can be found in the `link` module of the server crate.
  ],
) <fig_test_5>

=== "Server-to-Server" Connection

The application has a skeleton implementation of a strategy described in
@strategy_1_chapter. It includes the capability of configuring new
server-to-server connections. The @fig_test_6 presents verification of this
capability.

#figure(
  snippet_6, caption: [
  The `add_new_peer_to` function wraps around a `connect` subcommand of the server
  executable.
  ],
) <fig_test_6>

== Running the Target Binaries

The recommended way of launching the executables compiled from the attached
source code is through ```sh cargo run``` command. Because multiple binary
crates can exist within a single workspace, explicitly selecting the server
crate named `wit-server` is advised. @fig_cargo_run_examples presents example
commands that can be utilised to launch the server with Cargo.

#figure(
  snippet_7, caption: [
    A snippet presenting some of the available ways through which the server can be
    launched. Line 4 includes a command through which one can learn more about the
    available command line parameters.
  ],
) <fig_cargo_run_examples>

Since the artefacts created through integration tests get cleared at test
initialization, they can be investigated after any test run. Executing the
server at one of the generated directories one can use a preferred web browser
to access the files defined in the tests. @fig_browser_screenshot presents the
results of a scenario defined in @fig_test_4.

#figure(
  rect(stroke: luma(240) + 1.5pt, image("img/browser-screenshot.png")), caption: [
    A file generated by test presented by @fig_test_4 servered by the #wit server
    and accessed through the Firefox Browser.
  ],
) <fig_browser_screenshot>

#figure(
  rect(stroke: luma(240) + 1.5pt, image("img/terminal-logs-screenshot.png")), caption: [
  Log lines at verbosity level set to `debug` produced by an execution scenario
  mimicking that of a test presented by @fig_test_4.
  ],
) <fig_log_lines_screenshot>

The server during its execution writes to the standard output log lines which
verbosity can be controlled by an environment variable named `RUST_LOG`. Usage
of this specific variable is common for Rust programs as it is a default
behaviour for the `tracing-subscriber` @tracing_subscriber_docs crate which can
be used to implement logging facilities. The behaviour is outlined in the
documentation of its `EnvFilter` structure @tracing_env_logger_docs.
@fig_log_lines_screenshot presents debug-level log lines resulting from starting
the server and using a web browser to display a file as in
@fig_browser_screenshot.

Unless the `RUST_LOG` environment variable is set the verbosity level defaults
to `error`. Messages at this level can be obtained for example by attempting to
access a non-existing file as shown at @fig_not_found_screenshot. The resulting
lines can be found on @fig_log_lines_error_screenshot.

#figure(
  rect(
    stroke: luma(240) + 1.5pt, image("img/browser-not-found-screenshot.png"),
  ), caption: [
    A screenshot of an attempt at accessing a file not available from the server.
  ],
) <fig_not_found_screenshot>

#figure(
  rect(
    stroke: luma(240) + 1.5pt, image("img/terminal-logs-error-screenshot.png"),
  ), caption: [
    Log lines produced during an attempt to access a non-existing file.
  ],
) <fig_log_lines_error_screenshot>

Although only integration tests have access to the functionality designed for
the CLI client application, git can also be used within the #wit submodule to
make changes to the wiki contents. Assuming structure as presented at
@fig_client_and_server_files, one can execute git commands as visible on
@fig_committing_to_wiki to commit files and achieve results as presented at
@fig_committed_and_accessed.

#pagebreak(weak: true)

#figure(
  {
    let client_files = table(
      columns: (1fr, 4fr), rows: (13.7%), inset: 0pt, image("img/minimal-client-repo-tree.png"), {
        set block(height: 100%)
        snippet_8
      },
    )
    let server_files = table(
      columns: (1.61fr, 4fr), inset: 0pt, rows: 28%, image("img/server-files-screenshot.png"), {
        set block(height: 100%)
        snippet_9
      },
    )

    set block(breakable: false)
    table(
      columns: 1, inset: 0pt, stroke: 2pt, rect(
        width: 100%, fill: luma(210), [*Files at the git repository managed by #wit server*],
      ), server_files, rect(
        width: 100%, fill: luma(210), [*Files at a "client" git repository connected to #wit*],
      ), client_files,
    )
  }, caption: [
    Contents of directories created as an artifact of one of the integration tests.
  ],
) <fig_client_and_server_files>

#figure(
  table(
    columns: 1, rows: (15%, 19%), inset: 0pt, {
      set block(height: 100%, stroke: 1pt + black)
      grid(
        columns: 2, snippet_10, image("img/browser-committed-welcome-screenshot.png"),
      )
    }, {
      set block(height: 100%, stroke: 1pt + black)
      grid(
        columns: 2, snippet_11, image("img/browser-committed-list-screenshot.png"),
      )
    },
  ), caption: [
    Files committed to the submodule (on the left) and accessed through the #wit server
    and a browser (on the right).
  ],
) <fig_committed_and_accessed>

#figure(
  rect(
    stroke: luma(240) + 1.5pt, width: 70%, image("img/committing-to-wiki-screenshot.png"),
  ), caption: [
    Screenshot of terminal emulator presenting executed git commands. The operations
    performed at the directory storing the submodule containing wiki files result in
    committing new files to the #wit server.
  ],
) <fig_committing_to_wiki>

= Summary <summary-chapter>

The project introduces constraints that require novel solutions. Because of this
novelty, only a subsection of the requirements has been implemented during the
research period. Further work is necessary to move the implementation to a
complete proof-of-concept but the architecture of the application is not
expected to change significantly. The current selection of external packages is
expected to facilitate the implementation of most of the missing capabilities.

Most of the research time was spent on integrating the software with git which
comes with a parsimonious API reference for libgit2 and assumes familiarity with
many or even most of its _man page_ contents.

Further development and comparison of strategies described in
@strategy_1_chapter and @strategy_2_chapter with consideration for additional
features they could support would be a preferable next step. After the expected
server-to-server communication is established the application should grow in the
following areas to meet its proof-of-concept requirements:
- further design and implementation of a client application used to publish
  changes,
- authorization and authentication,
- support for marking pages as 'secret',
- support for HTML, and text files.
Once the proof-of-concept assumptions are met the development would benefit from
involving users from the target audience of the application. It is expected that
new features would need an introduction to make the experience of working with
an application comfortable enough to be acceptable to its users. Especially the
potential to enrich the HTML presentation of stored files remains uncharted.

To make the application usable in a professional environment its security
promises should be revised and verified. In its current design #wit assumes that
no further protection than the eventual implementation of authentication and
authorization in a scope similar to that of GitLab would be required because all
sensitive traffic can be configured to use HTTPS protocol and the contents of
the files are never transmitted between servers unless the file is designated to
be published. ]

#set align(bottom)
#line(length: 100%)
This document has been written with Typst markup-bassed typesetting system and
compiled with version #sys.version of the application available at #link("github.com/typst/typst") on #datetime.today().display("[day].[month].[year]").// Added so that anyone can reproduce having the source
