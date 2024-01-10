#let diploma(
  university_logo_file: none,
  university: "",
  faculty: "",
  titles: (""),
  short_title: "",
  author: (first_name: "", second_name: "", other_names: none, surname: ""),
  degree_programme: "",
  supervisor: "",
  date: datetime.today(),
  location: none,
  abstracts: [],
  acknowledgement: none,
  bibliography_file: "",
  content,
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

  set page(margin: (inside: 3cm, outside: 2cm))

  // Stylize headings:
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
  // Stylize paragraphs
  set par(justify: true, leading: 1.25em)
  // Stylize figures
  set figure(placement: auto)
  show figure: set place(clearance: 1.5em)

  // ABSTRACTS
  page(header: none, footer: none)[
    #set heading(outlined: false, bookmarked: true)
    #show heading.where(level: 1): hding => {
      align(center)[ #text(weight: 700)[#upper()[ #hding ]] ]
    }
    #abstracts
  ]

  // Default styling of content pages:
  set page(
    header: locate(
      header_loc => {
        let current_page_number = counter(page).at(header_loc).first()
        let all_h1_appearing_after_header = query(heading.where(level: 1, outlined: true).after(header_loc), header_loc)

        let is_h1_page = false

        if all_h1_appearing_after_header.len() > 0 {
          let next_h1_loc = all_h1_appearing_after_header.first().location()
          is_h1_page = next_h1_loc.page() == current_page_number
        }

        if not is_h1_page {
          let previous_headings = query(selector(heading.where(outlined: true)).before(header_loc), header_loc)
          let next_heading = query(selector(heading).after(header_loc), header_loc).first()

          let do_draw_previous_heading = previous_headings.len() > 0
          let text_on_header = ""

          if do_draw_previous_heading {
            let previous_heading = previous_headings.last()

            // Try to put on the header a heading that provides the most insight about the context:
            let heading_on_header = if previous_heading.level == next_heading.level {
              // If the next heading after the header is on the same nesting level
              // as the next heading before the header, then the header should display
              // the first heading that is less nested found before the header.
              let headings_on_level_higher = query(heading.where(level: previous_heading.level - 1).before(header_loc), header_loc)
              if headings_on_level_higher.len() > 0 {
                query(heading.where(level: previous_heading.level - 1).before(header_loc), header_loc).last()
              } else {
                previous_heading
              }
            } else {
              previous_heading
            }

            // Display header numbering in a "1.1. Lorem" format:
            let h_on_header_num = counter(heading.where(outlined: true)).at(heading_on_header.location()).fold("", (acc, it) => {
              if it != 0 {
                acc + str(it) + "."
              } else {
                acc
              }
            })

            text_on_header = h_on_header_num + " " + heading_on_header.body
          }

          if calc.even(current_page_number) {
            [ #current_page_number #h(1fr) #text_on_header ]
          } else {
            [ #text_on_header #h(1fr) #current_page_number ]
          }

          v(-0.66em)
          align(center)[#line(length: 105%, stroke: 1pt)]
        } else {
          // No headers on h1 pages.
        }
      },
    ),
    footer: locate(
      loc => {
        let current_page_number = counter(page).at(loc).first()

        let h_before_footer = query(selector(heading).before(loc), loc).last()
        let is_page_of_h1 = {
          counter(heading).at(h_before_footer.location()) == counter(heading.where(level: 1)).at(loc)
        } and {
          counter(page).at(h_before_footer.location()) == counter(page).at(loc)
        }

        if not is_page_of_h1 {
          align(center)[#line(length: 105%, stroke: 1pt)]
          v(-0.66em)

          let footer_text = [
            #author_short_name
            #h(0.6em)
            #text(style: "italic")[#short_title]
          ]

          if calc.even(current_page_number) {
            align(right)[#footer_text]
          } else {
            align(left)[#footer_text]
          }
        } else {
          align(center)[#text(size: footer_font_size)[#current_page_number]]
        }
      },
    ),
  )

  // empty page
  pagebreak()
  pagebreak()

  
  // ACKNOWLEDGEMENTS
  if acknowledgement != none {
    align(right + bottom)[
      #grid(columns: (75%), [
        #set par(justify: false, leading: 1.1em)
        #text(size: 1.1em, style: "italic")[
          #acknowledgement
        ]
      ])
      #v(7.5%)
    ]
    pagebreak()
  }

  // TABLE OF CONTENTS
  page(header: none, footer: minimal_footer)[
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
    #show heading: hding => {
      locate(
        loc => {
          let any_previous_headings_below_h1 = query(selector(heading)
          .before(loc, inclusive: false)
          .after(query(
            heading.where(level: 1, outlined: true).before(loc, inclusive: false),
            loc,
          ).last().location(), inclusive: false), loc)
          if any_previous_headings_below_h1.len() == 1 {
            pagebreak()
          }
          hding
        },
      )
    }
    #content
    #pagebreak(weak: true)
  ]

  // BIBLIOGRAPHY
  page(header: none, footer: minimal_footer)[
    #set heading(outlined: false, bookmarked: true)
    #bibliography(bibliography_file, style: "ieee")
  ]
}