# Changelog

All notable changes to Bilimagi will be documented in this file.

---

## [v6.1] - 2026-02-01

### Added - Comment Reporting & Code Quality

**Yorum Rapor Sistemi:**
- Kullanıcılar uygunsuz yorumları raporlayabiliyor
- 5 rapor sebebi: Spam, Taciz, Uygunsuz İçerik, Yanlış Bilgi, Diğer
- Rapor dialogu ile sebep seçimi ve ek detay girişi
- Yorum kartında bayrak ikonu (rapor butonu)
- Aynı yorumu tekrar raporlama engeli

**Moderasyon Paneli Genişletmesi:**
- Yeni "Raporlar" sekmesi (ilk tab olarak)
- Bekleyen raporlar listesi
- Rapor inceleme: "Reddet" veya "Gizle/Yasakla" aksiyonları
- Yorum gizleme + rapor kapatma tek tıkla
- Kullanıcı banlama + rapor kapatma tek tıkla

**Yeni Dosyalar:**

*Models:*
- `lib/models/report.dart` - ReportType, ReportStatus, ReportReason + Report model

*Services:*
- `lib/services/report_service.dart` - reportComment, getPendingReports, reviewReport

*Widgets:*
- `lib/widgets/report_dialog.dart` - Rapor sebep seçimi dialogu

### Changed

**Güncellenen Widgetlar:**
- `lib/widgets/comment_card.dart` - +onReport callback, bayrak ikonu

**Güncellenen Ekranlar:**
- `lib/screens/discussion_screen.dart` - Rapor entegrasyonu
- `lib/screens/moderation_dashboard_screen.dart` - Raporlar sekmesi (3 tab)

### Fixed

**Kod Kalitesi:**
- `withOpacity()` deprecation uyarıları düzeltildi (11 yer)
- `lib/core/theme.dart` - 8 düzeltme
- `lib/screens/profile_edit_screen.dart` - 2 düzeltme
- `lib/screens/week_screen.dart` - 1 düzeltme

### Firestore Schema Changes

**communities/{communityId}/reports/{reportId} (NEW):**
- `reporterUid: string`
- `reporterDisplayName: string`
- `type: "comment" | "user"`
- `targetId: string`
- `targetUid: string`
- `targetDisplayName: string?`
- `weekId: string?`
- `articleId: string?`
- `reason: "spam" | "harassment" | "inappropriate" | "misinformation" | "other"`
- `details: string?`
- `status: "pending" | "reviewed" | "dismissed"`
- `createdAt: timestamp`
- `reviewedByUid: string?`
- `reviewedAt: timestamp?`
- `reviewNote: string?`

---

## [v6.0] - 2026-02-01

### Added - Search, Activity Feed & Moderation System

**Topluluk Arama & Filtreleme:**
- Arama çubuğu (debounced input, topluluk adı/açıklama/kategori'de arama)
- Filtre bottom sheet (kategori + sıralama tek yerde)
- Aktif filtre göstergesi ve temizleme butonu
- Client-side filtreleme (Firestore okuma sonrası)

**Takip Edilen Aktivite Akışı:**
- Yeni `UserActivity` modeli (comment, vote, join, suggestion türleri)
- `ActivityService` - takip edilenlerin aktivitelerini aggregation
- `ActivityFeedCard` widget - aktivite gösterimi
- Ana sayfa "Takip" sekmesi aktivite akışı ile yeniden tasarlandı

**Gelişmiş Moderasyon:**
- Yorum gizleme sistemi (isHidden, hiddenByUid, hiddenAt, hiddenReason alanları)
- Kullanıcı banlama sistemi (kalıcı ban, sebep zorunlu)
- Audit log (moderasyon işlem geçmişi kaydı)
- Moderasyon paneli ekranı (Yasaklılar + İşlem Geçmişi tab'ları)
- Yorum kartında moderatör menüsü (gizle/göster)

**Yeni Bildirimler:**
- `roleChanged` - Rol değişikliği bildirimi (moderatör yapılma vb.)
- `memberRemoved` - Topluluktan çıkarılma bildirimi

**Topluluk Yönetimi İyileştirmeleri:**
- Topluluk silme UI (onay dialogu ile, isim yazma zorunluluğu)
- `isDeleted` alanı ile soft delete
- Silinen topluluklar tüm listelerden filtreleniyor

**Yeni Dosyalar:**

*Models:*
- `lib/models/user_activity.dart` - ActivityType enum + UserActivity model
- `lib/models/community_ban.dart` - CommunityBan model
- `lib/models/moderation_log.dart` - ModerationActionType enum + ModerationLog model

*Services:*
- `lib/services/activity_service.dart` - recordActivity, getFollowedUsersActivities
- `lib/services/moderation_service.dart` - hideComment, banUser, getModerationLogs

*Widgets:*
- `lib/widgets/community_search_bar.dart` - Debounced arama input
- `lib/widgets/category_filter_chips.dart` - FilterChip'ler + sort dropdown
- `lib/widgets/activity_feed_card.dart` - Aktivite gösterim kartı

*Screens:*
- `lib/screens/moderation_dashboard_screen.dart` - Ban listesi + audit log

### Changed

**Güncellenen Modeller:**
- `lib/models/comment.dart` - +isHidden, +hiddenByUid, +hiddenAt, +hiddenReason
- `lib/models/community.dart` - +isDeleted alanı

**Güncellenen Servisler:**
- `lib/services/community_service.dart` - +filterCommunities(), +isDeleted filtreleme, +bildirimler
- `lib/services/notification_service.dart` - +roleChanged, +memberRemoved bildirimleri
- `lib/services/week_service.dart` - +isDeleted filtreleme

**Güncellenen Widgetlar:**
- `lib/widgets/comment_card.dart` - +isModerator, +onHide, +onUnhide, mod menu

**Güncellenen Ekranlar:**
- `lib/screens/community_select_screen.dart` - Filtre bottom sheet UI
- `lib/screens/home_feed_screen.dart` - Aktivite akışı entegrasyonu
- `lib/screens/community_manage_screen.dart` - Moderasyon paneli + silme butonu
- `lib/screens/activity_screen.dart` - Yeni bildirim türleri desteği

### Firestore Schema Changes

**comments/{commentId} (UPDATED):**
- `+isHidden: boolean`
- `+hiddenByUid: string?`
- `+hiddenAt: timestamp?`
- `+hiddenReason: string?`

**communities/{communityId}/bans/{bannedUid} (NEW):**
- `bannedDisplayName: string`
- `bannedByUid: string`
- `bannedByDisplayName: string`
- `bannedAt: timestamp`
- `expiresAt: timestamp?` (null = kalıcı)
- `reason: string`

**communities/{communityId}/moderationLogs/{logId} (NEW):**
- `type: "hideComment" | "unhideComment" | "banUser" | "unbanUser" | ...`
- `moderatorUid: string`
- `moderatorDisplayName: string`
- `targetUid: string?`
- `targetDisplayName: string?`
- `targetId: string?`
- `reason: string?`
- `createdAt: timestamp`

**users/{uid}/activities/{activityId} (NEW):**
- `uid: string`
- `displayName: string`
- `avatarColorIndex: number`
- `type: "comment" | "vote" | "join" | "suggestion"`
- `targetType: "article" | "community" | "user"`
- `targetId: string`
- `targetName: string?`
- `weekId: string?`
- `communityId: string?`
- `communityName: string?`
- `preview: string?`
- `createdAt: timestamp`

---

## [v5.0] - 2026-02-01

### Added - Community Creation & Article Suggestion System

**Topluluk Oluşturma:**
- Kullanıcılar kendi topluluklarını oluşturabilir
- Hibrit kategori sistemi (Fizik, Biyoloji, Kimya, Matematik, Tıp, Mühendislik, Psikoloji + Diğer)
- Emoji simgesi seçimi (24 bilim temalı emoji)
- Renk paleti seçimi (8 renk)
- Topluluk istatistikleri (üye, hafta, makale sayısı)

**Üyelik Sistemi:**
- Üyelik başvurusu (onay gerekli)
- Owner/Moderator tarafından onay/red
- Rol hiyerarşisi: Owner > Moderator > Member
- Üye yönetimi (rol değiştirme, çıkarma)
- Bekleyen başvuru badge'leri

**Makale Önerisi Sistemi:**
- Oylama fazında makale önerisi gönderme
- İlgi oyları (diğer üyelerden)
- Moderatör inceleme ve onay/red
- Onaylanan öneriler otomatik makaleye dönüşür
- Red sebebi girişi

**Yeni Bildirimler:**
- `membershipRequest` - Üyelik başvurusu (owner/mod'a)
- `membershipApproved` - Üyelik onaylandı (kullanıcıya)
- `membershipRejected` - Üyelik reddedildi (kullanıcıya)
- `suggestionApproved` - Öneri onaylandı (öneren kişiye)
- `suggestionRejected` - Öneri reddedildi (öneren kişiye)

**Yeni Dosyalar:**

*Models:*
- `lib/models/community_membership.dart` - MemberRole, MemberStatus enums + model
- `lib/models/article_suggestion.dart` - SuggestionStatus enum + model

*Services:*
- `lib/services/community_service.dart` - CRUD, üyelik, rol yönetimi
- `lib/services/suggestion_service.dart` - Öneri, onay, ilgi oyu

*Widgets:*
- `lib/widgets/community_card.dart` - Topluluk kartı
- `lib/widgets/member_list_tile.dart` - Üye liste öğesi
- `lib/widgets/community_icon_picker.dart` - Emoji/renk seçici
- `lib/widgets/suggestion_card.dart` - Öneri kartı

*Screens:*
- `lib/screens/community_create_screen.dart` - Topluluk oluşturma formu
- `lib/screens/community_manage_screen.dart` - Topluluk yönetimi
- `lib/screens/community_members_screen.dart` - Üye listesi ve yönetimi
- `lib/screens/suggestion_screen.dart` - Makale önerisi formu
- `lib/screens/suggestion_review_screen.dart` - Öneri inceleme (mod)

### Changed

**Güncellenen Modeller:**
- `lib/models/community.dart` - category, customCategory, iconEmoji, colorIndex, createdAt, isPublic, CommunityStats alanları eklendi

**Güncellenen Servisler:**
- `lib/services/notification_service.dart` - 5 yeni bildirim türü ve metodları

**Güncellenen Ekranlar:**
- `lib/screens/community_select_screen.dart` - Tab görünümü (Keşfet/Katıldıklarım), FAB
- `lib/screens/week_screen.dart` - Öneri butonları, yönetim erişimi
- `lib/screens/activity_screen.dart` - Yeni bildirim türleri switch desteği

### Firestore Schema Changes

**communities/{communityId}:**
- `+category: string`
- `+customCategory: string?`
- `+iconEmoji: string?`
- `+colorIndex: number`
- `+createdAt: timestamp`
- `+isPublic: boolean`
- `+stats: {memberCount, weekCount, totalArticles}`

**communities/{communityId}/members/{uid} (NEW):**
- `role: "owner" | "moderator" | "member"`
- `status: "pending" | "approved" | "rejected"`
- `displayName: string`
- `requestedAt: timestamp`
- `approvedAt: timestamp?`
- `approvedByUid: string?`

**weeks/{weekId}/suggestions/{suggestionId} (NEW):**
- `title, summary, link: string`
- `submitterUid, submitterDisplayName: string`
- `status: "pending" | "approved" | "rejected"`
- `interestScore: number`
- `createdAt, reviewedAt: timestamp`

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
