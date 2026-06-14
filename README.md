# OpenSoundTouch

A third-party controller for Bose SoundTouch speakers — replacing the discontinued
official SoundTouch cloud experience.

> Not affiliated with or endorsed by Bose Corporation. "Bose" and "SoundTouch" are
> trademarks of Bose Corporation.

## What it does

- Discovers SoundTouch speakers on your local network (mDNS)
- Controls playback, volume, source, and multi-room zones
- Assigns internet radio stations to the speaker's preset buttons
- Searches the [Radio-Browser](https://www.radio-browser.info/) catalog of ~50k stations
- Plays internet radio independently from the smartphone — the speaker streams the
  source directly, freeing the phone for other media

## Project structure

```
OpenSoundTouch/
├── backend/   Spring Boot 3.3 + Java 21 — radio search proxy (Railway-hosted)
└── mobile/    Flutter app for iOS + Android (talks to speakers on LAN and to backend)
```

## Backend (development)

```
cd backend
mvn spring-boot:run
```

Runs on `http://localhost:8080`. Endpoints:

- `GET /health` — liveness
- `GET /api/radio/search?name=...&country=...&language=...&limit=25` — Radio-Browser proxy

## Mobile (development)

```
cd mobile
flutter pub get
flutter run
```

(Scaffolded once Flutter SDK is installed locally.)

## Deployment

- **Backend** deploys to Railway via `backend/Dockerfile` + `backend/railway.toml`
- **Mobile** is distributed via the Apple App Store and Google Play (TBD)
