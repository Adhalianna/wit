#import "presentation-template.typ": slides, transition

#let distributed_systems_book = [ Van Steen, M. and Tanenbaum, A.S., 2017. Distributed systems (p. 2). Leiden, The Netherlands: Maarten van Steen.]

#show: slides.with(
    title: "Topic Introduction",
    subtitle: "Distributed Wiki on top of Git for inter-project knowledge sharing targeting software developers as users",
    author: "Natalia Goc",
    date: "2023-10-24",
)


= Title breakdown
    
+ Distributed Wiki
+ on top of Git
+ for inter-project knowledge sharing
+ targeting software developers as users

= Title breakdown

+ Distributed Wiki
+ on top of Git
+ targeting software developers as users
+ for inter-project knowledge sharing

 ⮤ but, we will go with a new order

= Title breakdown

+ Distributed Wiki --- _what?_
+ on top of Git --- _what?_
+ targeting software developers as users --- _what?_
+ for inter-project knowledge sharing --- _why?_



#transition[
    The goal
]

= Distributed Wiki

A distributed system is a collection of autonomous computing elements
that appears to its users as a single coherent system. #footnote[#distributed_systems_book]

= Distributed Wiki

Goals of a distributed system design:
- Supporting resource sharing (e.g. BitTorrent)
- Making distribution transparent
- Scalable
- Being Open (interoperability, composability, exensibility) #footnote[#distributed_systems_book]


= Distributed Wiki

*Distributed computing* is a field of computer science that studies distributed systems. 

= Distributed Wiki

Message passing, and communication protocols are crucial elements of distributed programs.

= Distributed Wiki

For example:

#align(center)[
    client-server ⇏ distributed system
]

= Distributed Wiki

For example: 

#align(center)[
    client-server ⇒ distributed computing
]

#transition[Narrowing down...]

= on top of Git

Wikis built on Git:
- GitHub Wiki Pages #linebreak()
    `git clone https://github.com/USERNAME/REPOSITORY.wiki.git`
- GitLab Wiki
- gollum #linebreak()
    #emph[https://github.com/gollum/gollum]

#transition[...and down]

= targeting software developers as users

Software developers:
- Usually know Git VCS
- Perform significant amount of their work within Git repositories
- Can be easily found among Computer Science graduates
- Often work in collaborative environments that demand frequent knowledge sharing

= targeting software developers as users

Wikis built on Git:
- GitHub Wiki Pages #linebreak()
    `git clone https://github.com/USERNAME/REPOSITORY.wiki.git`
- GitLab Wiki
- gollum #linebreak()
    #emph[https://github.com/gollum/gollum]


#transition[Motivation]

= inter-project knowledge sharing

Knowledge can be shared between projects to:
- Synchronize work
- Assert data consistency 
    - e.g. a single list of requirements applying to multiple projects
- Benefit from _collaborative innovation_
- ...

= inter-project knowledge sharing

Knowledge can be shared over multiple organization structures:
- Single team dividing work into multiple indpendent projects
- Multiple teams in a single company working on dependent projects
- Dependent projects spanning multiple companies
- ...

= inter-project knowledge sharing

The discipline studying knowledge sharing processes, among other processes involving
knowledge, is called *knowledge management*.

= inter-project knowledge sharing

Trust is often mentioned as one of key requirements to successful knowledge sharing.
However, trust is not a static property.

= inter-project knowledge sharing

When social media user's began to lose trust in centralized platforms they were using,
decentralized alternatives saw a rise in popularity.


= inter-project knowledge sharing

"Due to its tendency towards a decentralised or even distributed infrastructure,
the Fediverse facilitates a more horizontal and distributed governance by redis-
tributing power and thus creating the possibility for more open machines able
to shape humans’ personal and collective identities – and be transformed by
human interactions (Milani 2010). [...] The very nature of the federation is built on
the autonomy of each node." #footnote[
    Anderlini, J. and Milani, C. 2022. Emerging Forms of Sociotechnical Organisation:
The Case of the Fediverse. In: Armano, E., Briziarelli, M., and Risi, E. (eds.), Digital
Platforms and Algorithmic Subjectivities. Pp. 167–181. London: University of
Westminster Press. DOI: https://doi.org/10.16997/book54.m. License:
CC-BY-NC-ND 4.0
]

#transition[So why really?]

= The questions that are driving me

- Can the ideas and technology that make Fediverse unique be transferred with its benefits to
    working environment of Software Developers?
- Could we use federated/distributed wikis to facilitate temporary cooperative efforts expressed
    as collaboration of multiple parties on dependent projects?
    
#transition[In the broader context]


= In the broader context

- Experimental application of distributed computing techniques, and software engineering.
- Solution to inter-company, temporary collaboration on common projects involving
    knowledge sharing that makes the process of building and splitting shared knowledge base
    simpler.
- An attempt at utilizing new approach to building a wiki that through comparison with
    traditional centralized wiki might bring new insight in the domain of knowledge management.
