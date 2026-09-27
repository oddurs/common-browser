use std::fmt;
use std::path::Path;
use std::sync::{Arc, Mutex, PoisonError};

use common_core::config::{self, Config, ConfigError};
use common_core::pages::{PageId, Pages};

uniffi::setup_scaffolding!();

/// The version of the core the app was built with.
#[uniffi::export]
pub fn core_version() -> String {
    common_core::VERSION.to_string()
}

/// The name to save a download under in a directory holding `taken`: `name.ext`, else
/// `name 2.ext`, and so on.
#[uniffi::export]
pub fn unique_download_name(suggested: String, taken: Vec<String>) -> String {
    common_core::downloads::unique_file_name(&suggested, taken.iter().map(String::as_str))
}

/// A window's pages, shared with Swift as a reference type. UniFFI objects must be `Sync`, hence
/// the mutex; Swift calls these from the main thread only, so it is never contended.
#[derive(uniffi::Object, Default)]
pub struct PageList(Mutex<Pages>);

/// A page's place in its window, counting from 1: "2 of 5".
#[derive(uniffi::Record)]
pub struct PagePosition {
    pub index: u32,
    pub count: u32,
}

#[uniffi::export]
impl PageList {
    #[uniffi::constructor]
    pub fn new() -> Arc<Self> {
        Arc::default()
    }

    pub fn open(&self) -> PageId {
        self.pages().open()
    }

    pub fn open_after(&self, opener: PageId) -> PageId {
        self.pages().open_after(opener)
    }

    pub fn close(&self, id: PageId) -> Option<PageId> {
        self.pages().close(id)
    }

    pub fn select(&self, id: PageId) -> bool {
        self.pages().select(id)
    }

    pub fn show_next(&self) -> Option<PageId> {
        self.pages().show_next()
    }

    pub fn show_previous(&self) -> Option<PageId> {
        self.pages().show_previous()
    }

    pub fn current(&self) -> Option<PageId> {
        self.pages().current()
    }

    pub fn ids(&self) -> Vec<PageId> {
        self.pages().ids().to_vec()
    }

    pub fn position(&self) -> Option<PagePosition> {
        self.pages().position().map(|(index, count)| PagePosition {
            // A window never holds four billion pages.
            index: index as u32,
            count: count as u32,
        })
    }
}

impl PageList {
    fn pages(&self) -> std::sync::MutexGuard<'_, Pages> {
        // A panic while holding the lock cannot leave `Pages` half-updated in a way that matters
        // more than losing the window, so keep going with what is there.
        self.0.lock().unwrap_or_else(PoisonError::into_inner)
    }
}

/// The settings a shell applies, flattened for Swift. Every field is always valid: a key with an
/// error keeps its default.
#[derive(uniffi::Record)]
pub struct Settings {
    pub home: String,
    pub theme: String,
    pub theme_light: String,
    /// `#rrggbb`.
    pub accent: String,
    pub start_full_screen: bool,
    /// A URL template in which `%s` stands for the search terms.
    pub search_engine: String,
}

impl From<Config> for Settings {
    fn from(config: Config) -> Self {
        let rgb = config.accent;
        Settings {
            home: config.home,
            theme: config.theme,
            theme_light: config.theme_light,
            accent: format!("#{:02x}{:02x}{:02x}", rgb.r, rgb.g, rgb.b),
            start_full_screen: config.window.start == config::WindowStart::Fullscreen,
            search_engine: config.search.engine,
        }
    }
}

/// One mistake in the file, with `summary` already worded the way `common config check` prints it.
#[derive(uniffi::Record)]
pub struct ConfigProblem {
    pub line: u32,
    pub column: u32,
    pub key: String,
    pub summary: String,
}

impl From<ConfigError> for ConfigProblem {
    fn from(error: ConfigError) -> Self {
        ConfigProblem {
            // A file with four billion lines is not a config file.
            line: error.line as u32,
            column: error.column as u32,
            summary: error.to_string(),
            key: error.key,
        }
    }
}

/// What a shell needs at launch: the settings, what was wrong with the file, and where it is.
#[derive(uniffi::Record)]
pub struct LoadedConfig {
    /// `None` when neither `XDG_CONFIG_HOME` nor `HOME` says where the file would be.
    pub path: Option<String>,
    pub settings: Settings,
    pub problems: Vec<ConfigProblem>,
    /// Set when the file exists but could not be read at all; the settings are then the defaults.
    pub unreadable: Option<String>,
}

/// Loads `common.toml` from its usual place.
#[uniffi::export]
pub fn load_config() -> LoadedConfig {
    match config::env_path() {
        Some(path) => load_config_from(path.display().to_string()),
        None => LoadedConfig {
            path: None,
            settings: Config::default().into(),
            problems: Vec::new(),
            unreadable: Some(config::LoadError::NoConfigDir.to_string()),
        },
    }
}

/// Loads the config at `path`.
#[uniffi::export]
pub fn load_config_from(path: String) -> LoadedConfig {
    let (settings, problems, unreadable) = match config::load_from(Path::new(&path)) {
        Ok((config, errors)) => (config, errors, None),
        Err(err) => (Config::default(), Vec::new(), Some(err.to_string())),
    };
    LoadedConfig {
        path: Some(path),
        settings: settings.into(),
        problems: problems.into_iter().map(ConfigProblem::from).collect(),
        unreadable,
    }
}

/// Why the config file could not be created.
#[derive(Debug, uniffi::Error)]
#[uniffi(flat_error)]
pub enum ConfigFileError {
    NoConfigDir,
    Io(String),
}

impl fmt::Display for ConfigFileError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ConfigFileError::NoConfigDir => {
                f.write_str(&config::LoadError::NoConfigDir.to_string())
            }
            ConfigFileError::Io(message) => f.write_str(message),
        }
    }
}

/// Makes sure `common.toml` exists, writing the commented template if not, and returns its path.
#[uniffi::export]
pub fn ensure_config_file() -> Result<String, ConfigFileError> {
    let path = config::env_path().ok_or(ConfigFileError::NoConfigDir)?;
    config::create_if_missing(&path)
        .map_err(|err| ConfigFileError::Io(format!("cannot create {}: {err}", path.display())))?;
    Ok(path.display().to_string())
}
