# UI Standard (MVP)

## Style
- Minimal, modern, calm. One accent color. No visual clutter.
- Consistent spacing: 16 (small), 24 (section), 32 (large).
- Cards for communities and articles. Rounded corners. Clear hierarchy.

## Screens (must exist)
- Login
- Community Select
- Week (phase + article list + voting/results)
- Discussion (winning article + comments)
- Admin (phase switch)

## UX rules
- Phase is always visible on the Week screen.
- Disable actions that are not allowed in the current phase:
  - no voting outside `voting`
  - no commenting outside `discussion`
- Realtime updates must be noticeable (results and comments update without refresh).
- Responsive: no overflow when keyboard opens on Login/Comment input.
