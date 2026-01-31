# Bilimagi Data Contract

**Version:** v5.0
**Last Updated:** 2026-02-01

Bu dosya Firestore veritabanı şemasını ve veri akışlarını detaylı şekilde açıklar.

---

## Koleksiyon Yapısı Özeti

```
firestore/
├── users/{uid}/
│   ├── following/{targetUid}/
│   ├── followers/{followerUid}/
│   ├── notifications/{notificationId}/
│   └── savedArticles/{articleId}/
├── communities/{communityId}/
│   └── members/{uid}/
└── weeks/{weekId}/
    ├── articles/{articleId}/
    │   ├── votes/{uid}/
    │   └── comments/{commentId}/
    │       └── votes/{uid}/
    └── suggestions/{suggestionId}/        [v5.0]
        └── interests/{uid}/               [v5.0]
```

---

## 1. Users Koleksiyonu

### users/{uid}
Kullanıcı profil bilgileri.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `displayName` | string | Görünen isim |
| `email` | string | E-posta adresi |
| `photoURL` | string? | Profil fotoğrafı URL'i |
| `bio` | string? | Kullanıcı biyografisi |
| `role` | string | "admin" \| "member" |
| `createdAt` | timestamp | Hesap oluşturma tarihi |
| `stats` | map | İstatistikler (aşağıda) |

**stats alt alanları:**
| Alan | Tip | Açıklama |
|------|-----|----------|
| `totalVotes` | number | Toplam verilen oy |
| `totalComments` | number | Toplam yorum sayısı |
| `followersCount` | number | Takipçi sayısı |
| `followingCount` | number | Takip edilen sayısı |
| `joinedAt` | timestamp | Katılım tarihi |

---

### users/{uid}/following/{targetUid}
Kullanıcının takip ettiği kişiler.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `followedAt` | timestamp | Takip başlangıç tarihi |

---

### users/{uid}/followers/{followerUid}
Kullanıcıyı takip edenler.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `followedAt` | timestamp | Takip başlangıç tarihi |

---

### users/{uid}/notifications/{notificationId}
Kullanıcı bildirimleri.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `type` | string | Bildirim türü (aşağıda) |
| `fromUid` | string | Bildirimi tetikleyen kullanıcı |
| `fromDisplayName` | string | Kullanıcı görünen ismi |
| `read` | boolean | Okundu mu? |
| `createdAt` | timestamp | Oluşturulma tarihi |
| `targetId` | string? | Hedef yorum ID'si |
| `weekId` | string? | İlgili hafta ID'si |
| `articleId` | string? | İlgili makale ID'si |
| `preview` | string? | Önizleme metni |
| `communityId` | string? | İlgili topluluk ID'si (v5.0) |
| `communityName` | string? | Topluluk adı (v5.0) |

**Bildirim Türleri (type):**
| Değer | Açıklama |
|-------|----------|
| `follow` | Birisi seni takip etti |
| `mention` | Birisi senden bahsetti |
| `reply` | Birisi yorumuna yanıt verdi |
| `upvote` | Birisi yorumunu beğendi |
| `membershipRequest` | Birisi topluluğuna katılmak istiyor (v5.0) |
| `membershipApproved` | Üyelik başvurun onaylandı (v5.0) |
| `membershipRejected` | Üyelik başvurun reddedildi (v5.0) |
| `suggestionApproved` | Makale önerin onaylandı (v5.0) |
| `suggestionRejected` | Makale önerin reddedildi (v5.0) |

---

### users/{uid}/savedArticles/{articleId}
Kaydedilen makaleler (denormalize).

| Alan | Tip | Açıklama |
|------|-----|----------|
| `title` | string | Makale başlığı |
| `summary` | string | Makale özeti |
| `weekId` | string | Hafta ID'si |
| `savedAt` | timestamp | Kaydetme tarihi |

---

## 2. Communities Koleksiyonu

### communities/{communityId}
Topluluk bilgileri.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `name` | string | Topluluk adı |
| `description` | string | Açıklama |
| `ownerUid` | string | Sahip kullanıcı ID'si |
| `currentWeekId` | string? | Aktif hafta ID'si |
| `category` | string | Kategori kodu (v5.0) |
| `customCategory` | string? | Özel kategori adı (v5.0) |
| `iconEmoji` | string? | Simge emoji (v5.0) |
| `colorIndex` | number | Renk indeksi 0-7 (v5.0) |
| `createdAt` | timestamp | Oluşturulma tarihi (v5.0) |
| `isPublic` | boolean | Herkese açık mı? (v5.0) |
| `stats` | map | İstatistikler (v5.0) |

**category değerleri:**
| Kod | Türkçe |
|-----|--------|
| `physics` | Fizik |
| `biology` | Biyoloji |
| `chemistry` | Kimya |
| `mathematics` | Matematik |
| `medicine` | Tıp |
| `engineering` | Mühendislik |
| `psychology` | Psikoloji |
| `other` | Diğer (customCategory kullanılır) |

**stats alt alanları:**
| Alan | Tip | Açıklama |
|------|-----|----------|
| `memberCount` | number | Üye sayısı |
| `weekCount` | number | Toplam hafta sayısı |
| `totalArticles` | number | Toplam makale sayısı |

---

### communities/{communityId}/members/{uid} [v5.0]
Topluluk üyeleri.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `uid` | string | Kullanıcı ID'si |
| `displayName` | string | Görünen isim |
| `role` | string | "owner" \| "moderator" \| "member" |
| `status` | string | "pending" \| "approved" \| "rejected" |
| `requestedAt` | timestamp | Başvuru tarihi |
| `approvedAt` | timestamp? | Onay tarihi |
| `approvedByUid` | string? | Onaylayan kullanıcı |

**Rol Yetkileri:**
| Rol | Yetkiler |
|-----|----------|
| `owner` | Tüm yetkiler, topluluğu silme, moderatör atama |
| `moderator` | Öneri onaylama, üye kabul/red, üye çıkarma |
| `member` | Oylama, yorum yapma, makale önerme |

---

## 3. Weeks Koleksiyonu

### weeks/{weekId}
Haftalık oylama/tartışma döngüsü.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `communityId` | string | Ait olduğu topluluk |
| `phase` | string | "voting" \| "discussion" \| "closed" |
| `createdAt` | timestamp | Oluşturulma tarihi |
| `lastVoteAt` | timestamp? | Son oy zamanı (stream trigger) |

**Faz Akışı:**
```
voting → discussion → closed
   ↑_________|  (yeni hafta ile)
```

---

### weeks/{weekId}/articles/{articleId}
Haftalık makaleler.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `title` | string | Makale başlığı |
| `summary` | string | Özet |
| `link` | string | Makale URL'i |
| `suggestedByUid` | string? | Öneren kullanıcı (v5.0) |
| `suggestedByDisplayName` | string? | Öneren ismi (v5.0) |
| `suggestionId` | string? | Kaynak öneri ID'si (v5.0) |
| `createdAt` | timestamp? | Oluşturulma tarihi |

---

### weeks/{weekId}/articles/{articleId}/votes/{uid}
Makale oyları.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `choice` | string | Seçilen makale ID'si |
| `weekId` | string | Hafta ID'si |
| `updatedAt` | timestamp | Oy zamanı |

---

### weeks/{weekId}/articles/{articleId}/comments/{commentId}
Makale yorumları.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `uid` | string | Yorum sahibi |
| `displayName` | string | Görünen isim |
| `text` | string | Yorum metni |
| `createdAt` | timestamp | Oluşturulma tarihi |
| `parentId` | string? | Üst yorum ID'si (yanıt için) |
| `depth` | number | Yuvalama derinliği (0, 1, 2...) |
| `replyCount` | number | Yanıt sayısı |
| `upvoteCount` | number | Beğeni sayısı |
| `downvoteCount` | number | Beğenmeme sayısı |
| `score` | number | upvoteCount - downvoteCount |
| `isEdited` | boolean? | Düzenlendi mi? |
| `editedAt` | timestamp? | Düzenleme zamanı |
| `isDeleted` | boolean? | Silindi mi? (soft delete) |

**@mention formatı:**
```
@[Kullanıcı Adı](userId)
```

---

### weeks/{weekId}/articles/{articleId}/comments/{commentId}/votes/{uid}
Yorum oyları.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `value` | number | 1 (upvote) veya -1 (downvote) |
| `createdAt` | timestamp | Oy zamanı |

---

### weeks/{weekId}/suggestions/{suggestionId} [v5.0]
Makale önerileri.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `title` | string | Makale başlığı |
| `summary` | string | Özet |
| `link` | string | Makale URL'i |
| `submitterUid` | string | Öneren kullanıcı |
| `submitterDisplayName` | string | Öneren ismi |
| `createdAt` | timestamp | Gönderilme tarihi |
| `status` | string | "pending" \| "approved" \| "rejected" |
| `interestScore` | number | İlgi oyu sayısı |
| `reviewerUid` | string? | İnceleyen moderatör |
| `reviewedAt` | timestamp? | İnceleme zamanı |
| `rejectionReason` | string? | Red sebebi |

---

### weeks/{weekId}/suggestions/{suggestionId}/interests/{uid} [v5.0]
Öneri ilgi oyları.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `createdAt` | timestamp | Oy zamanı |

---

## Sorgu Kalıpları

### Kullanıcının Üye Olduğu Topluluklar
```dart
collectionGroup('members')
  .where('uid', isEqualTo: userId)
  .where('status', isEqualTo: 'approved')
```

### Bekleyen Üyelik İstekleri
```dart
collection('communities/{id}/members')
  .where('status', isEqualTo: 'pending')
```

### Aktif Tartışmalar (Home Feed)
```dart
collection('weeks')
  .where('phase', isEqualTo: 'discussion')
  .limit(20)
```

### Oylama Fazındaki Haftalar
```dart
collection('weeks')
  .where('phase', isEqualTo: 'voting')
```

### Bekleyen Öneriler
```dart
collection('weeks/{weekId}/suggestions')
  .where('status', isEqualTo: 'pending')
```

---

## Firestore Güvenlik Kuralları (Özet)

```javascript
// Kullanıcılar
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;
}

// Topluluklar
match /communities/{communityId} {
  allow read: if resource.data.isPublic == true;
  allow create: if request.auth != null;
  allow update: if isOwnerOrMod(communityId);
}

// Üyelikler
match /communities/{communityId}/members/{uid} {
  allow read: if request.auth != null;
  allow create: if request.auth.uid == uid; // Kendi başvurusu
  allow update: if isOwnerOrMod(communityId);
}

// Öneriler
match /weeks/{weekId}/suggestions/{suggestionId} {
  allow read: if request.auth != null;
  allow create: if isMember(weekId);
  allow update: if isOwnerOrMod(weekId);
}
```

---

## Veri Akış Diyagramları

### Üyelik Başvuru Akışı
```
Kullanıcı                    Sistem                     Owner/Mod
    |                          |                           |
    |-- Katıl isteği --------> |                           |
    |                          |-- Kaydet (pending) -----> |
    |                          |-- Bildirim gönder ------> |
    |                          |                           |
    |                          | <-- Onayla/Reddet --------|
    |                          |-- Durum güncelle          |
    | <-- Bildirim ----------- |                           |
```

### Makale Önerisi Akışı
```
Üye                          Sistem                     Moderatör
 |                              |                           |
 |-- Öneri gönder ------------> |                           |
 |                              |-- Kaydet (pending)        |
 |                              |                           |
 |-- İlgi oyu ver ------------> |-- interestScore++        |
 |                              |                           |
 |                              | <-- Onayla ---------------|
 |                              |-- Article oluştur         |
 |                              |-- stats.totalArticles++   |
 | <-- Bildirim --------------- |                           |
```

---

## Index Gereksinimleri

Firestore composite index gerektiren sorgular:

| Koleksiyon | Alanlar | Sıralama |
|------------|---------|----------|
| `members` (collectionGroup) | `uid`, `status` | - |
| `suggestions` | `status`, `interestScore` | DESC |

---

**Son Güncelleme:** 2026-02-01 (v5.0)
