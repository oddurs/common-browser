//! The launcher's one field: whether what was typed is an address or a search, and which open
//! pages it names. It replaces the address bar and the tab strip in every shell, so every shell
//! must read input the same way.

use crate::pages::PageId;

/// Where typed input leads.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Destination {
    /// A URL to open.
    Address(String),
    /// The search engine's URL for the input.
    Search(String),
}

impl Destination {
    pub fn url(&self) -> &str {
        match self {
            Destination::Address(url) | Destination::Search(url) => url,
        }
    }
}

/// Reads launcher input. Anything with a scheme (`https://x`, `about:blank`, `file:///a.html`) or
/// shaped like a host (`example.org`, `localhost:5173`) is an address; anything else, including
/// every input with a space in it, is a search through `engine`, a URL template in which `%s`
/// stands for the terms. Empty input leads nowhere.
pub fn destination(input: &str, engine: &str) -> Option<Destination> {
    let input = input.trim();
    if input.is_empty() {
        return None;
    }
    if input.contains(char::is_whitespace) {
        return Some(search(input, engine));
    }
    if let Some(scheme) = scheme(input) {
        // `localhost:5173` parses as a scheme followed by a port, but it is a host.
        let rest = &input[scheme.len() + 1..];
        let port = rest.split('/').next().unwrap_or_default();
        if !port.is_empty() && port.bytes().all(|b| b.is_ascii_digit()) {
            return Some(Destination::Address(format!("http://{input}")));
        }
        return Some(Destination::Address(input.to_string()));
    }
    let authority = input.split(['/', '?', '#']).next().unwrap_or_default();
    let host = authority.split(':').next().unwrap_or_default();
    if host == "localhost" || is_ipv4(host) {
        return Some(Destination::Address(format!("http://{input}")));
    }
    if host.contains('.') && !host.starts_with('.') && !host.ends_with('.') {
        return Some(Destination::Address(format!("https://{input}")));
    }
    Some(search(input, engine))
}

/// An open page as the launcher sees it.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct PageSummary {
    pub id: PageId,
    pub title: String,
    pub url: String,
}

/// The open pages whose title or address contains every word of `query`, ignoring case. Pages
/// whose title starts with the query come first, then other title matches, then address-only
/// matches; within each, the pages keep their order. An empty query lists every page.
pub fn matching_pages(query: &str, pages: &[PageSummary]) -> Vec<PageId> {
    let query = query.trim().to_lowercase();
    let words: Vec<&str> = query.split_whitespace().collect();
    let mut ranked: Vec<(u8, usize, PageId)> = pages
        .iter()
        .enumerate()
        .filter_map(|(order, page)| {
            let title = page.title.to_lowercase();
            let url = page.url.to_lowercase();
            if !words
                .iter()
                .all(|word| title.contains(word) || url.contains(word))
            {
                return None;
            }
            let rank = if title.starts_with(query.as_str()) {
                0
            } else if words.iter().all(|word| title.contains(word)) {
                1
            } else {
                2
            };
            Some((rank, order, page.id))
        })
        .collect();
    ranked.sort();
    ranked.into_iter().map(|(_, _, id)| id).collect()
}

fn search(terms: &str, engine: &str) -> Destination {
    Destination::Search(engine.replace("%s", &encode(terms)))
}

/// Encodes search terms the way a form does: spaces as `+`, and every byte outside the unreserved
/// set as `%XX`.
fn encode(terms: &str) -> String {
    let mut out = String::with_capacity(terms.len());
    for byte in terms.bytes() {
        match byte {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'.' | b'_' | b'~' => {
                out.push(byte as char)
            }
            b' ' => out.push('+'),
            _ => out.push_str(&format!("%{byte:02X}")),
        }
    }
    out
}

/// The scheme of `text`, if it starts with one (RFC 3986: a letter, then letters, digits, `+`,
/// `-` or `.`, then `:`).
fn scheme(text: &str) -> Option<&str> {
    let (scheme, _) = text.split_once(':')?;
    let mut chars = scheme.chars();
    let valid = chars.next()?.is_ascii_alphabetic()
        && chars.all(|c| c.is_ascii_alphanumeric() || matches!(c, '+' | '-' | '.'));
    valid.then_some(scheme)
}

fn is_ipv4(host: &str) -> bool {
    let parts: Vec<&str> = host.split('.').collect();
    parts.len() == 4 && parts.iter().all(|part| part.parse::<u8>().is_ok())
}

#[cfg(test)]
mod tests {
    use super::*;

    const ENGINE: &str = "https://duckduckgo.com/?q=%s";

    fn address(url: &str) -> Option<Destination> {
        Some(Destination::Address(url.to_string()))
    }

    fn search_for(url: &str) -> Option<Destination> {
        Some(Destination::Search(url.to_string()))
    }

    #[test]
    fn a_host_and_port_is_an_address_over_http() {
        assert_eq!(
            destination("localhost:5173", ENGINE),
            address("http://localhost:5173")
        );
        assert_eq!(
            destination("127.0.0.1:8080/api", ENGINE),
            address("http://127.0.0.1:8080/api")
        );
    }

    #[test]
    fn a_domain_is_an_address_over_https() {
        assert_eq!(
            destination("example.org", ENGINE),
            address("https://example.org")
        );
        assert_eq!(
            destination("example.org/a?b=c", ENGINE),
            address("https://example.org/a?b=c")
        );
    }

    #[test]
    fn words_are_a_search() {
        assert_eq!(
            destination("what is rust", ENGINE),
            search_for("https://duckduckgo.com/?q=what+is+rust")
        );
        assert_eq!(
            destination("rust", ENGINE),
            search_for("https://duckduckgo.com/?q=rust")
        );
    }

    #[test]
    fn anything_with_a_scheme_is_opened_as_written() {
        for url in [
            "https://x",
            "about:blank",
            "file:///tmp/a.html",
            "mailto:a@b.c",
        ] {
            assert_eq!(destination(url, ENGINE), address(url), "{url}");
        }
    }

    #[test]
    fn localhost_alone_is_an_address() {
        assert_eq!(
            destination("localhost/admin", ENGINE),
            address("http://localhost/admin")
        );
    }

    #[test]
    fn a_domain_followed_by_words_is_a_search() {
        assert_eq!(
            destination("example.org docs", ENGINE),
            search_for("https://duckduckgo.com/?q=example.org+docs")
        );
    }

    #[test]
    fn search_terms_are_encoded() {
        assert_eq!(
            destination("c++ & rust?", ENGINE),
            search_for("https://duckduckgo.com/?q=c%2B%2B+%26+rust%3F")
        );
        assert_eq!(
            destination("café", ENGINE),
            search_for("https://duckduckgo.com/?q=caf%C3%A9")
        );
    }

    #[test]
    fn blank_input_leads_nowhere() {
        assert_eq!(destination("   ", ENGINE), None);
    }

    fn pages() -> Vec<PageSummary> {
        [
            (1, "Rust docs", "https://doc.rust-lang.org"),
            (2, "Trusted types", "https://web.dev/trusted-types"),
            (3, "News", "https://news.example/rust"),
            (4, "Mail", "https://mail.example"),
        ]
        .into_iter()
        .map(|(id, title, url)| PageSummary {
            id,
            title: title.to_string(),
            url: url.to_string(),
        })
        .collect()
    }

    #[test]
    fn pages_match_by_title_then_address() {
        // "Rust docs" starts with the query, "Trusted types" contains it, "News" only in its URL.
        assert_eq!(matching_pages("rust", &pages()), vec![1, 2, 3]);
    }

    #[test]
    fn every_word_must_match() {
        assert_eq!(matching_pages("rust lang", &pages()), vec![1]);
        assert!(matching_pages("rust mail", &pages()).is_empty());
    }

    #[test]
    fn matching_ignores_case() {
        assert_eq!(matching_pages("MAIL", &pages()), vec![4]);
    }

    #[test]
    fn an_empty_query_lists_every_page_in_order() {
        assert_eq!(matching_pages("", &pages()), vec![1, 2, 3, 4]);
    }
}
