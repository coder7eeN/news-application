# Flutter News App — Technical Plan (3-Day Deadline)

## 1. Project Overview

This project aims to build a **production-ready Flutter news application** that is scalable, maintainable, and reliable within a **3-day development deadline**.

The application retrieves news articles from **NewsAPI** and provides users with a smooth reading experience including searching, bookmarking, and offline access.

Key priorities:

- Clean and scalable architecture
- Efficient API usage
- Smooth user experience
- Offline bookmark support
- Reliable error handling
- Core business logic testing

API Provider: https://newsapi.org/

---

# 2. Core Features

## 2.1 News Feed

Displays the latest articles retrieved from the API.

Features:

- Infinite scroll pagination
- Pull-to-refresh
- Loading indicators
- Cached results for faster loading

Performance considerations:

- Avoid repeated API calls
- Smooth scrolling performance
- Cache recent results

---

## 2.2 Search Articles

Allows users to search for articles by keyword.

Features:

- Real-time search
- Input debouncing
- Loading and empty states
- Optimized API requests

Optimization techniques:

- Debounce user input (300–500ms)
- Cancel outdated requests
- Prevent unnecessary API calls

---

## 2.3 Article Details

Displays the selected article.

Display approaches:

- Render article content
- Open article using WebView

Features:

- Loading state
- Error handling
- External article navigation

---

## 2.4 Bookmarks

Users can save articles to read later.

Features:

- Add/remove bookmarks
- Offline access
- Persistent storage

Requirements:

Bookmarks must remain accessible **even without internet connection**.

---

## 2.5 Error Handling

The app should gracefully handle common failures.

Handled scenarios:

- No Internet connection
- Server errors
- API timeouts
- Empty results

UI behavior:

- Friendly error messages
- Retry option
- Cached fallback data when available

---

# 3. Architecture

The project follows **Clean Architecture combined with MVVM principles**.


# 4. MVVM Mapping

| Layer | Responsibility |
|------|------|
| View | Flutter pages and widgets |
| ViewModel | BLoC / ChangeNotifier / ValueNotifier |
| Model | Domain entities |

This mapping ensures UI remains independent of business logic.

---

# 5. Tech Stack

| Category | Technology |
|--------|--------|
| Framework | Flutter |
| Architecture | Clean Architecture + MVVM |
| State Management | flutter_bloc, Provider |
| Networking | Dio |
| Local Storage | Hive |
| Dependency Injection | GetIt |
| Equality | Equatable |
| Testing | Mocktail |
| WebView | webview_flutter |

---

# 6. State Management Strategy

| Feature | State Management | Reason |
|------|------|------|
| News Feed | BLoC | Handles pagination and async streams |
| Search | BLoC | Debounced input and complex states |
| Article Detail | ValueNotifier | Simple UI state |
| Bookmarks | ChangeNotifier | Local persistent state |

---
---

# 7. Caching Strategy

The application uses a **Cache-First strategy**.

---

# 8. Dependency Injection

Dependency injection is implemented using **GetIt**.

---

# 9. Security & Environment

## API Key Handling

Environment variables will be managed using:


flutter_dotenv

---
