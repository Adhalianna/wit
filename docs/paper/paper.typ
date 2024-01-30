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
  size: 12pt,
  fallback: true,
  lang: "en",
  region: "GB",
  slashed-zero: true,
  font: (
    "Times New Roman",
    "Times",
    "Liberation Serif",
    "Linux Libertine",
    "serif",
    "sans-serif",
    "Courier New",
    "Courier",
    "Source Code Pro",
    "monospace",
  ),
)

// ------ UTILS ------

// Just a quick patch for how d2 renders SVGs
#show image: img => {
  if img.path.ends-with(".svg") {
    let img_data = read(img.path)
    img_data = img_data.replace(
      regex("font-family: \"d2-\d+-font-regular\";"),
      "font-family: sans-serif, serif;",
    )
    img_data = img_data.replace(
      regex("font-family: \"d2-\d+-font-bold\";"),
      "font-family: sans-serif, serif; font-weight: bold;",
    )
    img_data = img_data.replace(
      regex("font-family: \"d2-\d+-font-italic\";"),
      "font-family: sans-serif, serif; font-style: italic;",
    )
    img_data = img_data.replace(
      regex("font-family: \"d2-\d+-font-semibold\";"),
      "font-family: sans-serif, serif; font-weight: 600;",
    )
    img_data = img_data.replace(
      regex("font-family: \"d2-\d+-font-mono\";"),
      "font-family: Source Code Pro, Courier New, monospace, mono;",
    )
    img_data = img_data.replace(
      regex("font-family: \"d2-\d+-font-mono-bold\";"),
      "font-family: Source Code Pro, Courier New, monospace, mono; font-weight: bold;",
    )
    img_data = img_data.replace(
      regex("font-family: \"d2-\d+-font-mono-bold\";"),
      "font-family: Source Code Pro, Courier New, monospace, mono; font-style: italic;",
    )
    img_data = img_data.replace(regex("@font-face \{.*}"), "") // the nasty bit that's not supported
    image.decode(
      img_data,
      height: img.at("height", default: auto),
      width: img.at("width", default: auto),
    )
  } else {
    img
  }
}
// personal preferred style for code blocks:
#show raw.where(block: true): block.with(inset: 1em, stroke: 1pt + luma(200))

// quickly create list-like table:
#let list_table(header: none, ..content_lines) = {
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
    columns: (auto, auto),
    align: (center + horizon, start),
    fill: luma(300),
    ..lines,
  )
  if type(header) == none or header == none {
    li
  } else if type(header) == content {
    table(
      rows: (auto, auto),
      align: center + horizon,
      fill: luma(230),
      inset: 0pt,
      { block(inset: 0.66em, strong(header)) },
      li,
    )
  } else {
    panic(
      "expected the header argument to be of type content, got: " + type(header),
    )
  }
}

// ------ CONTENT ------
#diploma(
  university_logo_file: "AGH.svg",
  university: "AGH University of Krakow",
  faculty: "Faculty of Electrical Engineering, Automatics, Computer Science and Biomedical Engineering",
  titles: (paper_title, pl_paper_title),
  short_title: "Distributed Wiki on top of Git",
  author: (first_name: "Natalia", second_name: "Kinga", surname: "Goc"),
  degree_programme: "Computer Science",
  supervisor: "prof. dr. inż. Krzysztof Kluza",
  location: "Kraków",
  acknowledgement: [
    I would love to say 'Thank you' to anyone who keeps making and promoting free
    and open source software, plenty of which I have used to write this thesis.
  ],
  abstracts: [
    = Summary
    *[TODO]*
    = Streszczenie
    *[TODO]*
  ],
  bibliography_file: "bibliography.yml",
)[

  = Introduction

  Enforcing knowledge consistency in an environment of frequent changes which can be observed during the development of a software product is still an area seeing plenty of attention and financial investment. One of the approaches taken by some organizations that can be seen as sufficiently efficient for a single project is to store all documentation and design documents in the same Git repository that is used for the developed software. Whether this approach is successful for that single repository depends on factors such as the utilised tools checking the consistency and the developers’ discipline in keeping the documentation up to date. The task becomes more difficult when consistency has to be enforced between multiple projects which may be managed by multiple teams.  In such a case there is no single version control system that would synchronize the knowledge base with each of the code bases. For many use cases, a separate centralized solution might be sufficient but for those who cannot allow the relevant data to be stored in a centralized manner, there is little to no open tooling available.

  The goal of the thesis is to research the possibility of developing tools composing a distributed wiki system that could be used by software developers working on multiple git repositories to create links between those repositories that would maintain referential integrity in a version-conscious manner. Such software could then later be used to compare the effects of a federated approach to documentation distribution on knowledge sharing efficiency with centralized solutions such as Jira and many other wikis based on Git VCS.

  == Paper structure

  The @theory-intro-chapter introduces the terminology related to the problem
  domain. Sections @implementation-chapter[] and @problem-chapter[] explain the
  implementation details starting from the software architecture and continuing to
  specific problems unique to the project. The results of the project are
  discussed in @results-chapter. The @summary-chapter both summarizes the project
  and explores the potential for further research.

  == Project naming

  For the project to be usable it needed a name that would be used for the executable artifacts. The name #wit has been selected in the spirit of Unix-like short command names and as a mnemonic or portmanteau referring to the words _wiki_ and _git_. @fig_wit_mnemonic presents the mnemonic on a graphic.

  #figure(image("img/wit-mnemonic.svg", height: 20%), caption: [
    Graphical presentation of the `wit` name origin.
  ]) <fig_wit_mnemonic>

  == Project role

  This project has been inspired by a general academic curiosity and by
  discussions with colleagues about problems of corporations working with
  subcontractors on engineering projects often involving data that must be kept
  confidential.

  === Problems #wit tries to address

  Before the specific list of problems that inspired the project is introduced some additional context might bring some insight on the nature of those problems and suggested solutions. In general, the problem space can be seen as narrow and it is further limited by the selection of a specific target audience.

  ==== A problems list

  Following is a list of specific problems and scenarios in which the #wit project has an ambition to help:
  + When two teams within a single company or two companies choose to cooperate through a wiki while coordinating multiple related projects, because of the centralized nature of most wikis, a transfer of knowledge to a new platform is necessary. That transfer might turn out not to be successful and as a result, some users might prefer to keep using their internal solutions thus making the knowledge sharing between involved parties more difficult.
  + A significant amount of companies perform knowledge transfer through file transfers with their employees sending required documents on demand or hosting them in cloud storage. This solution suffers from a lack of version control and it makes creating links between files either hard or impossible. One of the collaborating parties might find themselves with outdated documents which might even lead to tension between other parties.
  + Providing access to an internal platform of a team or company might not be possible or preferable because of sensitive information stored on those platforms. Decoupling the knowledge to share from sensitive documents can be difficult.
  + Documentation stored separately from the code is more likely to get outdated.
  + Using different platforms and storage solutions for a single project increases the burden on its creators who need to switch context and tools frequently to move the work forward. (In the context of software development, storing all the data within a single code repository has the benefit of reducing the amount of context switches a programmer has to perform to work on a project.)

  === Academic Interest

  Fedwiki is a project most similar in nature to the topic of this document but with different goals behind its hyperlinks implementation. While fedwiki aims to empower collaboration through "profligate copying" @fedwiki_profiligate_copying, the #wit project aims to enable collaboration in cases when it is desired to maintain distinct ownership of the data composing a wiki. In such a scenario it might not be desirable to copy data for modification, like fedwiki does, as that would, at least on a conceptual level, imply a new authority controlling the data.

  Furthermore, #wit builds on top of git to achieve tight integration into git-based developer workflows. As it is meant to span over multiple repositories, the work done on the paper might bring some insight into the development of systems which aim for an extra layer of version control between independent systems like the ones researched by Schnöhoff et. al @version_in_federated_database. Habib et. al @decentralized_git_version_control utilise technologies related (although with significant differences in properties they allow) to the ones implemented in #wit but to secure the repositories against malicious maintainers.

  = Wikis, version control systems, and distributed systems <theory-intro-chapter>

  To express clearly the requirements for the project, some concepts such as wikis, and distributed systems should be made clear. In particular, the term _wiki_ already expresses a certain amount of expected functionality of the tool. The selection of _git_ as a part of the implementation and integration target introduces further constraints. Finally, the _distributed_ property of a system can be realised to a varying degree so it is crucial to understand the ideas behind distributed systems to be able to describe them legibly.

  == Definitions

  According to Wikipedia, still the most popular instance of a wiki, a wiki is a form of online hypertext publication that is collaboratively edited and managed by its audience directly through a web browser @wikipedia_definition. The server software making up a wiki can be referred to as wiki engine and it offers functionality similar to content management systems.

  Git with which #wit project is meant to be integrated and on which it builds is an example of a Version Control System (VCS, also known as revision control) @history_of_version_control. A VCS encourages collaboration by recording each change made to content in such a way that it can be managed e.g. get reverted. Those systems can be split into two categories: Centralized Version Control Systems (CVCS), and Distributed Version Control Systems (DVCS) @version_control_systems_review. DVSCs are characterised as 'distributed' because they distribute the history of changes between participants. CVCSs on the other hand keep the history of changes centralised on a single server.

  More generally, a distributed system is a collection of autonomous computing elements that appears to its users as a single coherent system @distributed_systems_book_def. Such is a definition used by the distributed computing field. Strictly in this sense git is not a distributed system as its users do not share computing elements. It does not even align with the typical goals of a distributed system which usually include:
  - supporting resource sharing,
  - making distribution transparent,
  - providing scalability @distributed_systems_book_design_goals.
  Rather than being called a distributed system git should be considered a decentralized system but the term 'distributed'

  == Wikis and software development

  
  At present there is an abundance of implementations of a wiki and the form has been adapted to serve as software documentation. Popular repository-hosting web services such as GitHub and GitLab offer simple wikis to be hosted alongside code repositories they would be documenting.
  
  To track changes, revisions, and to avoid a loss of data caused by malicious editors wikis usually feature some sort of VCS. Conviniently the same VCSs that are used by software developers are also employed to create wikis. As such GitHub and GitLab both use git, the primary technology they offer as a service, in their wiki implementations @gitlab_wiki_docs @github_wiki_docs.
  
  Git presently is the most popular VCS for source code with a stable trend of growth. In 2023 GitHub only reported the number of users increasing by 26% resulting in over 100 million users total @github_octoverse_report_2023. Git URIs are also showing up more frequently in academic publications @prevalence_of_git_uri_in_scholar_publications. This trend makes the possibility to comfortably integrate a wiki with git quite favourable.

  = Requirements <requirements-chapter>

  Modern software development projects have grown to require collaboration not only between team members but also between distinct teams. As such software developers are more likely to need tools facilitating inter-project collaboration. However, extending the application in the future to improve the experience of other target groups should considered as one of its design goals.

  This section presents various forms of software requirements declaration which are finally summarised as a list of statements composing a specification. Using different formats inspires much more precise requirements for the system.

  == Use case diagram

  #figure(image("img/use-case-diagram.svg"), caption: [
    A use case diagram for the suggested system.
  ]) <fig_use_case_diagram>

 @fig_use_case_diagram presents a use case diagram for the system that could be composed of a CLI client and a server application. The web browser included as the only inanimate actor operates de facto as another client application. The diagram provides minimal insight into requirements. A very similar diagram could be drawn for any arbitrary wiki software as most features unique to #wit are non-functional requirements.

  == User Personas

  #figure(
    list_table(
      header: [User Personas],
      [
        The software developer wants to work on a wiki in a state appropriate to the version of their project. it is important to them as they might be at the moment amending an older version of the product and it is not desired, for example, to apply newer requirements to it. they plan to achieve that by setting their git repository to the appropiate version.
      ],
      [
        The software developer wants to make sure that when they create links they are valid references to the parts of the wiki maintained as part of other projects. They want it in such a way because they need to be aware of important changes like the removal of a page as those might invalidate what they were about to write on pages managed by them. They would like to be informed of invalid links each time they are about to publish changes preferably by an IDE extension but optionally by the execution of a CLI utility that can be included in CI/CD pipelines or invoked on demand.
      ],
      [
        The software developer wants to manage wiki files alongside the git repository they are working on. They want it so because their IDE is the most familiar and comfortable working environment for them and having a wiki in the same repository as the code will reduce the burden of a context switch between source code and documentation. They plan to achieve that by keeping the wiki files in a subdirectory of their source code repository.
      ],
      [
        The freshly employed engineer wants to be able to browse the wiki in a graphical form. It is important to them that the pages are presentable because it makes learning from them a much more pleasant experience. They plan to browse the pages rendered to HTML through their web browser of choice as that is the most intuitive way of exploring wikis for them.
      ],
      [
        The network systems administrator wants to be able to shut down any wiki server they host without affecting other projects' wikis. It is important to them that they cause no data loss to other collaborating parties and that they can do so without the need to coordinate the operation with other wiki administrators. They expect that shutting down permanently the wiki server process will not affect other wikis which might be owned by other organizations.
      ],
    ),
    caption: [
      A small set of user personas defined to make sure that the application provides
      a good user experience to its target audience.
    ],
  ) <fig_user_personas>

  Since the software is meant to be dedicated to a relatively limited target audience, a definition of a user persona might prove helpful in defining interfaces that are clear for that specific group. A user persona, or a _minimal collaborative persona_ @minimal_collaborative_persona, is an alternative to user stories form of expressing requirements with a focus on user experience.

  The personas in this document are expressed as statements describing three aspects:
  - *Goals* - answering the question "What do they want?".
  - *Purpose* - expressing the motivation of a user, answering "Why they want it?".
  - *Approach* - suggesting a means a user would take to achieve their goal. It is best to support this part with data from the users but having no access to such it will be speculated.
  Those descriptions consist of multiple free-form sentences and they have been aggregated in @fig_user_personas. This is a very simple model of a user persona, similar to a user story. They are not intended to guide all expected features of the implemented application but instead, they serve as an extra tool for improving the quality of user experience.

  == Requirements Specification for a proof-of-concept application

  Within the selected domain various viable products with different priorities and approaches could be specified. As the project is developed independently with no particular users available to interact with its creator has full freedom to select their priorities. The expression of those priorities is a specification of a proof-of-concept application split into functional requirements (listed in @fig_functional_requirements) and non-functional requirements (@fig_non_functional_requirements).

  Most notably those requirements do not include features such as:
  - Authentication and authorization -- it is assumed that the implementation of those would be similar to that of e.g. GitLab.
  - Web editor interface -- since the possibility of editing from an IDE or editor is required one of the most notable features of wikis has been considered to be of lower priority for a proof-of-concept specifically.
  Those features while not being included in the proof-of-concept should be implemented in an application that would be a Minimal Viable Product (MVP).

  #figure(
    list_table(
      header: [Functional Requirements],
      [Wiki should support text files in the following formats: plain text, Markdown,
        HTML],
      [Supported by the wiki files in a text format should be rendered to graphical
        HTML pages which can be displayed by the following web browsers: Firefox v122.0,
        Microsoft Edge v121.0.2277.83, Google Chrome v121.0.6167.85, Chromium
        v121.0.6167.135.],
      [Files in binary formats should be served to the browser _as is_ with correct
        MIME type specified in the Content-Type header.],
      [Pages and content can be made secret or not to other wikis invloved in
        collaboration],
      [A single wiki server can become connected to other wiki servers through an
        access to that server's machine. When wikis are connected wikis create a network
        and hyperlinks can be created between non-secret pages stored at those wikis.],
      [A page that is not secret should be available for browsing through other
        connected wiki servers.],
      [A wiki editor (a user editing a wiki) should be able to select a specific
        version of wiki content to edit through interaction with a git repository cloned
        from the wiki server],
      [The wiki and the files available from a single server should be available for
        editing from a sub-directory within an arbitrary git repository.],
      [Changing version of the currently managed by a user content should be possible
        through an interaction with the git repository in which sub-directory the wiki
        files are stored in such a manner that the version of the git repository is
        always connected with a specific version of the wiki],
      [A user browsing the wiki through a web browser should not be required to be
        aware of the fact that the files might be hosted on multiple wiki servers.],
      [A single version identifier can be used to reference a state of data available
        at all connected wikis.],
      [The application must support in files links in a dedicated scheme which locating
        a page through selection of:
        - a wiki version,
        - a specific wiki server,
        - a file path,
        - a file fragment.],
      [*[TODO?]*],
    ),
    caption: [
      A list of functional requirements for the software.
    ],
  ) <fig_functional_requirements>

  #figure(
    list_table(
      header: [Non-functional Requirements],
      [The wiki files cannot be copied between servers and exist at any point in
        operating memory of other wikis unless explicitly marked as not secret.],
      [Terminating the wiki server process manually or due to a hosting hardware
        failure must not cause a failure of other connected wiki servers.],
      [The software must be executable on a Linux system with kernel v6.6.3 and libgit2
        library v1.7.1 installed.],
      [*[TODO?]*],
    ),
    caption: [
      A list of non-functional requirements for the software.
    ],
  ) <fig_non_functional_requirements>

  = Implementation <implementation-chapter>

  This section describes how #wit was implemented, what decisions were made in that process and what unique challenges have been met.

  // == Software Architecture
  // 
  // #figure(
  //   image("img/architecture-concept-non-federated.svg", height: 70%),
  //   caption: [
  //     The technology stack of implemented solution.
  //   ],
  // ) <fig_arch_concept_non_federated>
  // 
  // #figure(
  //   image("img/architecture-concept-federated.svg", height: 70%),
  //   caption: [
  //     The technology stack of implemented solution.
  //   ],
  // ) <fig_arch_concept_federated>
  // 
  // *[TODO]* #lorem(15)

  == Implementation language

  #Wit has been implemented in the Rust programming language. The language comes with some tools considered a standard and its terminology. The following are the terms used later in the paper:
  
  / Cargo: A package manager as well as a build tool for Rust. Available as a CLI program which facilitates other utilities such as tests' compilation, and documentation generation.
  / crate: A package, a unit of dependency, or a compilation target managed by Cargo.
  / feature: In the context of projects built with Cargo, a declaration of conditionally compiled features of a package. Enabling a feature when building a package may include or exclude some dependencies and fragments of code.
  / manifest: A description of a package listing its dependencies, targets, features, and more. Saved in a file named `Cargo.toml`.
  / workspace: A collection of packages sharing common elements described by a `Cargo.toml` file. It enables executing Cargo commands that operate on multiple packages, e.g. ```sh cargo test --workspace``` to run all tests within the workspace.

This choice provides several benefits for the project including:
  - Compiled binaries with no additional runtime requirements besides dynamically linked libraries and target-specific interfaces (e.g. glibc, musl).
  - Linking against libraries using C ABI can be as simple as adding a dependency to a manifest file.
  - Low memory footprint and "C-like performance" @runtime_performance_of_rust but increased in comparison to C language developer productivity @rust_performance_productivity_in_hpc.
  - Built-in tools for unit and integration testing through Cargo.
  - Built-in tools for code documentation which make documentation of every published Rust crate follow the same format. This improves the speed of learning about new dependencies for programmers already familiar with Rust's tooling.

  == Technology Stack

  #figure(
    image("img/implementation-components.svg", height: 88%),
    caption: [
      The technology stack of implemented solution. The direct, most significant
      dependencies of the have been mapped conceptually to the 3-tier architecture
      model. The diagram is meant to make understanding the roles of each dependency
      easier but the software does not adhere to multi-tier architecture.
    ],
  ) <fig_tech_stack>
  
  As a prototype software #wit relies heavily on external libraries and components. Besides dependencies pulled with cargo - a builder and package manager for Rust programming language - the most important elements which belong to a web browser and git version control system are expected to already be present on the target user's system. The source code of the implementation attached with the thesis is however a purely Rust-based project as the tooling provided with the language allows easy linking of dynamic libraries through crates - cargo's dependency units.

  @fig_tech_stack presents a stack-like representation of technologies utilised by the server and client executables. The stack has been divided into 3 tiers to visually explain the roles of each utilised technology but the software does not aim to achieve a multitier architecture with each tier being an independent module. Aiming for such decoupling, especially through the development of new abstractions, could be seen as unproductive in the implementation of a proof-of-concept application. The presented #wit implementation has its business logic tightly coupled with the data and its interfaces.

  The source code does not reference libgit2 - "pure C implementation of the Git core methods" @libgit2_desc - directly but instead, it relies on a wrapper crate named git2. This allows for a single-language codebase and reduces the project complexity.

  Other significant, direct dependencies added as Rust crates include:
  //#[
  //  #set terms(separator: [ -- ])
  //  #show terms.item: it => [ - #it ]
  / axum: A web application framework.
  / clap: Command-line argument parser.
  / libp2p: A modular peer-to-peer networking framework. It facilitates server-to-server communication and provides an abstract implementation of Kademlia DHT.
  / markdown-it: Markdown parser with support for syntax extensions.
  / redb: Portable, ACID, embedded key-value store. It is used to store distributed hash table data managed through the Kademlia protocol.
  / tower-cgi: A crate forked for the project. Provides a service implementing the CGI 1.1 protocol.
  //]
  To see a full list of direct dependencies one may wish to investigate the
  manifest files available in the source code.

  == Communication Protocols

  #figure(
    image("img/user-interaction-outline.svg"),
    caption: [
      A diagram presenting a high-level overview of data transfers triggered by user's
      interaction with the software.
    ],
  ) <fig_interaction_outline>

  #Wit operates on multiple application-level communication protocols to utilise as extensively as possible the components on which it relies. Those protocols are used on a high level of abstraction and all of them can be considered application layer protocols (according to the OSI model) with the way they are used within the software.

  The specific underlying protocol selected for transferring data between local and remote git repositories depends on the submodule configuration present in the local to the developer's environment git repository and is fully managed by libgit2. Because of that reliance on libgit2 and the abstraction it provides, the network traffic it facilitates is further referred to as _libgit2 transport_. The source code of libgit2 also refers to underlying protocols it supports as _transports_ @libgit2_transports_src.

  The primary protocol over which #wit offers its unique features to users is HTTP -- Hypertext Transfer Protocol. The use of the protocol for serving APIs is well established and there are many high-quality libraries available for working with it.

  Common Gateway Interface (CGI) is a protocol allowing the execution of scripts stored on a server and transporting their output over HTTP. To improve the comfort of #wit server hosting it also serves as a proxy to a CGI implementation called _git-http-backend_ allowing the hosting of the underlying git repository with the same command that launches #wit wiki server. The executable for _git-http-backend_ is assumed to be available with every successful installation of _git_ on a system which is usually bundled with a libgit2 dynamically linked library.

  #Wit also uses _libp2p_ a peer-to-peer (P2P) networking framework and specification to implement a Kademlia Distributed Hash Table. The Rust crate offers support for multiple transport layer protocols as package features.

  === Kademlia DHT

  Distributed Hash Table (DHT) is a distributed system which provides a lookup service similar to a hash table. Key-value pairs are distributed over multiple nodes in a network. The technology has seen application in P2P software, e.g. BitTorrent.

  Kademlia is a protocol and an implementation of a DHT which performs "distance" calculation using exclusive or (XOR) of node IDs to the defined neighbourhood in a network. For $n$ nodes in a network, Kademlia's search algorithm has the complexity of $O(log_2(n))$ *[TODO: cite]*.

  == Resolving a page from an URI

  #figure(image("img/uri-resolution.svg", height: 95%), caption: [
    A flowchart of the URI resolution algorithm.
  ]) <fig_uri_resolution_flow>
  
  The network of wikis operating in a decentralized manner is in a way similar to peer-to-peer file sharing and because of that similarity #wit chooses to use the same methods that P2P file-sharing applications use for locating a specific file. Using Kademlia DHT #wit stores and shares between peers the information required to locate the host of a specific page. @fig_uri_resolution_flow presents the algorithm used by #wit to resolve a URI where "PageHosts" is a table in redb, the embedded database used as a backbone of the DHT.

  === HTTP routing

  *[TODO]*

  #let src = raw("let router = axum::Router::new()
   .route(\"/favicon.ico\", axum::routing::any(|| async { \"not set\" }))
   .route(\"/git\", git_proxy::new_proxy(\"/git\")) // CGI proxy
   .route(\"/git/*path\", git_proxy::new_proxy(\"/git/\")) // CGI proxy
   .route(\"/:file_path\", axum::routing::get(get::get))
   .with_state(state);
   ", block: true, lang: "rs") //TODO: Update

  #figure(src, caption: [
    Source code snippet presenting server's HTTP router definition.
  ])

  == Versioning in distributed context <problem-chapter>

  A functional requirement with no. *[TODO: number]* listed in @fig_functional_requirements leaves some significant freedom of interpretation. The version identifier could be applicable either only from a specific wiki server that understands it or from any server in the network of wikis. A universal (among connected wikis) version identifier would provide a better user experience but designing one comes with certain difficulties.

  = Project results <results-chapter>

  == Implemented feature set

  // TODO: make this actually anyhow relevant, maybe choose different features...
  #figure(
    {
      set text(weight: "light", size: 0.6em)
      set par(justify: false)

      table(columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto), ..((
        [],
        [render global ToC],
        [web UI],
        [web editor UI],
        [direct access to repository contents],
        [viewing branches],
        [supported formats],
        [validate links],
        [distribution level],
      ), (
        [#wit],
        [*[TODO]*],
        [yes],
        [no],
        [yes],
        [*[TODO]*],
        [Markdown, plain text, HTML],
        [yes],
        [git + federated],
      ), (
        [GitHub],
        [yes, managed with a file],
        [yes],
        [yes],
        [yes],
        [no],
        [AsciiDoc, GitHub Markdown, MediaWiki, and more],
        [no],
        [git],
      ), (
        [GitLab],
        [yes, managed with a file],
        [yes],
        [yes],
        [yes],
        [no],
        [GitLab Markdown],
        [no],
        [git],
      ), (
        [gollum],
        [file tree],
        [yes],
        [yes],
        [no],
        [no],
        [custom, AsciiDoc],
        [no],
        [git],
      ),).flatten())
    },
    caption: [
      A table comparing features provided by #wit with other wiki solutions based on
      git.
    ],
  )

  == Use cases and associated test cases

  = Summary <summary-chapter>

  The project has resulted in the creation of software that is limited in terms of implemented features but can be built reliably and tested on most operating systems which have libgit2 available.

  The implemented application is merely a proof-of-concept. Producing a viable product from it would allow testing it in an environment of multiple interconnected software projects. Although testing the product and adapting it to fit the needs of a multi-department company might sound like the expected next step, it could be developed first to find adaptation in a student club composed of multiple teams and divisions.

  
  == Further Research

  // = Scratchpad
  //
  // The part that should be eventually removed.
  //
  // == Inter-project knowledge sharing over different organization structures
  //
  // - Within a single team working on multiple projects.
  // - Between multiple teams working on their projects in a single organization
  //   (company, NGO).
  // - Between multiple organizations that share one or more projects.
  //   - "Then again, trust is not static; it is a dynamic process that evolves according
  //     to the development of the relationship (Clegg, 2000). Hence, an unsuccessful
  //     alliance could end in separation." @strategic_alliances_and_knowledge_sharing
  // - Between multiple organizations which work on their projects separately but which
  //   share some knowledge between projects.
  //
  // == Loose thoughts
  //
  // To self: The interdependence and cooperative vs competetive context are
  // discussed in @modeling_high_quality_knowledge_sharing
  //
  // Cooperative contexts are more likely to result in high-quality knowledge sharing
  // *[TODO: add citation]*. Competetive context might result from a "negative
  // interdependence" *[TODO: add citation]* which may result from belonging to
  // different projects or organizations.
  //
  // ==== Knowledge sharing in context of limited trust between parties
  //
  // Knowledge management is a research domain centered around processes such as
  // knowledge creation, sharing, and usage. The goal of knowledge management methods
  // and approach is to make the best use of knowledge in achieving organizational
  // goals. Researchers focused on techno-centric approach to knowledge sharing
  // produced numerous papers studying wikis as tools for knowledge sharing
  // @knowledge_sharing_in_wiki_communities,
  // @wiki_based_knowledge_sharing_knowledge_intensive_organization,
  // @wikifailure_limitation_of_technology,
  // @exploratory_study_online_wiki_knowledge_sharing,
  // @analysis_wiki_and_non_wiki_knowledge_management_systems,
  // @knowledge_construction_and_sharing_wiki_approach,
  // @motivation_to_share_using_wiki.
  //
  // While low level of trust is perceived as a factor negatively affecting the
  // quality of knowledge sharing between parties
  // @knowledge_sharing_global_software_development, overcoming this challenge by
  // increasing the amount of trust between parties can be time-consuming and as such
  // it has been highlighted by Vangen et al. @nurturing_collaborative_relations that
  // providing both means of increasing trust and working with limited trust are
  // recommended for successfull collaborative environment to grow.
  //
  // Zahedi et al. point out in their review
  // "lack of openness" as one of the most frequently observed knowledge sharing
  // challenges @knowledge_sharing_global_software_development. On the other hand
  // Martin et. al @alignment_flexibility_knowledge_based_perspective *[... TODO]*
  //
  //==== Federation as a tool for collaboration
  //
  // #figure(
  //  image("img/fediverse-stats-screenshot.png", width: 90%),
  //  caption: [
  //    A graph presenting the growth of a user base of the fediverse in recent years as
  //    reported and presented by the fediverse.observer website @fediverse_stats.
  //  ],
  // ) <fig_fediverse_stats>
  //
  // In recent years a growing distrust to centralized social media platforms such as
  // Reddit, and Twitter @social_media_crisis_fediverse_the_verge, has been met with
  // increased popularity of federated social networks (called collectively _fediverse_)
  // @fediverse_stats. @fig_fediverse_stats presents the growth in a number of users
  // registered in the fediverse from February 2021 to December 2023. While the idea
  // behind a federated architecture became popular due to recent centralized
  // platforms decay, known also as _enshittification_ @data_paradoxes, that caused
  // users to loose trust in the platform providers it is not nowel and it has
  // already seen its implementation in context of wiki systems, example of which is _fedwiki_.
  //
  // Fedwiki creators found inspiration for their software in the practice of forking
  // in the open source software. ...*[TODO: they thought federation is nice,
  // everyone has their own copy and can make
  // forks of other people's work, cute]* @wiki_as_pattern_language*[TODO: improve
  // bibliography for that one]*@distributed_learning_and_collab
  //
  // == Knowledge sharing barriers related to knowledge ownership and access to knowledge
  //
  // - Unwilingess to give up power associated with knowledge
  //   @unwilingness_to_share_knowledge_study_turkey
  // - Conflicts, especially with a sense of unfairness on one of the ends of the
  //   relation, leading to a hesitance to share knowledge
  //   @unwilingness_to_share_knowledge_study_turkey
  //   - Knowledge dissemination might lead to loosing the information about the original
  //     contributor which in turn may result in the contributor not being acknowledged
  //     by an organization.
  // - Security risks associated with certain information
  //   @unwilingness_to_share_knowledge_study_turkey
  //
  // == Relevant recomendations and solutions to knowledge sharing barriers
  //
  // - Assuring no disadvantage after sharing the knowledge
  //
  // == Implementation
  //
  // Possibly relevant:
  // - similar attempt on general files stored in a dedicated database
  //   @version_in_federated_database
  // - very similar domain but the goal is to integrate multiple previously existing
  //   services @open_web_application_lifecycle
  // - more of similar problems but in an overview
  //   @version_control_in_distributed_software
  // - an overview of distributed version control systems
  //   @analysis_of_distributed_version_control
  // - a useful introduction into distributed ledger technologies
  //   @review_distributed_ledger
  // - half of the job done, someone tried to make git actually distributed using
  //   distributed ledger @decentralized_git_version_control but their use case and
  //   goals were different.
  //
  // == Theory to remember / research
  //
  // - _CAP theorem_ - distributed system cannot be completely consistent (C),
  //   available (A), and tolerant of network partitions (P) all at the same time.
  //   *[TODO: add citation]*
  // - _Byzantine fault-tolerance_
  // - _Sybil attack_
  //
  // == Goals
  //
  // Design and implement a protocol for a distributed wiki using git (libgit2) for
  // version control and evaluate its suitability for use in organizations that work
  // on their projects using multiple git repositories and need to share as well as
  // synchronize some knowledge between those projects. The application
  // (implementation) should be approachable to software developers and integrate
  // well with their daily workflow which includes frequent use of git. Hyperlinks to
  // content related to another repository in the system should be verified by the
  // provided tooling.
]

#set align(bottom)
#line(length: 100%)
This document has been written with Typst markup-bassed typesetting system and
compiled with version #sys.version of the application available at #link("github.com/typst/typst") on #datetime.today().display("[day].[month].[year]").
// Added so that anyone can reproduce having the source
