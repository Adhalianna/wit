// ------ METADATA AND GLOBALS ------

#let paper_title = "Distributed Wiki on top of Git for inter-project knowledge sharing targeting software developers as users"
#set document(
    title: paper_title,
    author: "Natallia Goc"
)

// ------ GLOBAL STYLE ------

#set text(size: 11pt)

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

==== Inter-project knowledge sharing over different organization structures

- Within a single team working on multiple projects.
- Between multiple teams working on their projects in a single organization (company, NGO).
- Between multiple organizations that share one or more projects.
    - "Then again, trust is not static; it is a dynamic process that evolves
        according to the development of the relationship (Clegg, 2000). Hence, an unsuccessful
        alliance could end in separation." #cite("strategic_alliances_and_knowledge_sharing")
- Between multiple organizations which work on their projects separately but which share some knowledge between
    projects.

==== Loose thoughts

To self: The interdependence and cooperative vs competetive context are discussed in #cite("modeling_high_quality_knowledge_sharing")

Cooperative contexts are more likely to result in high-quality knowledge sharing *[TODO: add citation]*.
Competetive context might result from a "negative interdependence" *[TODO: add citation]* which may result from
belonging to different projects or organizations.

==== Knowledge sharing barriers related to knowledge ownership and access to knowledge

- Unwilingess to give up power associated with knowledge #cite("unwilingness_to_share_knowledge_study_turkey")
- Conflicts, especially with a sense of unfairness on one of the ends of the relation, leading to a
    hesitance to share knowledge #cite("unwilingness_to_share_knowledge_study_turkey")
    - Knowledge dissemination might lead to loosing the information about the original contributor which in turn
        may result in the contributor not being acknowledged by an organization.
- Security risks associated with certain information #cite("unwilingness_to_share_knowledge_study_turkey")

==== Relevant recomendations and solutions to knowledge sharing barriers

- Assuring no disadvantage after sharing the knowledge


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

#bibliography("bibliography.yml")
