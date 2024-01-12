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
#set text(size: 12pt, fallback: true, lang: "en", region: "GB", slashed-zero: true, font: (
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
))

// Just a quick patch for how d2 renders SVGs
#show image: img => {
  if img.path.ends-with(".svg") {
    let img_data = read(img.path)
    img_data = img_data.replace(regex("font-family: \"d2-\d+-font-regular\";"), "font-family: sans-serif, serif;")
    img_data = img_data.replace(regex("font-family: \"d2-\d+-font-bold\";"), "font-family: sans-serif, serif; font-weight: bold;")
    img_data = img_data.replace(regex("font-family: \"d2-\d+-font-italic\";"), "font-family: sans-serif, serif; font-style: italic;")
    img_data = img_data.replace(regex("font-family: \"d2-\d+-font-mono\";"), "font-family: Source Code Pro, Courier New, monospace, mono;")
    img_data = img_data.replace(regex("font-family: \"d2-\d+-font-mono-bold\";"), "font-family: Source Code Pro, Courier New, monospace, mono; font-weight: bold;")
    img_data = img_data.replace(regex("font-family: \"d2-\d+-font-mono-bold\";"), "font-family: Source Code Pro, Courier New, monospace, mono; font-style: italic;")
    img_data = img_data.replace(regex("@font-face \{.*}"), "") // the nasty bit that's not supported
    image.decode(img_data, height: img.at("height", default: auto), width: img.at("width", default: auto))
  } else {
    img
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
    *[TODO]* #lorem(30)
    = Streszczenie
    *[TODO]* #lorem(30)
  ],
  bibliography_file: "bibliography.yml",
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
  centralized solution might be sufficient but for those that need to enforce at
  least a referential integrity of links between multiple git repositories, there
  is no open tooling that supports such functionality. The goal of the thesis is
  to research the possibility of developing tools composing a distributed wiki
  system that could be used by software developers working on multiple git
  repositories to create links between those repositories that would maintain
  referential integrity in a version-conscious manner. Such software could then
  later be used to compare the effects of a federated approach to documentation
  distribution on knowledge sharing efficiency with the centralized solutions such
  as Jira and many other wikis based on Git VCS.

  == Knowledge sharing in software engineering projects

  *[TODO]*

  Especially the problem of keeping the documentation up to date with the source
  code has been researched by many
  @consistency_between_architecture_and_informal_docs @ebon_for_consistency but
  few have looked into the problem under constraints introduced by different
  levels of trust between collaborating parties. While low level of trust is
  perceived as a factor negatively affecting the quality of knowledge sharing
  between parties @knowledge_sharing_global_software_development, overcoming this
  challenge can be time-consuming and enabling collaboration with limited trust
  could enable a quicker start of productive cooperative work.

  Zahedi et al. point out in their review
  @knowledge_sharing_global_software_development _lack of openness_ as one of the
  most frequently observed knowledge sharing challenges. On the other hand Martin
  et. al @alignment_flexibility_knowledge_based_perspective *[... TODO]*

  == Federation as tool for collaboration in limited trust environment

  *[TODO]*

  = Software Architecture
  
  #figure(image("img/architecture-concept-non-federated.svg", height: 70%), caption: [
    The technology stack of implemented solution.
  ]) <fig_arch_concept_non_federated>
  
  #figure(image("img/architecture-concept-federated.svg", height: 70%), caption: [
    The technology stack of implemented solution.
  ]) <fig_arch_concept_federated>

  *[TODO]* #lorem(15)

  == Technology Stack

  As a prototype software #wit relies heavily on external libraries and
  components. Besides dependencies pulled with cargo - a builder and package
  manager for Rust programming language - the most important elements to which
  belong a web browser and git version control system are expected to already be
  present on the target user's system. The source code of the implementation
  attached with the thesis is however a purely Rust-based project as the tooling
  provided with the language allows easy linking of dynamic libraries through
  crates - cargo's dependency units. @fig_tech_stack present's a stack-like
  representation of technologies utilised by the server and client executables.

  #figure(image("img/implementation-components.svg", height: 70%), caption: [
    The technology stack of implemented solution.
  ]) <fig_tech_stack>

  The source code does not reference libgit2 -
  "pure C implementation of the Git core methods" @libgit2_desc - directly but
  instead it relies on a wrapper crate named git2. This allows for a
  single-language codebase and reduces the complexity.

  == Communication Protocols

  #Wit operates on multiple communication protocols to utilise as extensively as
  possible the components on which it relies. The specific application layer
  protocol selected for transferring data between local and remote git
  repositories depends on the submodule configuration present in the local to the
  developer's environment git repository and is fully managed by libgit2.

  #figure(
    image("img/user-interaction-outline.svg"),
    caption: [
      A diagram presenting general overview of user's interactions and triggered by
      them data transfers.
    ],
  ) <fig_interaction_outline>

  #figure(
    image("img/client-server-communication.svg", height: 90%),
    caption: [
      A sequence diagram presenting client-server-server communication over various
      protocols using the same color coding as @fig_interaction_outline. Presented
      sequence describes process with error-less link verification.
    ],
  ) <fig_client_server_sequence>

  The specific protocol utilised by libgit2 for transport, of which supported by
  the library are SSH and HTTPS, is defined by the url string used as an address
  of the remote wit server.

  = Unique challenges

  #lorem(10)

  = Scratchpad

  The part that should be eventually removed.

  == Inter-project knowledge sharing over different organization structures

  - Within a single team working on multiple projects.
  - Between multiple teams working on their projects in a single organization
    (company, NGO).
  - Between multiple organizations that share one or more projects.
    - "Then again, trust is not static; it is a dynamic process that evolves according
      to the development of the relationship (Clegg, 2000). Hence, an unsuccessful
      alliance could end in separation." @strategic_alliances_and_knowledge_sharing
  - Between multiple organizations which work on their projects separately but which
    share some knowledge between projects.

  == Loose thoughts

  To self: The interdependence and cooperative vs competetive context are
  discussed in @modeling_high_quality_knowledge_sharing

  Cooperative contexts are more likely to result in high-quality knowledge sharing
  *[TODO: add citation]*. Competetive context might result from a "negative
  interdependence" *[TODO: add citation]* which may result from belonging to
  different projects or organizations.

  == Knowledge sharing barriers related to knowledge ownership and access to knowledge

  - Unwilingess to give up power associated with knowledge
    @unwilingness_to_share_knowledge_study_turkey
  - Conflicts, especially with a sense of unfairness on one of the ends of the
    relation, leading to a hesitance to share knowledge
    @unwilingness_to_share_knowledge_study_turkey
    - Knowledge dissemination might lead to loosing the information about the original
      contributor which in turn may result in the contributor not being acknowledged
      by an organization.
  - Security risks associated with certain information
    @unwilingness_to_share_knowledge_study_turkey

  == Relevant recomendations and solutions to knowledge sharing barriers

  - Assuring no disadvantage after sharing the knowledge

  == Implementation

  Possibly relevant:
  - similar attempt on general files stored in a dedicated database
    @version_in_federated_database
  - very similar domain but the goal is to integrate multiple previously existing
    services @open_web_application_lifecycle
  - more of similar problems but in an overview
    @version_control_in_distributed_software
  - an overview of distributed version control systems
    @analysis_of_distributed_version_control
  - a useful introduction into distributed ledger technologies
    @review_distributed_ledger
  - half of the job done, someone tried to make git actually distributed using
    distributed ledger @decentralized_git_version_control but their use case and
    goals were different.

  == Theory to remember / research

  - _CAP theorem_ - distributed system cannot be completely consistent (C),
    available (A), and tolerant of network partitions (P) all at the same time.
    *[TODO: add citation]*
  - _Byzantine fault-tolerance_
  - _Sybil attack_

  == Goals

  Design and implement a protocol for a distributed wiki using git (libgit2) for
  version control and evaluate its suitability for use in organizations that work
  on their projects using multiple git repositories and need to share as well as
  synchronize some knowledge between those projects. The application
  (implementation) should be approachable to software developers and integrate
  well with their daily workflow which includes frequent use of git. Hyperlinks to
  content related to another repository in the system should be verified by the
  provided tooling.

  == Test template
  #lorem(30)
  === Lorem
  #lorem(30)
  ==== Lorem
  #lorem(40)
  ==== Lorem2
  #lorem(200)
  ===== Lorem
  #lorem(100)
  ===== Lorem2
  #lorem(100)
]