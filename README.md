# Bilimagi - Scientific Social Discussion Platform

**Version:** 10.0 (Extended Features Complete)
**Platform:** Flutter (Android, iOS, Web)
**Backend:** Firebase (Auth + Firestore + Storage)
**Status:** v10.0 Complete - All Features Tested

---

## What is Bilimagi?

Bilimagi is a **full-featured social platform** for scientific article discussions. Communities run flexible periods where users vote on curated articles, then discuss the top-voted articles with nested comments, @mentions, and social features.

### **Core Flow:**
1. **Voting Phase:** Users vote on scientific articles (multiple votes allowed)
2. **Discussion Phase:** Top N articles (most voted) are discussed
3. **Closed Phase:** Period ends, content becomes read-only

**Demo Mode:** Admin can instantly switch phases for testing

---

## Features (v10.0)

### **Extended Features (v10.0 NEW)**
- **Top-N Article System** - The N most-voted articles open for discussion (default: 3)
- **Period Search** - Search periods and communities from the Explore tab
- **Activity Filters** - Filter by comments, votes, participations and suggestions
- **Activity Pagination** - "Load more" button
- **Badge System UI** - Badges displayed on the profile screen
- **Contribution Level UI** - Level card on the profile screen
- **Announcement System UI** - Announcement banner on the period screen
- **Poll System UI** - Active polls on the period screen
- **Article Detail Screen** - Hero image, markdown rendering, bookmarking, sharing
- **User Search** - Find users with debounced search
- **Notification Categories** - Social, community and suggestion filters

### **Community Features (v8.0-v9.0)**
- **Flexible Period System** - Admin-defined periods (not tied to calendar)
- **Multi-Vote System** - Vote for multiple articles
- **Phase Control** - Owner/Moderator can switch phases
- **Cover Photos** - Community cover images
- **Community Rules** - Editable rules page
- **Badge System** - 6 badge types (Kurucu, Aktif Uye, etc.)
- **Contribution Scores** - Points for activities
- **Announcements** - Pinned community announcements
- **Polls** - Community voting polls

### **Profile Features (v7.x)**
- **Profile Photos** - Upload/change profile pictures
- **Interests System** - Select interests from 35+ categories
- **Animated Login** - Gradient UI with animations
- **Welcome/Goodbye Screens** - Onboarding experience

### **Social Features (v3.0-v6.x)**
- **User Following** - Follow/unfollow users
- **@Mentions** - Tag users in comments with autocomplete
- **Activity Feed** - Notifications for follows, mentions, replies
- **Comment Reporting** - Report inappropriate comments
- **Moderation Dashboard** - Hide comments, ban users
- **Community Search** - Search and filter communities

### **Discussion Features (v2.0)**
- **Nested Comments** - Reddit-style threaded conversations
- **Upvote/Downvote** - Quality-driven content ranking
- **Comment Sorting** - Sort by Popular or New
- **Realtime Updates** - All votes and comments sync live

### **Core Features (v1.0)**
- **Authentication** - Email/password login
- **Communities** - User-created communities
- **Weekly Voting** - Multiple votes per user
- **Phase Management** - Admin/Owner phase control
- **Bookmarks** - Save articles for later

---

## Architecture

### **Tech Stack**
- **Frontend:** Flutter 3.10.8+ (Dart)
- **Backend:** Firebase (Auth, Firestore, Storage)
- **State Management:** StatefulWidget + StreamBuilder
- **UI Framework:** Material 3

### **Project Structure**
```
bilimagi_app/lib/
├── main.dart              # Entry point + auth wrapper
├── core/
│   ├── theme.dart         # Material 3 theme system
│   ├── theme_provider.dart # Dark/light mode
│   └── interest_categories.dart
├── models/                # 15+ data models
│   ├── period.dart        # Flexible period model
│   ├── user_profile.dart
│   ├── community.dart
│   ├── article.dart
│   ├── comment.dart
│   ├── user_badge.dart
│   ├── announcement.dart
│   └── poll.dart
├── services/              # 18+ services
│   ├── period_service.dart    # Period CRUD + voting
│   ├── community_service.dart
│   ├── badge_service.dart
│   ├── announcement_service.dart
│   ├── poll_service.dart
│   └── ...
├── widgets/               # 25+ reusable widgets
│   ├── badge_display.dart
│   ├── contribution_level_card.dart
│   ├── announcement_banner.dart
│   ├── poll_card.dart
│   └── ...
└── screens/               # 25+ screens
    ├── period_screen.dart
    ├── profile_screen.dart
    ├── article_detail_screen.dart  # v10.0 NEW
    ├── user_search_screen.dart     # v10.0 NEW
    └── ...
```

---

## Quick Start

### **Prerequisites**
- Flutter 3.10.8 or higher
- Your own Firebase project (see [Firebase Setup](#firebase-setup) below)

### **Installation**
```bash
# Clone repository
git clone https://github.com/MustafaCanErsoy/Bilimagi_Social_Media_Project.git
cd Bilimagi_Social_Media_Project/bilimagi_app

# Install dependencies
flutter pub get

# Configure Firebase (required — see below)
flutterfire configure

# Run on Chrome (fastest for development)
flutter run -d chrome

# Run on Android emulator
flutter run -d emulator-5554
```

### **Firebase Setup**

> **No API keys are included in this repository.** `firebase_options.dart` and
> `google-services.json` hold project-specific configuration and are deliberately
> excluded from version control, so the app **will not run until you supply your own**.

Point the app at a Firebase project of your own:

1. Create a project at the [Firebase console](https://console.firebase.google.com/).
2. Enable **Authentication** (Email/Password provider) and **Cloud Firestore**.
3. Generate the config files:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   This writes `lib/firebase_options.dart` and `android/app/google-services.json`
   for your project. Both are gitignored, so they stay on your machine.

Prefer to do it by hand? Copy the templates and fill in the placeholders:

```bash
cp lib/firebase_options.dart.example lib/firebase_options.dart
cp android/app/google-services.json.example android/app/google-services.json
```

Then set your Firestore security rules before adding any real data — the default
test-mode rules leave the database open to anyone.

### **Load Demo Data**
1. Login with admin account:
   - Email: `admin@bilimagi.com`
   - Password: `admin123`
2. Navigate to Communities -> Admin icon (top-right)
3. Tap **"Demo Verilerini Yukle"** (Load demo data)
4. Wait for success message

---

## Demo Accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@bilimagi.com | admin123 |
| User 1 | ahmet@bilimagi.com | ahmet123 |
| User 2 | ayse@bilimagi.com | ayse123 |

---

## Testing Checklist

### **v10.0 Quick Test**
1. Login as admin
2. Go to Communities -> Select community
3. Create new period with topArticlesCount: 3
4. Add 5 articles, vote for them
5. Switch to discussion phase
6. Verify only top 3 articles are discussable
7. Test search in Explore tab
8. Test activity filters in Following tab
9. View profile -> Check badges and contribution level
10. Open article detail screen

### **Multi-User Test**
1. Open 2 Chrome tabs (normal + incognito)
2. Login as different users
3. Test realtime voting updates
4. Test comment notifications

---

## Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | System design and architecture |
| [DATA_CONTRACT.md](docs/DATA_CONTRACT.md) | Firestore database schema |
| [COMMUNITY_SYSTEM.md](docs/COMMUNITY_SYSTEM.md) | How communities and voting periods work |
| [CHANGELOG.md](docs/CHANGELOG.md) | Version history |

---

## Version History

- **v10.0** - Extended Features (Top N, Search, Badges UI, Polls UI)
- **v9.0** - Period System (Week -> Period migration)
- **v8.0** - Community Enhancements (Cover photos, rules, badges)
- **v7.x** - Profile Improvements (Photos, interests, animations)
- **v6.x** - Moderation & Reporting
- **v5.0** - Community & Suggestion System
- **v4.x** - Dark Mode, Settings
- **v3.0** - Social Features (Following, Mentions)
- **v2.0** - Nested Comments, Voting, Profiles
- **v1.0** - MVP

---

## Credits

**Development:**
- Built with Claude Code (AI pair programming)
- User: mqual (project owner)

**Tech Stack:**
- Flutter by Google
- Firebase by Google
- Material Design 3

---

**Last Updated:** 2026-02-03 (v10.0 Complete)
