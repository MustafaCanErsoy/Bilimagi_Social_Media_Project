# Bilimagi — MVP

Bilimagi MVP is a Flutter (Dart) mobile app (Android/iOS) backed by Firebase (Auth + Firestore) where **pre-defined communities** run a weekly flow:
- **Voting (Mon–Thu):** users vote on a small curated list of scientific texts/articles.
- **Discussion (Fri–Sun):** the selected (winning) text is discussed via comments.
- **Closed:** the week ends.

For demos, **do not change device time**. Use an **admin phase switch**:
`voting -> discussion -> closed`.

## Definition of Done
- Two different users can log in and vote in the same community.
- Vote results update **live** on another client (e.g., second emulator).
- Admin switches to `discussion` and the UI transitions correctly.
- Comments can be posted and appear **live** on another client.
- Data remains after app restart.
- Android live demo + iOS run/build proof from the same codebase.
