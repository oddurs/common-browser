---
id: 6e0024ef-d6c2-4c49-9556-9393a170726e
title: 'Spike: per-Space website data stores'
type: spike
status: backlog
milestone: v0.2
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: s
area: privacy
---

## Question

`WKWebsiteDataStore(forIdentifier:)` (macOS 14) gives each Space its own persistent store. Check
four things:

- Does it isolate cookies, localStorage, IndexedDB, service workers, cache and credentials?
- Can a store be deleted with `remove(forIdentifier:)` while no web view uses it?
- What do ten stores cost in memory and processes?
- Do two web views on the same identifier share a login immediately?

## Timebox

One day, with a throwaway app that signs into the same site in two stores.

## Answer

## Follow-up items
