# Design Tokens

Tous les tokens sont à déclarer dans `lib/core/theme/tokens.dart`.

---

## Couleurs

### Brand
| Token | Valeur | Usage |
|---|---|---|
| `colorBrand` | `#EE1D52` | CTA, likes actifs, badges, boutons primaires |
| `colorBrandCyan` | `#69C9D0` | Loader splash, accents secondaires |

### Fond (dark — mode principal)
| Token | Valeur | Usage |
|---|---|---|
| `colorBgBase` | `#000000` | Fond du feed (vidéo plein écran) |
| `colorBgSurface` | `#121212` | Splash, fond app principal |
| `colorBgCard` | `#1C1C1E` | Cards, bottom sheets dark |
| `colorBgOverlay` | `rgba(0,0,0,0.45)` | Overlay sur thumbnails |

### Fond (light — search, profil, filtres)
| Token | Valeur | Usage |
|---|---|---|
| `colorBgLight` | `#FFFFFF` | Search, profil, filtres |
| `colorBgLightSurface` | `#F2F2F2` | Chips non-actifs, champs input |
| `colorBgLightCard` | `#EFEFEF` | Dividers, backgrounds secondaires |

### Texte
| Token | Valeur | Usage |
|---|---|---|
| `colorTextPrimary` | `#FFFFFF` | Texte sur fond sombre |
| `colorTextPrimaryDark` | `#000000` | Texte sur fond clair |
| `colorTextSecondary` | `rgba(255,255,255,0.7)` | Sous-titres, métadonnées (dark) |
| `colorTextSecondaryDark` | `#8A8A8A` | Sous-titres (light) |
| `colorTextBrand` | `#EE1D52` | Liens, actions en couleur |

### États
| Token | Valeur | Usage |
|---|---|---|
| `colorLike` | `#EE1D52` | Like actif |
| `colorLiveRed` | `#FE2C55` | Badge LIVE |
| `colorVerified` | `#20D5EC` | Badge vérifié utilisateur |
| `colorFollowBtn` | `#EE1D52` | Bouton Suivre |
| `colorDivider` | `rgba(255,255,255,0.12)` | Dividers dark |
| `colorDividerLight` | `#E8E8E8` | Dividers light |

---

## Typographie

Police principale : **System font** (`-apple-system` / `Roboto`)  
→ Sur Android : `Roboto`, sur iOS : `SF Pro`  
→ En Flutter : pas de `fontFamily` custom → `ThemeData(fontFamily: null)` (OS par défaut)

| Token | Taille | Poids | Line-height | Usage |
|---|---|---|---|---|
| `typeTitleL` | 18sp | 700 | 1.3 | Headers, titres de section |
| `typeTitleM` | 16sp | 700 | 1.3 | Username sur profil |
| `typeBodyM` | 14sp | 400 | 1.4 | Corps de texte |
| `typeBodyS` | 13sp | 400 | 1.4 | Descriptions, hashtags feed |
| `typeLabelM` | 12sp | 600 | 1.2 | Compteurs sidebar, badges |
| `typeLabelS` | 11sp | 400 | 1.2 | Dates, métadonnées |
| `typeCaption` | 10sp | 400 | 1.2 | Badges sur thumbnails |

---

## Espacement (grille 4px)

| Token | Valeur | Usage |
|---|---|---|
| `space2` | 2px | Gap entre tiles de grille |
| `space4` | 4px | Micro-espacements |
| `space8` | 8px | Espacement interne compact |
| `space12` | 12px | Padding standard items liste |
| `space16` | 16px | Padding horizontal pages |
| `space20` | 20px | Espacement sections |
| `space24` | 24px | Spacing entre blocs importants |
| `space32` | 32px | Marges larges |
| `space48` | 48px | Height bottom nav |
| `space56` | 56px | Height headers/app bars |

---

## Rayons

| Token | Valeur | Usage |
|---|---|---|
| `radiusNone` | 0 | Thumbnails du feed plein écran |
| `radiusSm` | 4px | Thumbnails grille profil |
| `radiusMd` | 8px | Cards, chips |
| `radiusLg` | 12px | Bottom sheets, modals |
| `radiusPill` | 999px | Boutons pill (Suivre, filtres), avatars |

---

## Avatars

| Contexte | Taille | Bordure |
|---|---|---|
| Feed sidebar | 48px | Aucune (+ bouton `+` 18px rose en bas) |
| Stories LIVE | 64px | 2px rose si LIVE |
| Profil principal | 80px | Aucune |
| Inbox / résultats | 48px | Aucune |
| Chat/commentaires | 36px | Aucune |

---

## Icônes

Voir `LIBRARIES.md` — package `lucide_icons` ou `font_awesome_flutter`.

Tailles standard :
- Sidebar feed : 28px
- Bottom nav : 24px
- Header : 22px
- Actions inline : 20px

---

## Animations / Transitions

| Élément | Type | Durée |
|---|---|---|
| Swipe feed (PageView) | Physique (spring) | natif Flutter |
| Apparition overlay | Fade | 150ms |
| Like (tap) | Scale bounce 1.0→1.4→1.0 | 300ms |
| Bottom sheet | Slide up | 250ms ease-out |
| Spinner splash | Rotation continue | 800ms loop |
| Badge LIVE | Pulse opacity 1→0.6→1 | 1000ms loop |
| Tab underline | Slide horizontal | 200ms |
