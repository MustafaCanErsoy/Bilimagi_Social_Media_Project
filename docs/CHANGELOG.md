# Changelog

All notable changes to Bilimagi will be documented in this file.

---

## [v10.0] - 2026-02-03

### Added - Top N Makale + UI Entegrasyonları + Yeni Ekranlar

**Phase 1: Core Features**

**Özellik 1: Kapak Fotoğrafı Konumu:**
- Topluluk yönetim ekranında ikon seçici üste taşındı
- Kapak fotoğrafı ikona göre altına alındı
- Daha mantıklı UI sıralaması

**Özellik 2: Top N Makale Sistemi:**
- `minVotesForDiscussion` → `topArticlesCount` dönüşümü
- Artık "en az X oy alan" yerine "en çok oy alan X makale" tartışmaya açılıyor
- Varsayılan değer: 3 (en çok oy alan 3 makale)
- Beraberlik durumunda erken eklenen makale öncelikli (createdAt ascending)
- Period model güncellendi
- PeriodService._markEligibleArticles() yeni Top N sıralama mantığı
- period_create_screen.dart UI güncellemeleri
- period_screen.dart metin güncellemeleri

**Özellik 3: Arama Özelliği:**
- Ana sayfa Keşfet sekmesine arama alanı eklendi
- Dönem başlığında ve topluluk adında arama
- Case-insensitive, debounced arama
- In-memory filtreleme (Firestore sınırlaması)
- Arama sonucu boşsa özel mesaj

**Özellik 4: Aktivite Akışı Geliştirmeleri:**
- Filtre chip'leri: Tümü, Yorumlar, Oylar, Katılımlar, Öneriler
- Pagination: "Daha Fazla Yükle" butonu (20'şer kayıt)
- Join aktiviteleri artık topluluğa yönlendiriyor (profile değil)
- "Topluluğu gör" etiketi join aktivitelerinde

**Phase 2: UI Integrations**

**Özellik 5: Rozet ve Katkı Seviyesi UI:**
- profile_screen.dart'a rozet bölümü entegre edildi
- profile_screen.dart'a katkı seviyesi bölümü entegre edildi
- BadgeList widget ile kazanılan rozetler ve tarihler
- ContributionLevelCard widget ile detaylı puan dağılımı
- Gerçek zamanlı StreamBuilder ile güncelleme

**Özellik 6: Duyuru Sistemi UI:**
- period_screen.dart'a duyuru banner entegrasyonu
- Pinned duyurular otomatik olarak görünür
- Tüm duyurular için modal bottom sheet
- AnnouncementBanner ve AnnouncementCard kullanımı

**Özellik 7: Anket Sistemi UI:**
- period_screen.dart'a aktif anket bölümü eklendi
- Kompakt anket önizlemesi kartı
- Anket detayı için modal bottom sheet
- PollCard widget ile oy kullanma
- "Tümünü Gör" butonu ile tam liste

**Özellik 8: Bildirim Merkezi İyileştirmeleri:**
- Kategori filtreleri: Sosyal, Topluluk, Öneriler
- Topluluk bildirimleri artık topluluğa yönlendiriyor (profil yerine)
- Genişletilmiş filtre menüsü (10+ filtre seçeneği)

**Özellik 9: Makale Detay Ekranı (YENİ):**
- `article_detail_screen.dart` oluşturuldu
- Hero image ile SliverAppBar
- Markdown content görüntüleme (MarkdownViewer)
- Kaydetme (bookmark) özelliği
- Paylaşma ve orijinal makale bağlantısı
- Meta bilgiler (oy, yorum, yazar, tarih)
- Öneri bilgisi gösterimi

**Özellik 10: Kullanıcı Arama (YENİ):**
- `user_search_screen.dart` oluşturuldu
- Debounced arama (500ms)
- Kullanıcı listesi avatar ve bio ile
- Profil sayfasına navigasyon

### Changed

**Güncellenen Modeller:**
- `lib/models/period.dart` - minVotesForDiscussion → topArticlesCount

**Güncellenen Servisler:**
- `lib/services/period_service.dart` - Top N seçim mantığı, parametre değişikliği
- `lib/services/community_service.dart` - topArticlesCount parametresi
- `lib/services/seed_service.dart` - topArticlesCount: 3

**Güncellenen Ekranlar:**
- `lib/screens/community_manage_screen.dart` - UI sıralaması
- `lib/screens/period_create_screen.dart` - Top N UI
- `lib/screens/period_screen.dart` - Metin güncellemeleri + Duyuru + Anket UI
- `lib/screens/home_feed_screen.dart` - Arama + Aktivite geliştirmeleri
- `lib/screens/profile_screen.dart` - Rozet + Katkı seviyesi entegrasyonu
- `lib/screens/activity_screen.dart` - Kategori filtreleri + Topluluk navigasyonu

**Yeni Ekranlar:**
- `lib/screens/article_detail_screen.dart` - Makale detay görüntüleme
- `lib/screens/user_search_screen.dart` - Kullanıcı arama

**Güncellenen Widgetlar:**
- `lib/widgets/activity_feed_card.dart` - showCommunityHint parametresi

### Firestore Schema Changes

**periods/{periodId} (UPDATED):**
- `minVotesForDiscussion` → `topArticlesCount: number` (default: 3)
- Backward compat: Eski dökümanlar hala çalışır

---

## [v9.0] - 2026-02-03

### Changed - Week -> Period Sistemi Donusumu

**Hafta Sistemi -> Donem Sistemi:**
- Week modeli Period modeli ile degistirildi
- WeekService -> PeriodService donusumu
- WeekScreen -> PeriodScreen donusumu
- Esnek donem sistemi (takvime bagli degil)
- Donem basligi ve aciklamasi destegi
- Baslangic/bitis tarihleri (opsiyonel)

**Coklu Makale Tartismasi:**
- Artik tek kazanan makale yerine birden fazla makale tartisabilir
- `minVotesForDiscussion` esigi ile tartisma hakki belirlenir
- Esigi gecen makaleler tartismaya acilir
- Esik alti makaleler salt-okunur olarak gosterilir

**Coklu Oylama Sistemi:**
- Kullanicilar birden fazla makaleye oy verebilir
- Toggle bazli oylama (tikla = oy ver, tekrar tikla = geri al)
- Set<String> bazli oy takibi

**Firestore Yapi Degisiklikleri:**
- `weeks` collection -> `periods` collection
- `currentWeekId` -> `currentPeriodId`
- `weekId` -> `periodId` tum dosyalarda
- Article modeline `isEligibleForDiscussion` alani eklendi

**Yeni Dosyalar:**
- `lib/models/period.dart` - Yeni donem modeli
- `lib/services/period_service.dart` - Donem servisi (CRUD, faz gecisi, coklu oylama)
- `lib/screens/period_screen.dart` - Donem ekrani
- `lib/screens/period_create_screen.dart` - Donem olusturma ekrani

**Silinen Dosyalar:**
- `lib/models/week.dart`
- `lib/services/week_service.dart`
- `lib/screens/week_screen.dart`

**Guncellenen Dosyalar (~30):**
- Tum modeller weekId -> periodId guncellemesi
- Tum servisler weeks -> periods collection guncellemesi
- Tum ekranlar Period entegrasyonu
- Tum widgetlar Period parametreleri

---

## [v8.0] - 2026-02-03

### Added - Topluluk Sistemi Buyuk Gelistirme

**Kategori 1 - Faz Yonetimi:**
- Owner/Moderator faz degistirme yetkisi
- `changePhaseWithAuth()` metodu (week_service.dart)
- Topluluk yonetim ekraninda faz kontrol UI (3 buton)
- Onay dialoglu faz gecisi

**Kategori 2 - Topluluk Yonetimi:**
- JoinType enum: open (onaysiz katilim), approval (onay gerekli)
- Topluluk kapak fotografı yukleme (Firebase Storage)
- Topluluk kurallari sayfasi (Markdown destegi)
- Acik katilim sistemi (direkt uyelik)
- community_card.dart'a kapak gosterimi ve acik katilim etiketi

**Kategori 3 - Makale Sistemi:**
- Article modeli genisletildi (heroImageURL, content, status, author alanlari)
- ArticleStatus enum (draft, published, archived)
- Makale taslak sistemi (kaydet + yayinla)
- Basit Markdown editoru (kalin, italik, link, liste, baslik)
- Markdown onizleme ve gosterim
- Hero gorsel yukleme (article_post_card.dart)
- article_edit_screen.dart - Makale duzenleme ekrani

**Kategori 4 - Uyelik & Etkilesim:**
- 6 rozet tipi: Yeni Uye, Aktif Uye, Kidemli Uye, En Cok Katki, Yardimci, Veteran
- Katki puan sistemi (yorum=5, oy=1, oneri=10, onaylanan=25, upvote=2)
- 6 seviye: Baslangic, Merakli, Kesfedici, Uzman, Usta, Bilge
- Gercek zamanli rozet guncellemesi
- badge_display.dart ve contribution_level_card.dart widget'lari

**Kategori 5 - Yeni Ozellikler:**
- Topluluk duyuru sistemi (announcement_service.dart)
- Pinned yorum ozelligi (pinComment, unpinComment)
- Topluluk anket sistemi (poll_service.dart)
- Coklu secenek destekli anketler
- Anket olusturma ekrani (poll_create_screen.dart)

**Yeni Dosyalar:**

*Models:*
- `lib/models/user_badge.dart` - Rozet modeli ve BadgeChecker
- `lib/models/contribution_score.dart` - Katki puan ve seviye sistemi
- `lib/models/announcement.dart` - Duyuru modeli
- `lib/models/poll.dart` - Anket ve oylama modeli

*Services:*
- `lib/services/article_service.dart` - Makale CRUD ve taslak islemleri
- `lib/services/badge_service.dart` - Rozet ve katki yonetimi
- `lib/services/announcement_service.dart` - Duyuru CRUD
- `lib/services/poll_service.dart` - Anket CRUD ve oylama

*Widgets:*
- `lib/widgets/markdown_editor.dart` - Formatlama araclariyla markdown editoru
- `lib/widgets/markdown_viewer.dart` - Markdown icerik gosterici
- `lib/widgets/badge_display.dart` - Rozet chip'leri ve liste
- `lib/widgets/contribution_level_card.dart` - Seviye ve ilerleme karti
- `lib/widgets/announcement_card.dart` - Duyuru karti ve banner
- `lib/widgets/poll_card.dart` - Anket karti ve oylama UI

*Screens:*
- `lib/screens/community_rules_screen.dart` - Topluluk kurallari duzenleyici
- `lib/screens/article_edit_screen.dart` - Makale olusturma/duzenleme
- `lib/screens/poll_create_screen.dart` - Anket olusturma formu

### Changed

**Guncellenen Modeller:**
- `lib/models/community.dart` - +JoinType, +coverPhotoURL, +rules
- `lib/models/article.dart` - +heroImageURL, +content, +status, +authorUid, +authorDisplayName, +createdAt, +updatedAt, +publishedAt
- `lib/models/comment.dart` - +isPinned, +pinnedByUid, +pinnedAt
- `lib/models/user_profile.dart` - +badges, +contribution

**Guncellenen Servisler:**
- `lib/services/week_service.dart` - +changePhaseWithAuth()
- `lib/services/community_service.dart` - +JoinType mantigi, +kapak/kurallar desteği
- `lib/services/storage_service.dart` - +uploadCommunityCover(), +uploadArticleHeroImage()
- `lib/services/comment_service.dart` - +pinComment(), +unpinComment()

**Guncellenen Ekranlar:**
- `lib/screens/community_manage_screen.dart` - Faz kontrolu, kapak, kurallar, katilim tipi UI
- `lib/screens/community_create_screen.dart` - Katilim tipi secimi

**Guncellenen Widgetlar:**
- `lib/widgets/community_card.dart` - Kapak gosterimi, acik katilim etiketi
- `lib/widgets/article_post_card.dart` - Hero gorsel gosterimi

### Firestore Schema Changes

**communities/{communityId} (UPDATED):**
- `+joinType: "open" | "approval"`
- `+coverPhotoURL: string?`
- `+rules: string?`

**weeks/{weekId}/articles/{articleId} (UPDATED):**
- `+heroImageURL: string?`
- `+content: string?`
- `+status: "draft" | "published" | "archived"`
- `+authorUid: string?`
- `+authorDisplayName: string?`
- `+createdAt: timestamp?`
- `+updatedAt: timestamp?`
- `+publishedAt: timestamp?`

**comments (UPDATED):**
- `+isPinned: boolean`
- `+pinnedByUid: string?`
- `+pinnedAt: timestamp?`

**users/{uid} (UPDATED):**
- `+badges: array<{type, earnedAt}>`
- `+contribution: {totalComments, totalVotes, totalSuggestions, approvedSuggestions, receivedUpvotes}`

**communities/{communityId}/announcements/{id} (NEW):**
- `title, content, authorUid, authorDisplayName, createdAt, expiresAt?, isPinned`

**communities/{communityId}/polls/{pollId} (NEW):**
- `question, options[], authorUid, authorDisplayName, createdAt, endsAt?, status, allowMultiple, totalVotes`

**communities/{communityId}/polls/{pollId}/votes/{uid} (NEW):**
- `optionIds[], votedAt`

---

## [v7.2] - 2026-02-01

### Added - Profil Gelistirmeleri

**Profil Fotografı Yukleme:**
- Firebase Storage entegrasyonu
- Kamera veya galeriden fotograf secimi
- Otomatik boyutlandirma (512x512, 85% kalite)
- Fotograf kaldirma ozelligi
- Storage path: `users/{uid}/profile_photo.jpg`

**Ilgi Alanlari Sistemi:**
- 15 bilimsel ilgi alani kategorisi (Fizik, Biyoloji, Kimya, Matematik, Tip, Muhendislik, Psikoloji, Astronomi, Ekoloji, Bilgisayar Bilimi, Noroloji, Genetik, Iklim Bilimi, Yapay Zeka, Kuantum Fizigi)
- Multi-select FilterChip UI (maksimum 5 secim)
- Profilde ilgi alanlari gosterimi (ikonlu chip'ler)
- Turkce etiketler

**Kullanici Aktivitesi:**
- Son aktiviteler karti (bildirimler bazli)
- Aktivite turune gore renkli ikonlar
- Relatif zaman damgalari

**Profil Ekrani Yeniden Tasarim:**
- CustomScrollView + SliverAppBar layout
- Animasyonlu header (fade + scale)
- Staggered icerik animasyonlari (slide + fade)
- Modern gradient header tasarimi
- Modular widget yapisi

**Yeni Dosyalar:**

*Core:*
- `lib/core/interest_categories.dart` - Ilgi alani kategorileri ve Turkce etiketler

*Services:*
- `lib/services/storage_service.dart` - Firebase Storage profil fotografı islemleri

*Widgets:*
- `lib/widgets/profile_header.dart` - Animasyonlu gradient header, fotograf/avatar, takipci sayilari
- `lib/widgets/interest_tag_picker.dart` - Multi-select ilgi alani secici
- `lib/widgets/interest_tags_display.dart` - Ilgi alani chip'leri gosterimi
- `lib/widgets/profile_activity_card.dart` - Son aktiviteler karti

### Changed

**Guncellenen Modeller:**
- `lib/models/user_profile.dart` - +interests: List<String>

**Guncellenen Servisler:**
- `lib/services/profile_service.dart` - +updateProfilePhoto(), +removeProfilePhoto(), +updateInterests(), +getUserProfileOnce()

**Guncellenen Ekranlar:**
- `lib/screens/profile_screen.dart` - Tam yeniden tasarim (StatefulWidget, animasyonlar, modular yapı)
- `lib/screens/profile_edit_screen.dart` - +Fotograf yukleme bolumu, +Ilgi alanlari secici

**Guncellenen Bagimliliklar:**
- `pubspec.yaml` - +firebase_storage: ^13.0.6, +image_picker: ^1.1.2

### Firestore Schema Changes

**users/{uid} (UPDATED):**
- `+interests: string[]` - Kullanici ilgi alanlari ['physics', 'biology', ...]

**Firebase Storage (NEW):**
- `users/{uid}/profile_photo.jpg` - Profil fotografı

---

## [v7.1] - 2026-02-01

### Added - Login & Geçiş Animasyonları

**Login Ekranı Yeniden Tasarım:**
- Full gradient arka plan (splashGradient)
- Animasyonlu logo (fade in + scale)
- Form animasyonu (slide up + fade in)
- Glassmorphism tarzı floating input alanları
- Beyaz buton gradient üzerinde kontrast
- Kayıt ekranına geçiş animasyonu

**Hoş Geldin Ekranı (Welcome Screen):**
- Giriş sonrası karşılama ekranı
- Logo animasyonu (fade in + scale)
- Kişiselleştirilmiş "Hoş geldin, [İsim]!" mesajı
- Otomatik geçiş animasyonu (2.5 saniye)
- Pulsing dots loading indicator

**Hoşça Kal Ekranı (Goodbye Screen):**
- Çıkış öncesi veda ekranı
- "Hoşça kal, [İsim]!" mesajı
- "Tekrar görüşmek üzere!" alt mesajı
- El sallama ikonu
- Animasyonlu geçiş ve otomatik logout

**Logo Güncelleme:**
- "Bilimagi" → "BİLİMAĞI" (tümü büyük harf, Türkçe karakterler)
- Yeni ikon: DNA sarmalı (biotech) - gradient arka plan
- Font size artırıldı, letter spacing eklendi
- Slogan: "Bilimsel Tartışma"

**Yeni Dosyalar:**
- `lib/screens/welcome_screen.dart` - Hoş geldin ekranı (~220 satır)
- `lib/screens/goodbye_screen.dart` - Hoşça kal ekranı (~210 satır)

### Changed

**Güncellenen Ekranlar:**
- `lib/screens/login_screen.dart` - Tam yeniden tasarım (~310 satır)
- `lib/screens/register_screen.dart` - Aynı stil uygulaması (~340 satır)
- `lib/screens/settings_screen.dart` - Türkçe karakterler, goodbye entegrasyonu

**Güncellenen Widgetlar:**
- `lib/widgets/app_logo.dart` - Yeni logo tasarımı (BİLİMAĞI, biotech ikonu)

**Güncellenen Core:**
- `lib/main.dart` - Welcome flow entegrasyonu, route tanımları

### Fixed

**Türkçe Karakter Düzeltmeleri (settings_screen.dart):**
- "Gorunum" → "Görünüm"
- "Cikis Yap" → "Çıkış Yap"
- "Acik Tema" → "Açık Tema"
- "Sistem Ayari" → "Sistem Ayarı"
- "Iptal" → "İptal"
- "Hesabinizdan..." → "Hesabınızdan..."
- Versiyon: v3.0 → v7.1

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
