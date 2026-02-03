/// Interest categories for user profiles
/// v7.2: Scientific interest tags with Turkish labels
class InterestCategory {
  /// Map of interest keys to Turkish labels
  static const Map<String, String> labels = {
    'physics': 'Fizik',
    'biology': 'Biyoloji',
    'chemistry': 'Kimya',
    'mathematics': 'Matematik',
    'medicine': 'Tip',
    'engineering': 'Muhendislik',
    'psychology': 'Psikoloji',
    'astronomy': 'Astronomi',
    'ecology': 'Ekoloji',
    'computer_science': 'Bilgisayar Bilimi',
    'neuroscience': 'Noroloji',
    'genetics': 'Genetik',
    'climate': 'Iklim Bilimi',
    'artificial_intelligence': 'Yapay Zeka',
    'quantum': 'Kuantum Fizigi',
  };

  /// Get Turkish label for an interest key
  static String getLabel(String key) {
    return labels[key] ?? key;
  }

  /// Get all available interest keys
  static List<String> get allKeys => labels.keys.toList();

  /// Maximum number of interests a user can select
  static const int maxSelection = 5;
}
