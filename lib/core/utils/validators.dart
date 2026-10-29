class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'adresse e-mail est requise.';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Veuillez saisir une adresse e-mail valide.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis.';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit comporter au moins 6 caractères.';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone est requis.';
    }
    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\+]'), '');
    // Supports 8 digits, or 216 followed by 8 digits
    final phoneRegex = RegExp(r'^(216)?[24579]\d{7}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Numéro tunisien invalide (ex: 98123456 ou 20123456).';
    }
    return null;
  }

  static String? validateSeats(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nombre de places est requis.';
    }
    final seats = int.tryParse(value.trim());
    if (seats == null || seats < 1 || seats > 8) {
      return 'Le nombre de places doit être entre 1 et 8.';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La contribution par place est requise.';
    }
    final price = double.tryParse(value.trim());
    if (price == null || price <= 0) {
      return 'La contribution doit être un montant positif (en TND).';
    }
    return null;
  }

  static String? validateCities(String? departure, String? arrival) {
    if (departure == null || departure.trim().isEmpty) {
      return 'La ville de départ est requise.';
    }
    if (arrival == null || arrival.trim().isEmpty) {
      return 'La ville d\'arrivée est requise.';
    }
    if (departure.trim().toLowerCase() == arrival.trim().toLowerCase()) {
      return 'La ville de départ et la ville d\'arrivée ne peuvent pas être identiques.';
    }
    return null;
  }

  static String? validateFutureDate(DateTime? dateTime) {
    if (dateTime == null) {
      return 'La date et l\'heure de départ sont requises.';
    }
    if (dateTime.isBefore(DateTime.now())) {
      return 'La date de départ ne peut pas être dans le passé.';
    }
    return null;
  }
}
