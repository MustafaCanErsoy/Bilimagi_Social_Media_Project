# Architecture

**Version:** v2.0 (Social Media Transform)
**Last Updated:** 2026-01-31

## Folder structure
/lib
  /app
    app.dart
    router.dart (optional)
  /core
    constants.dart
    validators.dart
    theme.dart                    [v1.0 - Theme system]
  /models
    user_profile.dart
    community.dart
    article.dart
    week.dart
    comment_tree.dart             [v2.0 - Nested comments]
  /services
    auth_service.dart
    firestore_service.dart
    week_service.dart
    seed_service.dart
    vote_service.dart             [v2.0 - Comment voting]
    bookmark_service.dart         [v2.0 - Save articles]
  /screens
    login_screen.dart
    main_navigation_screen.dart   [v2.0 - Bottom nav shell]
    home_feed_screen.dart         [v2.0 - Discovery feed]
    community_select_screen.dart
    week_screen.dart
    discussion_screen.dart
    admin_screen.dart
    profile_screen.dart           [v2.0 - User profiles]
    profile_edit_screen.dart      [v2.0 - Edit profile]
    saved_articles_screen.dart    [v2.0 - Bookmarks]
  /widgets
    app_scaffold.dart
    primary_button.dart
    community_card.dart
    article_card.dart
    result_bar.dart

---

## Architecture Layers

### **Presentation Layer** (`/screens` + `/widgets`)
- **Responsibility:** UI rendering, user interaction, navigation
- **Rules:**
  - All Firebase queries via services (NO direct Firestore access)
  - Use StreamBuilder for real-time data
  - Check `mounted` before setState in async callbacks
  - Handle loading/error states

### **Business Logic Layer** (`/services`)
- **Responsibility:** Data operations, business rules, Firebase queries
- **Rules:**
  - Services are stateless (no internal state)
  - Return Streams for real-time data
  - Return Futures for one-time operations
  - Throw meaningful exceptions

### **Data Layer** (`/models`)
- **Responsibility:** Data structures, serialization, type safety
- **Rules:**
  - Immutable data classes
  - `fromFirestore()` factory constructors
  - `copyWith()` for updates
  - Validation in models, not in UI

---

## Service Responsibilities

### **AuthService** (`auth_service.dart`)
```dart
Purpose: User authentication
Methods:
  - signIn(email, password) → Future<UserCredential>
  - signOut() → Future<void>
  - currentUser → User?
  - authStateChanges → Stream<User?>
  - initializeUserStats(uid) → Future<void>
```

### **ProfileService** (`profile_service.dart`) [v2.0]
```dart
Purpose: User profile management
Methods:
  - getUserProfile(uid) → Stream<UserProfile?>
  - getCurrentUserProfile() → Stream<UserProfile?>
  - updateProfile({displayName, bio, photoURL}) → Future<void>
  - incrementStats({votes, comments}) → Future<void>
  - initializeUserStats(uid) → Future<void>
```

### **WeekService** (`week_service.dart`)
```dart
Purpose: Week/Article/Comment operations
Methods:
  - getWeek(weekId) → Stream<Week?>
  - getArticles(weekId) → Stream<List<Article>>
  - getVoteCounts(weekId) → Stream<Map<String, int>>
  - castVote(weekId, articleId) → Future<void>
  - getUserVote(weekId) → Stream<String?>
  - getWinningArticle(weekId) → Future<Article?>
  - changeWeekPhase(weekId, phase) → Future<void>
  - addComment(weekId, articleId, text) → Future<void>
  - addReply(weekId, articleId, parentId, depth, text) → Future<void>
  - getComments(weekId, articleId) → Stream<List<Comment>>
  - getActiveDiscussions() → Stream<List<Map>> [v2.0]
  - getVotingWeeks() → Stream<List<Map>> [v2.0]
  - getWeekOnce(weekId) → Future<Week?> [v2.0]
  - getArticleOnce(weekId, articleId) → Future<Article?> [v2.0]
```

### **VoteService** (`vote_service.dart`) [v2.0]
```dart
Purpose: Comment voting (upvote/downvote)
Methods:
  - voteComment({weekId, articleId, commentId, type}) → Future<void>
  - getUserVote({weekId, articleId, commentId}) → Stream<VoteType?>
Types:
  - VoteType: enum { up, down }
Logic:
  - Click same vote → remove vote
  - Click different vote → change vote (±2 score)
  - First vote → add vote (±1 score)
```

### **BookmarkService** (`bookmark_service.dart`) [v2.0]
```dart
Purpose: Article bookmarking
Methods:
  - saveArticle({article, week}) → Future<void>
  - unsaveArticle(articleId) → Future<void>
  - isSaved(articleId) → Stream<bool>
  - getSavedArticles() → Stream<List<SavedArticle>>
Storage:
  - users/{uid}/savedArticles/{articleId}
  - Denormalized: title, summary, weekId, communityId
```

### **FirestoreService** (`firestore_service.dart`)
```dart
Purpose: Community operations
Methods:
  - getCommunities() → Stream<List<Community>>
  - getCommunity(id) → Stream<Community?>
```

### **SeedService** (`seed_service.dart`)
```dart
Purpose: Demo data seeding
Methods:
  - seedDatabase() → Future<void>
Data:
  - 2 communities (Fizik, Biyoloji)
  - 3 users (Admin, Ahmet, Ayşe)
  - 9 articles (4+5)
  - Sample weeks
```

---

## Data Flow Patterns

### **Real-time Updates (StreamBuilder)**
```dart
// Example: Comments with real-time updates
StreamBuilder<List<Comment>>(
  stream: weekService.getComments(weekId, articleId),
  builder: (context, snapshot) {
    // Handle loading/error/data states
    final comments = snapshot.data ?? [];
    return ListView(children: comments.map(...));
  },
)
```

### **One-time Operations (FutureBuilder or async/await)**
```dart
// Example: Voting
Future<void> _castVote(String articleId) async {
  try {
    await weekService.castVote(weekId, articleId);
    // Success feedback
  } catch (e) {
    // Error handling
  }
}
```

### **Composite Queries (asyncMap)**
```dart
// Example: Home feed (week + community + article)
Stream<List<Map>> getActiveDiscussions() {
  return db.collection('weeks')
    .where('phase', isEqualTo: 'discussion')
    .snapshots()
    .asyncMap((snapshot) async {
      // Join data from multiple collections
      for (doc in snapshot.docs) {
        final community = await getCommunity(doc['communityId']);
        final article = await getWinningArticle(doc.id);
        results.add({'week': doc, 'community': community, 'article': article});
      }
      return results;
    });
}
```

---

## Navigation Flow

### **App Entry Point**
```
main.dart
  → Firebase.initializeApp()
  → MaterialApp(theme: AppTheme.lightTheme)
  → AuthWrapper
    → if (authenticated) MainNavigationScreen
    → else LoginScreen
```

### **MainNavigationScreen (Bottom Navigation)**
```
Tab 0: HomeFeedScreen (🏠 Ana Sayfa)
Tab 1: CommunitySelectScreen (👥 Topluluklar)
Tab 2: ProfileScreen (👤 Profil)
```

### **Navigation Hierarchy**
```
MainNavigationScreen
├─ HomeFeedScreen
│  ├─ DiscussionScreen (tap active discussion)
│  └─ WeekScreen (tap voting week)
├─ CommunitySelectScreen
│  ├─ WeekScreen (tap community)
│  └─ AdminScreen (tap admin icon)
└─ ProfileScreen
   ├─ ProfileEditScreen (tap edit button)
   ├─ SavedArticlesScreen (tap saved articles)
   └─ ProfileScreen (tap username in comments)

WeekScreen
  └─ DiscussionScreen (tap winning article in discussion phase)

DiscussionScreen
  ├─ ProfileScreen (tap username)
  └─ External Browser (tap "Makaleyi Oku")
```

---

## State Management

### **Current Approach: StatefulWidget + StreamBuilder**
- **Why:** Simple, built-in, no external dependencies
- **Pattern:** UI state in StatefulWidget, data state in Streams
- **Example:**
```dart
class _DiscussionScreenState extends State<DiscussionScreen> {
  bool _sortByScore = true; // UI state

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Comment>>( // Data state
      stream: weekService.getComments(...),
      builder: (context, snapshot) { /* ... */ },
    );
  }
}
```

### **Future Considerations**
- If complexity grows: Riverpod or Bloc
- Current scale: StatefulWidget is sufficient

---

## Error Handling Patterns

### **Loading States**
```dart
if (snapshot.connectionState == ConnectionState.waiting) {
  return Center(child: CircularProgressIndicator());
}
```

### **Error States**
```dart
if (snapshot.hasError) {
  return Center(child: Text('Hata: ${snapshot.error}'));
}
```

### **Empty States**
```dart
if (data.isEmpty) {
  return EmptyStateWidget(
    icon: Icons.chat_bubble_outline,
    message: 'Henüz yorum yok',
  );
}
```

### **Async Error Handling**
```dart
try {
  await service.operation();
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Başarılı!')),
    );
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hata: $e')),
    );
  }
}
```

---

## Performance Optimizations

### **Firestore Query Optimizations**
1. **Index-free queries:** Use `where` only, sort in memory
2. **Limit results:** Fetch 20, return 10 after sort
3. **Denormalization:** Store title/summary in savedArticles
4. **Realtime triggers:** Use `lastVoteAt` field for vote count updates

### **UI Optimizations**
1. **const constructors:** Use `const` for static widgets
2. **Keys for lists:** Use unique keys in ListView.builder
3. **StreamBuilder reuse:** Don't recreate streams on rebuild
4. **Lazy loading:** Use ListView.builder, not ListView

### **Memory Management**
1. **Dispose controllers:** TextEditingController, ScrollController
2. **Cancel subscriptions:** (Handled automatically by StreamBuilder)
3. **Check mounted:** Before setState in async callbacks

---

## Security Rules Summary

### **Firestore Rules**
```javascript
// users: read own, write own
match /users/{userId} {
  allow read: if request.auth.uid == userId;
  allow write: if request.auth.uid == userId;
}

// communities: read all
match /communities/{doc} {
  allow read: if request.auth != null;
}

// weeks/articles: read all, write admin only
match /weeks/{doc} {
  allow read: if request.auth != null;
  allow write: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}

// votes: read own, write own
match /weeks/{weekId}/articles/{articleId}/votes/{userId} {
  allow read, write: if request.auth.uid == userId;
}

// comments: read all, write authenticated
match /weeks/{weekId}/articles/{articleId}/comments/{doc} {
  allow read: if request.auth != null;
  allow create: if request.auth != null;
  allow update, delete: if request.auth.uid == resource.data.uid;
}
```

---

## Testing Strategy

### **Manual Testing**
- Multi-user testing (2+ Chrome tabs)
- Realtime updates verification
- Phase switching scenarios
- Error state testing

### **Future: Automated Testing**
- Unit tests for services
- Widget tests for screens
- Integration tests for user flows

---

## Deployment Checklist

- [ ] Firebase project configured
- [ ] Firestore rules deployed
- [ ] Authentication enabled (Email/Password)
- [ ] Demo data seeded
- [ ] Environment: Production / Staging
- [ ] Analytics configured (optional)
- [ ] Error monitoring (optional)

---

## Code Organization Rules

### **Naming Conventions**
- Screens: `*_screen.dart` (e.g., `discussion_screen.dart`)
- Services: `*_service.dart` (e.g., `vote_service.dart`)
- Widgets: `*_card.dart`, `*_button.dart` (e.g., `comment_card.dart`)
- Models: `*.dart` (e.g., `user_profile.dart`)

### **File Structure Rules**
- One screen per file
- Private widgets in same file as screen (prefix with `_`)
- Shared widgets in `/widgets`
- No circular dependencies between services

### **Import Order**
1. Dart SDK imports (`dart:*`)
2. Flutter imports (`package:flutter/*`)
3. Third-party packages (`package:*`)
4. Local imports (`../`)

---

## Architecture Decision Records (ADR)

### **ADR-1: Why StreamBuilder over State Management?**
- **Decision:** Use StreamBuilder with Firestore streams
- **Rationale:** Built-in real-time updates, no extra dependencies
- **Trade-off:** Less control over state, but simpler codebase

### **ADR-2: Why in-memory sorting over Firestore composite indexes?**
- **Decision:** Fetch 20, sort in memory, return 10
- **Rationale:** Avoid Firebase index setup complexity
- **Trade-off:** Slightly more data fetched, but negligible performance impact

### **ADR-3: Why denormalized data in savedArticles?**
- **Decision:** Store title/summary in savedArticles collection
- **Rationale:** Faster queries, no need to join with articles collection
- **Trade-off:** Data duplication, but read-optimized

### **ADR-4: Why Material 3 over Material 2?**
- **Decision:** Use Material 3 design system
- **Rationale:** Modern look, future-proof
- **Trade-off:** Some APIs deprecated, but migration guides available

---

## v2.0 Milestones

- ✅ **v1.0:** MVP (voting, discussion, admin, basic UI)
- ✅ **v1.5:** UI modernization (theme, Instagram-style discussion)
- ✅ **v2.0:** Social media transform (profiles, nested comments, voting, feed, bookmarks)
- 🔮 **v2.1:** Notifications, search (future)
- 🔮 **v3.0:** Moderation, analytics, mobile optimizations (future)
