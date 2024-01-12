# print available commands
default:
    @just --list

d2-regular-font := `fc-match "Times New Roman" -f "%{file}"`
d2-italic-font := `fc-match "Times New Roman:italic" -f "%{file}"`
d2-bold-font := `fc-match "Times New Roman:bold" -f "%{file}"`

export D2_PAD := "0"
export D2_CENTER := "true"
#export D2_FONT_REGULAR := d2-regular-font
#export D2_FONT_ITALIC := d2-italic-font
#export D2_FONT_BOLD := d2-bold-font
export D2_THEME := "1"
export D2_FORCE_APPENDIX := "true"

# render .d2 files in under docs/design to .svg graphics
_render-design-svg:
    cd docs/design && \
    d2 --layout dagre --pad 5 architecture-concept1.d2 && \
    d2 --layout dagre --pad 5 architecture-concept2.d2 && \
    d2 --layout dagre --pad 5 communication-protocol1.d2

# render the document present under docs/design
render-design: _render-design-svg
   cd docs/design && \
    typst compile design.typ

# render the thesis document
render-paper:
    cd docs/paper/img && \
        d2 user-interaction-outline.d2 && \
        d2 implementation-components.d2 && \
        d2 client-server-communication.d2 && \
        d2 architecture-concept-non-federated.d2 && \
        d2 architecture-concept-federated.d2
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
