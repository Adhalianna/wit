use std::sync::OnceLock;

use markdown_it::parser::inline::InlineRule;
use markdown_it::{MarkdownIt, Node};

use crate::server::link::WitLink;

static MARKDOWN_RENDERER: std::sync::OnceLock<MarkdownIt> = OnceLock::new();

struct AutolinkWitLinkScanner;
impl InlineRule for AutolinkWitLinkScanner {
    const MARKER: char = '<';

    fn run(state: &mut markdown_it::parser::inline::InlineState) -> Option<(Node, usize)> {
        let input = &state.src[state.pos..state.pos_max];
        let Some(input) = input.strip_prefix('<') else {
            return None;
        };
        let Some((input, _)) = input.split_once('>') else {
            return None;
        };
        let url = match WitLink::from_url(input) {
            Ok(wit_link) => wit_link.to_http(),
            Err(_) => input.to_owned(),
        };
        Some((
            Node::new(markdown_it::plugins::cmark::inline::autolink::Autolink { url }),
            2 + input.len(),
        ))
    }
}

fn translate_wit_links_full(url: Option<String>, title: Option<String>) -> Node {
    if let Some(url) = url {
        if let Ok(wit_link) = WitLink::from_url(&url) {
            Node::new(markdown_it::plugins::cmark::inline::link::Link {
                url: wit_link.to_http(),
                title,
            })
        } else {
            Node::new(markdown_it::plugins::cmark::inline::link::Link { url, title })
        }
    } else {
        unimplemented!()
    }
}

pub fn render(
    data: Vec<u8>,
    current_wiki_host: &str,
) -> Result<String, crate::server::render::RenderError> {
    let renderer = MARKDOWN_RENDERER.get_or_init(|| {
        let mut md = MarkdownIt::new();
        markdown_it::plugins::cmark::add(&mut md);
        markdown_it::plugins::extra::strikethrough::add(&mut md);
        markdown_it::plugins::extra::tables::add(&mut md);
        markdown_it::plugins::extra::syntect::add(&mut md);
        markdown_it::plugins::extra::linkify::add(&mut md);
        markdown_it::plugins::extra::heading_anchors::add(
            &mut md,
            markdown_it::plugins::extra::heading_anchors::simple_slugify_fn,
        );
        markdown_it::generics::inline::full_link::add::<true>(&mut md, translate_wit_links_full);
        md
    });

    Ok(renderer
        .parse(
            &String::from_utf8(data)
                .map_err(|_| crate::server::render::RenderError::InvalidUTF8)?,
        )
        .render())
}
