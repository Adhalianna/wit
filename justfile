render-design-svg:
    cd doc/design && \
    d2 --layout dagre --pad 5 architecture-concept1.d2 architecture-concept1.svg && \
    d2 --layout dagre --pad 5 architecture-concept2.d2 architecture-concept2.svg && \
    d2 --layout dagre --pad 5 communication-protocol1.d2 communication-protocol1.svg

render-design: render-design-svg
   cd doc/design && \
    typst compile design.typ

render-paper:
    cd doc/paper && \
    typst compile paper.typ

render-seminar-resources:
    cd doc/seminar && \
    typst compile presentation1.typ && \
    typst compile presentation2.typ --root ../.

test:
    RUST_BACKTRACE=1 cargo test -- --nocapture
