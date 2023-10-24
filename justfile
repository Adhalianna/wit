render-svg:
    cd doc/design && \
    d2 --layout dagre --pad 5 architecture-concept1.d2 architecture-concept1.svg && \
    d2 --layout dagre --pad 5 architecture-concept2.d2 architecture-concept2.svg

render-design: render-svg
   cd doc/design && \
    typst compile design.typ
render-paper:
    cd doc/paper && \
    typst compile paper.typ