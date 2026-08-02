class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[a-zA-Z]{2,}$');
  static final RegExp _phoneRegex = RegExp(r'^[0-9+\-\s]{7,15}$');

  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your full name';
    if (v.trim().length < 2) return 'Name is too short';
    return null;
  }

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your email';
    if (!_emailRegex.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter your phone number';
    if (!_phoneRegex.hasMatch(v.trim())) return 'Enter a valid phone number';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Enter a password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Confirm your password';
    if (v != original) return 'Passwords do not match';
    return null;
  }

  static String? district(String? v) {
    if (v == null || v.trim().isEmpty) return 'Select your district';
    return null;
  }

  static String? required(String? v, {String message = 'This field is required'}) {
    if (v == null || v.trim().isEmpty) return message;
    return null;
  }
}
