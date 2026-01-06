# 📝 Memo Me: Remember People, Not Just Numbers.

## 💡 The Problem

Traditional contact management has limitations:

* **Superficial:** Contacts only store numbers and names, but not the context or stories.
* **Disorganized:** It's hard to remember where you met someone or what topics you discussed.
* **Forgetful:** Over time, you lose important details about the people you know.

**Our Challenge:** Create a tech solution that transforms contacts into meaningful connections, organized by context and enriched with notes and emotions that truly matter.

---

## ✨ The Memo Me Solution

Memo Me is the digital platform designed to transform how you remember and organize people in your life, focusing on three core pillars:

### 1. Contextual Spaces (Intuitive Organization)

Organize your contacts into spaces that represent different contexts of your life (work, events, communities). Each space is a world where you can connect with people who share that specific context.

<img width="350" alt="Spaces & Contact Discovery" src="https://github.com/user-attachments/assets/2f4e78f8-93a5-4eb5-9195-5dca7a4d4526" />

#### Key Space Features:
* **Public & Private Spaces:** Join existing communities or create your own private spaces.
* **QR Code Join:** Scan QR codes to instantly join spaces (`QRCodeScanner`).
* **Contextual Profiles:** Each space displays your profile and other members' profiles with context-relevant information.

### 2. Personalized Memos (Notes & Vibes)

Save valuable information about each person: private notes and "vibes" (emotional tags) that capture the essence of your interactions. Contacts with memos automatically become your favorites.

<img width="350" alt="Contact Memos & Vibes" src="https://github.com/user-attachments/assets/78841659-ac4c-410d-9967-7292492a29ba" />

#### Key Memo Features:
* **Private Notes:** Save important details, conversations, or any information you want to remember.
* **Vibe System:** Tag contacts with emotions and contexts (⚡️ Energizing, 💡 Insightful, 💼 Business, ☕️ Casual, and more).
* **Favorites View:** Quickly access all your memos organized in one place.

### 3. Innovative Visualization (3D Sphere & List)

Explore your contacts in two unique ways: an interactive 3D sphere that rotates and displays all members, or a traditional list view for more structured navigation.

https://github.com/user-attachments/assets/dbce8444-81ad-4cbf-a56c-c1890fc82fc6

#### Key Visualization Features:
* **3D Sphere View:** Immersive interface with automatic rotation that displays contacts visually (`ContactSphereView`).
* **List View:** Traditional navigation with search and vibe filters.
* **Search & Filters:** Quickly find contacts by name or filter by specific vibes.

---

## 🛠️ Tech Stack & Architecture

| Category | Details |
| :--- | :--- |
| **Language** | Swift 5.9+ |
| **Frameworks** | **SwiftUI** (Declarative UI), **Firebase Firestore** (Backend), **AVFoundation** (QR Scanner) |
| **Architecture** | MVVM (Model-View-ViewModel) |
| **Development** | iOS 17.0+ |
| **Authentication** | Sign in with Apple |
| **Local Storage** | UserDefaults (Notes, Vibes, Favorites) |

**Key Structure Insight:** The modular use of `ViewModels` (`ContactDetailViewModel`, `SpacesViewModel`, `FavoritesViewModel`) and `Services` (`ContactNoteService`, `ContactVibeService`, `SpaceService`) ensures clear separation between business logic and UI, making the app highly scalable and testable.
