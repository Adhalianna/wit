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

  let footer_font_size = 0.8em
  let minimal_footer = locate(loc => {
    let current_page = counter(page).at(loc).first()
    align(center)[#text(size: 1em)[#current_page]]
  })

  // TITLE PAGE
  
  // WARN!: this duplicate within code is a Quickfix
  // TODO: fix this and/or allow some means of adding title pages
  import "title_page_pl.typ": thesis_title_page as thesis_title_page_pl
  thesis_title_page_pl(
    logo_path: university_logo_file,
    university: "Akademia Górniczo-Hutnicza im. Stanisława Staszica w Krakowie",
    faculty: "WYDZIAŁ ELEKTROTECHNIKI, AUTOMATYKI, INFORMATYKI I INŻYNIERII BIOMEDYCZNEJ",
    document_type: [Pojekt dyplomowy],
    titles: titles,
    author: author.first_name + " " + author.second_name + if author.at("other_names", default: none) != none { " " + author.other_names } + " " + author.surname,
    degree_programme: degree_programme,
    supervisor: supervisor,
    location: location,
    date: date,
  )
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

  // Set margins:
  set page(margin: (inside: 3cm, outside: 2cm))

  // Stylize headings:
  show heading.where(level: 1): hding => {
    v(2.66em, weak: true)
    text(size: 1.5em)[#hding]
    v(2.33em, weak: true)
  }
  show heading.where(level: 2): hding => {
    v(2em, weak: true)
    text(size: 1.25em)[#hding]
    v(1.5em, weak: true)
  }
  show heading.where(level: 3): hding => {
    v(1.5em, weak: true)
    text(size: 1.1em)[#hding]
    v(1.33em, weak: true)
  }
  show heading.where(level: 4): hding => {
    v(1.33em, weak: true)
    hding
    v(1.2em, weak: true)
  }
  show heading: set par(justify: false, leading: 1em)
  show heading: set block(spacing: 1em)
  show heading.where(level: 1): set block(spacing: 2em)
  // Stylize paragraphs
  set par(justify: true, leading: 1.25em)
  show par: set block(spacing: 2em)
  // Stylize figures
  set figure(gap: 1.5em)
  show figure: set par(leading: 1em)
  show figure: set place(clearance: 2em)
  show figure: set block(breakable: true)
  // Stylize code/raw blocks
  show raw.where(block: true): set par(justify: false, linebreaks: "simple")
  // Stylize tables
  set table(inset: 0.66em, columns: (97.5%))
  show table: set par(leading: 0.75em)
  // Stylize lists
  set list(indent: 1.25em)

  // ABSTRACTS
  page(header: none, footer: none)[
    #set heading(outlined: false, bookmarked: true)
    #show heading.where(level: 1): hding => {
      align(center)[ #text(weight: 700)[#upper()[ #hding ]] ]
    }
    #abstracts
  ]
  pagebreak()
  pagebreak()

  // Default styling of content pages:
  set page(
    header: locate(
      header_loc => {
        set text(size: 0.8em)
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
              let headings_on_level_higher = query(
                heading.where(level: previous_heading.level - 1).before(header_loc),
                header_loc,
              )
              if headings_on_level_higher.len() > 0 {
                query(
                  heading.where(level: previous_heading.level - 1).before(header_loc),
                  header_loc,
                ).last()
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
          set text(size: 0.8em)
          if calc.even(current_page_number) {
            align(right)[#footer_text]
          } else {
            align(left)[#footer_text]
          }
        } else {
          align(center)[#text(size: 1em)[#current_page_number]]
        }
      },
    ),
  )

  counter(page).update(1)

  // empty page
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

    // Skip outlining headers which are "alone" at their depth.
    // Require at least two headings at a given depth to get them outlined.
    // ... for some reason this doesn't actually work despite detecting
    // correctly "lone" headings.
    #show heading: hding => {
      let hding_func = hding.func()
      let loc = hding.location()

      let counter_elements = counter(heading).at(loc)

      if counter_elements.last() == 1 {
        let depth_level = counter_elements.len()

        let headings_at_same_level = query(heading.where(level: depth_level).after(loc), loc)

        if headings_at_same_level.len() != 0 {
          let next_at_same_level = headings_at_same_level.first()
          let next_counter = counter(heading).at(next_at_same_level.location())

          if next_counter.last() != 2 {
            set heading(outlined: false)
            hding
          } else {
            set heading(outlined: true)
            hding
          }
        } else {
          set heading(outlined: false)
          hding
        }
      } else {
        set heading(outlined: true)
        hding
      }
    }

    //// add pagebreak after content under heading level 1 and before heading level 2
    //#show heading: hding => {
    //  locate(
    //    loc => {
    //      let any_previous_headings_below_h1 = query(selector(heading)
    //      .before(loc, inclusive: false)
    //      .after(query(
    //        heading.where(level: 1, outlined: true).before(loc, inclusive: false),
    //        loc,
    //      ).last().location(), inclusive: false), loc)
    //      if any_previous_headings_below_h1.len() == 1 {
    //        pagebreak()
    //      }
    //      hding
    //    },
    //  )
    //}

    #content
    #pagebreak(weak: true)
  ]

  // BIBLIOGRAPHY
  page(header: none, footer: minimal_footer)[
    #set heading(outlined: false, bookmarked: true)
    #bibliography(bibliography_file, style: "ieee")
  ]
}
