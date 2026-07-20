# Composants — Specs détaillées

## FeedItem (écran principal vidéo)

```
┌─────────────────────────────────┐  ← plein écran (100vw × 100vh)
│  [LIVE]    Suivis | Pour toi  🔍│  ← header flottant, 56px, transparent
│                                 │
│         VIDEO BACKGROUND        │
│         (VideoPlayer)           │
│                                 │
│                          [AVT]  │  ← avatar 48px + bouton + 18px
│                          [❤️]   │  ← icône 28px + compteur 12sp
│                         5273    │
│                          [💬]   │
│                          259    │
│                          [🔖]   │
│                          207    │
│                          [↗️]   │
│                          537    │
│                          [🎵]   │  ← disque rotatif 48px
│                                 │
│ @username                       │  ← blanc bold 14sp
│ Description du contenu...       │  ← blanc 13sp, 2 lignes max
│ #tag1 #tag2 #tag3              │
│ ♪ Nom artiste - Nom son ~~~~   │  ← marquee 12sp
│─────────────────────────────────│  ← barre de progression 2px rose
│  🏠      👥    [+]    💬    👤 │  ← bottom nav 48px
└─────────────────────────────────┘
```

### Sidebar droite — détail
- **Avatar + bouton** : `Stack` avec `CircleAvatar(r:24)` + `Positioned(bottom:0)` un `Container(16px, color:brand, child:Icon(plus,12))`
- **Action item** : `Column(children: [Icon(28), SizedBox(2), Text(count,12)])` — gap 24px entre items
- **Like animation** : tap → `AnimationController` scale 1→1.4→1.0 en 300ms + couleur rouge

### Header flottant
- `Positioned(top:0)` avec `SafeArea`
- `Row` : badge LIVE | tabs `Suivis`/`Pour toi` | `Icon(search)`
- Tab actif : `Container(decoration: underline 2px blanc)`

---

## SearchBar

```dart
Container(
  height: 36,
  decoration: BoxDecoration(
    color: Colors.grey[100],
    borderRadius: BorderRadius.circular(4),
  ),
  child: Row(
    children: [
      Icon(LucideIcons.search, 16, color: grey),
      TextField(hint: 'Rechercher', border: none),
      Icon(LucideIcons.mic, 16, color: grey),
    ],
  ),
)
```

---

## SearchResultTab (chip scrollable)

```dart
// TabBar horizontal scrollable, no indicator line full-width
// Tab actif : texte noir bold + Container underline 2px noir
// Tab inactif : texte gris #8A8A8A
TabBar(
  isScrollable: true,
  indicatorColor: Colors.black,
  indicatorWeight: 2,
  labelColor: Colors.black,
  unselectedLabelColor: Color(0xFF8A8A8A),
)
```

---

## VideoThumbnailCard (grille 2 colonnes — résultats)

```
┌──────────────────────┐
│                      │  ← aspect ratio 9/16
│    THUMBNAIL IMAGE   │
│                      │
│ 29/4      🔊        │  ← badge date + son (12sp blanc)
└──────────────────────┘
 Titre de la vidéo      ← 13sp noir, 2 lignes max
 en 2 lignes
 [AVT] @username  ❤️84 ← 12sp gris
```

- Gap entre 2 colonnes : 2px
- Coins : `borderRadius: 4px`

---

## UserListTile (résultats utilisateurs)

```
[AVT 48] username ✓           [Suivre]
         BIO courte
         349K abonnés · 761 vidéos
```
- Bouton Suivre : `ElevatedButton` rouge, `BorderRadius.circular(4)`, 72×32px
- Séparateur : `Divider(height:1, color: #E8E8E8)`

---

## HashtagListTile

```
 ○ #  hashtag              42,0B vues
```
- Cercle gris 32px avec `#` centré
- Views à droite, gris `#8A8A8A`

---

## FilterChip (bottom sheet filtres)

```dart
// Chip non-actif
Container(
  padding: EdgeInsets.symmetric(horizontal:12, vertical:8),
  decoration: BoxDecoration(
    color: Color(0xFFF2F2F2),
    borderRadius: BorderRadius.circular(4),
  ),
  child: Text(label, style: TextStyle(color: Colors.black87)),
)

// Chip actif
Container(
  decoration: BoxDecoration(
    border: Border.all(color: Colors.black, width: 1.5),
    borderRadius: BorderRadius.circular(4),
  ),
)
```

---

## ProfileGrid (3 colonnes)

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
    crossAxisSpacing: 2,
    mainAxisSpacing: 2,
    childAspectRatio: 9/16,
  ),
  ...
)
```

Chaque tile :
- Thumbnail via `CachedNetworkImage`
- Overlay bas-gauche : `▷ 220` en blanc 12sp

---

## ProfileStats

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    _StatColumn('2413', 'Suivis'),
    _Divider(),
    _StatColumn('110', 'Followers'),
    _Divider(),
    _StatColumn('28', 'J\'aime'),
  ],
)
// _StatColumn: number bold 16sp + label regular 13sp gris
```

---

## BottomNav

```dart
BottomNavigationBar(
  backgroundColor: Colors.black,
  selectedItemColor: Colors.white,
  unselectedItemColor: Color(0xFF8A8A8A),
  type: BottomNavigationBarType.fixed,
  items: [
    BottomNavigationBarItem(icon: LucideIcons.home, label: 'Accueil'),
    BottomNavigationBarItem(icon: LucideIcons.users, label: 'Amis'),
    BottomNavigationBarItem(icon: _CreateButton(), label: ''),
    BottomNavigationBarItem(icon: _InboxIcon(badge:8), label: 'Boîte de réception'),
    BottomNavigationBarItem(icon: LucideIcons.user, label: 'Profil'),
  ],
)
```

Bouton créer (central) :
```dart
// Rectangle bicolore cyan/rose avec coins arrondis et icône +
Container(
  width: 42, height: 28,
  child: Stack(
    children: [
      Positioned(left:0, child: Container(w:26, h:28, color:colorBrandCyan, borderRadius:L)),
      Positioned(right:0, child: Container(w:26, h:28, color:colorBrand, borderRadius:R)),
      Center(child: Container(w:28, h:28, color:white, child: Icon(plus, black))),
    ],
  ),
)
```

---

## LiveBadge

```dart
// Badge LIVE rouge avec animation pulse
AnimatedContainer(
  padding: EdgeInsets.symmetric(horizontal:6, vertical:2),
  decoration: BoxDecoration(color: colorLiveRed, borderRadius: BorderRadius.circular(3)),
  child: Text('LIVE', style: TextStyle(color:white, fontSize:11, fontWeight:bold)),
)
// Animation : opacity pulse 1.0 ↔ 0.7 en 1000ms répété
```
