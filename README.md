# 🧠 Brainex — AI-Powered Learning Platform

Brainex is a full-stack learning platform that combines a **Flutter mobile app** with a **FastAPI backend**, powered by **MongoDB**, **Firebase Auth**, and **AI-driven study workflows**.

---

## 📚 Table of Contents

- [1) Product Snapshot](#1-product-snapshot)
- [2) Visual System Architecture](#2-visual-system-architecture)
- [3) End-to-End User Flows](#3-end-to-end-user-flows)
- [4) Repository Blueprint](#4-repository-blueprint)
- [5) Frontend Architecture (Flutter)](#5-frontend-architecture-flutter)
- [6) Backend Architecture (FastAPI)](#6-backend-architecture-fastapi)
- [7) API Surface Map](#7-api-surface-map)
- [8) Data Layer & Collections](#8-data-layer--collections)
- [9) AI & Content Pipelines](#9-ai--content-pipelines)
- [10) Local Setup & Run Guide](#10-local-setup--run-guide)
- [11) Environment & Configuration](#11-environment--configuration)
- [12) Operational Notes](#12-operational-notes)

---

## 1) Product Snapshot

### Core capabilities
- 🔐 Authentication via Firebase (email/password, Google, anonymous testing)
- 👤 Onboarding + user profile + XP progression
- 🏠 Home dashboard, leaderboard, profile
- 📝 AI model paper generation + performance analysis
- 📅 AI study plan generation and retrieval
- 🤝 Friend challenges (join, start, submit, results)
- 🌍 Global weekly challenges with schedule/progress/results
- 📒 Short note generation + storage + predefined notes
- 🛠️ Admin portal (stats, user controls, notes/papers utilities)

### High-level product map

```mermaid
mindmap
  root((Brainex))
    Mobile App (Flutter)
      Authentication
      Onboarding
      Home + Leaderboard + Profile
      AI Study Plan
      Model Papers
      Challenges
      Short Notes
      Admin Screens
    Backend API (FastAPI)
      User/XP Services
      Model Paper Engine
      Challenge Engine
      Planner Engine
      Notes Engine
      Admin APIs
    Data + Infra
      MongoDB
      Firebase Auth
      AI Providers
      PDF Knowledge Sources
```

---

## 2) Visual System Architecture

```mermaid
graph TD
    U[Student / Admin User] --> F[Flutter App]

    F -->|Auth| FB[Firebase Auth]
    F -->|HTTP JSON APIs| B[FastAPI Backend]

    B --> DB[(MongoDB)]
    B --> AI1[Gemini / AI Services]
    B --> PDF[Local Subject PDF Corpus]

    subgraph Frontend Layers
      F1[Screens]
      F2[Services]
      F3[Models/Providers/Widgets]
    end

    F --> F1
    F1 --> F2
    F2 --> F3

    subgraph Backend Layers
      B1[Routes]
      B2[Service Layer]
      B3[Schemas]
      B4[DB Access]
    end

    B --> B1 --> B2 --> B3
    B2 --> B4 --> DB
```

---

## 3) End-to-End User Flows

### App entry flow (wrapper-driven)

```mermaid
flowchart LR
    A[App Launch] --> B[Show Splash]
    B --> C{Authenticated?}
    C -- No --> D[Language Screen / Login Path]
    C -- Yes --> E{Admin UID?}
    E -- Yes --> F[Admin Dashboard]
    E -- No --> G[Fetch User Profile]
    G --> H{Onboarding Completed?}
    H -- Yes --> I[Root Screen]
    H -- No --> J[Exam Details / Onboarding]
```

### Model paper lifecycle

```mermaid
sequenceDiagram
    participant User as User
    participant App as Flutter App
    participant API as FastAPI /modelpapers
    participant AI as RAG + Gemini Services
    participant DB as MongoDB
    participant XP as User Profile Service

    User->>App: Request model papers
    App->>API: POST /modelpapers/generate
    API->>AI: Generate MCQs by grade/term/topic
    AI-->>API: Question set(s)
    API->>DB: Store model paper docs
    API-->>App: Created papers

    User->>App: Submit answers
    App->>API: POST /modelpapers/analyze
    API->>AI: Analyze performance
    API->>DB: Upsert submission
    API->>XP: Award paper XP
    API-->>App: Score + feedback + XP
```

### Global challenge lifecycle

```mermaid
stateDiagram-v2
    [*] --> Preloaded : startup preload
    Preloaded --> Scheduled : weekly slots built
    Scheduled --> Joined : user joins challenge
    Joined --> InProgress : questions fetched / progress saved
    InProgress --> Submitted : answers submitted
    Submitted --> Ranked : results calculated
    Ranked --> [*]
```

---

## 4) Repository Blueprint

```text
Brainex/
├── backend/
│   ├── app/
│   │   ├── core/                # settings and configuration
│   │   ├── db/                  # Mongo client + collection handles
│   │   ├── routes/              # FastAPI endpoint modules
│   │   ├── schemas/             # request/response Pydantic schemas
│   │   ├── services/            # business + AI + scoring logic
│   │   └── main.py              # FastAPI app bootstrap + router wiring
│   ├── scripts/                 # DB utility scripts
│   ├── requirements.txt
│   └── .env                     # local runtime secrets/config (not committed)
├── frontend/
│   ├── lib/
│   │   ├── screens/             # feature screens and UI flows
│   │   ├── services/            # backend communication + platform services
│   │   ├── models/              # domain models
│   │   ├── providers/           # app state providers (locale)
│   │   ├── widgets/             # reusable visual components
│   │   └── main.dart            # Flutter bootstrap
│   ├── assets/                  # images + localization assets
│   └── pubspec.yaml             # Flutter dependencies/config
└── docs/
    ├── api-contract/
    └── database/
```

---

## 5) Frontend Architecture (Flutter)

### Frontend module map

```mermaid
graph LR
    M[main.dart] --> W[Wrapper]
    W -->|admin uid| AD[Admin Dashboard]
    W -->|onboarding done| R[Root Screen]
    W -->|new user| ONB[Exam Details / Onboarding]
    W -->|not authenticated| AUTH[Language/Auth Screens]

    R --> H[Home]
    R --> L[Leaderboard]
    R --> P[Profile]
    R --> SP[AI Study Plan Setup]

    H --> CH[Challenges]
    H --> MP[Model Papers]
    H --> SN[Short Notes]
    H --> CB[Chatbot]
```

### Key frontend domains

| Domain | Main files |
|---|---|
| Bootstrap & shell | `lib/main.dart`, `lib/screens/wrapper.dart`, `lib/screens/root_screen.dart` |
| Authentication | `lib/services/auth.dart`, `lib/screens/authentication/*` |
| Study planning | `lib/screens/ai_studyplan/*`, `lib/services/study_plan_service.dart` |
| Model papers | `lib/screens/papers/*`, related service calls to `/modelpapers` |
| Challenges | `lib/screens/activity_challenges/*` |
| Short notes | `lib/screens/shortnote_page/short_notes_page.dart`, `lib/services/short_notes_service.dart` |
| Leaderboard/profile | `lib/screens/leaderboard/*`, `lib/screens/profile screen/*`, `lib/services/user_profile_service.dart` |
| Admin | `lib/screens/admin_*`, `lib/services/admin_service.dart` |
| Localization | `lib/providers/locale_provider.dart`, `lib/services/localization_service.dart`, `assets/lang/*` |

---

## 6) Backend Architecture (FastAPI)

### Backend execution map

```mermaid
graph TD
    MAIN[app/main.py] --> ROUTES[Route Modules]
    MAIN --> MAINT[Global Challenge Startup + Maintenance Loop]

    ROUTES --> CHAT[chat.py]
    ROUTES --> MODEL[modelpapers.py]
    ROUTES --> FRIEND[friend_challenges.py]
    ROUTES --> GLOBAL[global_challenges.py]
    ROUTES --> USERS[users.py]
    ROUTES --> PLAN[planner.py]
    ROUTES --> NOTES[short_notes.py]
    ROUTES --> PAST[pastpapers.py]
    ROUTES --> ADMIN[admin.py]

    CHAT --> SVC1[arcee_service + pdf_service]
    MODEL --> SVC2[rag_service + user_profile_service]
    FRIEND --> SVC3[friend_challenge_service]
    GLOBAL --> SVC4[global_challenge_service]
    USERS --> SVC5[user_profile_service + leaderboard_service]
    PLAN --> SVC6[planner_service]
    NOTES --> SVC7[gemini_service]

    SVC1 --> MONGO[(MongoDB)]
    SVC2 --> MONGO
    SVC3 --> MONGO
    SVC4 --> MONGO
    SVC5 --> MONGO
    SVC6 --> MONGO
    SVC7 --> MONGO
```

### Backend layers
- **Routes (`app/routes`)**: HTTP endpoints and request handling
- **Services (`app/services`)**: domain logic, AI orchestration, scoring/XP
- **Schemas (`app/schemas`)**: typed contracts for payload validation
- **DB (`app/db/mongo.py`)**: shared Mongo collection handles
- **Core (`app/core/config.py`)**: environment-driven settings

---

## 7) API Surface Map

> Implemented route groups currently wired by `app/main.py`.

| Domain | Base path | Representative endpoints |
|---|---|---|
| Chat | *(no prefix)* | `POST /chat`, `POST /chat/clear` |
| Model Papers | `/modelpapers` | `POST /generate`, `GET /`, `GET /{paper_id}`, `POST /analyze` |
| Friend Challenges | `/friend-challenges` | `POST /`, `GET /{id}`, `POST /{id}/join`, `POST /{id}/start`, `GET /{id}/questions`, `POST /{id}/submit`, `GET /{id}/results` |
| Global Challenges | `/global-challenges` | `POST /preload`, `GET /schedule`, `POST /{id}/join`, `GET /{id}/questions`, `POST /{id}/progress`, `POST /{id}/submit`, `GET /{id}/results` |
| Users & XP | `/users` | `GET /leaderboard/global`, `GET /leaderboard/me`, `GET /{user_id}`, `POST /{user_id}/login`, `PUT /{user_id}/onboarding`, `PATCH /{user_id}/profile` |
| Study Planner | `/planner` | `POST /generate-and-save`, `GET /user/{user_id}`, `GET /{plan_id}` |
| Short Notes | `/short_notes` | `POST /generate`, `POST /{user_uid}`, `GET /predefined/all`, `GET /{user_uid}`, `DELETE /{user_uid}/{note_id}` |
| Past Papers | `/pastpapers` | `GET /`, `GET /{year_val}`, `POST /generate` |
| Admin | `/admin` | `GET /stats`, `GET /short_notes`, `GET /users`, `PUT /users/{user_id}/status` |

---

## 8) Data Layer & Collections

### Mongo collection map (`app/db/mongo.py`)

```mermaid
erDiagram
    USERS ||--o{ MODEL_PAPER_SUBMISSIONS : earns_xp_from
    USERS ||--o{ STUDY_PLANS : owns
    USERS ||--o{ SHORT_NOTES : creates
    USERS ||--o{ FRIEND_CHALLENGE_PARTICIPANTS : joins
    USERS ||--o{ GLOBAL_CHALLENGE_PARTICIPANTS : joins
    USERS ||--o{ GLOBAL_CHALLENGE_PROGRESS : saves
    USERS ||--o{ GLOBAL_CHALLENGE_SUBMISSIONS : submits
    USERS ||--o{ FRIEND_CHALLENGE_SUBMISSIONS : submits

    MODEL_PAPERS ||--o{ MODEL_PAPER_SUBMISSIONS : has_submissions
    GLOBAL_CHALLENGES ||--o{ GLOBAL_CHALLENGE_PARTICIPANTS : has
    GLOBAL_CHALLENGES ||--o{ GLOBAL_CHALLENGE_PROGRESS : tracks
    GLOBAL_CHALLENGES ||--o{ GLOBAL_CHALLENGE_SUBMISSIONS : has
    FRIEND_CHALLENGES ||--o{ FRIEND_CHALLENGE_PARTICIPANTS : has
    FRIEND_CHALLENGES ||--o{ FRIEND_CHALLENGE_SUBMISSIONS : has

    MODEL_PAPERS {
      string title
      string paper_type
      string grade
      string difficulty
      array questions
    }
    USERS {
      string user_id
      number total_xp
      bool onboarding_completed
    }
```

### Primary collections in use
- `users`
- `model_papers`, `model_paper_submissions`
- `study_plans`
- `short_notes`, `predefined_notes`
- `friend_challenges`, `friend_challenge_participants`, `friend_challenge_submissions`
- `global_challenges`, `global_challenge_participants`, `global_challenge_progress`, `global_challenge_submissions`
- `papers`, `mcq_bank`, `syllabus_chunks`

---

## 9) AI & Content Pipelines

### Model paper generation pipeline

```mermaid
flowchart TD
    A[Generate Request] --> B[Normalize paper type constraints]
    B --> C[Retrieve context<br/>DB + PDFs + syllabus chunks]
    C --> D[Generate/paraphrase MCQs via AI service]
    D --> E[Persist paper in MongoDB]
    E --> F[Return structured paper set]
```

### Study assistance/chat pipeline

```mermaid
flowchart TD
    U[User message] --> C1[/chat endpoint/]
    C1 --> C2[Session memory handling]
    C2 --> C3[Subject classification]
    C3 --> C4[Load cached PDF context]
    C4 --> C5[AI answer generation]
    C5 --> C6[Store assistant reply in session]
    C6 --> U2[Return answer]
```

---

## 10) Local Setup & Run Guide

### Backend

```bash
cd /home/runner/work/Brainex/Brainex/backend
python -m venv .venv
source .venv/bin/activate   # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Frontend

```bash
cd /home/runner/work/Brainex/Brainex/frontend
flutter pub get
flutter run
```

### Base URL behavior (frontend)
- Android emulator default: `http://10.0.2.2:8000`
- iOS/web/local desktop default: `http://127.0.0.1:8000`

---

## 11) Environment & Configuration

Backend settings (`backend/app/core/config.py`) are environment-driven:

| Variable | Purpose |
|---|---|
| `MONGO_URI` | MongoDB connection URI |
| `DB_NAME` | Database name (default `brainex`) |
| `GEMINI_API_KEY` | Key for AI generation services |
| `GEMINI_MODEL` | Gemini model name (default `gemini-1.5-flash`) |
| `openrouter_api_key` | Optional OpenRouter key |
| `github_token` | Optional token |

> Keep secrets in local `.env` and never commit them.

---

## 12) Operational Notes

- Global challenges are preloaded and maintained on backend startup.
- User XP is awarded from multiple flows (daily login, model paper completion, challenge outcomes).
- Frontend contains both learner and admin experiences in one app shell.
- Existing docs are available under `/docs` and can be expanded into deeper architecture references.

---

If you want, the next step can be a **diagram-first API handbook** under `docs/` where each domain gets request/response examples and sequence diagrams.
