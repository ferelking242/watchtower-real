# Écrans — Inventaire complet

> Référence visuelle : voir `.design/screenshots/`

## Navigation principale (Bottom Nav)
5 onglets permanents :
| Icône | Label | Route |
|---|---|---|
| 🏠 | Accueil | `/` |
| 👥 | Amis | `/friends` |
| ➕ | (Créer) | — modal |
| 💬 | Boîte de réception | `/inbox` |
| 👤 | Profil | `/profile` |

---

## 01 — Splash Screen
**Screenshot :** `01_splash_screen.png`
- Fond : `#121212` (quasi-noir)
- Logo TikTok centré (blanc, 80px)
- Loader : 2 points (cyan `#69C9D0` + rose `#EE1D52`) qui tournent
- Durée : ~1.5s puis transition vers le Feed

---

## 02 — Feed Principal (vidéo)
**Screenshot :** `02_feed_main.png`
- **PageView vertical** plein écran, swipe up/down
- **Header flottant** (transparent) :
  - Gauche : badge `LIVE` (rouge)
  - Centre : tabs `Suivis` | `Pour toi` (texte blanc, underline sur actif)
  - Droite : icône loupe
- **Overlay bas-gauche** :
  - Avatar + username en gras (blanc)
  - Description + hashtags (blanc, 2 lignes max)
  - Son (♪ nom artiste — scrolling marquee)
- **Sidebar droite** (icônes empilées verticalement) :
  - Avatar du créateur (+ bouton rouge `+` en bas)
  - ❤️ Likes (compteur)
  - 💬 Commentaires (compteur)
  - 🔖 Sauvegarder (compteur)
  - ↗️ Partager (compteur)
  - 🎵 Disque rotatif (son)
- **Barre de progression vidéo** : fine ligne rose en bas de l'écran

---

## 03 — Feed avec Stories LIVE
**Screenshot :** `03_feed_with_live_stories.png`
- **Row LIVE** en haut : avatars circulaires (64px) avec badge `LIVE` rouge
- Fond noir avec contour rose sur avatar LIVE actif
- Vidéo du feed visible en dessous

---

## 04 — Recherche — Suggestions
**Screenshot :** `04_search_suggestions.png`
- Fond blanc
- Barre de recherche : retour `<`, champ texte, micro 🎤, bouton "Rechercher" (rouge)
- **Historique récent** : liste avec ⏱ icône + ✕ pour supprimer
- "Afficher plus ▾"
- **Section "Tu pourrais aimer"** :
  - Bullet coloré (rouge/orange/gris) + texte tendance
  - Icône trending 📈 rouge sur les sujets chauds

---

## 05 — Recherche — Saisie Vocale
**Screenshot :** `05_search_voice.png`
- Fond blanc
- ✕ en haut-gauche, 🌐 langue en haut-droite
- Texte "Parle maintenant..." centré (noir, gros)
- Animation : cercle rose pulsant avec point rouge central
- Bouton "♪ Recherche de son" en bas (pill gris)

---

## 06 — Résultats de recherche — Top
**Screenshot :** `06_search_results_top.png`
- **Tabs horizontaux scrollables** : `Top` | `Vidéos` | `Utilisateurs` | `Sons` | `LIVE` | `Hashtags`
- Tab actif : texte noir en gras + underline noir
- **Grille 2 colonnes** de vidéos :
  - Thumbnail plein-width
  - Badge date (ex: `29/4`) + icône son
  - Titre (2 lignes, noir)
  - Avatar + username (tronqué) + ❤️ compteur

---

## 07 — Résultats — Menu Overflow
**Screenshot :** `07_search_results_overflow.png`
- Bottom sheet blanc demi-hauteur
- Items : `≡ Filtres` / `☐ Partager des commentaires`

---

## 08 — Feedback Recherche
**Screenshot :** `08_search_feedback.png`
- Fond blanc, header `← Commentaires`
- Titre section + liste de checkboxes (case carrée)
- Case cochée = fond rose + ✓ blanc
- Bouton "Envoyer" rouge full-width en bas

---

## 09 — Filtres de recherche
**Screenshot :** `09_search_filters.png`
- Bottom sheet blanc
- Header : `Annuler` | **Filtres** | `Appliquer` (grisé par défaut)
- 3 sections avec **pill chips** :
  - Trier par : Pertinence (actif=bordure noire) | Nombre de j'aime | Date de publication
  - Catégorie vidéo : Tous (actif) | Non regardées | Regardées | A aimé | Personnes que tu suis
  - Date de publication : Tous (actif) | Dernières 24h | Cette semaine | Ce mois-ci | 3 derniers mois | 6 derniers mois

---

## 10 — Résultats — Onglet Vidéos
**Screenshot :** `10_search_results_videos.png`
- Grille 2 colonnes
- Badge "Les plus aimées" (fond gris sombre) sur thumbnail
- Séparateur `Suivis` (pill gris centré) entre sections

---

## 11 — Résultats — Onglet Utilisateurs
**Screenshot :** `11_search_results_users.png`
- Liste verticale
- Avatar 48px + username bold + bio + followers·vidéos
- Bouton `Suivre` rouge (pill) à droite
- Badge vérifié bleu ✓ sur username

---

## 12 — Résultats — Onglet Hashtags
**Screenshot :** `12_search_results_hashtags.png`
- Liste : cercle `#` gris + hashtag bold + "X vues" à droite (gris)

---

## 13 — LIVE Multi-Invités
**Screenshot :** `13_live_multi_guest.png`
- Fond sombre bleu-noir
- Header : avatar + nom + likes + `+ Suivre` + icônes + ✕
- Grille d'invités (1 grand + 6 petits) avec numéros (niveau ?)
- Badge `Hôte` sur l'invité principal
- Chat en bas + barre de commentaire + icônes actions

---

## 14 — Boîte de Réception
**Screenshot :** `14_inbox.png`
- Header : icône édition + "Boîte de réception" + 🔍
- Row stories (Créer + avatars)
- Liste conversations :
  - Icône colorée (rond vert/bleu/rose) + titre + description
  - Bouton action (ex: `Trouver`)
  - Timestamp + badge nombre non-lus

---

## 15 — Profil — Vue Principale
**Screenshot :** `15_profile_main.png`
- Header : `USERNAME ▾` centré + icônes droite
- Avatar 80px centré + bouton `+` bleu
- @username + icône QR
- Stats : `Suivis | Followers | J'aime`
- Boutons : `Modifier le profil` | `Ajout d'amis` (gris, arrondi)
- Bio (texte centré)
- **Tabs de contenu** : ⊞ (vidéos) | 🔒 (privé) | ↺ (repost) | 🔖 (sauvegardé) | ❤️ (aimés)
- Grille 3 colonnes de vidéos

---

## 16 — Profil — Grille Vidéos
**Screenshot :** `16_profile_grid.png`
- Grille 3 colonnes, spacing 1-2px
- Chaque tile : thumbnail + `▷ compteur` en bas-gauche

---

## 17 — Profil — Onglet Sauvegardé
**Screenshot :** `17_profile_saved_tab.png`
- Sub-tabs horizontaux : `Publications X | Collections X | Sons X | Effets...`
- Grille 3 colonnes avec compteurs de vues

---

## 18 — Profil — Onglet J'aime
**Screenshot :** `18_profile_liked_tab.png`
- Banner informatif (fond blanc, texte + lien rose, ✕)
- Grille 3 colonnes

---

## 19 — Profil — Menu Settings
**Screenshot :** `19_profile_settings_menu.png`
- Bottom sheet (demi-hauteur)
- Items : `★ Outils pour les créateurs` (point rouge) | `⊞ Mon code QR` | `⚙ Paramètres et confidentialité`
