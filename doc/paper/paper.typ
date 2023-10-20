// ------ METADATA AND GLOBALS ------

#let paper_title = "Distributed Wiki on top of Git for inter-project knowledge sharing targeting software developers as users"
#set document(
    title: paper_title,
    author: "Natallia Goc"
)

#set text(font: "New Computer Modern", size: 11pt)

// ------ TITLE PAGE ------

#align(center + horizon)[
   = #paper_title
   Natalia Goc
]

#pagebreak()

// ------ SCRATCHPAD CONTENT ------

= Scratchpad

== Intro

Enforcing knowledge consistency in an environment of frequent changes to data such as requirements or design documents
that can be observed during the development of a software product is still an area seeing plenty of attention and
financial investment. One of the approaches taken by some organizations that can be seen as sufficiently efficient for
a single project is to store all documentation and design documents in the same git repository that is used for the
developed software. Whether this approach is successful for that single repository depends on factors such as the
provided tools checking the consistency and the developers’ discipline in keeping the documentation up to date. The
task becomes more difficult when consistency has to be enforced between multiple projects which may be managed by
multiple teams. In such a case there is no single version control system that would synchronize the knowledge base with
each of the code bases. For many use cases, a separate centralized solution might be sufficient but for those that need
to enforce at least a referential integrity of links between multiple git repositories, there is no open tooling to
support it. The goal of the thesis is to research the possibility of developing tools composing a distributed wiki
system that could be used by software developers working on multiple git repositories to create links between those
repositories that would maintain referential integrity in a version-conscious manner.

== Goals

Design and implement a protocol for a distributed wiki using git (libgit2) for version control and evaluate its
suitability for use in organizations that work on their projects using multiple git repositories and need to share as
well as synchronize some knowledge between those projects. The application (implementation) should be approachable to
software developers and integrate well with their daily workflow which includes frequent use of git. Hyperlinks to
content related to another repository in the system should be verified by the provided tooling.

#pagebreak()

// ------ CONTENT ------

#set heading(outlined: true)

= Introduction

// ------ BIBLIOGRAPHY ------

#bibliography("bibliography.yml", style: "ieee")
