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

- Flutter 3.32+ (Dart 3.8+)
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

## Project Structure

```
lib/
  app/
    core/          # constants, theme, environment config
    data/
      models/      # data models
      providers/   # Pixabay API client
      repositories/
      services/    # storage, auth/session
    modules/       # feature modules: home, search, details, login, favorites
    routes/        # route definitions
  main.dart
```

## Screenshots

_TODO: add screenshots / screen recording._
