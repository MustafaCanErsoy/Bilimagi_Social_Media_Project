# Bilimagi - Scientific Discussion Platform

**Version:** 2.0 (Social Media Transform)
**Platform:** Flutter (Android, iOS, Web)
**Backend:** Firebase (Auth + Firestore)
**Status:** ✅ MVP Complete + v2.0 Features Complete

---

## 🎯 What is Bilimagi?

Bilimagi is a **Reddit/HackerNews-style platform** for scientific article discussions. Communities run weekly cycles where users vote on curated articles, then discuss the winning article in-depth.

### **Core Flow:**
1. **📊 Voting Phase (Mon-Thu):** Users vote on 3-5 curated scientific articles
2. **💬 Discussion Phase (Fri-Sun):** Community discusses the winning article with nested comments
3. **🔒 Closed Phase:** Week ends, content becomes read-only

**Demo Mode:** Admin can instantly switch phases (no device time manipulation required)

---

## ✨ Features (v2.0)

### **User Experience**
- ✅ **User Profiles** - Display name, bio, avatar, statistics
- ✅ **Bottom Navigation** - Modern 3-tab layout (Home, Communities, Profile)
- ✅ **Home Feed** - Discover active discussions and voting weeks
- ✅ **Bookmarks** - Save articles for later reading
- ✅ **Material 3 Design** - Modern UI with Deep Purple + Teal color scheme

### **Discussion Features**
- ✅ **Nested Comments** - Reddit-style threaded conversations (max depth: 5)
- ✅ **Upvote/Downvote** - Quality-driven content ranking
- ✅ **Comment Sorting** - Sort by Popular (score) or New (time)
- ✅ **Reply Threads** - Multi-level discussions with visual indentation
- ✅ **Realtime Updates** - All votes and comments sync live across clients

### **Core MVP**
- ✅ **Authentication** - Email/password login with demo accounts
- ✅ **Communities** - Pre-seeded communities (Physics, Biology)
- ✅ **Weekly Voting** - 1 vote per user, realtime results
- ✅ **Phase Management** - Admin can switch phases (voting → discussion → closed)
- ✅ **Demo Data Seeding** - One-click demo data loading

---

## 🏗️ Architecture

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
├── services/              # 6 services (business logic)
│   ├── auth_service.dart
│   ├── profile_service.dart
│   ├── week_service.dart
│   ├── vote_service.dart
│   ├── bookmark_service.dart
│   └── seed_service.dart
└── screens/               # 9 UI screens
    ├── login_screen.dart
    ├── main_navigation_screen.dart
    ├── home_feed_screen.dart
    ├── community_select_screen.dart
    ├── week_screen.dart
    ├── discussion_screen.dart
    ├── profile_screen.dart
    ├── profile_edit_screen.dart
    └── admin_screen.dart
```

**See:** [FILE_MAP.md](FILE_MAP.md) for detailed file-by-file breakdown

---

## 🚀 Quick Start

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

# Run on Android/iOS
flutter run -d <device-id>
```

### **Load Demo Data**
1. Login with admin account:
   - Email: `admin@bilimagi.com`
   - Password: `admin123`
2. Navigate to Communities → Admin icon (top-right)
3. Tap "Demo Verilerini Yükle"
4. Wait for success message

**Demo Accounts:** See [CLAUDE.md](CLAUDE.md) for credentials

---

## 📱 Demo Instructions

### **Multi-User Testing (2 Clients)**
1. **Client 1 (Chrome normal tab):**
   - Login as Ahmet (`ahmet@bilimagi.com` / `ahmet123`)
   - Go to Fizik Topluluğu
   - Cast vote on Article 1

2. **Client 2 (Chrome incognito tab):**
   - Login as Ayşe (`ayse@bilimagi.com` / `ayse123`)
   - Go to Fizik Topluluğu
   - See realtime vote update from Client 1 ✅
   - Cast vote on Article 2

3. **Admin Phase Switch:**
   - Login as Admin
   - Go to Admin screen
   - Switch phase to "Discussion"
   - See both clients transition to discussion mode ✅

4. **Realtime Comments:**
   - Client 1: Post comment "Harika makale!"
   - Client 2: See comment appear live ✅
   - Client 2: Reply to comment
   - Client 1: See reply nested under parent ✅

---

## 🎯 Definition of Done

### **v1.0 MVP (Complete ✅)**
- ✅ Two users can login and vote in the same community
- ✅ Vote results update live on other client (verified: Chrome + Incognito)
- ✅ Admin switches to discussion → UI transitions correctly
- ✅ Comments appear live on other client
- ✅ Data persists after app restart

### **v2.0 Social Media (Complete ✅)**
- ✅ User profiles viewable and editable
- ✅ Nested comments (reply threads) working
- ✅ Upvote/downvote system functional
- ✅ Bottom navigation + home feed operational
- ✅ Bookmark system working
- ✅ All features realtime multi-user tested
- ✅ No critical bugs
- ✅ Documentation updated

### **Deployment (Pending ⏳)**
- ⏳ Android APK build + test
- ⏳ iOS build proof

---

## 📊 Project Statistics (v2.0)

- **Total Files:** 25 Dart files (~3,500 lines)
- **Services:** 6 (Auth, Profile, Week, Vote, Bookmark, Seed)
- **Screens:** 9 (Login, Nav, Home, Communities, Week, Discussion, Profile, Edit, Saved, Admin)
- **Models:** 5 (UserProfile, Community, Week, Article, CommentTree)
- **Documentation:** 7 MD files (~2,700+ lines)

**Code Quality:**
- `flutter analyze`: 53 warnings, 0 errors ✅
- Multi-user realtime verified ✅
- All v2.0 features tested ✅

---

## 📚 Documentation

### **For Developers:**
- **START_HERE.md** - Navigation guide (read first!)
- **FILE_MAP.md** - Complete file breakdown + AI navigation
- **ARCHITECTURE.md** - Service layer, data flows, ADRs
- **DATA_CONTRACT.md** - Firestore schema + data access map

### **For Project Management:**
- **STATUS.md** - Current progress tracker
- **CHANGELOG.md** - Version history
- **ROADMAP_V2.md** - v2.0 sprint plan (archive)

### **For AI Agents:**
- **CLAUDE.md** - Claude Code specific instructions
- **FILE_MAP.md** - "I need to change X" → file finder
- **DATA_CONTRACT.md** - "Where is X data accessed?" → service map

---

## 🔐 Scope

### **✅ In Scope (v2.0)**
- Weekly voting + discussion flow
- User profiles with stats
- Nested comments (threaded discussions)
- Upvote/downvote system
- Home feed discovery
- Bookmark system
- Admin phase management

### **❌ Out of Scope (Future v3.0+)**
- Community creation by users
- User following/followers
- Direct messages (DMs)
- Push notifications
- Advanced moderation dashboard
- Full-text search (Algolia)
- Email notifications

**Rationale:** Focus on core discussion experience first, expand social features later

---

## 🐛 Known Issues

- None critical (v2.0 tested and stable)
- Minor: Flutter analyze shows 53 warnings (no errors)

**Reporting:** Open issue on GitHub or contact maintainers

---

## 🔮 Future Roadmap (v3.0+)

**High Priority:**
- Dark mode toggle
- Search functionality (articles + comments)
- Push notifications (new replies)
- User following system

**Medium Priority:**
- Comment editing/deletion
- Report system
- Trending algorithm
- Weekly archives

**Low Priority:**
- Image uploads (profile pictures)
- Moderation dashboard
- Analytics dashboard

**See:** [ROADMAP_V2.md](ROADMAP_V2.md) for detailed feature planning

---

## 👥 Credits

**Development:**
- Built with Claude Opus 4.5 (AI pair programming)
- User: mqual (project owner)

**Tech Stack:**
- Flutter by Google
- Firebase by Google
- Material Design 3

---

## 📄 License

[Specify license here]

---

## 🔗 Links

- **Documentation:** [START_HERE.md](START_HERE.md)
- **Architecture:** [ARCHITECTURE.md](ARCHITECTURE.md)
- **File Map:** [FILE_MAP.md](FILE_MAP.md)
- **Status:** [STATUS.md](STATUS.md)

---

**Last Updated:** 2026-01-31 (v2.0 Complete)
**Next Step:** Android build + iOS proof
