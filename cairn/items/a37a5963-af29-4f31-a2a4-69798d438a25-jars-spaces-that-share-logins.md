---
id: a37a5963-af29-4f31-a2a4-69798d438a25
title: 'Jars: Spaces that share logins'
type: feature
status: backlog
milestone: v0.2
depends_on:
- 6e0024ef-d6c2-4c49-9556-9393a170726e
- d865dd06-3b60-4b24-919b-ba95bc7f2168
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: m
area: spaces
---

## Problem

Two Spaces for the same client should share one set of logins without sharing history.

## Proposal

`jar = "work"` on a Space maps to a data store identifier derived from the jar name (UUID v5), so
every Space with that jar shares cookies and storage. Spaces without a jar get their own store.

## Acceptance criteria

- [ ] Two Spaces with `jar = "work"` share a login, and a third without it does not.
- [ ] Deleting the last Space in a jar asks before deleting the jar's data.
