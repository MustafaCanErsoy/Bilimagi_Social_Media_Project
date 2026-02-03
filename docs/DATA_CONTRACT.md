# Bilimagi Data Contract

**Version:** v9.0
**Last Updated:** 2026-02-03

Bu dosya Firestore veritabanı şemasını ve veri akışlarını detaylı şekilde açıklar.

---

## Koleksiyon Yapısı Özeti

```
firestore/
├── users/{uid}/
│   ├── following/{targetUid}/
│   ├── followers/{followerUid}/
│   ├── notifications/{notificationId}/
│   ├── savedArticles/{articleId}/
│   └── activities/{activityId}/              [v6.0]
├── communities/{communityId}/
│   ├── members/{uid}/
│   ├── bans/{bannedUid}/                     [v6.0]
│   ├── moderationLogs/{logId}/               [v6.0]
│   └── reports/{reportId}/                   [v6.1]
└── periods/{periodId}/                       [v9.0 - eskiden weeks]
    ├── articles/{articleId}/
    │   ├── votes/{uid}/
    │   └── comments/{commentId}/
    │       └── votes/{uid}/
    └── suggestions/{suggestionId}/           [v5.0]
        └── interests/{uid}/                  [v5.0]
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
| `avatarColorIndex` | number? | Avatar renk indeksi (0-9) |
| `interests` | string[] | Ilgi alanlari ['physics', 'biology', ...] [v7.2] |
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
| `periodId` | string? | İlgili dönem ID'si [v9.0] |
| `articleId` | string? | İlgili makale ID'si |
| `preview` | string? | Önizleme metni |
| `communityId` | string? | İlgili topluluk ID'si |
| `communityName` | string? | Topluluk adı |
| `newRole` | string? | Yeni rol (roleChanged için) [v6.0] |

**Bildirim Türleri (type):**
| Değer | Açıklama | Versiyon |
|-------|----------|----------|
| `follow` | Birisi seni takip etti | v1.0 |
| `mention` | Birisi senden bahsetti | v3.0 |
| `reply` | Birisi yorumuna yanıt verdi | v3.0 |
| `upvote` | Birisi yorumunu beğendi | v3.0 |
| `membershipRequest` | Birisi topluluğuna katılmak istiyor | v5.0 |
| `membershipApproved` | Üyelik başvurun onaylandı | v5.0 |
| `membershipRejected` | Üyelik başvurun reddedildi | v5.0 |
| `suggestionApproved` | Makale önerin onaylandı | v5.0 |
| `suggestionRejected` | Makale önerin reddedildi | v5.0 |
| `roleChanged` | Topluluktaki rolün değişti | v6.0 |
| `memberRemoved` | Topluluktan çıkarıldın | v6.0 |

---

### users/{uid}/savedArticles/{articleId}
Kaydedilen makaleler (denormalize).

| Alan | Tip | Açıklama |
|------|-----|----------|
| `title` | string | Makale başlığı |
| `summary` | string | Makale özeti |
| `periodId` | string | Dönem ID'si [v9.0] |
| `savedAt` | timestamp | Kaydetme tarihi |

---

### users/{uid}/activities/{activityId} [v6.0]
Kullanıcı aktiviteleri (takip akışı için).

| Alan | Tip | Açıklama |
|------|-----|----------|
| `uid` | string | Kullanıcı ID'si |
| `displayName` | string | Görünen isim |
| `avatarColorIndex` | number | Avatar renk indeksi |
| `type` | string | Aktivite türü (aşağıda) |
| `targetType` | string | Hedef türü (aşağıda) |
| `targetId` | string | Hedef ID'si |
| `targetName` | string? | Hedef adı |
| `periodId` | string? | İlgili dönem ID'si [v9.0] |
| `communityId` | string? | İlgili topluluk ID'si |
| `communityName` | string? | Topluluk adı |
| `preview` | string? | Önizleme metni |
| `createdAt` | timestamp | Aktivite zamanı |

**Aktivite Türleri (type):**
| Değer | Açıklama |
|-------|----------|
| `comment` | Yorum yaptı |
| `vote` | Oy verdi |
| `join` | Topluluğa katıldı |
| `suggestion` | Makale önerdi |

**Hedef Türleri (targetType):**
| Değer | Açıklama |
|-------|----------|
| `article` | Makale |
| `community` | Topluluk |
| `user` | Kullanıcı |

---

## 2. Communities Koleksiyonu

### communities/{communityId}
Topluluk bilgileri.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `name` | string | Topluluk adı |
| `description` | string | Açıklama |
| `ownerUid` | string | Sahip kullanıcı ID'si |
| `currentPeriodId` | string? | Aktif dönem ID'si [v9.0] |
| `category` | string | Kategori kodu |
| `customCategory` | string? | Özel kategori adı |
| `iconEmoji` | string? | Simge emoji |
| `colorIndex` | number | Renk indeksi 0-7 |
| `coverPhotoURL` | string? | Kapak fotoğrafı URL'i [v8.0] |
| `rules` | string? | Topluluk kuralları (Markdown) [v8.0] |
| `joinType` | string | "open" \| "approval" [v8.0] |
| `createdAt` | timestamp | Oluşturulma tarihi |
| `isPublic` | boolean | Herkese açık mı? |
| `isDeleted` | boolean | Silindi mi? (soft delete) [v6.0] |
| `stats` | map | İstatistikler |

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

**colorIndex değerleri:**
| İndeks | Renk |
|--------|------|
| 0 | Mavi (#2196F3) |
| 1 | Yeşil (#4CAF50) |
| 2 | Turuncu (#FF9800) |
| 3 | Mor (#9C27B0) |
| 4 | Kırmızı (#F44336) |
| 5 | Turkuaz (#00BCD4) |
| 6 | Pembe (#E91E63) |
| 7 | Kahverengi (#795548) |

**stats alt alanları:**
| Alan | Tip | Açıklama |
|------|-----|----------|
| `memberCount` | number | Üye sayısı |
| `periodCount` | number | Toplam dönem sayısı [v9.0] |
| `totalArticles` | number | Toplam makale sayısı |

---

### communities/{communityId}/members/{uid}
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
| `moderator` | Öneri onaylama, üye kabul/red, üye çıkarma, yorum gizleme, kullanıcı banlama |
| `member` | Oylama, yorum yapma, makale önerme |

---

### communities/{communityId}/bans/{bannedUid} [v6.0]
Yasaklı kullanıcılar.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `bannedUid` | string | Yasaklanan kullanıcı ID'si |
| `bannedDisplayName` | string | Yasaklanan kullanıcı adı |
| `bannedByUid` | string | Yasaklayan moderatör ID'si |
| `bannedByDisplayName` | string | Yasaklayan moderatör adı |
| `bannedAt` | timestamp | Yasaklanma tarihi |
| `expiresAt` | timestamp? | Yasak bitiş tarihi (null = kalıcı) |
| `reason` | string | Yasaklanma sebebi |

---

### communities/{communityId}/moderationLogs/{logId} [v6.0]
Moderasyon işlem geçmişi (audit log).

| Alan | Tip | Açıklama |
|------|-----|----------|
| `type` | string | İşlem türü (aşağıda) |
| `moderatorUid` | string | İşlemi yapan moderatör ID'si |
| `moderatorDisplayName` | string | Moderatör adı |
| `targetUid` | string? | Hedef kullanıcı ID'si |
| `targetDisplayName` | string? | Hedef kullanıcı adı |
| `targetId` | string? | Hedef içerik ID'si (yorum vb.) |
| `reason` | string? | İşlem sebebi |
| `details` | string? | Ek detaylar |
| `createdAt` | timestamp | İşlem zamanı |

**Moderasyon İşlem Türleri (type):**
| Değer | Açıklama |
|-------|----------|
| `hideComment` | Yorum gizlendi |
| `unhideComment` | Yorum görünür yapıldı |
| `banUser` | Kullanıcı yasaklandı |
| `unbanUser` | Kullanıcı yasağı kaldırıldı |
| `changeRole` | Kullanıcı rolü değiştirildi |
| `removeMember` | Kullanıcı topluluktan çıkarıldı |
| `approveMember` | Üyelik onaylandı |
| `rejectMember` | Üyelik reddedildi |
| `approveSuggestion` | Öneri onaylandı |
| `rejectSuggestion` | Öneri reddedildi |

---

### communities/{communityId}/reports/{reportId} [v6.1]
Kullanıcı raporları.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `reporterUid` | string | Raporlayan kullanıcı ID'si |
| `reporterDisplayName` | string | Raporlayan kullanıcı adı |
| `type` | string | "comment" \| "user" |
| `targetId` | string | Hedef ID'si (commentId veya uid) |
| `targetUid` | string | Hedef kullanıcı ID'si |
| `targetDisplayName` | string? | Hedef kullanıcı adı |
| `periodId` | string? | İlgili dönem ID'si [v9.0] |
| `articleId` | string? | İlgili makale ID'si |
| `reason` | string | Rapor sebebi (aşağıda) |
| `details` | string? | Ek detaylar |
| `status` | string | "pending" \| "reviewed" \| "dismissed" |
| `createdAt` | timestamp | Rapor zamanı |
| `reviewedByUid` | string? | İnceleyen moderatör |
| `reviewedAt` | timestamp? | İnceleme zamanı |
| `reviewNote` | string? | İnceleme notu |

**Rapor Sebepleri (reason):**
| Değer | Türkçe |
|-------|--------|
| `spam` | Spam |
| `harassment` | Taciz / Zorbalık |
| `inappropriate` | Uygunsuz İçerik |
| `misinformation` | Yanlış Bilgi |
| `other` | Diğer |

---

## 3. Periods Koleksiyonu [v9.0]

### periods/{periodId}
Esnek tartışma dönemleri (eski: weeks).

| Alan | Tip | Açıklama |
|------|-----|----------|
| `communityId` | string | Ait olduğu topluluk |
| `title` | string | Dönem başlığı (örn: "Ocak 2026 Tartışması") |
| `description` | string? | Dönem açıklaması |
| `phase` | string | "voting" \| "discussion" \| "closed" |
| `startDate` | timestamp? | Başlangıç tarihi (opsiyonel) |
| `endDate` | timestamp? | Bitiş tarihi (opsiyonel) |
| `minVotesForDiscussion` | number | Tartışma için minimum oy (varsayılan: 1) |
| `createdAt` | timestamp | Oluşturulma tarihi |
| `phaseChangedAt` | timestamp? | Son faz değişikliği zamanı |
| `phaseChangedByUid` | string? | Faz değiştiren kullanıcı |

**Faz Akışı:**
```
voting → discussion → closed
   ↑_________|  (yeni dönem ile)
```

**v9.0 Yenilikler:**
- Esnek dönemler (takvime bağlı değil)
- Başlık ve açıklama desteği
- minVotesForDiscussion ile tartışma eşiği
- Çoklu makale tartışması

---

### periods/{periodId}/articles/{articleId}
Dönem makaleleri.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `title` | string | Makale başlığı |
| `summary` | string | Özet |
| `link` | string | Makale URL'i |
| `heroImageURL` | string? | Hero görsel URL'i [v8.0] |
| `content` | string? | Makale içeriği (Markdown) [v8.0] |
| `voteCount` | number | Toplam oy sayısı (cached) |
| `isEligibleForDiscussion` | boolean | Tartışmaya uygun mu? [v9.0] |
| `suggestedByUid` | string? | Öneren kullanıcı |
| `suggestedByDisplayName` | string? | Öneren ismi |
| `suggestionId` | string? | Kaynak öneri ID'si |
| `createdAt` | timestamp? | Oluşturulma tarihi |

---

### periods/{periodId}/articles/{articleId}/votes/{uid} [v9.0]
Makale oyları (çoklu oylama destekli).

| Alan | Tip | Açıklama |
|------|-----|----------|
| `votedAt` | timestamp | Oy zamanı |

**v9.0 Değişiklikler:**
- Artık her makale için ayrı oy kaydı
- Kullanıcı birden fazla makaleye oy verebilir (toggle)
- `choice` alanı kaldırıldı

---

### periods/{periodId}/articles/{articleId}/comments/{commentId}
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
| `isPinned` | boolean? | Sabitlendi mi? [v8.0] |
| `pinnedByUid` | string? | Sabitleyen kullanıcı [v8.0] |
| `pinnedAt` | timestamp? | Sabitleme zamanı [v8.0] |
| `isHidden` | boolean? | Moderatör tarafından gizlendi mi? [v6.0] |
| `hiddenByUid` | string? | Gizleyen moderatör ID'si [v6.0] |
| `hiddenAt` | timestamp? | Gizlenme zamanı [v6.0] |
| `hiddenReason` | string? | Gizleme sebebi [v6.0] |

**@mention formatı:**
```
@[Kullanıcı Adı](userId)
```

---

### periods/{periodId}/articles/{articleId}/comments/{commentId}/votes/{uid}
Yorum oyları.

| Alan | Tip | Açıklama |
|------|-----|----------|
| `value` | number | 1 (upvote) veya -1 (downvote) |
| `createdAt` | timestamp | Oy zamanı |

---

### periods/{periodId}/suggestions/{suggestionId}
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

### periods/{periodId}/suggestions/{suggestionId}/interests/{uid}
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

### Aktif Tartışmalar (Home Feed) [v9.0]
```dart
collection('periods')
  .where('phase', isEqualTo: 'discussion')
  .limit(20)
// + client-side: community.isDeleted == false filtresi
```

### Oylama Fazındaki Dönemler [v9.0]
```dart
collection('periods')
  .where('phase', isEqualTo: 'voting')
// + client-side: community.isDeleted == false filtresi
```

### Kullanıcının Oyladığı Makaleler (Dönem içinde) [v9.0]
```dart
collection('periods/{periodId}/articles')
  .get()
// Her makale için:
collection('periods/{periodId}/articles/{articleId}/votes')
  .doc(uid)
  .get()
// Set<String> olarak döndür
```

### Tartışmaya Uygun Makaleler [v9.0]
```dart
collection('periods/{periodId}/articles')
  .where('isEligibleForDiscussion', isEqualTo: true)
```

### Bekleyen Öneriler
```dart
collection('periods/{periodId}/suggestions')
  .where('status', isEqualTo: 'pending')
```

### Public Topluluklar (Silinmemiş) [v6.0]
```dart
collection('communities')
  .where('isPublic', isEqualTo: true)
// + client-side: isDeleted == false filtresi
```

### Topluluk Arama (Client-side) [v6.0]
```dart
// Tüm public topluluklar alınır, sonra filtrelenir:
communities.where((c) =>
  c.name.toLowerCase().contains(query) ||
  c.description.toLowerCase().contains(query) ||
  c.category.contains(query)
)
```

### Yasaklı Kullanıcılar [v6.0]
```dart
collection('communities/{id}/bans')
  .orderBy('bannedAt', descending: true)
```

### Moderasyon Logları [v6.0]
```dart
collection('communities/{id}/moderationLogs')
  .orderBy('createdAt', descending: true)
  .limit(50)
```

### Takip Edilen Aktiviteler [v6.0]
```dart
// Her takip edilen için:
collection('users/{followedUid}/activities')
  .orderBy('createdAt', descending: true)
  .limit(10)
// Sonra client-side merge ve sıralama
```

---

## Firestore Güvenlik Kuralları (Özet)

```javascript
// Kullanıcılar
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;
}

// Aktiviteler
match /users/{userId}/activities/{activityId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;
}

// Topluluklar
match /communities/{communityId} {
  allow read: if resource.data.isPublic == true;
  allow create: if request.auth != null;
  allow update: if isOwnerOrMod(communityId);
  allow delete: if isOwner(communityId);
}

// Üyelikler
match /communities/{communityId}/members/{uid} {
  allow read: if request.auth != null;
  allow create: if request.auth.uid == uid; // Kendi başvurusu
  allow update: if isOwnerOrMod(communityId);
  allow delete: if isOwnerOrMod(communityId);
}

// Banlar [v6.0]
match /communities/{communityId}/bans/{bannedUid} {
  allow read: if request.auth != null;
  allow write: if isOwnerOrMod(communityId);
}

// Moderasyon Logları [v6.0]
match /communities/{communityId}/moderationLogs/{logId} {
  allow read: if isOwnerOrMod(communityId);
  allow create: if isOwnerOrMod(communityId);
}

// Raporlar [v6.1]
match /communities/{communityId}/reports/{reportId} {
  allow read: if isOwnerOrMod(communityId);
  allow create: if request.auth != null;
  allow update: if isOwnerOrMod(communityId);
}

// Dönemler [v9.0]
match /periods/{periodId} {
  allow read: if request.auth != null;
  allow create: if isOwnerOrMod(periodId);
  allow update: if isOwnerOrMod(periodId);
}

// Öneriler
match /periods/{periodId}/suggestions/{suggestionId} {
  allow read: if request.auth != null;
  allow create: if isMember(periodId);
  allow update: if isOwnerOrMod(periodId);
}

// Yorumlar (gizleme için) [v6.0]
match /periods/{periodId}/articles/{articleId}/comments/{commentId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null;
  allow update: if request.auth.uid == resource.data.uid || isOwnerOrMod(periodId);
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

### Çoklu Oylama Akışı [v9.0]
```
Kullanıcı                    Sistem
    |                          |
    |-- Makale 1'e oy ver ---> |
    |                          |-- votes/{uid} oluştur
    |                          |-- voteCount++
    |                          |
    |-- Makale 2'ye oy ver --> |
    |                          |-- votes/{uid} oluştur
    |                          |-- voteCount++
    |                          |
    |-- Makale 1 oyu geri al-> |
    |                          |-- votes/{uid} sil
    |                          |-- voteCount--
```

### Faz Geçişi Akışı [v9.0]
```
Moderatör                    Sistem
    |                          |
    |-- Tartışma fazına geç -> |
    |                          |-- phase = 'discussion'
    |                          |-- Her makale için:
    |                          |   if voteCount >= minVotes:
    |                          |     isEligibleForDiscussion = true
    |                          |-- phaseChangedAt = now
    |                          |-- phaseChangedByUid = mod
```

### Yorum Gizleme Akışı [v6.0]
```
Moderatör                    Sistem                     Kullanıcı
    |                          |                           |
    |-- Yorumu gizle --------> |                           |
    |                          |-- isHidden = true         |
    |                          |-- hiddenByUid = mod       |
    |                          |-- Audit log kaydet        |
    |                          |                           |
    |                          |-- [Yorum gizli görünür] ->|
```

### Kullanıcı Banlama Akışı [v6.0]
```
Moderatör                    Sistem                     Kullanıcı
    |                          |                           |
    |-- Kullanıcıyı banla ---> |                           |
    |                          |-- Ban kaydı oluştur       |
    |                          |-- Üyelikten çıkar         |
    |                          |-- Audit log kaydet        |
    |                          |-- Bildirim gönder ------->|
```

---

## Index Gereksinimleri

Firestore composite index gerektiren sorgular:

| Koleksiyon | Alanlar | Sıralama |
|------------|---------|----------|
| `members` (collectionGroup) | `uid`, `status` | - |
| `suggestions` | `status`, `interestScore` | DESC |
| `activities` | `uid`, `createdAt` | DESC |
| `moderationLogs` | `communityId`, `createdAt` | DESC |
| `bans` | `communityId`, `bannedAt` | DESC |
| `periods` | `phase`, `createdAt` | DESC |
| `articles` | `isEligibleForDiscussion`, `voteCount` | DESC |

---

## Enum Değerleri Özeti

### NotificationType
```dart
enum NotificationType {
  follow,            // v1.0
  mention,           // v3.0
  reply,             // v3.0
  upvote,            // v3.0
  membershipRequest, // v5.0
  membershipApproved,// v5.0
  membershipRejected,// v5.0
  suggestionApproved,// v5.0
  suggestionRejected,// v5.0
  roleChanged,       // v6.0
  memberRemoved,     // v6.0
}
```

### MemberRole
```dart
enum MemberRole {
  owner,
  moderator,
  member,
}
```

### MemberStatus
```dart
enum MemberStatus {
  pending,
  approved,
  rejected,
}
```

### PeriodPhase [v9.0]
```dart
enum PeriodPhase {
  voting,
  discussion,
  closed,
}
```

### SuggestionStatus
```dart
enum SuggestionStatus {
  pending,
  approved,
  rejected,
}
```

### ActivityType [v6.0]
```dart
enum ActivityType {
  comment,
  vote,
  join,
  suggestion,
}
```

### ModerationActionType [v6.0]
```dart
enum ModerationActionType {
  hideComment,
  unhideComment,
  banUser,
  unbanUser,
  changeRole,
  removeMember,
  approveMember,
  rejectMember,
  approveSuggestion,
  rejectSuggestion,
}
```

### ReportType [v6.1]
```dart
enum ReportType {
  comment,
  user,
}
```

### ReportStatus [v6.1]
```dart
enum ReportStatus {
  pending,
  reviewed,
  dismissed,
}
```

### ReportReason [v6.1]
```dart
class ReportReason {
  static const spam = 'spam';
  static const harassment = 'harassment';
  static const inappropriate = 'inappropriate';
  static const misinformation = 'misinformation';
  static const other = 'other';
}
```

### CommunityCategory
```dart
class CommunityCategory {
  static const physics = 'physics';
  static const biology = 'biology';
  static const chemistry = 'chemistry';
  static const mathematics = 'mathematics';
  static const medicine = 'medicine';
  static const engineering = 'engineering';
  static const psychology = 'psychology';
  static const other = 'other';
}
```

### JoinType [v8.0]
```dart
enum JoinType {
  open,      // Onaysız katılım
  approval,  // Onay gerekli
}
```

### InterestCategory [v7.2]
```dart
class InterestCategory {
  static const labels = {
    'physics': 'Fizik',
    'biology': 'Biyoloji',
    'chemistry': 'Kimya',
    'mathematics': 'Matematik',
    'medicine': 'Tip',
    'engineering': 'Muhendislik',
    'psychology': 'Psikoloji',
    'astronomy': 'Astronomi',
    'ecology': 'Ekoloji',
    'computer_science': 'Bilgisayar Bilimi',
    'neuroscience': 'Noroloji',
    'genetics': 'Genetik',
    'climate': 'Iklim Bilimi',
    'artificial_intelligence': 'Yapay Zeka',
    'quantum': 'Kuantum Fizigi',
  };
  static const maxSelection = 5;
}
```

---

## Firebase Storage

### Profil Fotograflari [v7.2]
**Path:** `users/{uid}/profile_photo.jpg`

| Metadata | Deger |
|----------|-------|
| contentType | image/jpeg |
| maxWidth | 512px |
| maxHeight | 512px |
| quality | 85% |

### Topluluk Kapak Fotograflari [v8.0]
**Path:** `communities/{communityId}/cover_photo.jpg`

| Metadata | Deger |
|----------|-------|
| contentType | image/jpeg |
| maxWidth | 1200px |
| maxHeight | 600px |
| quality | 85% |

### Makale Hero Gorselleri [v8.0]
**Path:** `periods/{periodId}/articles/{articleId}/hero_image.jpg`

| Metadata | Deger |
|----------|-------|
| contentType | image/jpeg |
| maxWidth | 1200px |
| maxHeight | 675px |
| quality | 85% |

---

**Son Guncelleme:** 2026-02-03 (v9.0 - Period Sistemi)
