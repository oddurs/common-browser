//! `common.toml`, the only settings surface. There is no settings window to fall back on, so a
//! mistake in the file has to read like a compiler error: where it is, what was expected, and the
//! nearest thing that would have worked. Parsing never fails outright: a broken key keeps its
//! default, so a shell can start and show every error at once.

use std::ffi::OsStr;
use std::fmt;
use std::io;
use std::ops::Range;
use std::path::{Path, PathBuf};

use toml::Spanned;
use toml::de::{DeTable, DeValue};

/// The built-in themes `theme` and `theme_light` may name.
pub const THEMES: [&str; 2] = ["graphite", "paper"];

/// Every setting, each with the value it has when the file leaves it out.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Config {
    /// The page a new window opens. Defaults to `about:blank`: nothing loads that the user did
    /// not ask for.
    pub home: String,
    /// The theme used in dark mode.
    pub theme: String,
    /// The theme used in light mode.
    pub theme_light: String,
    pub accent: Rgb,
    pub window: Window,
    pub search: Search,
    pub keys: Keys,
}

impl Default for Config {
    fn default() -> Self {
        Config {
            home: "about:blank".to_string(),
            theme: "graphite".to_string(),
            theme_light: "paper".to_string(),
            accent: Rgb {
                r: 0xd9,
                g: 0x89,
                b: 0x5b,
            },
            window: Window::default(),
            search: Search::default(),
            keys: Keys::default(),
        }
    }
}

/// A colour written as `#rrggbb`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Rgb {
    pub r: u8,
    pub g: u8,
    pub b: u8,
}

/// The `[window]` table.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Window {
    pub start: WindowStart,
}

/// How a new window first appears.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum WindowStart {
    #[default]
    Windowed,
    Fullscreen,
}

/// The `[search]` table.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Search {
    /// A URL template; `%s` is replaced by the search terms.
    pub engine: String,
}

impl Default for Search {
    fn default() -> Self {
        Search {
            engine: "https://duckduckgo.com/?q=%s".to_string(),
        }
    }
}

/// The `[keys]` table.
#[derive(Clone, Debug, Default, PartialEq, Eq)]
pub struct Keys {
    pub mode: KeyMode,
}

/// The family of keybindings. Vim bindings arrive in v0.3, so `standard` is the only one yet.
#[derive(Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum KeyMode {
    #[default]
    Standard,
}

/// One problem in the file, as data a shell can render however it likes.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ConfigError {
    /// 1-based.
    pub line: usize,
    /// 1-based, counted in characters rather than bytes so it matches what an editor shows.
    pub column: usize,
    /// The dotted path of the key, such as `search.engine`. Empty for a TOML syntax error, which
    /// may not belong to any key.
    pub key: String,
    pub message: String,
    /// What the user probably meant, such as a key name for a misspelt key.
    pub suggestion: Option<String>,
}

impl fmt::Display for ConfigError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}:{}: {}", self.line, self.column, self.message)?;
        if let Some(suggestion) = &self.suggestion {
            write!(f, " (did you mean `{suggestion}`?)")?;
        }
        Ok(())
    }
}

/// Why the file could not be read at all, as opposed to read and found wanting.
#[derive(Debug)]
pub enum LoadError {
    NoConfigDir,
    Read { path: PathBuf, source: io::Error },
}

impl fmt::Display for LoadError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            LoadError::NoConfigDir => {
                write!(
                    f,
                    "cannot find common.toml: neither XDG_CONFIG_HOME nor HOME is set"
                )
            }
            LoadError::Read { path, source } => {
                write!(f, "cannot read {}: {source}", path.display())
            }
        }
    }
}

impl std::error::Error for LoadError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            LoadError::NoConfigDir => None,
            LoadError::Read { source, .. } => Some(source),
        }
    }
}

/// Where `common.toml` lives: `$XDG_CONFIG_HOME/common/common.toml`, else
/// `$HOME/.config/common/common.toml`. The variables are parameters so callers and tests decide
/// where they come from. A relative or empty `XDG_CONFIG_HOME` is ignored, as the XDG base
/// directory specification requires.
pub fn default_path(xdg_config_home: Option<&OsStr>, home: Option<&OsStr>) -> Option<PathBuf> {
    let xdg = xdg_config_home
        .map(Path::new)
        .filter(|dir| dir.is_absolute());
    let base = match xdg {
        Some(dir) => dir.to_path_buf(),
        None => Path::new(home.filter(|dir| !dir.is_empty())?).join(".config"),
    };
    Some(base.join("common").join("common.toml"))
}

/// Loads `common.toml` from [`default_path`], reading the variables from the environment.
pub fn load() -> Result<(Config, Vec<ConfigError>), LoadError> {
    let xdg = std::env::var_os("XDG_CONFIG_HOME");
    let home = std::env::var_os("HOME");
    let path = default_path(xdg.as_deref(), home.as_deref()).ok_or(LoadError::NoConfigDir)?;
    load_from(&path)
}

/// Loads the config at `path`. A missing file is not an error: it means every key has its
/// default.
pub fn load_from(path: &Path) -> Result<(Config, Vec<ConfigError>), LoadError> {
    match std::fs::read_to_string(path) {
        Ok(text) => Ok(parse(&text)),
        // Windows reports some paths that exist but cannot be read as a file, such as a
        // directory, as not found. Only a path that is really absent means "use the defaults".
        Err(err)
            if err.kind() == io::ErrorKind::NotFound && matches!(path.try_exists(), Ok(false)) =>
        {
            Ok((Config::default(), Vec::new()))
        }
        Err(source) => Err(LoadError::Read {
            path: path.to_path_buf(),
            source,
        }),
    }
}

/// Parses the text of a `common.toml`. The config is always usable: a key with an error keeps its
/// default. Errors are ordered by position in the file.
pub fn parse(text: &str) -> (Config, Vec<ConfigError>) {
    let mut config = Config::default();
    let (root, syntax) = DeTable::parse_recoverable(text);
    let mut check = Checker {
        text,
        errors: Vec::new(),
    };
    if !syntax.is_empty() {
        // The parser recovers well enough to find later syntax errors, but not well enough to
        // trust the values it recovered, so a file that is not valid TOML gives the defaults.
        for err in &syntax {
            let offset = err.span().map_or(0, |span| span.start);
            check.report(offset..offset, "", err.message().to_string(), None);
        }
        return (config, check.finish());
    }

    for (key, value) in root.get_ref() {
        let name: &str = key.get_ref();
        match name {
            "home" => {
                if let Some(url) = check.url("home", value) {
                    config.home = url.to_string();
                }
            }
            "theme" => {
                if let Some(theme) = check.choice("theme", value, &THEMES.map(|t| (t, t))) {
                    config.theme = theme.to_string();
                }
            }
            "theme_light" => {
                if let Some(theme) = check.choice("theme_light", value, &THEMES.map(|t| (t, t))) {
                    config.theme_light = theme.to_string();
                }
            }
            "accent" => {
                if let Some(accent) = check.colour("accent", value) {
                    config.accent = accent;
                }
            }
            "window" => check.section(key, value, &["start"], |check, name, value| {
                let options = [
                    ("windowed", WindowStart::Windowed),
                    ("fullscreen", WindowStart::Fullscreen),
                ];
                if let Some(start) = check.choice(name, value, &options) {
                    config.window.start = start;
                }
            }),
            "search" => check.section(key, value, &["engine"], |check, name, value| {
                if let Some(engine) = check.search_engine(name, value) {
                    config.search.engine = engine.to_string();
                }
            }),
            "keys" => check.section(key, value, &["mode"], |check, name, value| {
                if value.get_ref().as_str() == Some("vim") {
                    check.report(
                        value.span(),
                        name,
                        "vim keys arrive in v0.3; `keys.mode` can only be \"standard\" for now"
                            .to_string(),
                        None,
                    );
                } else if let Some(mode) =
                    check.choice(name, value, &[("standard", KeyMode::Standard)])
                {
                    config.keys.mode = mode;
                }
            }),
            "space" => check.report(
                key.span(),
                "space",
                "Spaces arrive in v0.2".to_string(),
                None,
            ),
            "workspace" => check.report(
                key.span(),
                "workspace",
                "[[workspace]] was renamed to [[space]], and Spaces arrive in v0.2".to_string(),
                Some("space"),
            ),
            _ => check.unknown("", key, &TOP_LEVEL),
        }
    }
    (config, check.finish())
}

/// The keys a misspelt top-level key is compared against. `space` is left out: suggesting it
/// would only lead to another error until v0.2.
const TOP_LEVEL: [&str; 7] = [
    "home",
    "theme",
    "theme_light",
    "accent",
    "window",
    "search",
    "keys",
];

type Key<'i> = Spanned<std::borrow::Cow<'i, str>>;
type Value<'i> = Spanned<DeValue<'i>>;

struct Checker<'t> {
    text: &'t str,
    errors: Vec<ConfigError>,
}

impl Checker<'_> {
    fn report(&mut self, span: Range<usize>, key: &str, message: String, suggestion: Option<&str>) {
        let (line, column) = position(self.text, span.start);
        self.errors.push(ConfigError {
            line,
            column,
            key: key.to_string(),
            message,
            suggestion: suggestion.map(str::to_string),
        });
    }

    fn finish(mut self) -> Vec<ConfigError> {
        // The document tree is ordered by key name, not by position; the file order reads better.
        self.errors.sort_by_key(|e| (e.line, e.column));
        self.errors
    }

    fn unknown(&mut self, section: &str, key: &Key<'_>, known: &[&str]) {
        let name: &str = key.get_ref();
        let (path, message) = if section.is_empty() {
            (name.to_string(), format!("unknown key `{name}`"))
        } else {
            (
                format!("{section}.{name}"),
                format!("unknown key `{name}` in [{section}]"),
            )
        };
        self.report(key.span(), &path, message, nearest(name, known));
    }

    /// Checks a table such as `[window]`, handing each known key to `apply` with its dotted path.
    fn section<'v>(
        &mut self,
        key: &Key<'_>,
        value: &'v Value<'v>,
        known: &[&str],
        mut apply: impl FnMut(&mut Self, &str, &'v Value<'v>),
    ) {
        let section: &str = key.get_ref();
        let Some(table) = value.get_ref().as_table() else {
            let message = format!(
                "`{section}` must be a table, written [{section}], not {}",
                describe(value.get_ref())
            );
            self.report(value.span(), section, message, None);
            return;
        };
        for (key, value) in table {
            let name: &str = key.get_ref();
            if known.contains(&name) {
                apply(self, &format!("{section}.{name}"), value);
            } else {
                self.unknown(section, key, known);
            }
        }
    }

    fn string<'v>(&mut self, path: &str, value: &'v Value<'_>) -> Option<&'v str> {
        let found = value.get_ref().as_str();
        if found.is_none() {
            let message = format!(
                "`{path}` must be a string, not {}",
                describe(value.get_ref())
            );
            self.report(value.span(), path, message, None);
        }
        found
    }

    fn choice<T: Copy>(
        &mut self,
        path: &str,
        value: &Value<'_>,
        options: &[(&str, T)],
    ) -> Option<T> {
        let found = self.string(path, value)?;
        if let Some((_, option)) = options.iter().find(|(name, _)| *name == found) {
            return Some(*option);
        }
        let names: Vec<&str> = options.iter().map(|(name, _)| *name).collect();
        let listed = names
            .iter()
            .map(|name| format!("\"{name}\""))
            .collect::<Vec<_>>()
            .join(", ");
        let message = format!("`{path}` must be one of {listed}, not {found:?}");
        self.report(value.span(), path, message, nearest(found, &names));
        None
    }

    fn url<'v>(&mut self, path: &str, value: &'v Value<'_>) -> Option<&'v str> {
        let found = self.string(path, value)?;
        if has_scheme(found) {
            return Some(found);
        }
        let message = format!(
            "`{path}` must be a URL with a scheme, like \"https://example.com\", not {found:?}"
        );
        self.report(value.span(), path, message, None);
        None
    }

    fn search_engine<'v>(&mut self, path: &str, value: &'v Value<'_>) -> Option<&'v str> {
        let found = self.string(path, value)?;
        if !found.contains("%s") {
            let message = format!(
                "`{path}` must contain %s where the search terms go, like \"https://duckduckgo.com/?q=%s\""
            );
            self.report(value.span(), path, message, None);
            return None;
        }
        self.url(path, value)
    }

    fn colour(&mut self, path: &str, value: &Value<'_>) -> Option<Rgb> {
        let found = self.string(path, value)?;
        let parsed = parse_hex(found);
        if parsed.is_none() {
            let message = format!("`{path}` must be a hex colour like \"#d9895b\", not {found:?}");
            self.report(value.span(), path, message, None);
        }
        parsed
    }
}

fn describe(value: &DeValue<'_>) -> &'static str {
    match value {
        DeValue::String(_) => "a string",
        DeValue::Integer(_) => "an integer",
        DeValue::Float(_) => "a float",
        DeValue::Boolean(_) => "a boolean",
        DeValue::Datetime(_) => "a date",
        DeValue::Array(_) => "an array",
        DeValue::Table(_) => "a table",
    }
}

fn parse_hex(text: &str) -> Option<Rgb> {
    let hex = text.strip_prefix('#')?;
    if hex.len() != 6 || !hex.bytes().all(|b| b.is_ascii_hexdigit()) {
        return None;
    }
    let channel = |i: usize| u8::from_str_radix(&hex[i..i + 2], 16).ok();
    Some(Rgb {
        r: channel(0)?,
        g: channel(2)?,
        b: channel(4)?,
    })
}

/// Whether `text` starts with a URL scheme (RFC 3986: a letter, then letters, digits, `+`, `-` or
/// `.`, then `:`). Enough to catch `example.com` written without `https://`.
fn has_scheme(text: &str) -> bool {
    let Some((scheme, _)) = text.split_once(':') else {
        return false;
    };
    let mut chars = scheme.chars();
    chars.next().is_some_and(|c| c.is_ascii_alphabetic())
        && chars.all(|c| c.is_ascii_alphanumeric() || matches!(c, '+' | '-' | '.'))
}

/// The candidate closest to `word`, if it is close enough to be a plausible typo: within two edits,
/// or a third of the word's length for longer words.
fn nearest<'c>(word: &str, candidates: &[&'c str]) -> Option<&'c str> {
    let word = word.to_lowercase();
    let (best, distance) = candidates
        .iter()
        .map(|c| (*c, edit_distance(&word, &c.to_lowercase())))
        .min_by_key(|(_, d)| *d)?;
    let limit = 2.max(word.chars().count() / 3);
    (distance <= limit).then_some(best)
}

/// Levenshtein distance over characters.
fn edit_distance(a: &str, b: &str) -> usize {
    let b: Vec<char> = b.chars().collect();
    let mut row: Vec<usize> = (0..=b.len()).collect();
    for (i, ca) in a.chars().enumerate() {
        let mut diagonal = row[0];
        row[0] = i + 1;
        for (j, cb) in b.iter().enumerate() {
            let substitute = diagonal + usize::from(ca != *cb);
            diagonal = row[j + 1];
            row[j + 1] = substitute.min(row[j] + 1).min(diagonal + 1);
        }
    }
    row[b.len()]
}

/// The 1-based line and column of a byte offset. Columns count characters, so a multi-byte
/// character earlier on the line moves the column by one, as it does in an editor.
fn position(text: &str, offset: usize) -> (usize, usize) {
    let before = &text[..text.floor_char_boundary(offset)];
    let line_start = before.rfind('\n').map_or(0, |i| i + 1);
    let line = before.matches('\n').count() + 1;
    let column = before[line_start..].chars().count() + 1;
    (line, column)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn errors(text: &str) -> Vec<ConfigError> {
        parse(text).1
    }

    fn only_error(text: &str) -> ConfigError {
        let mut errors = errors(text);
        assert_eq!(errors.len(), 1, "{errors:#?}");
        errors.remove(0)
    }

    #[test]
    fn an_empty_file_is_the_defaults() {
        assert_eq!(parse(""), (Config::default(), Vec::new()));
    }

    #[test]
    fn defaults_are_the_documented_values() {
        let config = Config::default();
        assert_eq!(config.home, "about:blank");
        assert_eq!(config.theme, "graphite");
        assert_eq!(config.theme_light, "paper");
        assert_eq!(parse_hex("#d9895b"), Some(config.accent));
        assert_eq!(config.window.start, WindowStart::Windowed);
        assert_eq!(config.search.engine, "https://duckduckgo.com/?q=%s");
        assert_eq!(config.keys.mode, KeyMode::Standard);
    }

    #[test]
    fn every_key_is_read() {
        let text = r##"
home = "https://example.com"
theme = "paper"
theme_light = "graphite"
accent = "#1A2b3c"

[window]
start = "fullscreen"

[search]
engine = "https://example.com/search?q=%s"

[keys]
mode = "standard"
"##;
        let (config, errors) = parse(text);
        assert_eq!(errors, Vec::new());
        assert_eq!(
            config,
            Config {
                home: "https://example.com".to_string(),
                theme: "paper".to_string(),
                theme_light: "graphite".to_string(),
                accent: Rgb {
                    r: 0x1a,
                    g: 0x2b,
                    b: 0x3c
                },
                window: Window {
                    start: WindowStart::Fullscreen
                },
                search: Search {
                    engine: "https://example.com/search?q=%s".to_string()
                },
                keys: Keys {
                    mode: KeyMode::Standard
                },
            }
        );
    }

    #[test]
    fn inline_tables_and_dotted_keys_are_the_same_as_sections() {
        let text =
            "window = { start = \"fullscreen\" }\nsearch.engine = \"https://a.example/?q=%s\"\n";
        let (config, errors) = parse(text);
        assert_eq!(errors, Vec::new());
        assert_eq!(config.window.start, WindowStart::Fullscreen);
        assert_eq!(config.search.engine, "https://a.example/?q=%s");
    }

    #[test]
    fn an_unknown_key_is_located_and_the_nearest_key_suggested() {
        let error = only_error("home = \"about:blank\"\n  thme = \"paper\"\n");
        assert_eq!((error.line, error.column), (2, 3));
        assert_eq!(error.key, "thme");
        assert_eq!(error.suggestion.as_deref(), Some("theme"));
        assert_eq!(
            error.to_string(),
            "2:3: unknown key `thme` (did you mean `theme`?)"
        );
    }

    #[test]
    fn an_unknown_key_in_a_section_is_compared_with_that_section() {
        let error = only_error("[search]\nengin = \"https://a.example/?q=%s\"\n");
        assert_eq!((error.line, error.column), (2, 1));
        assert_eq!(error.key, "search.engin");
        assert_eq!(error.message, "unknown key `engin` in [search]");
        assert_eq!(error.suggestion.as_deref(), Some("engine"));
    }

    #[test]
    fn a_key_unlike_any_known_key_gets_no_suggestion() {
        let error = only_error("wallpaper = \"stars.png\"\n");
        assert_eq!(error.suggestion, None);
        assert_eq!(error.to_string(), "1:1: unknown key `wallpaper`");
    }

    #[test]
    fn a_wrong_type_names_the_expected_type_and_the_line() {
        let (config, errors) = parse("\ntheme = 3\n");
        assert_eq!(config.theme, "graphite");
        assert_eq!(errors.len(), 1);
        assert_eq!(
            errors[0].to_string(),
            "2:9: `theme` must be a string, not an integer"
        );
        assert_eq!(errors[0].key, "theme");
    }

    #[test]
    fn a_section_written_as_a_value_names_the_table_it_must_be() {
        let error = only_error("window = \"fullscreen\"\n");
        assert_eq!(
            error.to_string(),
            "1:10: `window` must be a table, written [window], not a string"
        );
    }

    #[test]
    fn several_errors_are_all_reported_in_file_order() {
        let text = "\
thme = \"paper\"
accent = \"orange\"

[window]
start = \"fullscren\"

[search]
engine = \"https://duckduckgo.com/\"
";
        let (config, errors) = parse(text);
        assert_eq!(config, Config::default());
        let lines: Vec<String> = errors.iter().map(ToString::to_string).collect();
        assert_eq!(
            lines,
            [
                "1:1: unknown key `thme` (did you mean `theme`?)",
                "2:10: `accent` must be a hex colour like \"#d9895b\", not \"orange\"",
                "5:9: `window.start` must be one of \"windowed\", \"fullscreen\", not \"fullscren\" \
                 (did you mean `fullscreen`?)",
                "8:10: `search.engine` must contain %s where the search terms go, like \
                 \"https://duckduckgo.com/?q=%s\"",
            ]
        );
    }

    #[test]
    fn a_broken_key_keeps_its_default_and_the_rest_still_apply() {
        let (config, errors) = parse("theme = \"paper\"\naccent = \"#12345\"\n");
        assert_eq!(errors.len(), 1);
        assert_eq!(errors[0].key, "accent");
        assert_eq!(config.theme, "paper");
        assert_eq!(config.accent, Config::default().accent);
    }

    #[test]
    fn a_search_engine_without_a_placeholder_says_so() {
        let error = only_error("[search]\nengine = \"https://duckduckgo.com/\"\n");
        assert_eq!(error.key, "search.engine");
        assert!(
            error.message.contains("must contain %s"),
            "{}",
            error.message
        );
    }

    #[test]
    fn urls_need_a_scheme() {
        let error = only_error("home = \"example.com\"\n");
        assert_eq!(
            error.message,
            "`home` must be a URL with a scheme, like \"https://example.com\", not \"example.com\""
        );
        let error = only_error("[search]\nengine = \"duckduckgo.com/?q=%s\"\n");
        assert_eq!(error.key, "search.engine");
        assert!(error.message.contains("with a scheme"), "{}", error.message);
    }

    #[test]
    fn an_unknown_theme_lists_the_themes() {
        let error = only_error("theme_light = \"papr\"\n");
        assert_eq!(
            error.to_string(),
            "1:15: `theme_light` must be one of \"graphite\", \"paper\", not \"papr\" \
             (did you mean `paper`?)"
        );
    }

    #[test]
    fn vim_keys_are_promised_for_a_later_release() {
        let (config, errors) = parse("[keys]\nmode = \"vim\"\n");
        assert_eq!(config.keys.mode, KeyMode::Standard);
        assert_eq!(errors.len(), 1);
        assert_eq!(errors[0].key, "keys.mode");
        assert_eq!((errors[0].line, errors[0].column), (2, 8));
        assert!(
            errors[0].message.starts_with("vim keys arrive in v0.3"),
            "{}",
            errors[0].message
        );
    }

    #[test]
    fn spaces_are_promised_for_a_later_release() {
        let error = only_error("theme = \"paper\"\n\n[[space]]\nname = \"Work\"\n");
        assert_eq!(error.to_string(), "3:3: Spaces arrive in v0.2");
        assert_eq!(error.key, "space");
    }

    #[test]
    fn workspace_points_to_its_new_name() {
        let error = only_error("[[workspace]]\nname = \"Work\"\n");
        assert_eq!(error.key, "workspace");
        assert_eq!(error.suggestion.as_deref(), Some("space"));
        assert_eq!(
            error.to_string(),
            "1:3: [[workspace]] was renamed to [[space]], and Spaces arrive in v0.2 \
             (did you mean `space`?)"
        );
    }

    #[test]
    fn a_syntax_error_is_located_and_gives_the_defaults() {
        let (config, errors) = parse("theme = \"paper\"\naccent = #d9895b\n");
        assert_eq!(config, Config::default());
        assert!(!errors.is_empty());
        assert_eq!((errors[0].line, errors[0].column), (2, 10));
        assert_eq!(errors[0].key, "");
    }

    #[test]
    fn positions_are_one_based_and_count_characters() {
        let text = "ab\nçé = 1\r\nx";
        assert_eq!(position(text, 0), (1, 1));
        assert_eq!(position(text, 2), (1, 3));
        assert_eq!(position(text, 3), (2, 1));
        // `ç` and `é` are two bytes each.
        assert_eq!(position(text, 8), (2, 4));
        assert_eq!(position(text, text.len() - 1), (3, 1));
        // An offset inside a character belongs to that character.
        assert_eq!(position(text, 4), (2, 1));
        assert_eq!(position(text, 99), (3, 2));
    }

    #[test]
    fn suggestions_only_come_from_close_matches() {
        assert_eq!(nearest("THME", &TOP_LEVEL), Some("theme"));
        assert_eq!(nearest("accnt", &TOP_LEVEL), Some("accent"));
        assert_eq!(nearest("colour", &TOP_LEVEL), None);
        assert_eq!(nearest("x", &[]), None);
        assert_eq!(edit_distance("kitten", "sitting"), 3);
        assert_eq!(edit_distance("", "abc"), 3);
    }

    /// An absolute directory on every platform: `/xdg` is not absolute on Windows.
    fn absolute(name: &str) -> PathBuf {
        std::env::temp_dir().join(name)
    }

    #[test]
    fn the_path_prefers_an_absolute_xdg_config_home() {
        let (xdg, home) = (absolute("xdg"), absolute("home"));
        let path = default_path(Some(xdg.as_os_str()), Some(home.as_os_str()));
        assert_eq!(path, Some(xdg.join("common").join("common.toml")));
    }

    #[test]
    fn the_path_falls_back_to_home() {
        let home = absolute("home");
        let expected = Some(home.join(".config").join("common").join("common.toml"));
        let home = Some(home.as_os_str());
        assert_eq!(default_path(None, home), expected);
        assert_eq!(default_path(Some(OsStr::new("")), home), expected);
        assert_eq!(default_path(Some(OsStr::new("relative")), home), expected);
    }

    #[test]
    fn without_either_variable_there_is_no_path() {
        assert_eq!(default_path(None, None), None);
        assert_eq!(default_path(None, Some(OsStr::new(""))), None);
    }

    #[test]
    fn a_missing_file_gives_the_defaults_without_errors() {
        let path = std::env::temp_dir()
            .join("common-config-test-missing")
            .join("common.toml");
        let (config, errors) = load_from(&path).expect("a missing file is not an error");
        assert_eq!(config, Config::default());
        assert_eq!(errors, Vec::new());
    }

    #[test]
    fn an_existing_file_is_parsed() {
        let dir = std::env::temp_dir().join(format!("common-config-test-{}", std::process::id()));
        std::fs::create_dir_all(&dir).expect("create a temporary directory");
        let path = dir.join("common.toml");
        std::fs::write(&path, "theme = \"paper\"\n").expect("write the config");
        let loaded = load_from(&path);
        std::fs::remove_dir_all(&dir).expect("remove the temporary directory");
        let (config, errors) = loaded.expect("a readable file loads");
        assert_eq!(config.theme, "paper");
        assert_eq!(errors, Vec::new());
    }

    #[test]
    fn an_unreadable_file_is_an_error_naming_the_path() {
        // A directory exists but cannot be read as a file.
        let dir = std::env::temp_dir();
        let err = load_from(&dir).expect_err("a directory is not a config file");
        assert!(matches!(err, LoadError::Read { .. }));
        assert!(
            err.to_string().contains(&dir.display().to_string()),
            "{err}"
        );
    }
}
