<div align="center">

# 💕 Us.Love

### A real-time couples game platform — play together, anywhere.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-6DB33F?style=for-the-badge&logo=spring-boot&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Render](https://img.shields.io/badge/Render-46E3B7?style=for-the-badge&logo=render&logoColor=white)

[🌐 Live Web App](https://uslove.onrender.com) · [📱 Download APK](#-download) · [📄 SRS Document](./CouplesGamePlatform_SRS.docx)

</div>

---

## 📱 Download

> **Android APK** — Install directly on your phone, no Play Store needed.

| Version | Date | Download |
|---|---|---|
| v1.0.0 | March 2026 | [⬇️ Download APK](https://github.com/harshitgoyal25/Us_Love/releases/latest) |

**How to install:**
1. Download the APK from the link above
2. On your Android phone → Settings → Install unknown apps → Allow
3. Open the downloaded APK and install
4. Open Us.Love and register!

---

## ✨ What is Us.Love?

Us.Love is a real-time couples game web platform where two partners connect through a shared virtual room and play fun activities together — no matter where they are.

One partner creates a room and gets a 6-character invite code. The other partner enters the code on their device. Both are instantly connected and can play games together in real time.

---

## 🎮 Games

| Game | Type | Description |
|---|---|---|
| 🎯 How Well Do You Know Me | Turn-based | Answer questions about each other and score points |
| 🤔 Would You Rather | Simultaneous | Both pick between two scenarios and reveal together |
| 🃏 Truth or Dare | Card flip | Draw from a curated deck of truth/dare prompts |
| 💬 Couple Quiz | Turn-based | Trivia about your own relationship milestones |
| 🎨 Draw & Guess | Real-time | One draws, the other guesses live |
| 🎡 Spin the Wheel | Random | Spin to land on a random activity or dare |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter Web + Mobile (Dart) |
| Backend | Spring Boot 3.5 (Java 17) |
| Real-time | WebSocket + STOMP |
| Database | PostgreSQL via Supabase |
| Hosting (Backend) | Render Free Tier |
| Hosting (Frontend) | Render Free Tier |

**Total monthly cost: ₹0**

---

## 🏗️ Architecture

```
Flutter App (Web / Android / iOS)
         ↓ HTTPS / WSS
Spring Boot Monolith (Render)
    ├── REST API (Auth, Rooms)
    └── WebSocket (Game sync)
         ↓ JDBC + SSL
PostgreSQL (Supabase)
```

### How rooms work
```
Partner A creates room → gets code "LOVE42"
Partner B enters code  → both connected to WebSocket room
Partner A sees game cards → picks a game
Both phones navigate simultaneously → game starts
All game moves sync in real time via WebSocket
```

---

## 🚀 Running Locally

### Prerequisites
- Java 17
- Flutter 3.x
- A Supabase project (free)

### Backend

```bash
cd backend
```

Create `src/main/resources/application.properties` from the example:
```bash
cp src/main/resources/application.properties.example src/main/resources/application.properties
```

Fill in your Supabase credentials, then run:
```bash
./gradlew bootRun
```

Backend runs on `http://localhost:8080`

### Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

Make sure `core/api_client.dart` points to `http://localhost:8080` for local dev.

---

## 📁 Project Structure

```
Us_Love/
├── backend/                    # Spring Boot monolith
│   └── src/main/java/com/couples/backend/
│       ├── config/             # WebSocket + Security config
│       ├── controller/         # REST + WebSocket controllers
│       ├── model/              # JPA entities
│       ├── repository/         # Spring Data repositories
│       ├── service/            # Business logic
│       ├── security/           # JWT filter + util
│       └── dto/                # Request/response objects
│
├── frontend/                   # Flutter app
│   └── lib/
│       ├── core/               # API client + Socket service + Auth provider
│       ├── models/             # Data models
│       ├── screens/            # All app screens
│       │   └── games/          # Individual game modules
│       └── widgets/            # Reusable widgets
│
└── CouplesGamePlatform_SRS.docx  # Full requirements document
```

---

## 🔌 WebSocket Events

| Event | Direction | Description |
|---|---|---|
| `PARTNER_JOINED` | Server → Both | Partner connected to room |
| `GAME_SELECTED` | Client → Server | Host picked a game |
| `GAME_START` | Server → Both | Both navigate to game screen |
| `GAME_ACTION` | Client → Server | Any in-game move |
| `GAME_STATE_UPDATE` | Server → Both | Synced game state |
| `GAME_END` | Server → Both | Game over with scores |
| `PARTNER_DISCONNECTED` | Server → One | Partner lost connection |

---

## 🗄️ Database Schema

```sql
users         → id, name, email, password_hash, couple_id
couples       → id, partner_a_id, partner_b_id, linked_at
game_sessions → id, couple_id, game_type, winner_id, score_a, score_b, played_at
questions     → id, game_type, content, category
```

---

## 📦 Adding a New Game Module

The platform uses a plug-in game pattern. Adding a new game requires changes to exactly 3 places — no backend changes needed:

1. Create `frontend/lib/screens/games/your_game_screen.dart`
2. Add a route in `main.dart`:
```dart
GoRoute(path: '/game/your_game', builder: (_,__) => YourGameScreen()),
```
3. Add a game card in `lobby_screen.dart`:
```dart
{'id': 'your_game', 'title': 'Your Game', 'emoji': '🎮', 'color': 0xFFFF6B9D}
```

---

## 🌐 Deployment

| Service | URL |
|---|---|
| Backend API | https://uslove-backend.onrender.com |
| Web App | https://uslove.onrender.com |

> **Note:** Free tier instances sleep after 15 mins of inactivity. First request may take ~30 seconds to wake up.

---

## 📄 License

This project is private and personal. Built with ❤️ by [Harshit Goyal](https://github.com/harshitgoyal25).

---

<div align="center">
  <sub>Made for couples, by a developer in love with building things 💕</sub>
</div>
