# Prompt Log

---

## ChatGPT

### Prompt 1

Format lại file plan đính kèm, dịch toàn bộ sang tiếng anh, sau đó xuất thành file markdown.

> *(đính kèm file plan của tôi)*

---

### Prompt 2

Tôi có 1 app tin tức, sử dụng Flutter.

**Core Features:**

- **News Feed:** Display a list of the latest articles with pagination (infinite scroll).
- **Search:** Allow users to search for articles. Provide a smooth, instantaneous search experience while optimizing the frequency of API calls to prevent server overloading.
- **Article Details:** Show the full content or a web view of the article.
- **Bookmarks:** Users can save articles to read later. This list must be accessible even if the device is offline.
- **Error Handling:** The app should gracefully handle common issues like "No Internet" or "Server Errors."

**Technical Expectations:**

- **Architecture:** Choose a structure that separates business logic from the UI (e.g., Clean Architecture). We look for code that follows SOLID principles.
- **State Management (Hybrid Requirement):**
  - The Search and Feed logic must be implemented using the `flutter_bloc` package to demonstrate your handling of complex event streams.
  - However, for the Article Details or Bookmark logic, you are required to use a different, more lightweight approach to show how you choose the right tool for simpler UI states.
- **Data Strategy:** Implement a caching mechanism. The app should feel fast and should not fetch the same data repeatedly.
- **Reliability:** Core business logic should be verified with unit tests. We value quality over quantity.
- **Security & Environment:** Ensure the app is ready for a production environment (e.g., secure API key handling, obfuscation).
- **Optional Requirement:** If you have time, show us how you would automate the build or testing process (e.g., CI/CD (Github Actions) or UI Automation (Patrol)).

Tôi có lên plan và chọn tech stack để phát triển:

- Tôi muốn bạn với vai trò là 1 developer trong dự án, check file plan, phản biện và cho ý kiến của bạn.
- Trên thang điểm 10 tôi muốn bạn đánh giá plan.
- Dựa trên những đánh giá, hãy cho tôi những đánh giá để cải thiện.

> *(đính kèm file plan_orginal.md)*

---

### Prompt 3

Trước khi viết lại plan, hãy làm những việc sau:

- Nếu xài Cubit thì sẽ như thế nào, nếu vẫn giữ nguyên như tôi lựa chọn xài Provider thì sẽ như thế nào.
- Tôi muốn triển khai CI/CD theo hướng sau:
  - Sử dụng Github Actions.
  - Khi tạo commit thì sẽ chạy unit test cho phần xử lý logic cụ thể là các bloc, sau đó sẽ là phần review code bằng Copilot ở repo git.

---

### Prompt 4

- Bắt đầu lên plan theo flow của bạn.
- Thiết kế architecture diagram + folder structure chuẩn production.
- Xuất ra file markdown.

---

### Prompt 5

Cũng cùng yêu cầu đánh giá về plan, hãy đánh giá về plan này.

> *(đính kèm file plan của Claude)*

---

## Claude

### Prompt 1

Tôi có 1 app tin tức, sử dụng Flutter.

**Core Features:**

- **News Feed:** Display a list of the latest articles with pagination (infinite scroll).
- **Search:** Allow users to search for articles. Provide a smooth, instantaneous search experience while optimizing the frequency of API calls to prevent server overloading.
- **Article Details:** Show the full content or a web view of the article.
- **Bookmarks:** Users can save articles to read later. This list must be accessible even if the device is offline.
- **Error Handling:** The app should gracefully handle common issues like "No Internet" or "Server Errors."

**Technical Expectations:**

- **Architecture:** Choose a structure that separates business logic from the UI (e.g., Clean Architecture). We look for code that follows SOLID principles.
- **State Management (Hybrid Requirement):**
  - The Search and Feed logic must be implemented using the `flutter_bloc` package to demonstrate your handling of complex event streams.
  - However, for the Article Details or Bookmark logic, you are required to use a different, more lightweight approach to show how you choose the right tool for simpler UI states.
- **Data Strategy:** Implement a caching mechanism. The app should feel fast and should not fetch the same data repeatedly.
- **Reliability:** Core business logic should be verified with unit tests. We value quality over quantity.
- **Security & Environment:** Ensure the app is ready for a production environment (e.g., secure API key handling, obfuscation).
- **Optional Requirement:** If you have time, show us how you would automate the build or testing process (e.g., CI/CD (Github Actions) or UI Automation (Patrol)).

Tôi có lên plan và chọn tech stack để phát triển:

- Tôi muốn bạn với vai trò là 1 developer trong dự án, check file plan, phản biện và cho ý kiến của bạn.
- Trên thang điểm 10 tôi muốn bạn đánh giá plan.
- Dựa trên những đánh giá, hãy cho tôi những đánh giá để cải thiện.

> *(đính kèm file plan_orginal.md)*

---

### Prompt 2

Trước khi viết lại, tôi muốn triển khai CI/CD theo hướng sau:

- Sử dụng Github Actions.
- Khi tạo commit thì sẽ chạy unit test cho phần xử lý logic cụ thể là các bloc, sau đó sẽ là phần review code bằng Copilot ở repo git.

---

### Prompt 3

**Q: Trigger CI/CD chạy khi nào? (Select all that apply)**
**A:** Khi tạo Pull Request.

**Q: Copilot Code Review — bạn muốn review theo hướng nào?**
**A:** Auto review mọi PR (Copilot tự comment).

**Q: Sau khi test pass, bạn có muốn build APK tự động không?**
**A:** Có, nhưng chỉ khi merge vào main.

---

### Prompt 4

Cũng cùng yêu cầu đánh giá về plan, hãy đánh giá về plan này.

> *(đính kèm file plan của ChatGPT)*

---

### Prompt 5

Trong plan này của bạn chỉ cần thêm 3 thứ nhỏ:

**1. BLoC Concurrency Strategy**

Ví dụ:

```dart
on<FetchNextPage>(
  _fetchNext,
  transformer: droppable(),
);
```

**2. Repository Interface Example**

Thêm:

```dart
abstract class NewsRepository {
  Future<List<Article>> getLatestArticles(int page);
}
```

**3. Connectivity Strategy**

Bạn có mention `connectivity_plus` nhưng chưa nói flow. Ví dụ:

```
if offline
  return cache
```

---

### Prompt 6

Về phần Day Development Timeline, mỗi lần commit code lên GitHub sẽ trigger để chạy unit test và code review. Liệu plan này có đáp ứng được điều đó khi qua ngày thứ 3 mới làm CI/CD?

---

### Prompt 7

Kiểm tra lại về ngày đầu tiên đã có news feed bloc nhưng lại thiếu unit test cho phần này.

---

### Prompt 8

Liệu có phải là thiếu sót khi chưa mô tả về phần design trong plan này?

---

### Prompt 9

- Không cần thêm phần UI/UX.
- Dựa vào plan này, hãy giúp tôi tạo 1 file markdown mới, dùng để estimation. File này bao gồm:
  - **User Stories:** Break down the requirements into clear User Stories.
  - **Story Points:** Assign an estimated Story Point to each User Story to reflect its complexity.
  - **Subtasks & Time Estimation:** Break down each User Story into smaller Subtasks and provide a Time Estimation for each.
  - **Dependency Management:** Clearly identify and explain any dependencies between subtasks or between different User Stories (e.g., which task must be completed before another can start).

> *(đính kèm file plan_final của Claude)*

---

### Prompt 10

Dựa trên file plan, phần Copilot review:

- Thiết lập repository rule cho branch protection, required status checks.
- Thêm gợi ý nếu những ý trên còn thiếu sót.

---

## Claude CLI

### Prompt 1

I want to handle the CI in the `@.github/workflows/ci.yml`:

- The test coverage will run when the commit includes the business logic such as bloc, use case, notifier. If not, skip this step.
- Verify the CI handle in here.
- Config the sub-agent to plan and implement task.

---

### Prompt 2

```
/plan @docs/estimation_v2.md US-02 — CI/CD Pipeline Setup
```

---

### Prompt 3

```
/implement
```

---

### Prompt 4

```
/simplify
```

---

### Prompt 5

I have this issue when running the CI:

```
Target of URI hasn't been generated: 'package:news_app/features/news_feed/data/models/article_model.g.dart' ...
```

---

### Prompt 6

```
/plan @docs/estimation_v2.md US-03 — View Latest News Articles
```

---

### Prompt 7

```
/implement task-01.md, task-02.md, task-03.md
```

---

### Prompt 8

```
/simplify
```

---

### Prompt 9

```
/plan @docs/estimation_v2.md US-04 — Paginate Through News Articles
```

---

### Prompt 10

```
/implement task-01.md, task-02.md
```

---

### Prompt 11

```
/simplify
```

---

### Prompt 12

```
/plan @docs/estimation_v2.md US-05 — Cache News Feed for Fast Loading
```

---

### Prompt 13

```
/implement
```

---

### Prompt 14

```
/plan @docs/estimation_v2.md US-06 — Search Articles by Keyword
```

---

### Prompt 15

```
/implement task-03.md, task-04.md
```

---

### Prompt 16

```
/simplify
```

---

### Prompt 17

```
/plan @docs/estimation_v2.md US-07 — Optimized Search with Debounce and Request Cancellation
```

---

### Prompt 18

```
/implement
```

---

### Prompt 19

```
/simplify
```

---

### Prompt 20

```
/plan US-08 — View Full Article Content
```

---

### Prompt 21

```
/implement
```

---

### Prompt 22

```
/simplify
```

---

### Prompt 23

```
/plan @docs/estimation_v2.md US-09 — Bookmark Articles to Read Later and US-10 — Access Bookmarks Offline
```

---

### Prompt 24

```
/plan US-11 — Graceful Error and Offline Handling Across All Features
```

---

### Prompt 25

`@lib/features/news_feed/data/datasources/news_feed_remote_datasource.dart` — today is 2026-02-14, why does `fromDate` return 2026-02-12?

---

### Prompt 26

I want to update the `@lib/features/article_detail/presentation/pages/article_detail_page.dart`:

- When open this view, just need to load the webview.
- Webview will load the URL in the article.

---

### Prompt 27

I updated the `@lib/features/article_detail/presentation/notifier/article_detail_notifier.dart`:

- Do we need the `@lib/features/article_detail/presentation/notifier/article_detail_state.dart`?
- If we need it, explain to me why.
- With the new update, can you check if it's good or bad?
- Update the unit test later.

---

### Prompt 28

In the `@lib/features/article_detail/presentation/pages/article_detail_page.dart`, explain to me the difference between using `sl<ArticleDetailNotifier>()` and the current approach.

---

### Prompt 29

`cancelToken` in `@lib/features/search/data/datasources/search_remote_datasource.dart` — explain it to me.

---

### Prompt 30

In the search feature we have the requirement:

> Provide a smooth, instantaneous search experience while optimizing the frequency of API calls to prevent server overloading.

- Why do you use `restartable` and `cancelToken`?
- Why don't we use `debounceTime`?
- Compare and explain it to me.

---

### Prompt 31

Remove all the `.gitkeep` files in this project.

---

### Prompt 32

This app doesn't have login, so it has a fixed `NEWS_API_KEY`. If it had login and `NEWS_API_KEY` was fetched from the server, what should we handle?

---

### Prompt 33

Why `_toModel` in `@lib/features/bookmark/data/datasources/bookmark_local_datasource.dart`?

- Explain to me its purpose when it's in this file.
- Should we move it to `@lib/features/news_feed/data/models/article_model.dart`?

---

### Prompt 34

Analyse this request:

> Security & Environment: Ensure the app is ready for a production environment (e.g., secure API key handling, obfuscation).

Check if this project satisfies this request.

---

### Prompt 35

```
/plan
```

This project is an assignment. I have a request to organize the `README.md` like a technical report...

> *(with 4 pasted texts about README requirements, git workflow, planning docs, and comparison of plans)*
