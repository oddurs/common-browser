use std::sync::{Arc, Mutex, PoisonError};

use common_core::pages::{PageId, Pages};

uniffi::setup_scaffolding!();

/// The version of the core the app was built with.
#[uniffi::export]
pub fn core_version() -> String {
    common_core::VERSION.to_string()
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
