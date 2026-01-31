# Bilimagi - Scientific Social Discussion Platform

**Version:** 3.0 (Social Expansion Complete)
**Platform:** Flutter (Android, iOS, Web)
**Backend:** Firebase (Auth + Firestore)
**Status:** v3.0 Complete - All Features Tested

---

## What is Bilimagi?

Bilimagi is a **full-featured social platform** for scientific article discussions. Communities run weekly cycles where users vote on curated articles, then discuss the winning article with nested comments, @mentions, and social features.

### **Core Flow:**
1. **Voting Phase (Mon-Thu):** Users vote on 3-5 curated scientific articles
2. **Discussion Phase (Fri-Sun):** Community discusses the winning article with nested comments
3. **Closed Phase:** Week ends, content becomes read-only

**Demo Mode:** Admin can instantly switch phases for testing

---

## Features (v3.0)

### **Social Features (v3.0 NEW)**
- **User Following** - Follow/unfollow users, see follower counts
- **@Mentions** - Tag users in comments with autocomplete (@username)
- **Activity Feed** - Notifications for follows, mentions, replies, upvotes
- **Personalized Feed** - "Explore" and "Following" tabs on home screen
- **User Suggestions** - Discover new users to follow

### **Discussion Features (v2.0)**
- **Nested Comments** - Reddit-style threaded conversations (max depth: 5)
- **Upvote/Downvote** - Quality-driven content ranking
- **Comment Sorting** - Sort by Popular (score) or New (time)
- **Reply Threads** - Multi-level discussions with visual indentation
- **Realtime Updates** - All votes and comments sync live across clients

### **User Experience (v2.0)**
- **User Profiles** - Display name, bio, avatar, statistics
- **Bottom Navigation** - Modern 4-tab layout (Home, Communities, Notifications, Profile)
- **Home Feed** - Discover active discussions and voting weeks
- **Bookmarks** - Save articles for later reading
- **Material 3 Design** - Modern UI with Deep Purple + Teal color scheme

### **Core MVP (v1.0)**
- **Authentication** - Email/password login with demo accounts
- **Communities** - Pre-seeded communities (Physics, Biology)
- **Weekly Voting** - 1 vote per user, realtime results
- **Phase Management** - Admin can switch phases
- **Demo Data Seeding** - One-click demo data loading

---

## Architecture

### **Tech Stack**
- **Frontend:** Flutter 3.10.8+ (Dart)
- **Backend:** Firebase (Auth, Firestore)
- **State Management:** StatefulWidget + StreamBuilder
- **UI Framework:** Material 3

### **Project Structure**
```
bilimagi_app/lib/
├── main.dart              # Entry point + auth wrapper
├── core/
│   └── theme.dart         # Material 3 theme system
├── models/                # 5 data models
│   ├── user_profile.dart
│   ├── community.dart
│   ├── week.dart
│   ├── article.dart
│   └── comment_tree.dart
├── services/              # 9 services (business logic)
│   ├── auth_service.dart
│   ├── profile_service.dart
│   ├── week_service.dart
│   ├── vote_service.dart
│   ├── bookmark_service.dart
│   ├── follow_service.dart      # v3.0
│   ├── mention_service.dart     # v3.0
│   ├── notification_service.dart # v3.0
│   └── seed_service.dart
└── screens/               # 12 UI screens
    ├── login_screen.dart
    ├── main_navigation_screen.dart
    ├── home_feed_screen.dart
    ├── community_select_screen.dart
    ├── week_screen.dart
    ├── discussion_screen.dart
    ├── profile_screen.dart
    ├── profile_edit_screen.dart
    ├── saved_articles_screen.dart
    ├── activity_screen.dart      # v3.0
    ├── followers_screen.dart     # v3.0
    ├── following_screen.dart     # v3.0
    └── admin_screen.dart
```

**See:** [FILE_MAP.md](FILE_MAP.md) for detailed file-by-file breakdown

---

## Quick Start

### **Prerequisites**
- Flutter 3.10.8 or higher
- Firebase project configured (see `firebase_options.dart`)
- Android Studio / Xcode (for mobile builds)

### **Installation**
```bash
# Clone repository
git clone <repo-url>
cd bilimagi_app

# Install dependencies
flutter pub get

# Run on Chrome (fastest for development)
flutter run -d chrome

# Run on Android emulator
flutter emulators --launch Medium_Phone_API_36.1
flutter run -d emulator-5554
```

### **Load Demo Data**
1. Login with admin account:
   - Email: `admin@bilimagi.com`
   - Password: `admin123`
2. Navigate to Communities -> Admin icon (top-right)
3. Tap "Demo Verilerini Yukle"
4. Wait for success message

**Demo Accounts:** See [CLAUDE.md](CLAUDE.md) for credentials

---

## Demo Instructions

### **Multi-User Testing (2 Clients)**
1. **Client 1 (Chrome normal tab):**
   - Login as Ahmet (`ahmet@bilimagi.com` / `ahmet123`)
   - Go to Fizik Toplulugu
   - Cast vote on Article 1

2. **Client 2 (Chrome incognito tab):**
   - Login as Ayse (`ayse@bilimagi.com` / `ayse123`)
   - Go to Fizik Toplulugu
   - See realtime vote update from Client 1
   - Cast vote on Article 2

3. **Test Social Features (v3.0):**
   - Client 1: Follow Ayse from her profile
   - Client 2: See notification in Activity tab
   - Client 1: Post comment with @Ayse mention
   - Client 2: See mention notification
   - Both: Check "Takip" tab for personalized feed

---

## Definition of Done

### **v1.0 MVP (Complete)**
- Two users can login and vote in the same community
- Vote results update live on other client
- Admin switches to discussion -> UI transitions correctly
- Comments appear live on other client
- Data persists after app restart

### **v2.0 Social Media (Complete)**
- User profiles viewable and editable
- Nested comments (reply threads) working
- Upvote/downvote system functional
- Bottom navigation + home feed operational
- Bookmark system working

### **v3.0 Social Expansion (Complete)**
- User following system (follow/unfollow)
- Followers/following lists viewable
- @Mentions in comments (autocomplete + clickable)
- Activity feed with notifications (follow, mention, reply, upvote)
- Unread notification badge
- Personalized home feed with "Kesfel" and "Takip" tabs
- User suggestions for discovery

---

## Project Statistics (v3.0)

- **Total Files:** ~30 Dart files (~4,500 lines)
- **Services:** 9 (Auth, Profile, Week, Vote, Bookmark, Follow, Mention, Notification, Seed)
- **Screens:** 12 (Login, Nav, Home, Communities, Week, Discussion, Profile, Edit, Saved, Activity, Followers, Following, Admin)
- **Models:** 5 (UserProfile, Community, Week, Article, CommentTree)
- **Documentation:** 10+ MD files (~3,500+ lines)

**Code Quality:**
- `flutter analyze`: Warnings only, 0 errors
- Multi-user realtime verified
- All v3.0 features tested on Android emulator

---

## Documentation

### **For Developers:**
- **START_HERE.md** - Navigation guide (read first!)
- **FILE_MAP.md** - Complete file breakdown + AI navigation
- **ARCHITECTURE.md** - Service layer, data flows, ADRs
- **DATA_CONTRACT.md** - Firestore schema + data access map

### **For Project Management:**
- **STATUS.md** - Current progress tracker
- **CHANGELOG.md** - Version history
- **ROADMAP_V2.md** - v2.0 sprint plan (archive)
- **ROADMAP_V3.md** - v3.0 sprint plan (archive)

### **For AI Agents:**
- **CLAUDE.md** - Claude Code specific instructions
- **FILE_MAP.md** - "I need to change X" -> file finder
- **DATA_CONTRACT.md** - "Where is X data accessed?" -> service map

---

## Scope

### **In Scope (v3.0 Complete)**
- Weekly voting + discussion flow
- User profiles with stats
- User following system
- @Mentions with autocomplete
- Activity feed / notifications
- Nested comments (threaded discussions)
- Upvote/downvote system
- Home feed discovery (Explore + Following tabs)
- Bookmark system
- Admin phase management

### **Out of Scope (Future v4.0+)**
- Community creation by users
- Direct messages (DMs)
- Push notifications (FCM)
- Advanced moderation dashboard
- Full-text search (Algolia)
- Email notifications
- Dark mode

---

## Known Issues

- None critical (v3.0 tested and stable)
- Minor: Flutter analyze shows warnings (no errors)
- Large files: discussion_screen.dart and home_feed_screen.dart need refactoring

---

## Future Roadmap (v4.0+)

**High Priority:**
- Dark mode toggle
- Search functionality (articles + users + comments)
- Push notifications (new replies, mentions)
- Comment editing/deletion

**Medium Priority:**
- Report system
- Trending algorithm
- Weekly archives
- User blocking

**Low Priority:**
- Image uploads (profile pictures)
- Moderation dashboard
- Analytics dashboard

---

## Credits

**Development:**
- Built with Claude Opus 4.5 (AI pair programming)
- User: mqual (project owner)

**Tech Stack:**
- Flutter by Google
- Firebase by Google
- Material Design 3

---

## Links

- **Documentation:** [START_HERE.md](START_HERE.md)
- **Architecture:** [ARCHITECTURE.md](ARCHITECTURE.md)
- **File Map:** [FILE_MAP.md](FILE_MAP.md)
- **Status:** [STATUS.md](STATUS.md)

---

**Last Updated:** 2026-01-31 (v3.0 Complete - Merged to main)
