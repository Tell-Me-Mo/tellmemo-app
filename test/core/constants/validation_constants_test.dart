import 'package:flutter_test/flutter_test.dart';
import 'package:pm_master_v2/core/constants/validation_constants.dart';

void main() {
  group('ValidationConstants', () {
    test('should have correct min/max length values', () {
      expect(ValidationConstants.nameMinLength, 3);
      expect(ValidationConstants.nameMaxLength, 100);
      expect(ValidationConstants.descriptionMaxLength, 500);
    });

    test('should have correct error messages', () {
      expect(ValidationConstants.nameRequired, 'Please enter a name');
      expect(ValidationConstants.nameTooShort('Project'), 'Project name must be at least 3 characters');
      expect(ValidationConstants.nameTooLong('Portfolio'), 'Portfolio name must be less than 100 characters');
      expect(ValidationConstants.descriptionTooLong, 'Description must be less than 500 characters');
      expect(ValidationConstants.namePatternError, 'Name can only contain letters, numbers, spaces, and common punctuation');
    });

    test('namePattern should match valid names', () {
      final validNames = [
        'Project A',
        'Test-123',
        'Portfolio_2024',
        'Q4 (Planning)',
        'Tech & Design',
        'Meeting, Day 1',
        'Initiative.Final',
      ];

      for (final name in validNames) {
        expect(
          ValidationConstants.namePattern.hasMatch(name),
          true,
          reason: 'Expected "$name" to match namePattern',
        );
      }
    });

    test('namePattern should reject invalid names', () {
      final invalidNames = [
        'Test@Email',
        'Name#Tag',
        'Price\$100',
        'Test%Value',
        'Name^Power',
        'Test*Star',
        'Name+Plus',
        'Test=Equal',
        'Name[Bracket]',
        'Test{Brace}',
        'Name|Pipe',
        'Test\\Backslash',
        'Name/Slash',
        'Test<Greater',
        'Name>Less',
        'Test?Question',
        'Name!Exclaim',
        'Test~Tilde',
        'Name`Backtick',
      ];

      for (final name in invalidNames) {
        expect(
          ValidationConstants.namePattern.hasMatch(name),
          false,
          reason: 'Expected "$name" to NOT match namePattern',
        );
      }
    });
  });

  group('FormValidators.validateName', () {
    group('Required field validation', () {
      test('should return error when value is null', () {
        final result = FormValidators.validateName(null, 'Project');
        expect(result, ValidationConstants.nameRequired);
      });

      test('should return error when value is empty', () {
        final result = FormValidators.validateName('', 'Project');
        expect(result, ValidationConstants.nameRequired);
      });

      test('should return error when value is only whitespace', () {
        final result = FormValidators.validateName('   ', 'Project');
        expect(result, ValidationConstants.nameRequired);
      });
    });

    group('Length validation', () {
      test('should return error when name is too short', () {
        final result = FormValidators.validateName('AB', 'Project');
        expect(result, 'Project name must be at least 3 characters');
      });

      test('should accept name with exactly min length', () {
        final result = FormValidators.validateName('ABC', 'Project');
        expect(result, null);
      });

      test('should accept name within valid range', () {
        final result = FormValidators.validateName('Valid Project Name', 'Project');
        expect(result, null);
      });

      test('should accept name with exactly max length', () {
        final name = 'A' * 100;
        final result = FormValidators.validateName(name, 'Project');
        expect(result, null);
      });

      test('should return error when name exceeds max length', () {
        final name = 'A' * 101;
        final result = FormValidators.validateName(name, 'Project');
        expect(result, 'Project name must be less than 100 characters');
      });

      test('should trim whitespace before checking length', () {
        final result = FormValidators.validateName('  ABC  ', 'Project');
        expect(result, null);
      });
    });

    group('Pattern validation', () {
      test('should accept names with letters and numbers', () {
        final result = FormValidators.validateName('Project123', 'Project');
        expect(result, null);
      });

      test('should accept names with spaces', () {
        final result = FormValidators.validateName('My Project', 'Project');
        expect(result, null);
      });

      test('should accept names with hyphens', () {
        final result = FormValidators.validateName('Project-A', 'Project');
        expect(result, null);
      });

      test('should accept names with underscores', () {
        final result = FormValidators.validateName('Project_A', 'Project');
        expect(result, null);
      });

      test('should accept names with ampersands', () {
        final result = FormValidators.validateName('Tech & Design', 'Project');
        expect(result, null);
      });

      test('should accept names with parentheses', () {
        final result = FormValidators.validateName('Q4 (Planning)', 'Project');
        expect(result, null);
      });

      test('should accept names with commas', () {
        final result = FormValidators.validateName('Day 1, Part A', 'Project');
        expect(result, null);
      });

      test('should accept names with periods', () {
        final result = FormValidators.validateName('Version 1.0', 'Project');
        expect(result, null);
      });

      test('should reject names with @ symbol', () {
        final result = FormValidators.validateName('Project@123', 'Project');
        expect(result, ValidationConstants.namePatternError);
      });

      test('should reject names with # symbol', () {
        final result = FormValidators.validateName('Project#123', 'Project');
        expect(result, ValidationConstants.namePatternError);
      });

      test('should reject names with \$ symbol', () {
        final result = FormValidators.validateName(r'Project$123', 'Project');
        expect(result, ValidationConstants.namePatternError);
      });

      test('should reject names with special characters', () {
        final invalidNames = ['Test*', 'Name+', 'Value=', 'Name[', 'Test{', 'Name|'];
        for (final name in invalidNames) {
          final result = FormValidators.validateName(name, 'Project');
          expect(result, ValidationConstants.namePatternError);
        }
      });
    });

    group('Different item types', () {
      test('should customize error message for Portfolio', () {
        final result = FormValidators.validateName('AB', 'Portfolio');
        expect(result, 'Portfolio name must be at least 3 characters');
      });

      test('should customize error message for Program', () {
        final result = FormValidators.validateName('AB', 'Program');
        expect(result, 'Program name must be at least 3 characters');
      });

      test('should customize error message for Task', () {
        final result = FormValidators.validateName('AB', 'Task');
        expect(result, 'Task name must be at least 3 characters');
      });
    });
  });

  group('FormValidators.validateDescription', () {
    test('should accept null description', () {
      final result = FormValidators.validateDescription(null);
      expect(result, null);
    });

    test('should accept empty description', () {
      final result = FormValidators.validateDescription('');
      expect(result, null);
    });

    test('should accept description within max length', () {
      final description = 'A' * 400;
      final result = FormValidators.validateDescription(description);
      expect(result, null);
    });

    test('should accept description with exactly max length', () {
      final description = 'A' * 500;
      final result = FormValidators.validateDescription(description);
      expect(result, null);
    });

    test('should return error when description exceeds max length', () {
      final description = 'A' * 501;
      final result = FormValidators.validateDescription(description);
      expect(result, ValidationConstants.descriptionTooLong);
    });

    test('should trim whitespace before checking length', () {
      final description = '  ${'A' * 500}  ';
      final result = FormValidators.validateDescription(description);
      expect(result, null);
    });

    test('should handle multiline descriptions', () {
      final description = 'Line 1\nLine 2\nLine 3';
      final result = FormValidators.validateDescription(description);
      expect(result, null);
    });
  });

  group('FormValidators.validateUrl', () {
    group('Optional URL', () {
      test('should accept null URL', () {
        final result = FormValidators.validateUrl(null);
        expect(result, null);
      });

      test('should accept empty URL', () {
        final result = FormValidators.validateUrl('');
        expect(result, null);
      });

      test('should accept whitespace-only URL', () {
        final result = FormValidators.validateUrl('   ');
        expect(result, null);
      });
    });

    group('Valid URLs', () {
      test('should accept HTTP URLs', () {
        final result = FormValidators.validateUrl('http://example.com');
        expect(result, null);
      });

      test('should accept HTTPS URLs', () {
        final result = FormValidators.validateUrl('https://example.com');
        expect(result, null);
      });

      test('should accept URLs with paths', () {
        final result = FormValidators.validateUrl('https://example.com/path/to/page');
        expect(result, null);
      });

      test('should accept URLs with query parameters', () {
        final result = FormValidators.validateUrl('https://example.com?param=value&id=123');
        expect(result, null);
      });

      test('should accept URLs with ports', () {
        final result = FormValidators.validateUrl('https://example.com:8080');
        expect(result, null);
      });

      test('should accept URLs with subdomains', () {
        final result = FormValidators.validateUrl('https://subdomain.example.com');
        expect(result, null);
      });

      test('should trim whitespace from URLs', () {
        final result = FormValidators.validateUrl('  https://example.com  ');
        expect(result, null);
      });
    });

    group('Invalid URLs', () {
      test('should reject URL without scheme', () {
        final result = FormValidators.validateUrl('example.com');
        expect(result, 'Please enter a valid URL');
      });

      test('should reject URL with scheme but no authority', () {
        final result = FormValidators.validateUrl('https://');
        expect(result, 'Please enter a valid URL');
      });

      test('should reject malformed URLs', () {
        final result = FormValidators.validateUrl('not a url');
        expect(result, 'Please enter a valid URL');
      });

      test('should accept URLs with FTP scheme (limitation of current implementation)', () {
        final result = FormValidators.validateUrl('ftp://example.com');
        // Note: This passes because we only check hasScheme and hasAuthority
        // If we want to restrict to http/https only, this would be a bug
        expect(result, null);
      });
    });
  });

  group('FormValidators.validateEmail', () {
    group('Required field validation', () {
      test('should return error when email is null', () {
        final result = FormValidators.validateEmail(null);
        expect(result, 'Please enter an email address');
      });

      test('should return error when email is empty', () {
        final result = FormValidators.validateEmail('');
        expect(result, 'Please enter an email address');
      });

      test('should return error when email is only whitespace', () {
        final result = FormValidators.validateEmail('   ');
        expect(result, 'Please enter an email address');
      });
    });

    group('Valid email formats', () {
      test('should accept standard email', () {
        final result = FormValidators.validateEmail('user@example.com');
        expect(result, null);
      });

      test('should accept email with dots in local part', () {
        final result = FormValidators.validateEmail('first.last@example.com');
        expect(result, null);
      });

      test('should accept email with plus sign', () {
        final result = FormValidators.validateEmail('user+tag@example.com');
        expect(result, null);
      });

      test('should accept email with numbers', () {
        final result = FormValidators.validateEmail('user123@example456.com');
        expect(result, null);
      });

      test('should accept email with hyphens in domain', () {
        final result = FormValidators.validateEmail('user@my-company.com');
        expect(result, null);
      });

      test('should accept email with subdomain', () {
        final result = FormValidators.validateEmail('user@mail.example.com');
        expect(result, null);
      });

      test('should accept email with long TLD', () {
        final result = FormValidators.validateEmail('user@example.museum');
        expect(result, null);
      });

      test('should trim whitespace from email', () {
        final result = FormValidators.validateEmail('  user@example.com  ');
        expect(result, null);
      });
    });

    group('Invalid email formats', () {
      test('should reject email without @ symbol', () {
        final result = FormValidators.validateEmail('userexample.com');
        expect(result, 'Please enter a valid email address');
      });

      test('should reject email without domain', () {
        final result = FormValidators.validateEmail('user@');
        expect(result, 'Please enter a valid email address');
      });

      test('should reject email without local part', () {
        final result = FormValidators.validateEmail('@example.com');
        expect(result, 'Please enter a valid email address');
      });

      test('should reject email without TLD', () {
        final result = FormValidators.validateEmail('user@example');
        expect(result, 'Please enter a valid email address');
      });

      test('should reject email with spaces', () {
        final result = FormValidators.validateEmail('user name@example.com');
        expect(result, 'Please enter a valid email address');
      });

      test('should reject email with multiple @ symbols', () {
        final result = FormValidators.validateEmail('user@@example.com');
        expect(result, 'Please enter a valid email address');
      });

      test('should reject email with invalid characters', () {
        final result = FormValidators.validateEmail('user!name@example.com');
        expect(result, 'Please enter a valid email address');
      });

      test('should reject email with TLD less than 2 characters', () {
        final result = FormValidators.validateEmail('user@example.c');
        expect(result, 'Please enter a valid email address');
      });
    });
  });

  group('FormValidators.validateRequiredEmail', () {
    test('should behave identically to validateEmail', () {
      final testCases = [
        null,
        '',
        '   ',
        'user@example.com',
        'invalid',
        'user@',
        '@example.com',
      ];

      for (final testCase in testCases) {
        final result1 = FormValidators.validateEmail(testCase);
        final result2 = FormValidators.validateRequiredEmail(testCase);
        expect(result1, result2, reason: 'validateRequiredEmail should match validateEmail for "$testCase"');
      }
    });
  });

  group('FormValidators.validatePassword', () {
    group('Required field validation', () {
      test('should return error when password is null', () {
        final result = FormValidators.validatePassword(null);
        expect(result, 'Please enter a password');
      });

      test('should return error when password is empty', () {
        final result = FormValidators.validatePassword('');
        expect(result, 'Please enter a password');
      });
    });

    group('Password strength validation', () {
      test('should return error when password is less than 6 characters', () {
        final result = FormValidators.validatePassword('12345');
        expect(result, 'Password must be at least 6 characters');
      });

      test('should accept password with exactly 6 characters', () {
        final result = FormValidators.validatePassword('123456');
        expect(result, null);
      });

      test('should accept password with more than 6 characters', () {
        final result = FormValidators.validatePassword('12345678');
        expect(result, null);
      });

      test('should accept password with letters and numbers', () {
        final result = FormValidators.validatePassword('Pass123');
        expect(result, null);
      });

      test('should accept password with special characters', () {
        final result = FormValidators.validatePassword('Pass@123!');
        expect(result, null);
      });

      test('should accept strong password', () {
        final result = FormValidators.validatePassword('MyStr0ng!Pass');
        expect(result, null);
      });
    });

    group('Edge cases', () {
      test('should not trim whitespace from password', () {
        // Passwords should not be trimmed - whitespace can be part of password
        final result = FormValidators.validatePassword('  123456  ');
        expect(result, null); // 10 characters including spaces
      });

      test('should accept password with only spaces if length >= 6', () {
        final result = FormValidators.validatePassword('      ');
        expect(result, null); // 6 spaces
      });
    });
  });

  group('FormValidators.validateConfirmPassword', () {
    group('Required field validation', () {
      test('should return error when confirm password is null', () {
        final result = FormValidators.validateConfirmPassword(null, 'password123');
        expect(result, 'Please confirm your password');
      });

      test('should return error when confirm password is empty', () {
        final result = FormValidators.validateConfirmPassword('', 'password123');
        expect(result, 'Please confirm your password');
      });
    });

    group('Password matching', () {
      test('should accept when passwords match', () {
        final result = FormValidators.validateConfirmPassword('password123', 'password123');
        expect(result, null);
      });

      test('should return error when passwords do not match', () {
        final result = FormValidators.validateConfirmPassword('password123', 'password456');
        expect(result, 'Passwords do not match');
      });

      test('should be case-sensitive', () {
        final result = FormValidators.validateConfirmPassword('Password123', 'password123');
        expect(result, 'Passwords do not match');
      });

      test('should check exact match including whitespace', () {
        final result = FormValidators.validateConfirmPassword('password123 ', 'password123');
        expect(result, 'Passwords do not match');
      });

      test('should accept matching passwords with special characters', () {
        final result = FormValidators.validateConfirmPassword('Pass@123!', 'Pass@123!');
        expect(result, null);
      });

      test('should accept matching passwords with spaces', () {
        final result = FormValidators.validateConfirmPassword('my password', 'my password');
        expect(result, null);
      });

      test('should accept matching empty strings', () {
        final result = FormValidators.validateConfirmPassword('', '');
        expect(result, 'Please confirm your password');
      });
    });
  });
}
