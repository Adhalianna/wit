#let thesis_title_page(
    logo_path: none,
    logo_width: 33%,
    university: "",
    faculty: "",
    document_type: [Diploma Project],
    titles: (""),
    author: "",
    degree_programme: "",
    supervisor: "",
    location: none,
    date: datetime.today(),
    font: ("DejaVu Sans", "Noto Sans", "sans-serif"),
    text_size: 11pt,
    empty_page_after: true,
) = {
    set document(title: titles.at(0), author: author, date: date)
    set align(center)
    set text(font: font, fallback: true, size: text_size)

    page(
        footer: [
            #set align(center)
            #set text(size: 0.84em)
            #text()[
                #if location != none [
                    #location,
                ]
                #date.year()
            ]
        ]
    )[
        #grid(
            columns: (auto),
            rows: (10fr, 5fr, 2fr),
            // faculty intro
            [
                #set align(center + horizon)
                #if logo_path != none [
                    #image(logo_path, width: 33%)
                ]
                #text(weight: 900)[
                    #par()[#smallcaps(university)]
                    #par()[#upper(faculty)]
                ]
                #v(3.5em)
                #par()[#document_type]
            ],
            // titles
            align(center + top)[
                #for title in titles [
                    #text(style: "italic")[#title]
                    #parbreak()
            ]],
            // author details
            align(left + top)[
                #set text(size: 0.9em)
                #grid(
                    columns: (140pt, auto),
                    gutter: 0.9em,
                    "Author:", author,
                    "Degree Programme:", degree_programme,
                    "Supervisor:", supervisor,
                )
            ]
        )
    ]

    // add an empty page
    if empty_page_after {
        pagebreak()
        pagebreak()
    }
}