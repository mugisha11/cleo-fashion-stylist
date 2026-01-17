# 🚀 Cleo Fashion - Complete Codebase Guide

## **Project Overview**

**Cleo Fashion (Virtual Twin)** is an AI-powered fashion styling and virtual try-on application. It's a full-stack mobile/web app that combines:
- **Flutter frontend** for iOS/Android/Web
- **Python FastAPI backend** for AI-powered virtual try-ons
- **Firebase** for authentication and real-time features
- **Supabase** for storage and edge functions
- **Gemini AI** for image generation

---

## 📦 **Tech Stack**

### **Frontend (Flutter/Dart)**
| Technology | Purpose |
|---|---|
| **Flutter 3.x** | Cross-platform mobile/web framework |
| **Riverpod** | State management |
| **Firebase** | Auth, Firestore, Storage, Cloud Functions, Messaging |
| **Supabase** | Image storage, Edge Functions, Cron jobs |
| **Google Sign-In** | OAuth authentication |
| **Hive** | Local caching/offline storage |
| **Model Viewer Plus** | 3D model rendering |
| **WebView Flutter** | Embedded web content (Ready Player Me) |

### **Backend (Python)**
| Technology | Purpose |
|---|---|
| **FastAPI 0.104** | REST API framework |
| **Python 3.11+** | Backend runtime |
| **OpenCV** | Image processing & manipulation |
| **PyTorch** | Deep learning models |
| **MediaPipe** | Pose & hand detection |
| **InsightFace** | Face recognition & similarity (98%+ accuracy) |
| **YOLO (Ultralytics)** | Clothing segmentation |
| **Gemini API** | Image generation (via OpenRouter) |
| **OpenRouter** | Multimodal AI tasks |
| **Supabase SDK** | Database & storage access |

### **Cloud Services**
| Service | Purpose |
|---|---|
| **Firebase** | Auth, real-time DB, file storage, functions |
| **Supabase** | PostgreSQL, file storage, Edge Functions |
| **Gemini AI** | Advanced image generation |
| **OpenRouter** | AI model aggregation layer |

---

## 🗂️ **Directory Structure**

### **Frontend: `/lib`**

```
lib/
├── main.dart                          # App entry point + Firebase init
├── src/
│   ├── app.dart                       # Root widget + routing
│   ├── routes.dart                    # Navigation routes
│   ├── features/                      # Feature modules
│   │   ├── auth/                      # Login, signup, password reset
│   │   ├── avatar/                    # Avatar creation/customization
│   │   ├── calendar/                  # Calendar & event management
│   │   ├── dashboard/                 # Home dashboard
│   │   ├── home/                      # Home screen
│   │   ├── notifications/             # Push notifications
│   │   ├── onboarding/                # First-time user setup
│   │   ├── recommendations/           # Daily outfit recommendations
│   │   ├── settings/                  # User preferences
│   │   ├── tryon/                     # Virtual try-on (CORE FEATURE)
│   │   ├── virtualwearon/             # Related to avatar try-ons
│   │   ├── vton/                      # VTON engine integration
│   │   └── wardrobe/                  # Clothing management
│   └── core/                          # Shared business logic
│       ├── providers/                 # Riverpod state providers
│       ├── services/                  # Business logic services
│       │   ├── fashion_ai_chat_service.dart   # AI fashion advisor
│       │   ├── weather_service.dart           # Weather API
│       │   ├── cache_service.dart             # Local caching
│       │   ├── config_service.dart            # OpenAI config
│       │   └── ...
│       ├── models/                    # Data models
│       ├── theme/                     # UI theme
│       ├── utils/                     # Utility functions
│       └── widgets/                   # Reusable UI components
```

### **Backend: `/backend`**

```
backend/
├── app/
│   ├── main.py                        # FastAPI application setup
│   ├── api/
│   │   ├── tryon.py                   # /try-on endpoint
│   │   ├── tryon_compat.py            # Flutter-compatible responses
│   │   └── recommend.py               # Recommendations endpoint
│   ├── services/                      # Business logic
│   │   ├── pose.py                    # MediaPipe pose estimation
│   │   ├── parsing.py                 # Body part segmentation
│   │   ├── face_lock.py               # Face preservation (CRITICAL)
│   │   ├── viton.py                   # Try-on inference
│   │   ├── garment_analyzer.py        # AI garment analysis
│   │   ├── image_generator.py         # Gemini image generation
│   │   └── storage.py                 # Supabase storage ops
│   ├── core/
│   │   ├── config.py                  # Environment & settings
│   │   ├── quality.py                 # Quality assurance checks
│   │   └── retry.py                   # Retry logic
│   ├── models/
│   │   └── schemas.py                 # Pydantic request/response models
│   └── stages/                        # 6-stage pipeline
│       ├── stage1_validate.py         # Image validation
│       ├── stage2_semantic_analysis.py # Garment analysis
│       ├── stage3_mask_generation.py  # Segmentation & masking
│       ├── stage4_prompt_synthesis.py # Prompt creation
│       ├── stage5_image_generation.py # Gemini generation
│       └── stage6_quality_check.py    # Quality validation
├── tests/                             # Test files
├── Dockerfile                         # Container configuration
├── requirements.txt                   # Python dependencies
└── .env.example                       # Environment template
```

---

## 🎯 **Core Features Explained**

### **1. Virtual Try-On (VTON) - The Main Feature**

**What it does:** Takes a photo of a person and a clothing item, then generates a realistic image of the person wearing that clothing.

**Flow:**
```
User Photo + Clothing Item
    ↓
[BACKEND 6-STAGE PIPELINE]
Stage 1: Validate images
Stage 2: Analyze garment (type, placement, color)
Stage 3: Create segmentation masks (body parts, garment)
Stage 4: Generate precise AI prompt
Stage 5: Generate composite image with Gemini
Stage 6: Quality checks (face similarity ≥98%)
    ↓
Result Image + Quality Metrics
```

**Key Technologies:**
- **InsightFace**: Face preservation (locks original face, ≥98% similarity)
- **MediaPipe**: Pose detection & body parsing
- **YOLO**: Clothing segmentation
- **Gemini**: Advanced image generation
- **OpenRouter**: Model aggregation

**Code Locations:**
- Frontend: [`lib/src/features/tryon/`](lib/src/features/tryon/)
- Backend: [`backend/app/api/tryon.py`](backend/app/api/tryon.py), [`backend/app/stages/`](backend/app/stages/)

---

### **2. AI Fashion Chat Service**

**What it does:** ChatGPT-level conversation about fashion with intelligence to generate outfit recommendations.

**Features:**
- Intent analysis (distinguishes outfit requests from casual chat)
- Context-aware recommendations using:
  - User's wardrobe
  - Calendar events
  - Weather data
  - Previous try-on sessions
- Generates structured outfit suggestions

**Code Location:** [`lib/src/core/services/fashion_ai_chat_service.dart`](lib/src/core/services/fashion_ai_chat_service.dart)

**Data Models:**
- `OutfitRecommendation` - Structured outfit format
- `TryOnSession` - Saved try-on results

---

### **3. Daily Recommendations**

**What it does:** Automatically generates 5 outfit recommendations daily at 5 AM for each user.

**Technologies:**
- Supabase Edge Functions
- Cron job scheduling
- OpenAI GPT-4o-mini for reasoning

**Triggers:** Runs automatically via Supabase cron

**Code Location:** Backend Supabase functions

---

### **4. Avatar System**

**Features:**
- Create custom 3D avatars using Ready Player Me
- Try clothing on the avatar
- Store avatar preferences

**Code Location:** [`lib/src/features/avatar/`](lib/src/features/avatar/)

---

### **5. Wardrobe Management**

**What it does:**
- Manage user's clothing inventory
- Organize by category, color, occasion
- Tag with metadata (brand, size, material)
- Upload photos

**Storage:** Firebase Storage + Supabase

**Code Location:** [`lib/src/features/wardrobe/`](lib/src/features/wardrobe/)

---

### **6. Notifications & Calendar Integration**

**Features:**
- Push notifications for new recommendations
- Calendar event linked outfit suggestions
- Reminder scheduling

**Code Location:** [`lib/src/features/notifications/`](lib/src/features/notifications/), [`lib/src/features/calendar/`](lib/src/features/calendar/)

---

## 🔐 **Authentication Flow**

```
User
  ↓
Sign-In Options:
  ├─ Email/Password (Firebase Auth)
  ├─ Google OAuth (Google Sign-In)
  └─ Apple Sign-In
  ↓
Firebase Authentication
  ↓
Create/Update User Record
  ↓
Token generated
  ↓
Access granted to Firestore & Storage
```

**Code Location:** [`lib/src/features/auth/`](lib/src/features/auth/)

---

## 🗄️ **Database Schema**

### **Firebase (Firestore)**

```
users/{userId}
  ├── email
  ├── displayName
  ├── photoUrl
  ├── preferences
  └── createdAt

wardrobe/{userId}/items/{itemId}
  ├── name
  ├── category
  ├── color
  ├── brand
  ├── imageUrl
  ├── occasion
  └── metadata

favorites/{userId}/items/{itemId}
  └── itemId

notifications/{userId}/messages/{msgId}
  ├── title
  ├── body
  ├── timestamp
  └── read
```

### **Supabase (PostgreSQL)**

```sql
-- Try-on sessions
CREATE TABLE tryon_sessions (
  id UUID PRIMARY KEY,
  user_id TEXT,
  base_image_url TEXT,
  result_image_url TEXT,
  outfit_ids TEXT[],
  created_at TIMESTAMPTZ
);

-- Daily recommendations
CREATE TABLE daily_recommendations (
  id UUID PRIMARY KEY,
  user_id TEXT,
  recommended_for DATE,
  recommendations JSONB,
  created_at TIMESTAMPTZ
);

-- Calendar events linked to outfits
CREATE TABLE calendar_outfit_links (
  id UUID PRIMARY KEY,
  user_id TEXT,
  event_id TEXT,
  outfit_id TEXT,
  created_at TIMESTAMPTZ
);
```

---

## 🚀 **How to Run**

### **Frontend Setup**

```bash
cd c:\Users\PETER\Downloads\Cleo-fashion-main\Cleo-fashion-main

# Get dependencies
flutter pub get

# Generate code (Riverpod, Hive, etc.)
flutter pub run build_runner build

# Run on device/emulator
flutter run

# Run on web
flutter run -d chrome

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios
```

### **Backend Setup**

```bash
cd backend

# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Or activate (PowerShell)
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt

# Create .env file
cp .env.example .env
# Edit .env with your API keys

# Run server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Docker deployment
docker build -t cleo-fashion .
docker run -p 8000:8000 --env-file .env cleo-fashion
```

---

## 🔑 **Required Environment Variables**

### **Backend `.env`**
```
OPENAI_API_KEY=your-openai-key
GEMINI_API_KEY=your-gemini-key
OPENROUTER_API_KEY=your-openrouter-key
SUPABASE_URL=your-supabase-url
SUPABASE_SERVICE_KEY=your-service-key
FACE_SIMILARITY_THRESHOLD=0.98
USE_GPU=false
```

### **Frontend (Firebase)**
See [get_firebase_web_key.ps1](get_firebase_web_key.ps1) and configure in:
- [lib/firebase_options.dart](lib/firebase_options.dart)
- [android/app/google-services.json](android/app/google-services.json)
- [ios/Runner/GoogleService-Info.plist](ios/Runner/GoogleService-Info.plist)

---

## 📊 **API Endpoints**

### **Backend REST API**

| Endpoint | Method | Purpose |
|---|---|---|
| `/try-on` | POST | Virtual try-on processing |
| `/recommend` | POST | Generate recommendations |
| `/health` | GET | Health check |

### **Request/Response Examples**

**Virtual Try-On Request:**
```json
{
  "user_image_url": "https://example.com/photo.jpg",
  "garment_image_urls": ["https://example.com/shirt.jpg"],
  "user_id": "user123"
}
```

**Response:**
```json
{
  "status": "success",
  "result_url": "https://cdn.example.com/result.jpg",
  "metrics": {
    "face_similarity": 0.99,
    "garment_coverage": 0.95
  },
  "stages": { ... }
}
```

---

## 🔄 **Data Flow Architecture**

```
┌─────────────────────────────────────────────────────────────┐
│                     FLUTTER APP (UI)                        │
├─────────────────────────────────────────────────────────────┤
│  Auth │ Wardrobe │ Try-On │ Calendar │ Notifications │      │
├─────────────────────────────────────────────────────────────┤
│              Riverpod (State Management)                     │
├─────────────────────────────────────────────────────────────┤
│  Firebase Auth │ Firestore │ Storage │ Cloud Functions       │
│  Supabase Client │ Edge Functions                            │
├─────────────────────────────────────────────────────────────┤
│  FastAPI Backend                                            │
├─────────────────────────────────────────────────────────────┤
│  Try-On Pipeline:                                           │
│  1. Validation → 2. Analysis → 3. Masking                  │
│  4. Synthesis → 5. Generation → 6. Quality Check           │
├─────────────────────────────────────────────────────────────┤
│  External AI Services:                                      │
│  Gemini API │ OpenRouter │ InsightFace │ MediaPipe         │
├─────────────────────────────────────────────────────────────┤
│  Storage & Database:                                        │
│  Supabase (PostgreSQL) │ Firebase │ Cloud Storage           │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎨 **UI Architecture**

**Theme:** Material Design 3 (Flutter Material)

**Key Screens:**
- Auth (Login/Signup)
- Dashboard (Home)
- Virtual Try-On Screen (Main feature)
- Wardrobe Management
- Calendar View
- Settings

**State Management:** Riverpod (declarative, reactive)

**Code Location:** [`lib/src/core/theme/`](lib/src/core/theme/)

---

## 🧪 **Testing**

### **Backend Tests**
```bash
cd backend
pytest tests/
pytest -v                    # Verbose
pytest tests/test_apis.py    # Specific test
```

**Test Files:**
- [`test_tryon_endpoint.py`](backend/test_tryon_endpoint.py)
- [`test_gemini_api.py`](backend/test_gemini_api.py)
- [`test_image_generation.py`](backend/test_image_generation.py)
- [`test_apis.py`](backend/test_apis.py)

### **Frontend Testing**
```bash
flutter test
```

---

## 📝 **Key Design Patterns**

### **1. Provider Pattern (Riverpod)**
For all state management - predictable, reactive, testable.

### **2. Service Layer**
Business logic separated in services (e.g., `FashionAIChatService`)

### **3. Repository Pattern**
Data access abstracted through repositories

### **4. Model-View-ViewModel (MVVM)**
Clear separation of concerns in feature modules

### **5. Async/Await**
All async operations properly handled with error handling

---

## 🐛 **Common Issues & Solutions**

### **Firebase Not Initialized**
- Check `firebase_options.dart` exists
- Run: `flutterfire configure --project=ai-styling-c45cf`
- Verify API keys in Firebase Console

### **Backend 404 Errors**
- Ensure server is running: `uvicorn app.main:app --reload`
- Check port (default 8000)
- Verify endpoint URLs in frontend

### **Face Similarity < 98%**
- Use clearer, well-lit photos
- Ensure face is clearly visible
- Check InsightFace model is up-to-date

### **Image Generation Timeout**
- Gemini API may be slow (normal: 10-30s)
- Check API quota
- Verify API key is valid

---

## 📚 **Documentation Files**

| File | Purpose |
|---|---|
| [README.md](README.md) | Project overview |
| [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) | Installation guide |
| [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) | Feature details |
| [VIRTUAL_TRYON_COMPLETE.md](VIRTUAL_TRYON_COMPLETE.md) | Try-on feature details |
| [backend/API_DOCUMENTATION.md](backend/API_DOCUMENTATION.md) | API specs |
| [backend/README.md](backend/README.md) | Backend overview |

---

## 🎓 **Learning Path**

1. **Start with:** [README.md](README.md) & [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)
2. **Frontend structure:** Explore [`lib/src/`](lib/src/)
3. **Core features:** Study [`lib/src/features/tryon/`](lib/src/features/tryon/) (main feature)
4. **State management:** Review Riverpod providers in [`lib/src/core/providers/`](lib/src/core/providers/)
5. **Backend pipeline:** Study [`backend/app/stages/`](backend/app/stages/) files
6. **Database:** Review Supabase & Firebase configurations
7. **Deployment:** Check Docker setup and cloud configs

---

## 🚀 **Quick Commands Reference**

```bash
# Frontend
flutter pub get                           # Install deps
flutter pub run build_runner build        # Generate code
flutter run -d chrome                     # Run on web
flutter clean && flutter pub get          # Clean install

# Backend
pip install -r requirements.txt           # Install deps
python -m venv venv                       # Create env
uvicorn app.main:app --reload            # Run server
pytest tests/                             # Run tests

# Git
git status                                # Check status
git add .                                 # Stage changes
git commit -m "message"                   # Commit
git push                                  # Push changes
```

---

## 📞 **Contact & Support**

- **Backend Issues:** Check logs in terminal
- **Frontend Issues:** Use Flutter DevTools (`flutter pub global run devtools`)
- **API Issues:** Check backend/DIAGNOSE_NOT_FOUND.md

---

**Happy coding! 🎉**

This codebase implements a complete AI-powered fashion platform. Focus on the virtual try-on pipeline first as it's the core feature.
