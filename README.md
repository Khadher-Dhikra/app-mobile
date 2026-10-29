# TAWSILA (توصيلة) — Covoiturage Interurbain en Tunisie

[![Flutter](https://img.shields.io/badge/Flutter-3.47.7-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-tawsila--91768-FFCA28?logo=firebase)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.13.5-0175C2?logo=dart)](https://dart.dev)
[![Tests](https://img.shields.io/badge/Tests-12%2F12%20Passés-success)]()

Application mobile Android complète et sécurisée de covoiturage interurbain en Tunisie, développée selon des standards de qualité logicielle élevés avec **Flutter**, **Firebase Cloud Firestore**, **Firebase Authentication** et **Riverpod 3**.

---

## 👥 Projet Académique & Équipe

- **Étudiantes développeuses** :
  - **Dhikra Khadher**
  - **Eya Boukadida**
- **Encadrante universitaire** :
  - **Mme Sabrine Brahmi**

---

## 🌟 Fonctionnalités Clés Implémentées

### 1. Authentification & Gestion de Profil
- Inscription par e-mail / mot de passe avec validation stricte (formats tunisiens, mot de passe robuste).
- Connexion sécurisée avec gestion des sessions persistantes et récupération de mot de passe.
- Profil utilisateur complet (Prénom, Nom, Ville tunisienne, Téléphone privé `+216 XX XXX XXX`, bio, rôle `user`/`admin`).
- Confidentialité : Le numéro de téléphone reste masqué tant qu'une réservation n'a pas été formellement acceptée par le conducteur.

### 2. Recherche & Découverte de Trajets (Mockups Screens 4 & 5)
- Sélection intuitive des gouvernorats et villes de départ et d'arrivée parmi les 24 gouvernorats tunisiens (`Tunis`, `Sousse`, `Sfax`, `Nabeul`, `Bizerte`, `Kairouan`, etc.).
- Filtrage par date de départ et places minimales disponibles.
- Affichage dynamique des cartes de trajets avec :
  - Villes de départ et d'arrivée, horaire précis.
  - Avatar, nom du conducteur et lieu de rendez-vous exact.
  - Nombre de places disponibles et prix par passager en **TND**.
  - Badge de statut ("Ouvert", "Complet", "Annulé").

### 3. Publication de Trajet en 2 Étapes (Mockup Screen 12)
- Assistant fluide en deux temps :
  - **Étape 1** : Villes départ/arrivée, date et heure, nombre de places proposées (1 à 8), prix par passager (TND), point de rencontre précis et description optionnelle.
  - **Étape 2** : Écran de récapitulatif avant publication avec aperçu du trajet et validation finale.

### 4. Réservations Transactionnelles & Concurrence Critique
- Protection absolue contre la surréservation (double-booking) via des transactions atomiques Firestore (`runTransaction`).
- Décrémentation et réincrémentation atomique des places disponibles lors de l'acceptation ou de l'annulation.
- Cycle de vie complet de réservation : `pending` (En attente) ➔ `accepted` (Acceptée) ➔ `rejected` (Refusée) / `cancelled` (Annulée) ➔ `completed` (Terminée).

### 5. Protocole de Validation de Départ par Code OTP Sécurisé (Mockups Screens 8 & 9)
- Dès l'acceptation de la réservation, un code de départ alphanumérique unique à 6 caractères (ex: `7K4 9P2`) est généré côté serveur.
- Affichage passager sur carte contrastée sombre ("Mon code de départ", "Prêt à prendre la route ?").
- Interface conducteur pour saisir le code du passager au point de rencontre.
- **Sécurité renforcée** :
  - Validation atomique vérifiant la correspondance du code.
  - Expiration automatique (6 heures après l'heure de départ prévue).
  - Blocage automatique après **3 tentatives infructueuses** pour empêcher toute force brute.

### 6. Espace Activité & Gestion des Rôles (Mockups Screens 7, 13 & 14)
- Sélecteur segmenté fluide à double vue :
  - **Mes réservations (Passager)** : Visualisation des trajets réservés, code de départ accessible, possibilité d'annuler.
  - **Mes trajets (Conducteur)** : Suivi des départs, consultation et examen des demandes reçues avec boutons d'acceptation/refus instantanés, bouton "Saisir le code au départ".

### 7. Signalement & Modération (Mockup Screen 11)
- Formulaire dédié permettant de signaler un utilisateur ou un trajet suspect.
- Catégories prédéfinies : *Informations inexactes, Conduite dangereuse, Retard injustifié ou non-présentation, Comportement inapproprié, Prix abusif, Véhicule non conforme, Autre motif*.
- Règles de sécurité Firestore garantissant que seuls les administrateurs peuvent consulter et traiter les signalements.

### 8. Avis & Notations Post-Trajet
- Système de notation (1 à 5 étoiles) et commentaire après réalisation du voyage.
- Calcul en temps réel de la moyenne des avis et du nombre total de trajets complétés sur le profil.

---

## 🎨 Charte Graphique & Design System

Fidélité stricte aux maquettes Figma du projet :
- **Couleur Primaire** : Vert Pétrole Méditerranéen (`#0D4E56`).
- **Couleur Secondaire / Accents** : Émeraude doux (`#1A6B75`), badges vert clair (`#E6F4F1`).
- **Fonds & Surfaces** : Blanc pur (`#FFFFFF`), fond doux (`#F8FAF9`), cartes surélevées (`#F0F5F4`).
- **Typographie** : Famille de polices moderne **Outfit** (Google Fonts).
- **Logo Dynamique** : Tracé vectoriel personnalisé stylisant la route interurbaine et les deux nœuds de connexion.

---

## 📐 Architecture Technique

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart        # Palette chromatique officielle Figma
│   │   ├── app_constants.dart     # Limites métiers, délais d'expiration
│   │   └── tunisian_cities.dart   # Liste complète des 24 gouvernorats tunisiens
│   ├── utils/
│   │   ├── currency_formatter.dart # Formatage standardisé en TND
│   │   ├── date_formatter.dart     # Formatage bilingue dates & heures
│   │   └── validators.dart         # Validations e-mail, téléphone tunisien, prix
│   └── widgets/
│       ├── app_logo.dart           # Logo vectoriel Tawsila custom painter
│       ├── custom_button.dart      # Boutons primaires, outline et loadings
│       ├── custom_text_field.dart  # Champs stylisés avec icônes
│       └── loading_indicator.dart  # Spinners d'attente harmonisés
├── features/
│   ├── auth/                       # Authentification & Sessions
│   │   ├── data/auth_repository.dart
│   │   ├── domain/user_profile.dart
│   │   ├── presentation/
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   └── providers/auth_providers.dart
│   ├── rides/                      # Trajets & Publications
│   │   ├── data/ride_repository.dart
│   │   ├── domain/ride.dart
│   │   ├── presentation/
│   │   │   ├── ride_search_screen.dart
│   │   │   ├── ride_details_screen.dart
│   │   │   ├── publish_ride_screen.dart
│   │   │   └── widgets/ride_card.dart
│   │   └── providers/ride_providers.dart
│   ├── bookings/                   # Réservations & Départ OTP
│   │   ├── data/booking_repository.dart
│   │   ├── domain/booking.dart
│   │   ├── domain/trip_session.dart
│   │   ├── presentation/
│   │   │   ├── my_bookings_screen.dart
│   │   │   └── departure_code_screen.dart
│   │   └── providers/booking_providers.dart
│   ├── profile/                    # Profil & Préférences
│   │   └── presentation/profile_screen.dart
│   ├── reports/                    # Signalements & Modération
│   │   ├── data/report_repository.dart
│   │   ├── domain/report.dart
│   │   ├── presentation/report_screen.dart
│   │   └── providers/report_providers.dart
│   ├── reviews/                    # Avis & Évaluations
│   │   ├── data/review_repository.dart
│   │   ├── domain/review.dart
│   │   └── providers/review_providers.dart
│   └── shell/                      # Navigation Shell
│       └── presentation/app_shell.dart
├── firebase_options.dart           # Initialisation Firebase CLI multiplateforme
├── main.dart                       # Point d'entrée, Thème & GoRouter
└── app.dart
```

---

## 🔒 Configuration Firebase & Sécurité

- **Projet Firebase** : `tawsila-91768` (ID Projet : `tawsila-91768`, Numéro : `608829457774`)
- **Fichiers de configuration déployés** :
  - `android/app/google-services.json` (ID d'application Android : `tn.tawsila.tawsila`)
  - `firestore.rules` : Règles de sécurité granulaires basées sur le principe du moindre privilège
  - `firestore.indexes.json` : Index composites optimisés pour les requêtes complexes
  - `functions/index.js` : Cloud Functions avec validation OTP et gestion d'annulation

---

## 🚀 Installation & Exécution

### Prérequis
- Flutter SDK 3.24+ (testé avec Flutter 3.47.7 / Dart 3.13.5)
- Android Studio ou VS Code avec SDK Android (API 23+)
- Node.js & Firebase CLI (`npm install -g firebase-tools`)

### Commandes

1. **Récupérer les dépendances** :
   ```bash
   flutter pub get
   ```

2. **Vérifier l'analyse statique du code (0 avertissement)** :
   ```bash
   flutter analyze
   ```

3. **Exécuter les tests unitaires et widgets** :
   ```bash
   flutter test
   ```

4. **Lancer l'application sur émulateur ou appareil Android** :
   ```bash
   flutter run
   ```

5. **Déployer les règles Firestore et index** :
   ```bash
   firebase deploy --only firestore --project tawsila-91768
   ```

---

© 2026 Tawsila — Dhikra Khadher & Eya Boukadida. Sous la direction de Mme Sabrine Brahmi.
