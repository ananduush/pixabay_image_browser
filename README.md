# Pixabay Image Browser

A Flutter mobile application for browsing, searching, and favoriting images from the
[Pixabay](https://pixabay.com/) REST API.

## Features

- Browse Pixabay images in a grid
- Search images by keyword
- View image details
- Simple local login
- Favorites for logged-in users: add, view, delete — persisted across restarts

## Tech Stack

- **Flutter / Dart**
- **GetX** — state management, routing, and dependency injection
- **GetStorage** — local key-value storage (favorites, session)
- **Pixabay REST API** — image data
- **cached_network_image** — image loading and caching

## Getting Started

### Prerequisites

- Flutter 3.47+ (Dart 3.13+)
- A free Pixabay API key — create an account at
  [pixabay.com/api/docs](https://pixabay.com/api/docs/) and copy your key

### Configuring the Pixabay API key

The API key is provided at build time and is **never committed to the repository**.

1. Copy the example file:

   ```sh
   cp env.example.json env.json
   ```

2. Put your key in `env.json`:

   ```json
   {
     "PIXABAY_API_KEY": "your-actual-key"
   }
   ```

   `env.json` is listed in `.gitignore`.

### Run

```sh
flutter pub get
flutter run --dart-define-from-file=env.json
```

The key can also be passed directly:

```sh
flutter run --dart-define=PIXABAY_API_KEY=YOUR_KEY
```

If no key is supplied the app starts and shows an "API key missing" screen with
these instructions instead of sending an invalid request.

## Project Structure

Feature-first vertical slices. Each feature owns its models, data access,
GetX controller/binding and UI; `core/` holds only what more than one feature
genuinely shares.

```
lib/
  core/
    config/        # compile-time environment (PIXABAY_API_KEY)
    routes/        # GetX route table
    theme/         # design tokens: colours, spacing, typography, ThemeData
    widgets/       # shared widgets: glass surface, pill button, line glyphs
  features/
    gallery/       # Explore feed (Pixabay editor's picks) and keyword search
      models/      # PixabayImage, PixabayPage
      services/    # PixabayService (Dio) + typed PixabayException
      repositories/
      controllers/ # GalleryController + sealed GalleryState
      bindings/
      views/
      widgets/
  main.dart
test/
  features/gallery/   # model parsing, service, controller and view tests
```

Data flows View → Controller → Repository → Service → Pixabay API; models are
the typed data passed between layers.

## Screenshots

_TODO: add screenshots / screen recording._
