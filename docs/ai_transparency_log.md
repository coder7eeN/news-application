# AI Transparency Log

Full disclosure of AI tools used throughout the development of this project.

---

## 1. Tools Used

| Tool | Model | Purpose |
|---|---|---|
| Claude Code CLI | Claude (Anthropic) | Pair programming partner — architecture planning, assisted implementation, code review, bug fixing |
| ChatGPT | GPT-4 (OpenAI) | Alternative technical plan for comparison |
| GitHub Copilot Auto Review | Copilot (GitHub) | Automated code review on every pull request |

---

## 2. AI-Assisted Modules

| Area | Contribution | Notes |
|---|---|---|
| Personal technical plan | Self-written | [`docs/plan_original.md`](plan_original.md) — initial plan before any AI input |
| ChatGPT technical plan | ChatGPT (GPT-4) | [`docs/chat_gpt_plan.md`](chat_gpt_plan.md) — second perspective on architecture |
| Final technical plan | Co-authored (developer + Claude) | [`docs/plan_final.md`](plan_final.md) — refined plan incorporating best ideas from all three |
| Architecture reference docs | AI-assisted (Claude) | [`docs/architecture_reference.md`](architecture_reference.md), [`docs/caching_and_networking.md`](caching_and_networking.md), [`docs/code_style_reference.md`](code_style_reference.md) |
| Estimation & task breakdown | Co-authored (developer + Claude) | [`docs/estimation.md`](estimation.md) — user stories, story points, subtask estimates developed together |
| Feature implementation (UI, business logic) | Pair programming (developer + Claude) | Developer wrote code with AI assistance across 11 PRs — not fully AI-generated |
| Unit tests | AI heavily assisted (Claude) | Test files generated with AI, reviewed and adjusted by developer |
| CI/CD pipelines | AI heavily assisted (Claude) | `ci.yml` and `build.yml` workflow files |
| News Feed config & model | AI heavily assisted (Claude) | Dio setup, Hive adapters, `ArticleModel` serialization |
| Code review (PRs) | GitHub Copilot | Automated review comments on every pull request |

---

## 3. Prompt Log

AI assistance was used through structured workflow commands rather than ad-hoc prompts:

| Workflow | Command | What It Did |
|---|---|---|
| Planning | `/plan` | Scanned codebase, analyzed requirements, produced layer-ordered task lists for each feature |
| Implementation | `/implement` | Generated production code for each subtask following Clean Architecture rules |
| Review | `/review` | Ran 4-point quality checklist: lint, tests, domain boundary check, `.fold()` verification |
| Fix | `/fix` | Fixed lint errors, test failures, and architecture violations flagged during review |

### Development Workflow

This is the end-to-end workflow used for every feature:

```
Estimation file (docs/estimation.md)
    ↓
Split user story into tasks by layer (domain → data → presentation)
    ↓
Assign task to Claude Code with structured prompt
    ↓
Claude Code generates code (pair programming)
    ↓
Local review: flutter analyze + flutter test + check imports
    ↓
Fix immediately in session if issues found
    ↓
Commit + push → create PR
    ↓
CI runs automatically (test + analyze)
    ↓
Copilot Auto Review comments on PR
    ↓
Fix if needed → CI green → merge → APK build automatically
```

Each cycle followed the same commands: `/plan` → `/implement` → `/review` → `/fix` (if needed)

---

## 4. Code Review Reflection

### Review Process

Development was done through pair programming — I wrote code alongside AI, not by accepting fully generated output. AI-assisted code was always reviewed before merge. Each PR went through:

1. **Architecture boundary check** — verified domain layer has zero imports from data/presentation
2. **Error handling audit** — confirmed every `.fold()` handles both `Left` (failure) and `Right` (success) paths
3. **Edge case testing** — tested offline mode, empty results, API errors manually
4. **UI/UX review** — verified layouts, loading states, and error messages match design intent

### AI Strengths

- **Consistent Clean Architecture adherence** — layer boundaries were never violated across 11 PRs
- **Comprehensive error handling** — `Either<Failure, T>` pattern applied uniformly
- **Boilerplate reduction** — BLoC events/states, Hive adapters, and DI registration generated quickly
- **Test scaffolding** — `bloc_test` + `mocktail` patterns generated correctly on first attempt

### AI Weaknesses

- **Needed human judgment for UI/UX decisions** — spacing, loading indicator placement, empty state messaging
- **Assignment rubric compliance** — AI didn't know what the rubric required; this required manual mapping
- **Feature prioritization** — AI would implement the "ideal" version; had to scope down for 3-day deadline
- **Context drift** — longer sessions occasionally lost track of earlier architectural decisions

### Mistakes Caught

- **`flutter_dotenv` security issue** — Both the personal plan ([`plan_original.md`](plan_original.md)) and ChatGPT plan ([`chat_gpt_plan.md`](chat_gpt_plan.md)) recommended `flutter_dotenv` for API key management. The Claude-assisted final plan ([`plan_final.md`](plan_final.md)) identified this as a security risk: `.env` files are bundled as assets and extractable from APK via `apktool`. The final plan switched to `--dart-define`, which compiles the value into the binary.
- **Cache TTL mismatch** — ChatGPT plan suggested 10-minute TTL; final plan standardized on 15 minutes after analyzing typical NewsAPI rate limits.
- **Test timing** — Initial plan placed all tests at the end (Day 3). Final plan integrated tests at the end of each feature task, ensuring CI catches issues immediately.

---

## 5. Personal Insights

AI was genuinely helpful as a pair programming partner — it made the 3-day deadline achievable without cutting corners. The workflow was collaborative: I wrote code alongside AI, using it to handle the repetitive boilerplate (Hive adapters, BLoC events/states, DI registration, unit tests) while I focused on the decisions that actually matter: architecture boundaries, caching strategy, UI/UX, and offline behavior.

The areas where AI contributed most heavily were unit tests, CI/CD pipeline setup, and the news feed configuration/model layer — these are pattern-heavy tasks where AI consistency saved significant time. For features like search, article detail, and bookmarks, it was more of a back-and-forth: I'd write the core logic, AI would help with the surrounding infrastructure, and I'd review and adjust.

That said, AI wasn't a replacement for thinking. Every plan it generated needed adjustment — scoping features for the deadline, choosing what to test vs. skip, and making sure the rubric requirements were covered. The most productive pattern was treating AI as a knowledgeable but context-limited teammate: give it clear instructions, code together, and make the final calls myself.

---

## 6. Lessons Learned

- **Comparing multiple AI plans is valuable.** The three-plan approach (personal, ChatGPT, Claude) caught the `flutter_dotenv` security issue that a single plan would have missed. Each tool had blind spots the others filled.
- **AI excels at boilerplate but needs oversight for architecture decisions.** It reliably produced correct BLoC/UseCase/Repository code, but decisions like "should search results be cached?" or "what cache TTL makes sense?" required human judgment.
- **Structured workflows beat ad-hoc prompting.** The `/plan` -> `/implement` -> `/review` -> `/fix` cycle kept output consistent and caught issues early. Unstructured "just write the feature" prompts produced lower quality code.
- **CI/CD from Day 1 catches AI mistakes early.** Having `flutter analyze` and tests run on every PR meant lint errors and test failures were caught in the same session they were introduced, not days later.
- **AI doesn't know your constraints.** It doesn't know the rubric, the deadline, or which features are optional. The developer's role is to provide that context and make the trade-off decisions.
