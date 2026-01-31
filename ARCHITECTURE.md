# Architecture

**Version:** v2.0 (Social Media Transform)
**Last Updated:** 2026-01-31

## Folder structure
/lib
  /app
    app.dart
    router.dart (optional)
  /core
    constants.dart
    validators.dart
    theme.dart                    [v1.0 - Theme system]
  /models
    user_profile.dart
    community.dart
    article.dart
    week.dart
    comment_tree.dart             [v2.0 - Nested comments]
  /services
    auth_service.dart
    firestore_service.dart
    week_service.dart
    seed_service.dart
    vote_service.dart             [v2.0 - Comment voting]
    bookmark_service.dart         [v2.0 - Save articles]
  /screens
    login_screen.dart
    main_navigation_screen.dart   [v2.0 - Bottom nav shell]
    home_feed_screen.dart         [v2.0 - Discovery feed]
    community_select_screen.dart
    week_screen.dart
    discussion_screen.dart
    admin_screen.dart
    profile_screen.dart           [v2.0 - User profiles]
    profile_edit_screen.dart      [v2.0 - Edit profile]
    saved_articles_screen.dart    [v2.0 - Bookmarks]
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
