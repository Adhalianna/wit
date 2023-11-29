= Design document

== Explicit non-goals

- Permission managament, user verification
- GUI

== Inter-project knowledge sharing challanges

- Reluctance to give up the power that comes with knowledge

== Architecture

=== Wit servers in federation

#figure(image("architecture-concept1.svg", fit: "contain", height: 80%), caption: [
    Wit operating in client-server architecture in federation with other servers.
]) <architecture_concept1>

Challenges of the architecture described by @architecture_concept1:
- Recording a single version between the servers
- Validating local links against other servers in federation
- Connecting reliably servers within the federation

Benefits of the architecture described by @architecture_concept1:
- Limited access to files managed by other projects
- Connflicts cannot occur as files are not shared

=== Git-like single remote

#figure(image("architecture-concept2.svg", fit: "contain", height: 70%), caption: [
    Wit operating just like git.
]) <architecture_concept2>

Challenges of the architecture described by @architecture_concept2:
- Limiting access to files managed by other projects
- Limiting the amount of data cloned into a single project
- Conflicts can occur

== Federation communication protocol

#figure(image("communication-protocol1.svg"))

== CLI utility design

=== User personas

Each user persona will be built of short paragraphs explaining their goals, purpose and approach.

+ *Goals* - What they want?
+ *Purpose* - Why they want it?
+ *Approach* - How they want to achieve it?

#linebreak()

==== Software Developer working on a project that depends on other projects

- The developer wants to view the wiki in a *state appropiate to the version of their project*. 
    It is important to them as they might be at the moment amending an older version of the product 
    and it is not desired to apply, for example, newer requirements to it. They plan to achieve that by setting
    their git repository to appropiate version and (_optionally_) using a CLI utility to move the
    wiki to the corresponding version.
- The developer wants to make sure that when they create links they are valid references to the parts of the
    wiki that are maintained as part of other projects. They want it such because they need to be aware of
    significant changes to the documents they are referencing as those might invalidate what they were about to
    write on pages managed by them. They would like to be *informed of invalid links* each time they are about to
    publish changes, preferably by an IDE extension but optionally by execution of a CLI utility that can be included
    in CI/CD pipelines or invoked by demand.
- The developer wants to see managed by them wiki files *alongside the git repository* they are working on. *[TODO]*
- The developer wants to easily *initialize the wiki* in a new project they are working on which depends on other
    projects. *[TODO]*

=== Commands overview

==== Git commands which can be mapped to wit

- `git status` → `wit status`
- `git log` → `wit log`
- `git pull` → `wit pull`
- `git checkout` → `wit checkout`
- `git init` → `wit init`
- `git clone` → `wit clone`
