# print available commands
default:
    @just --list

d2-regular-font := `fc-match "Times New Roman" -f "%{file}"`
d2-italic-font := `fc-match "Times New Roman:italic" -f "%{file}"`
d2-bold-font := `fc-match "Times New Roman:bold" -f "%{file}"`
bold:=`tput bold`
reset:=`tput sgr0`

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

# Whacky, nasty thing but makes the recipes sooo much faster.
# See: https://unix.stackexchange.com/a/742040
# Should be decently portable, uses POSIX shell.
start_parallel:='set -o pipefail; run_parallel() {'
pll:='<&3 3<&- >&4 4>&-' # start each line with this, finish with a pipe `|` and obviously `\`
end_parallel:=';}; run_parallel 3<&0 4>&1 || exit 1'

# render the thesis document
render-paper:
    @cd docs/paper/img && \
        echo '{{bold}}cd docs/paper/img && d2 ...{{reset}}' && \
        {{start_parallel}} \
        {{pll}} d2 --dagre-edgesep 20 --dagre-nodesep 200 user-interaction-outline.d2 | \
        {{pll}} d2 implementation-components.d2 | \
        {{pll}} d2 architecture-concept-non-federated.d2 | \
        {{pll}} d2 architecture-concept-federated.d2 | \
        {{pll}} d2 wit-mnemonic.d2 | \
        {{pll}} d2 --elk-edgeNodeBetweenLayers 10 --elk-nodeNodeBetweenLayers 0 --elk-padding "[top=80,left=40,right=40,bottom=50]" use-case-diagram.d2 | \
        {{pll}} d2 --elk-edgeNodeBetweenLayers 5 --elk-nodeNodeBetweenLayers 0 --elk-padding "[top=20,left=35,right=35,bottom=20]" uri-resolution.d2 \
        {{end_parallel}}
    cd docs/paper && \
        typst compile paper.typ

# render presentations used in seminar classes
render-seminar-resources:
    cd docs/seminar && \
    typst compile presentation1.typ && \
    d2 --layout dagre --pad 0 architecture-simple.d2 && \
    d2 --layout dagre --pad 0 web-interaction.d2 && \
    typst compile presentation2.typ

# run tests with cargo
test:
    cargo test --workspace -- --nocapture
