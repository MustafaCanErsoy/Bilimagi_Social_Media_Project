# Bilimagi — MVP

Bilimagi MVP is a Flutter (Dart) mobile app (Android/iOS) backed by Firebase (Auth + Firestore) where **pre-defined communities** run a weekly flow:
- **Voting (Mon–Thu):** users vote on a small curated list of scientific texts/articles.
- **Discussion (Fri–Sun):** the selected (winning) text is discussed via comments.
- **Closed:** the week ends.

For demos, **do not change device time**. Use an **admin phase switch**:
`voting -> discussion -> closed`.

## Definition of Done
- [x] Two different users can log in and vote in the same community.
- [x] Vote results update **live** on another client (verified: Chrome + Incognito).
- [x] Admin switches to `discussion` and the UI transitions correctly.
- [x] Comments can be posted and appear **live** on another client.
- [ ] Data remains after app restart.
- [ ] Android live demo + iOS run/build proof from the same codebase.

## Current Progress
- ✅ Demo data seeding (2 communities, 9 articles, 3 users)
- ✅ Multi-user voting with realtime updates
- ✅ Multi-user discussion with realtime comments
- ✅ Admin phase switching (voting → discussion → closed)
- ✅ **MVP Core Features: COMPLETE**
- ⏳ Platform deployment testing (Android/iOS) - next phase
