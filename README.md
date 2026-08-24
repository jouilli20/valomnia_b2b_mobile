# Valomnia B2B Mobile

Courte description du projet :
Cette application mobile permet de gérer une activité B2B Valomnia, notamment l'authentification des clients, la consultation du catalogue, la gestion du panier, le passage de commandes et le suivi de l'historique des commandes.

## Fonctionnalités

- Connexion / Authentification
- Mot de passe oublié
- Sélection de langue
- Consultation du catalogue produits
- Gestion des catégories
- Gestion du panier
- Passage de commande
- Historique des commandes
- Profil client
- Détection du mode hors ligne
- Cache local des données

## Technologies utilisées

### Frontend

- Flutter
- Dart
- Material Design
- Flutter Riverpod
- Go Router

### Backend

- API Valomnia
- Dio pour les appels HTTP

### Base de données

- SQLite local avec Sqflite
- Shared Preferences
- Flutter Secure Storage

## Installation

1. Cloner le projet

```bash
git clone https://github.com/jouilli20/valomnia_b2b_mobile.git
```

2. Accéder au dossier du projet

```bash
cd valomnia_b2b_mobile
```

3. Installer les dépendances

```bash
flutter pub get
```

4. Lancer le projet

```bash
flutter run
```

## Configuration

Créer un fichier `.env` si le projet est adapté pour charger la configuration depuis l'environnement :

```env
API_URL=...
TENANT_BASE_URL=...
WEB_ORDERS_URL=...
```

Les URLs de l'API sont actuellement centralisées dans :

```text
lib/core/constants/api_constants.dart
```

Attention : ne pas mettre les mots de passe, jetons d'accès ou clés API directement dans le README.

## Structure du projet

```text
android/
ios/
assets/
lib/
  core/
    constants/
    l10n/
    network/
    presentation/
    storage/
  features/
    auth/
    cart/
    catalog/
    customer/
    orders/
    profile/
test/
README.md
pubspec.yaml
```

## Utilisation

1. Installer Flutter et configurer un émulateur ou un appareil mobile.
2. Installer les dépendances avec `flutter pub get`.
3. Lancer l'application avec `flutter run`.
4. Se connecter avec un compte B2B valide.
5. Consulter le catalogue, ajouter des produits au panier et passer une commande.
