---
id: 6d0f3caf-f4c6-424f-a859-1282d619a80b
title: 'Permission prompts: camera, microphone, location, notifications'
type: feature
status: backlog
milestone: v0.4
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: m
area: web
---

## Problem

Video calls and maps need permissions, and the answers must be remembered.

## Proposal

Handle WebKit's media-capture and geolocation delegate calls with a small native prompt anchored
to the page. Remember the answer per site per Space. A "Site permissions" launcher view lists them
and can revoke them.

## Acceptance criteria

- [ ] A video call site gets camera and microphone after one prompt, and the prompt does not recur on reload.
- [ ] Revoking takes effect on the next request.
