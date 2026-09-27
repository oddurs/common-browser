//! Platform-independent core of Common Browser. Every platform shell and the `common` CLI link
//! this crate, so nothing in it may depend on a UI toolkit or a web engine.

/// The version reported by every shell and by the CLI.
pub const VERSION: &str = env!("CARGO_PKG_VERSION");
