# Pixabay Image Browser

A Flutter mobile application for browsing, searching, and favoriting images from the
[Pixabay](https://pixabay.com/) REST API.

## Features

- Browse Pixabay images in a grid
- Search images by keyword
- View image details
- Email/password accounts with Supabase Auth: sign in, create account, log out;
  the session is restored on launch
- Favorites for logged-in users: add, view, delete — persisted across restarts

## Tech Stack

- **Flutter / Dart**
- **GetX** — state management, routing, and dependency injection
- **supabase_flutter** — Supabase Auth (email/password); the SDK persists and
  restores the session
- **GetStorage** — local key-value storage (favorites)
- **Pixabay REST API** — image data
- **cached_network_image** — image loading and caching

## Getting Started

### Prerequisites

- Flutter 3.47+ (Dart 3.13+)
- A free Pixabay API key — create an account at
  [pixabay.com/api/docs](https://pixabay.com/api/docs/) and copy your key
- The Aperture Supabase project's URL and **publishable** key — see
  [`supabase/README.md`](supabase/README.md) for the project and its Auth settings

### Configuring the API keys

The Pixabay key and the Supabase client values are provided at build time and
are **never committed to the repository**.

1. Copy the example file:

   ```sh
   cp env.example.json env.json
   ```

2. Put the values in `env.json`:

   ```json
   {
     "PIXABAY_API_KEY": "your-actual-key",
     "SUPABASE_URL": "https://ezbczxhwznbyxjnsxsvv.supabase.co",
     "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_..."
   }
   ```

   Only the Supabase *publishable* key ever goes in the app — never a
   service-role or secret key.

   `env.json` is listed in `.gitignore`.

### Run

```sh
flutter pub get
flutter run --dart-define-from-file=env.json
```

The values can also be passed directly:

```sh
flutter run \
  --dart-define=PIXABAY_API_KEY=YOUR_KEY \
  --dart-define=SUPABASE_URL=https://ezbczxhwznbyxjnsxsvv.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
```

If no Pixabay key is supplied the app starts and shows an "API key missing"
screen with these instructions instead of sending an invalid request. Without
the Supabase values the app still starts; browsing works and the Profile tab
and sign-in screen explain the missing configuration.

## Project Structure

Feature-first vertical slices. Each feature owns its models, data access,
GetX controller/binding and UI; `core/` holds only what more than one feature
genuinely shares.

```
lib/
  core/
    config/        # compile-time environment (PIXABAY_API_KEY, SUPABASE_*)
    routes/        # GetX route table
    theme/         # design tokens: colours, spacing, typography, ThemeData
    widgets/       # shared widgets: glass surface, glass tab bar, pill buttons
  features/
    home/          # tabbed shell: Explore and Profile kept alive side by side
    gallery/       # Explore feed (Pixabay editor's picks), search, Image Details
      models/      # PixabayImage, PixabayPage
      services/    # PixabayService (Dio) + typed PixabayException
      repositories/
      controllers/ # GalleryController + sealed GalleryState
      bindings/
      views/
      widgets/
    auth/          # Supabase email/password accounts and the Profile tab
      models/      # AuthUser (id, email, createdAt)
      services/    # SupabaseAuthService (the only Supabase touchpoint) + AuthException
      repositories/
      controllers/ # app-scoped AuthController + sealed AuthState; AuthFormController
      bindings/
      views/       # AuthView (sign in / create account), ProfileView
      widgets/
  main.dart
test/
  features/gallery/   # model parsing, service, controller and view tests
  features/auth/      # service mapping, controllers and screens, no network
  features/home/      # tab switching keeps the Gallery untouched
```

Data flows View → Controller → Repository → Service → Pixabay API, and for
accounts View → AuthController → AuthRepository → SupabaseAuthService →
Supabase Auth; models are the typed data passed between layers. Supabase's
session is the only source of truth for who is signed in.

## Screenshots

_TODO: add screenshots / screen recording._
