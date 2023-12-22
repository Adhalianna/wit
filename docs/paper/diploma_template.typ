#let diploma(
    university_logo_file: none,
    university: "",
    faculty: "",
    titles: (""),
    short_title: "",
    author: (
        first_name: "",
        second_name: "",
        other_names: none,
        surname: "",
    ),
    degree_programme: "",
    supervisor: "",
    date: datetime.today(),
    location: none,
    abstracts: [],
    acknowledgement: none,
    bibliography_file: "",
    content
) = {
    assert(type(author) == "dictionary")

    let author_first_name_initial = author.first_name.at(0) + "."
    let author_second_name_initial = if author.at("second_name", default: none) != none {
        author.second_name.at(0) + "."
    }

    let author_short_name = author_first_name_initial + " " + if author_second_name_initial != none { author_second_name_initial + " " } + author.surname

    let footer_font_size = 11pt
    let minimal_footer = locate(loc => {
        let current_page = counter(page).at(loc).first()
        align(center)[#text(size: footer_font_size)[#current_page]]
    })

    // TITLE PAGE
    import "title_page.typ": *
    thesis_title_page(
        logo_path: university_logo_file,
        university: university,
        faculty: faculty,
        document_type: [Diploma Project],
        titles: titles,
        author: author.first_name + " " + author.second_name + if author.at("other_names", default: none) != none { " " + author.other_names } + " " + author.surname,
        degree_programme: degree_programme,
        supervisor: supervisor,
        location: location,
        date: date,
    )

    // default styling of content pages
    set page(
        margin: auto,
        header: locate(loc => {
            let current_page = counter(page).at(loc).first()

            let next_h1_loc = query(heading.where(level: 1, outlined: true).after(loc), loc).first().location()
            let h_between = query(selector(heading).after(loc).before(next_h1_loc, inclusive: false), loc).len()
            let is_h1_page = h_between == 0


            if not is_h1_page {
                let previous_h = query(selector(heading).before(loc), loc).last()
                let next_h = query(selector(heading).after(loc), loc).first()

                let h_on_header = if previous_h.level == next_h.level {
                    let h_level_higher = query(heading.where(level: previous_h.level - 1).before(loc), loc)
                    if h_level_higher.len() > 0 {
                        query(heading.where(level: previous_h.level - 1).before(loc), loc).last()
                    } else {
                        previous_h
                    }
                } else {
                    previous_h
                }
                let h_on_header_num = counter(heading.where(outlined: true)).at(h_on_header.location()).fold("", (acc, it) => {
                    if it != 0 {
                        acc + str(it) + "."
                    } else {
                        acc
                    }
                })

                let h_on_header_txt = h_on_header_num + " " + h_on_header.body

                if calc.even(current_page) {
                    [ #current_page #h(1fr) #h_on_header_txt ]
                } else {
                    [ #h_on_header_txt #h(1fr) #current_page ]
                }
                v(-0.66em)
                align(center)[#line(length: 102%, stroke: 1pt)]
            } else {
            }
        }),
        footer: locate(loc => {
            let current_page = counter(page).at(loc).first()

            let h_before_footer = query(selector(heading).before(loc), loc).last()
            let is_page_of_h1 = {
                counter(heading).at(h_before_footer.location()) == counter(heading.where(level: 1)).at(loc)
            } and {
                counter(page).at(h_before_footer.location()) == counter(page).at(loc)
            }

            if not is_page_of_h1 {
                align(center)[#line(length: 102%, stroke: 1pt)]
                v(-0.66em)

                let footer_text = [
                    #author_short_name
                    #h(0.6em)
                    #text(style: "italic")[#short_title]
                ]

                if calc.even(current_page) {
                    align(right)[#footer_text]
                } else {
                    align(left)[#footer_text]
                }
            } else {
                align(center)[#text(size: footer_font_size)[#current_page]]
            }
        })
    )
    show heading.where(level: 1): hding => {
        v(0.6em)
        text(size: 1.5em)[#hding]
        v(1.2em)
    }
    show heading.where(level: 2): hding => {
        v(0.3em)
        text(size: 1.25em)[#hding]
        v(0.6em)
    }
    show heading.where(level: 3): hding => {
        text(size: 1.1em)[#hding]
        v(0.33em)
    }

    // ABSTRACTS
    page(
        header: none,
        footer: none,
    )[
        #set heading(outlined: false, bookmarked: true)
        #show heading.where(level: 1): hding => {
            align(center)[ #text(weight: 500)[#upper()[ #hding ]] ]
        }
        #abstracts
    ]

    // empty page
    pagebreak()
    pagebreak()

    // ACKNOWLEDGEMENTS
    if acknowledgement != none {
        align(right + bottom)[
            #grid(
                columns: (50%),
                [#text(size: 1.1em, style: "italic")[
                    #acknowledgement
                ]]
            )
            #v(7.5%)
        ]
        pagebreak()
    }

    // TABLE OF CONTENTS
    page(
        header: none,
        footer: minimal_footer
    )[
        #show outline.entry.where(level: 1): entr => {
            strong(entr)
        }
        #outline(indent: true)
    ]

    counter(heading).update(0)

    // PAPER CONTENT
    [
        #set heading(numbering: "1.")
        #show heading.where(level: 1): hding => {
            pagebreak(weak: true)
            align(top + left)[#hding]
        }
        // add pagebreak after content under heading level 1 and before heading level 2
        #show heading.where(level: 2): hding => {
            locate(loc => {
                let any_previous_h2 = query(
                    selector(heading).before(loc, inclusive: false).after(heading.where(level: 1, numbering: "1."), inclusive: false),
                    loc
                )
                if any_previous_h2.len() == 1 {
                    pagebreak()
                }
                hding
            })
        }
        #content
        #pagebreak(weak: true)
    ]

    // BIBLIOGRAPHY
    page(
        header: none,
        footer: minimal_footer
    )[
        #set heading(outlined: false, bookmarked: true)
        #bibliography(bibliography_file, style: "ieee")
    ]
}