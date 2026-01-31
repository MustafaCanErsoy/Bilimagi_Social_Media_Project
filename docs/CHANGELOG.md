# Changelog

All notable changes to Bilimagi will be documented in this file.

---

## [v4.2] - 2026-02-01

### Added - UX İyileştirmeleri

**Yeni Paketler:**
- `share_plus: ^10.0.0` - Native paylaşım desteği
- `connectivity_plus: ^6.0.0` - İnternet bağlantısı takibi

**Yeni Widgetlar:**
- `lib/widgets/skeleton_loading.dart` - Shimmer efektli iskelet yükleme
- `lib/widgets/connectivity_indicator.dart` - Çevrimdışı banner göstergesi

**Bildirimler İyileştirmeleri:**
- Otomatik okundu işaretleme (ekran açıldığında 1.5s sonra)
- Zaman bazlı gruplama (Bugün, Dün, Bu Hafta, Bu Ay, Daha Eski)
- Filtre popup menüsü (Tümü/Takip/Bahsetme/Yanıt/Beğeni)

**Pull to Refresh:**
- Ana sayfa (Keşfet ve Takip sekmeleri)
- Bildirimler ekranı

**Skeleton Loading:**
- Ana sayfa kartları için iskelet yükleme
- Bildirim listesi için iskelet yükleme

**Paylaş Butonu:**
- Makale kartlarında paylaş butonu
- Ana sayfa tartışma kartlarında paylaş ikonu

**Gerçek Zamanlı Sayaçlar:**
- Yorum sayısı badge (StreamBuilder ile)
- Oy sayısı badge (StreamBuilder ile)

**Çevrimdışı Göstergesi:**
- İnternet yokken kırmızı banner

### Changed

**Güncellenen Servisler:**
- `week_service.dart` - `getArticleVoteCount()` stream metodu eklendi
- `comment_service.dart` - `getCommentCount()` stream metodu eklendi

**Güncellenen Ekranlar:**
- `activity_screen.dart` - Filtreleme, gruplama, skeleton loading
- `home_feed_screen.dart` - Pull to refresh, skeleton loading, gerçek zamanlı sayaçlar
- `main_navigation_screen.dart` - Connectivity indicator wrapper

**Güncellenen Widgetlar:**
- `article_post_card.dart` - Paylaş butonu, gerçek zamanlı sayaçlar

---

## [v4.1] - 2026-02-01

### Added - AI-Developability Refactoring

**New Core Utilities:**
- `lib/core/avatar_colors.dart` - Consistent avatar color palette utility
- `lib/core/time_utils.dart` - Relative time formatting (Turkish)

**New Models:**
- `lib/models/comment.dart` - Comment model extracted from week_service

**New Services:**
- `lib/services/comment_service.dart` - Comment CRUD operations with notifications

**New Widgets (8 files):**
- `lib/widgets/section_header.dart` - Reusable section header with icon
- `lib/widgets/empty_state_card.dart` - Empty state card and screen widgets
- `lib/widgets/vote_buttons.dart` - Comment upvote/downvote UI
- `lib/widgets/article_post_card.dart` - Instagram-style article card
- `lib/widgets/discussion_dialogs.dart` - Reply/Edit/Delete modal dialogs
- `lib/widgets/sort_tabs.dart` - Comment sorting tabs (Popular/New)
- `lib/widgets/comment_card.dart` - Comment display with mentions
- `lib/widgets/mention_autocomplete.dart` - @mention autocomplete controller

**New Documentation:**
- `docs/STATUS.md` - Project status tracking
- `docs/FILE_MAP.md` - File structure and dependency map
- `docs/CHANGELOG.md` - This file

### Changed

**Refactored Files:**
- `lib/screens/discussion_screen.dart` - 1455 → ~290 lines (-80%)
- `lib/screens/home_feed_screen.dart` - 820 → ~480 lines (-42%)
- `lib/services/week_service.dart` - 558 → ~295 lines (-47%)

**Updated Documentation:**
- `CLAUDE.md` - Updated to v4.1 with new file structure

### Fixed
- Replaced deprecated `withOpacity()` calls with `withValues(alpha:)` in new files

---

## [v4.0] - 2026-02-01

### Added
- Dark mode with theme switching (Light/Dark/System)
- `lib/core/theme_provider.dart` - Theme state management
- `lib/screens/settings_screen.dart` - App settings UI
- `lib/services/settings_service.dart` - User preferences storage
- Comment editing with "düzenlendi" indicator
- Comment deletion (soft delete with placeholder)
- User registration from login screen

---

## [v3.0] - 2026-01-XX

### Added
- User following system
- @mentions in comments with autocomplete
- Activity feed with notifications
- Personalized home feed (Explore/Following tabs)
- `lib/services/follow_service.dart`
- `lib/services/mention_service.dart`
- `lib/services/notification_service.dart`
- `lib/screens/activity_screen.dart`
- `lib/screens/followers_screen.dart`
- `lib/screens/following_screen.dart`

---

## [v2.0] - 2026-01-XX

### Added
- Nested comments with threading
- Upvote/downvote system for comments
- Home feed with active discussions
- User profile pages
- Bookmarks (saved articles)
- `lib/services/vote_service.dart`
- `lib/services/bookmark_service.dart`
- `lib/screens/profile_screen.dart`
- `lib/screens/saved_articles_screen.dart`
- `lib/models/comment_tree.dart`

---

## [v1.0] - 2026-01-XX

### Added
- Initial MVP release
- Firebase authentication
- Article voting system
- Basic comments
- Admin phase control (voting → discussion → closed)
- Community selection
- Demo data seeding
