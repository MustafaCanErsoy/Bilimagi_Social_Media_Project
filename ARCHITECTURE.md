# Architecture (MVP)

## Folder structure
/lib
  /app
    app.dart
    router.dart
  /core
    constants.dart
    validators.dart
  /models
    user_profile.dart
    community.dart
    article.dart
  /services
    auth_service.dart
    firestore_service.dart
    week_service.dart
  /screens
    login_screen.dart
    community_select_screen.dart
    week_screen.dart
    discussion_screen.dart
    admin_screen.dart
  /widgets
    app_scaffold.dart
    primary_button.dart
    community_card.dart
    article_card.dart
    result_bar.dart

## Rules
- Keep all UI in `screens/` and reusable UI in `widgets/`.
- Keep Firebase access inside `services/` only.
- Do not create new top-level folders under `/lib` without a strong reason.
- Keep naming consistent: `*_screen.dart`, `*_service.dart`, `*_card.dart`.
- MVP-first: prefer simple, readable code over abstractions.
