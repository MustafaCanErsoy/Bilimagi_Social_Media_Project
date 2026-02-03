# Bilimagi Topluluk Sistemi Dokumantasyonu

**Version:** v7.2
**Son Guncelleme:** 2026-02-03

---

## Genel Bakis

Bilimagi topluluk sistemi, kullanicilarin bilimsel topluluklari olusturmasini, yonetmesini ve etkilesimde bulunmasini saglayan kapsamli bir yapidir.

### Temel Akis

```
Topluluk Olustur → Uye Kabul Et → Hafta Baslat → Makale Oner/Oyla → Tartis
```

---

## 1. Veri Modelleri

### 1.1 Community (community.dart)
**Konum:** `lib/models/community.dart` (~179 satir)

```dart
Community {
  id: String
  name: String
  description: String
  ownerUid: String
  currentWeekId: String?

  // Kategori
  category: CommunityCategory  // physics, biology, chemistry, math, medicine, engineering, psychology, other
  customCategory: String?      // "Diger" secildiginde

  // Gorunum
  iconEmoji: String?          // 24 bilim emojisi
  colorIndex: int             // 10+ renk paleti

  // Meta
  createdAt: DateTime
  isPublic: bool
  isDeleted: bool             // Soft delete

  // Istatistikler
  stats: CommunityStats {
    memberCount: int
    weekCount: int
    totalArticles: int
  }
}
```

### 1.2 CommunityMembership (community_membership.dart)
**Konum:** `lib/models/community_membership.dart` (~132 satir)

```dart
CommunityMembership {
  communityId: String
  uid: String
  displayName: String

  role: MemberRole      // owner | moderator | member
  status: MemberStatus  // pending | approved | rejected

  requestedAt: DateTime
  approvedAt: DateTime?
  approvedByUid: String?
}

// Rol Hiyerarsisi: Owner > Moderator > Member
```

### 1.3 ArticleSuggestion (article_suggestion.dart)
**Konum:** `lib/models/article_suggestion.dart` (~126 satir)

```dart
ArticleSuggestion {
  id: String
  weekId: String

  // Icerik
  title: String
  summary: String
  link: String

  // Basvuran
  submitterUid: String
  submitterDisplayName: String
  createdAt: DateTime

  // Inceleme
  status: SuggestionStatus  // pending | approved | rejected
  interestScore: int        // Ilgi oyu sayisi
  reviewerUid: String?
  reviewedAt: DateTime?
  rejectionReason: String?
}
```

---

## 2. Servisler

### 2.1 CommunityService (community_service.dart)
**Konum:** `lib/services/community_service.dart` (~572 satir)

#### CRUD Operasyonlari
| Metod | Aciklama |
|-------|----------|
| `createCommunity()` | Yeni topluluk olustur (otomatik sahip eklenir) |
| `updateCommunity()` | Topluluk bilgilerini guncelle |
| `deleteCommunity()` | Soft delete (isDeleted = true) |
| `getCommunity()` | Stream ile topluluk getir |
| `getCommunityOnce()` | Tek seferlik topluluk verisi |
| `getPublicCommunities()` | Tum genel topluluklari stream |
| `getUserCommunities()` | Kullanicinin topluluklari |

#### Arama & Filtreleme
| Metod | Aciklama |
|-------|----------|
| `filterCommunities()` | Client-side filtreleme |

**Siralama Secenekleri:**
- `sortByPopular` - Uye sayisina gore
- `sortByNewest` - Olusturma tarihine gore
- `sortByName` - Alfabetik

#### Uyelik Yonetimi
| Metod | Aciklama |
|-------|----------|
| `requestMembership()` | Katilim istegi gonder |
| `approveMembership()` | Isteği onayla + bildirim |
| `rejectMembership()` | Isteği reddet + bildirim |
| `leaveCommunity()` | Topluluktan ayril |
| `removeMember()` | Uyeyi cikar |
| `setMemberRole()` | Rol degistir |

#### Sorgular
| Metod | Aciklama |
|-------|----------|
| `getMembers()` | Onayli uyeleri stream |
| `getPendingMembers()` | Bekleyen istekler |
| `getUserRole()` | Kullanicinin rolu |
| `getMembershipStatus()` | Uyelik durumu |
| `getPendingMemberCount()` | Badge icin sayi |

### 2.2 SuggestionService (suggestion_service.dart)
**Konum:** `lib/services/suggestion_service.dart` (~269 satir)

#### Onerge Yonetimi
| Metod | Aciklama |
|-------|----------|
| `submitSuggestion()` | Makale onerisi gonder |
| `getSuggestions()` | Tum onerileri getir (interestScore sirali) |
| `getPendingSuggestions()` | Bekleyen oneriler |
| `getSuggestion()` | Tek onerge detayi |

#### Onay/Red
| Metod | Aciklama |
|-------|----------|
| `approveSuggestion()` | Onayla → Makaleye donustur |
| `rejectSuggestion()` | Reddet (sebep ile) |

#### Ilgi Oylamasi
| Metod | Aciklama |
|-------|----------|
| `toggleInterest()` | Ilgi ekle/kaldir |
| `hasExpressedInterest()` | Ilgi gosterdi mi? |
| `getInterestCount()` | Ilgi sayisi |

---

## 3. Ekranlar

### 3.1 CommunitySelectScreen (~520 satir)
**Konum:** `lib/screens/community_select_screen.dart`

**2 Sekme:**
1. **Kesfet** - Tum genel topluluklar
   - Arama cubugu
   - Kategori + siralama filtresi
   - Topluluk kartlari

2. **Katildiklarim** - Kullanicinin topluluklari
   - Yonetim erisimi

**Ozellikler:**
- Admin paneline erisim (sag ust)
- Topluluk olusturma FAB
- Filter bottom sheet

### 3.2 CommunityCreateScreen (~282 satir)
**Konum:** `lib/screens/community_create_screen.dart`

**Form Alanlari:**
- Topluluk adi (min 3 karakter)
- Aciklama (min 10 karakter)
- Kategori dropdown
- Ozel kategori (Diger icin)
- Simge & renk secici

**Ozellikler:**
- Canli onizleme karti
- Yukleme durumu

### 3.3 CommunityManageScreen (~200+ satir)
**Konum:** `lib/screens/community_manage_screen.dart`

**Yonetim Ozellikleri:**
- Ad & aciklama guncelle
- Simge/renk degistir
- Yeni hafta baslat
- Uyelik yonetimi linki
- Moderasyon paneli linki
- Topluluk silme

### 3.4 CommunityMembersScreen (~200+ satir)
**Konum:** `lib/screens/community_members_screen.dart`

**2 Sekme:**
1. **Bekleyenler** - Onay bekleyen istekler
   - Onayla/Reddet butonlari

2. **Uyeler** - Onayli uyeler
   - Rol degistirme
   - Uye cikarma

### 3.5 SuggestionScreen (~150+ satir)
**Konum:** `lib/screens/suggestion_screen.dart`

**Form Alanlari:**
- Baslik (5-200 karakter)
- Ozet (20-500 karakter)
- URL (gecerli HTTP/HTTPS)

### 3.6 SuggestionReviewScreen (~150+ satir)
**Konum:** `lib/screens/suggestion_review_screen.dart`

**3 Sekme:**
1. Bekleyen oneriler (badge)
2. Onaylanan oneriler
3. Reddedilen oneriler

---

## 4. Widgetlar

### 4.1 CommunityCard (~226 satir)
**Konum:** `lib/widgets/community_card.dart`

- Topluluk ikonu/emoji
- Ad, aciklama, kategori badge
- Uye sayisi
- Katilim butonu (Katil/Beklemede/Ayril)

### 4.2 CommunityIconPicker (~203 satir)
**Konum:** `lib/widgets/community_icon_picker.dart`

- 24 bilim emojisi secimi
- 10+ renk paleti
- Dialog ile secim

### 4.3 CommunitySearchBar (~75 satir)
**Konum:** `lib/widgets/community_search_bar.dart`

- Debounced arama (300ms)
- Temizleme butonu

### 4.4 SuggestionCard (~279 satir)
**Konum:** `lib/widgets/suggestion_card.dart`

- Basvuran bilgileri
- Statu badge
- Baslik, ozet, link
- Ilgi skoru ve oylama
- Moderator aksiyonlari

### 4.5 MemberListTile (~220 satir)
**Konum:** `lib/widgets/member_list_tile.dart`

- Avatar ve isim
- Rol badge
- Onayla/Reddet (bekleyenler)
- Rol yonetimi menu (uyeler)

---

## 5. Firestore Yapisi

```
communities/{communityId}/
├── name, description, ownerUid
├── category, customCategory, iconEmoji, colorIndex
├── createdAt, isPublic, isDeleted
├── currentWeekId
├── stats: {memberCount, weekCount, totalArticles}
│
├── members/{uid}/
│   ├── role, status, displayName
│   ├── requestedAt, approvedAt, approvedByUid
│
├── bans/{bannedUid}/
│   └── ... (moderasyon)
│
├── moderationLogs/{logId}/
│   └── ... (audit log)
│
└── reports/{reportId}/
    └── ... (raporlar)

weeks/{weekId}/
├── communityId, phase, createdAt
│
├── articles/{articleId}/
│   ├── title, summary, link
│   ├── suggestedByUid?, suggestionId?
│   └── votes...
│
└── suggestions/{suggestionId}/
    ├── title, summary, link
    ├── submitterUid, submitterDisplayName
    ├── status, interestScore
    ├── reviewerUid?, reviewedAt?, rejectionReason?
    │
    └── interests/{uid}/
        └── createdAt
```

---

## 6. Bildirim Turleri

| Tur | Alici | Tetikleyici |
|-----|-------|-------------|
| `membershipRequest` | Sahip/Moderator | Yeni katilim istegi |
| `membershipApproved` | Kullanici | Istek onaylandi |
| `membershipRejected` | Kullanici | Istek reddedildi |
| `suggestionApproved` | Oneren | Oneri onaylandi |
| `suggestionRejected` | Oneren | Oneri reddedildi |
| `roleChanged` | Uye | Rol degistirildi |
| `memberRemoved` | Uye | Topluluktan cikarildi |

---

## 7. Mevcut Kisitlamalar & Gelecek Iyilestirmeler

### Mevcut Kisitlamalar

1. **Topluluk Olusturma**
   - Herkes topluluk olusturabilir (limit yok)
   - Benzer isim kontrolu yok

2. **Uyelik**
   - Sadece "onay gerekli" modu var
   - Acik katilim secenegi yok

3. **Makale Sistemi**
   - Sadece link paylasimi
   - Gorsel/dosya yukleme yok
   - Makale duzenlenemiyor

4. **Hafta Yonetimi**
   - Manuel faz degisimi
   - Otomatik zamanlama yok

5. **Moderasyon**
   - Temel ban/gizleme
   - Gecici ban yok
   - Uyari sistemi yok

### Potansiyel Iyilestirmeler

1. **Topluluk**
   - Kapak fotografı
   - Acik/kapali katilim secenegi
   - Topluluk kurallari sayfasi
   - Davet linki sistemi

2. **Uyelik**
   - Uye rozetleri/seviyeleri
   - Katki puanlari
   - Aktiflik istatistikleri

3. **Makale**
   - Gorsel yukleme
   - Zengin metin editoru
   - Makale duzenle/guncelle
   - Taslak sistemi

4. **Hafta/Faz**
   - Otomatik faz gecisi
   - Programlanmis haftalar
   - Arsiv gorunumu

5. **Etkilesim**
   - Topluluk duyurulari
   - Pinned yazilar
   - Anketler

---

## 8. Dosya Haritasi

```
lib/
├── models/
│   ├── community.dart           # Topluluk modeli
│   ├── community_membership.dart # Uyelik modeli
│   └── article_suggestion.dart  # Onerge modeli
│
├── services/
│   ├── community_service.dart   # Topluluk CRUD + uyelik
│   └── suggestion_service.dart  # Onerge yonetimi
│
├── screens/
│   ├── community_select_screen.dart  # Kesfet/Katildiklarim
│   ├── community_create_screen.dart  # Topluluk olustur
│   ├── community_manage_screen.dart  # Topluluk yonet
│   ├── community_members_screen.dart # Uye yonetimi
│   ├── suggestion_screen.dart        # Onerge gonder
│   └── suggestion_review_screen.dart # Onerge incele
│
└── widgets/
    ├── community_card.dart        # Topluluk karti
    ├── community_icon_picker.dart # Simge/renk secici
    ├── community_search_bar.dart  # Arama cubugu
    ├── suggestion_card.dart       # Onerge karti
    └── member_list_tile.dart      # Uye liste ogesi
```

---

**Son Guncelleme:** 2026-02-03
