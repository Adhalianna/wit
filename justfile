render-design-svg:
    cd docs/design && \
    d2 --layout dagre --pad 5 architecture-concept1.d2 architecture-concept1.svg && \
    d2 --layout dagre --pad 5 architecture-concept2.d2 architecture-concept2.svg && \
    d2 --layout dagre --pad 5 communication-protocol1.d2 communication-protocol1.svg

render-design: render-design-svg
   cd docs/design && \
    typst compile design.typ

render-paper:
    cd docs/paper && \
    typst compile paper.typ

render-seminar-resources:
    cd docs/seminar && \
    typst compile presentation1.typ && \
    d2 --layout dagre --pad 0 architecture-simple.d2 && \
    d2 --layout dagre --pad 0 web-interaction.d2 && \
    typst compile presentation2.typ

test:
    RUST_BACKTRACE=1 cargo test -- --nocapture
