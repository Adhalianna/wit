#import "presentation-template.typ": slides, transition


#show: slides.with(
    title: "Wiki on top of Git",
    author: "Natalia Goc",
    date: "2023-10-24",
)

= Implementation challenges

- poor documentation of libgit2
- encapsulating git transport for communication between client and server applications

= Utilized git features

- vcs
- submodules
- git hooks (pre-commit)

= Design goals

#figure(image("../design/architecture-concept1.svg"))

= Design goals

- interface similar to git
- use of git submodules hidden from the user
- wiki links checked before commit

= Design goals

- *`git status` → `wit status`* - show uncommitted changes to the wiki 
    (while being in the project git repository operates as if within the submodule)
- *`git log` → `wit log`* - show history of changes to the wiki including available
    changes from other servers (pulls more information than `git log` run within submodule,
    utilizes the distributed nature of the servers)
- *`git add` → `wit add`*
- *`git commit` → `wit commit`* - saves changes in a commit in both the submodule and the
    project git repository and the submodule (default mode of operation)
- *`git pull` → `wit pull`* 
- *`git init` → `wit init`* - starts a new wiki submodule in the git repository storing the project