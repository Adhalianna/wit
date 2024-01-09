default: render-paper

# render .d2 files in under docs/design to .svg graphics
render-design-svg:
    cd docs/design && \
    d2 --layout dagre --pad 5 architecture-concept1.d2 && \
    d2 --layout dagre --pad 5 architecture-concept2.d2 && \
    d2 --layout dagre --pad 5 communication-protocol1.d2

# render the document present under docs/design
render-design: render-design-svg
   cd docs/design && \
    typst compile design.typ

# render the thesis document
render-paper:
    cd docs/paper/img && \
        d2 --pad 0 -t 1 --center user-interaction-outline.d2 && \
        d2 --pad 0 -t 1 --center implementation-components.d2 && \
        d2 --pad 0 -t 1 --center client-server-communication.d2
    cd docs/paper && \
        typst compile paper.typ && \
        echo $?

# render presentations used in seminar classes
render-seminar-resources:
    cd docs/seminar && \
    typst compile presentation1.typ && \
    d2 --layout dagre --pad 0 architecture-simple.d2 && \
    d2 --layout dagre --pad 0 web-interaction.d2 && \
    typst compile presentation2.typ

# run tests with cargo
test:
    RUST_BACKTRACE=1 cargo test -- --nocapture
