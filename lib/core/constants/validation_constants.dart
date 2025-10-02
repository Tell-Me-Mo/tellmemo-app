class ValidationConstants {
  ValidationConstants._();

  // Name validation
  static const int nameMinLength = 3;
  static const int nameMaxLength = 100;
  static const int descriptionMaxLength = 500;
  
  // Error messages
  static const String nameRequired = 'Please enter a name';
  static String nameTooShort(String itemType) => 
    '$itemType name must be at least $nameMinLength characters';
  static String nameTooLong(String itemType) => 
    '$itemType name must be less than $nameMaxLength characters';
  static const String descriptionTooLong = 
    'Description must be less than $descriptionMaxLength characters';
  
  // Regex patterns
  static final RegExp namePattern = RegExp(r'^[a-zA-Z0-9\s\-_&(),.]+$');
  static const String namePatternError = 
    'Name can only contain letters, numbers, spaces, and common punctuation';
}

class FormValidators {
  FormValidators._();
  
  static String? validateName(String? value, String itemType) {
    if (value == null || value.trim().isEmpty) {
      return ValidationConstants.nameRequired;
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length < ValidationConstants.nameMinLength) {
      return ValidationConstants.nameTooShort(itemType);
    }
    
    if (trimmed.length > ValidationConstants.nameMaxLength) {
      return ValidationConstants.nameTooLong(itemType);
    }
    
    if (!ValidationConstants.namePattern.hasMatch(trimmed)) {
      return ValidationConstants.namePatternError;
    }
    
    return null;
  }
  
  static String? validateDescription(String? value) {
    if (value != null && value.trim().length > ValidationConstants.descriptionMaxLength) {
      return ValidationConstants.descriptionTooLong;
    }
    return null;
  }
  
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL is optional
    }
    
    try {
      final uri = Uri.parse(value.trim());
      if (!uri.hasScheme || !uri.hasAuthority) {
        return 'Please enter a valid URL';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }
  
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an email address';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validateRequiredEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an email address';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }

    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }
}