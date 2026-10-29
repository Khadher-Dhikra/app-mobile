class TunisianCities {
  static const List<String> list = [
    'Ariana',
    'Béja',
    'Ben Arous',
    'Bizerte',
    'Gabès',
    'Gafsa',
    'Jendouba',
    'Kairouan',
    'Kasserine',
    'Kebili',
    'Le Kef',
    'Mahdia',
    'La Manouba',
    'Médenine',
    'Monastir',
    'Nabeul',
    'Sfax',
    'Sidi Bouzid',
    'Siliana',
    'Sousse',
    'Tataouine',
    'Tozeur',
    'Tunis',
    'Zaghouan',
    // Villes et destinations populaires
    'Hammamet',
    'Djerba',
    'Zarzis',
    'Marsa',
    'Carthage',
    'Kelibia',
  ];

  static List<String> filter(String query) {
    if (query.trim().isEmpty) return list;
    final lower = query.toLowerCase().trim();
    return list.where((city) => city.toLowerCase().contains(lower)).toList();
  }
}
