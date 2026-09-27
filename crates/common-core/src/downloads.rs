//! Naming downloaded files. A download never overwrites a file: the second `report.pdf` becomes
//! `report 2.pdf`, as Finder and Safari name copies. Every shell saves downloads, so the rule lives
//! here and they all agree on it.

/// The name used when a server suggests nothing usable.
const FALLBACK: &str = "download";

/// The first name, from `suggested`, that is not in `taken`: `name.ext`, then `name 2.ext`,
/// `name 3.ext` and so on.
///
/// `suggested` comes from the network, so it is reduced to a plain file name first: path
/// separators cannot lead outside the downloads directory and leading dots cannot hide the file.
/// Names compare case-insensitively because the default macOS and Windows file systems do, and
/// treating `Report.pdf` as taken by `report.pdf` costs nothing where they differ.
pub fn unique_file_name<'a>(suggested: &str, taken: impl IntoIterator<Item = &'a str>) -> String {
    let name = plain_file_name(suggested);
    let taken: Vec<String> = taken.into_iter().map(str::to_lowercase).collect();
    let (stem, extension) = split_extension(&name);
    (1..)
        .map(|n| match n {
            1 => name.clone(),
            _ => format!("{stem} {n}{extension}"),
        })
        .find(|candidate| !taken.contains(&candidate.to_lowercase()))
        .expect("the candidates are endless and `taken` is finite")
}

fn plain_file_name(suggested: &str) -> String {
    let replaced: String = suggested
        .chars()
        .map(|c| match c {
            '/' | '\\' | ':' => '-',
            c if c.is_control() => '-',
            c => c,
        })
        .collect();
    let trimmed = replaced.trim().trim_start_matches('.').trim_start();
    if trimmed.is_empty() {
        FALLBACK.to_string()
    } else {
        trimmed.to_string()
    }
}

/// Splits `name.ext` into `("name", ".ext")`. A name without a dot, or ending in one, has no
/// extension.
fn split_extension(name: &str) -> (&str, &str) {
    match name.rfind('.') {
        Some(dot) if dot > 0 && dot + 1 < name.len() => name.split_at(dot),
        _ => (name, ""),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_free_name_is_kept() {
        assert_eq!(unique_file_name("report.pdf", []), "report.pdf");
    }

    #[test]
    fn downloading_the_same_file_twice_numbers_the_second() {
        assert_eq!(unique_file_name("name.ext", ["name.ext"]), "name 2.ext");
    }

    #[test]
    fn numbering_continues_past_every_taken_copy() {
        let taken = ["name.ext", "name 2.ext", "name 3.ext"];
        assert_eq!(unique_file_name("name.ext", taken), "name 4.ext");
    }

    #[test]
    fn a_gap_in_the_numbering_is_reused() {
        assert_eq!(
            unique_file_name("name.ext", ["name.ext", "name 3.ext"]),
            "name 2.ext"
        );
    }

    #[test]
    fn only_the_last_extension_moves_after_the_number() {
        assert_eq!(
            unique_file_name("archive.tar.gz", ["archive.tar.gz"]),
            "archive.tar 2.gz"
        );
    }

    #[test]
    fn a_name_without_an_extension_gets_the_number_at_the_end() {
        assert_eq!(unique_file_name("README", ["README"]), "README 2");
        assert_eq!(unique_file_name("notes.", ["notes."]), "notes. 2");
    }

    #[test]
    fn taken_names_compare_case_insensitively() {
        assert_eq!(
            unique_file_name("Report.PDF", ["report.pdf"]),
            "Report 2.PDF"
        );
    }

    #[test]
    fn path_separators_cannot_leave_the_directory() {
        assert_eq!(unique_file_name("../../etc/passwd", []), "-..-etc-passwd");
        assert_eq!(unique_file_name("a\\b:c", []), "a-b-c");
    }

    #[test]
    fn leading_dots_cannot_hide_the_file() {
        assert_eq!(unique_file_name(".profile", []), "profile");
        assert_eq!(unique_file_name("  ..hidden.txt ", []), "hidden.txt");
    }

    #[test]
    fn an_unusable_suggestion_falls_back_to_download() {
        assert_eq!(unique_file_name("", []), "download");
        assert_eq!(unique_file_name(" .. ", []), "download");
        assert_eq!(unique_file_name("", ["download"]), "download 2");
    }

    #[test]
    fn control_characters_are_replaced() {
        assert_eq!(unique_file_name("a\nb\u{0}.txt", []), "a-b-.txt");
    }
}
