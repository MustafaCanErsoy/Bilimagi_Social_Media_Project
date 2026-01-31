# Demo Plan (presentation-ready)

## Goal
Show a working MVP product flow with multiple users:
- live voting updates across clients
- admin phase switch to open discussion
- live comments during discussion
- show that different communities can have different weekly agendas

## Setup
- Use 2 Android emulators (or emulator + web/phone) to simulate two users.
- Use pre-created demo accounts (email/password).
- Use seeded communities and seeded article lists.

## Demo Flow (10–12 minutes)
1) Login as a **jury/viewer** account -> show Community list (min 2).
2) Open **Community A** -> show phase is `voting` and the weekly article list.
3) Switch to **Member 1** (Client A) -> cast a vote.
4) Switch to **Member 2** (Client B) -> cast a vote for a different item.
5) Show **realtime** results updating across both clients.
6) Login as **Admin** -> switch phase to `discussion`.
7) Back to **jury/viewer** -> open the winning article -> post a comment.
8) Show comment appears **realtime** on the other client.
9) (Optional) Open **Community B** briefly to show a different weekly list/outcome.

## Notes
- “Time travel” is done only by **admin phase switch**, never by changing device time.
- Prefer **1 winning article** per community/week to keep the demo focused.
