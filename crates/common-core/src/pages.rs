//! The pages in a window: their order, which one is visible, and what closing one shows next.
//! There are no tabs, so this order is the only structure the user sees; every shell must behave
//! the same way, which is why it lives here rather than in a shell.

use std::collections::HashMap;

/// Identifies a page for as long as the process runs. Never reused, so a stale id cannot select
/// the wrong page.
pub type PageId = u64;

#[derive(Clone, Debug, Default)]
pub struct Pages {
    order: Vec<PageId>,
    current: Option<usize>,
    last_id: PageId,
    /// Which page opened which, for pages opened by another (a link to a new window, a pop-up).
    openers: HashMap<PageId, PageId>,
}

impl Pages {
    pub fn new() -> Self {
        Self::default()
    }

    /// Adds a page at the end and makes it the visible one.
    pub fn open(&mut self) -> PageId {
        self.insert(self.order.len())
    }

    /// Adds a page that `opener` opened, right after it, and makes it the visible one, so a
    /// pop-up sits beside the page it belongs to. An unknown opener opens the page at the end.
    pub fn open_after(&mut self, opener: PageId) -> PageId {
        let Some(index) = self.index(opener) else {
            return self.open();
        };
        let id = self.insert(index + 1);
        self.openers.insert(id, opener);
        id
    }

    /// Removes a page and returns the page now visible. Closing the visible page shows the page
    /// that opened it if that is still open, as a finished sign-in pop-up returns to its site;
    /// otherwise its right-hand neighbour, or its left-hand one if it was last, so the eye stays
    /// where it was. `None` means no pages are left; what happens then is the shell's decision.
    pub fn close(&mut self, id: PageId) -> Option<PageId> {
        let Some(index) = self.index(id) else {
            return self.current();
        };
        let opener = self.openers.remove(&id);
        self.openers.retain(|_, &mut opener| opener != id);
        self.order.remove(index);
        self.current = match self.current {
            _ if self.order.is_empty() => None,
            Some(current) if current == index => opener
                .and_then(|opener| self.index(opener))
                .or(Some(index.min(self.order.len() - 1))),
            Some(current) if current > index => Some(current - 1),
            other => other,
        };
        self.current()
    }

    /// Makes `id` the visible page. Returns false, changing nothing, if there is no such page.
    pub fn select(&mut self, id: PageId) -> bool {
        match self.index(id) {
            Some(index) => {
                self.current = Some(index);
                true
            }
            None => false,
        }
    }

    /// Shows the page to the right, wrapping to the first.
    pub fn show_next(&mut self) -> Option<PageId> {
        self.step(1)
    }

    /// Shows the page to the left, wrapping to the last.
    pub fn show_previous(&mut self) -> Option<PageId> {
        self.step(self.order.len().saturating_sub(1))
    }

    pub fn current(&self) -> Option<PageId> {
        self.current.map(|index| self.order[index])
    }

    pub fn ids(&self) -> &[PageId] {
        &self.order
    }

    /// The visible page's place as (position, count), counting from 1: "2 of 5".
    pub fn position(&self) -> Option<(usize, usize)> {
        self.current.map(|index| (index + 1, self.order.len()))
    }

    fn insert(&mut self, index: usize) -> PageId {
        self.last_id += 1;
        self.order.insert(index, self.last_id);
        self.current = Some(index);
        self.last_id
    }

    fn step(&mut self, by: usize) -> Option<PageId> {
        let current = self.current?;
        self.current = Some((current + by) % self.order.len());
        self.current()
    }

    fn index(&self, id: PageId) -> Option<usize> {
        self.order.iter().position(|&page| page == id)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn with(count: usize) -> (Pages, Vec<PageId>) {
        let mut pages = Pages::new();
        let ids = (0..count).map(|_| pages.open()).collect();
        (pages, ids)
    }

    #[test]
    fn a_new_list_has_no_visible_page() {
        let pages = Pages::new();
        assert_eq!(pages.current(), None);
        assert_eq!(pages.position(), None);
    }

    #[test]
    fn opening_appends_and_shows_the_new_page() {
        let (mut pages, ids) = with(2);
        pages.select(ids[0]);
        let third = pages.open();
        assert_eq!(pages.ids(), &[ids[0], ids[1], third]);
        assert_eq!(pages.current(), Some(third));
        assert_eq!(pages.position(), Some((3, 3)));
    }

    #[test]
    fn closing_the_visible_page_shows_its_right_neighbour() {
        let (mut pages, ids) = with(3);
        pages.select(ids[1]);
        assert_eq!(pages.close(ids[1]), Some(ids[2]));
        assert_eq!(pages.position(), Some((2, 2)));
    }

    #[test]
    fn closing_the_last_visible_page_shows_its_left_neighbour() {
        let (mut pages, ids) = with(3);
        assert_eq!(pages.close(ids[2]), Some(ids[1]));
    }

    #[test]
    fn closing_a_hidden_page_keeps_the_visible_one() {
        let (mut pages, ids) = with(3);
        pages.select(ids[2]);
        assert_eq!(pages.close(ids[0]), Some(ids[2]));
        assert_eq!(pages.position(), Some((2, 2)));
    }

    #[test]
    fn closing_the_only_page_leaves_none() {
        let (mut pages, ids) = with(1);
        assert_eq!(pages.close(ids[0]), None);
        assert!(pages.ids().is_empty());
    }

    #[test]
    fn closing_an_unknown_page_changes_nothing() {
        let (mut pages, ids) = with(2);
        assert_eq!(pages.close(99), Some(ids[1]));
        assert_eq!(pages.ids().len(), 2);
    }

    #[test]
    fn next_and_previous_wrap_around() {
        let (mut pages, ids) = with(3);
        assert_eq!(pages.show_next(), Some(ids[0]));
        assert_eq!(pages.show_previous(), Some(ids[2]));
        assert_eq!(pages.show_previous(), Some(ids[1]));
    }

    #[test]
    fn next_on_an_empty_list_is_none() {
        assert_eq!(Pages::new().show_next(), None);
        assert_eq!(Pages::new().show_previous(), None);
    }

    #[test]
    fn selecting_an_unknown_page_changes_nothing() {
        let (mut pages, ids) = with(2);
        assert!(!pages.select(42));
        assert_eq!(pages.current(), Some(ids[1]));
    }

    #[test]
    fn a_page_opened_by_another_goes_right_after_it_and_is_shown() {
        let (mut pages, ids) = with(3);
        let popup = pages.open_after(ids[0]);
        assert_eq!(pages.ids(), &[ids[0], popup, ids[1], ids[2]]);
        assert_eq!(pages.current(), Some(popup));
        assert_eq!(pages.position(), Some((2, 4)));
    }

    #[test]
    fn a_page_opened_by_an_unknown_page_goes_at_the_end() {
        let (mut pages, ids) = with(2);
        let popup = pages.open_after(99);
        assert_eq!(pages.ids(), &[ids[0], ids[1], popup]);
        assert_eq!(pages.current(), Some(popup));
    }

    #[test]
    fn closing_a_page_shows_the_page_that_opened_it() {
        let (mut pages, ids) = with(3);
        let popup = pages.open_after(ids[2]);
        pages.select(ids[0]);
        let second = pages.open_after(ids[2]);
        assert_eq!(pages.ids(), &[ids[0], ids[1], ids[2], second, popup]);
        // The opener is left of the closed page here, where the default would go right.
        assert_eq!(pages.close(second), Some(ids[2]));
        pages.select(popup);
        assert_eq!(pages.close(popup), Some(ids[2]));
    }

    #[test]
    fn closing_a_hidden_page_ignores_its_opener() {
        let (mut pages, ids) = with(3);
        let popup = pages.open_after(ids[0]);
        pages.select(ids[2]);
        assert_eq!(pages.close(popup), Some(ids[2]));
    }

    #[test]
    fn a_page_whose_opener_closed_falls_back_to_its_neighbour() {
        let (mut pages, ids) = with(3);
        let popup = pages.open_after(ids[0]);
        pages.close(ids[0]);
        pages.select(popup);
        assert_eq!(pages.close(popup), Some(ids[1]));
    }

    #[test]
    fn ids_are_never_reused() {
        let (mut pages, ids) = with(2);
        pages.close(ids[1]);
        assert!(!ids.contains(&pages.open()));
    }
}
