class Validators {
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Email is required';
    if (!_email.hasMatch(input)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final input = value ?? '';
    if (input.isEmpty) return 'Password is required';
    if (input.length < 8) return 'Password must be at least 8 characters';
    if (!input.contains(RegExp(r'[A-Za-z]'))) {
      return 'Password must contain a letter';
    }
    if (!input.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a number';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'Confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? fullName(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Name is required';
    if (input.length < 2) return 'Name is too short';
    if (input.length > 60) return 'Name must be 60 characters or fewer';
    return null;
  }

  static String? routeLabel(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Give this route a name';
    if (input.length > 60) return 'Name must be 60 characters or fewer';
    return null;
  }

  static String? requiredStation(String? value, String field) {
    if (value == null || value.isEmpty) return 'Select a $field station';
    return null;
  }

  static String? distinctStations(String? origin, String? destination) {
    if (origin == null || destination == null) return null;
    if (origin == destination) return 'Origin and destination must differ';
    return null;
  }
}
