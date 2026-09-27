uniffi::setup_scaffolding!();

/// The version of the core the app was built with.
#[uniffi::export]
pub fn core_version() -> String {
    common_core::VERSION.to_string()
}
