/// Shared password validation utilities used across the app.

// Requirements

class PasswordRequirement {
  final String label;
  final bool Function(String) test;
  const PasswordRequirement({required this.label, required this.test});
}

final passwordRequirements = <PasswordRequirement>[
  PasswordRequirement(
    label: 'At least 8 characters',
    test:  (p) => p.length >= 8,
  ),
  PasswordRequirement(
    label: 'One uppercase letter (A-Z)',
    test:  (p) => p.contains(RegExp(r'[A-Z]')),
  ),
  PasswordRequirement(
    label: 'One lowercase letter (a-z)',
    test:  (p) => p.contains(RegExp(r'[a-z]')),
  ),
  PasswordRequirement(
    label: 'One number (0-9)',
    test:  (p) => p.contains(RegExp(r'[0-9]')),
  ),
  PasswordRequirement(
    label: 'One special character (!@#\$...)',
    // Use a non-raw string so \$ works; escape the special chars explicitly
    test:  (p) => p.contains(RegExp(r'[!@#$%^&*()\-_=+\[\]{};:,.<>?/\\|`~]')),
  ),
];

// Strength score (0-5)

int passwordStrength(String password) {
  if (password.isEmpty) return 0;
  final met = passwordRequirements.where((r) => r.test(password)).length;
  if (met <= 1) return 1; // Weak
  if (met == 2) return 2; // Fair
  if (met == 3) return 3; // Good
  if (met == 4) return 4; // Strong
  return 5;               // Very Strong (all 5)
}

String strengthLabel(int score) {
  switch (score) {
    case 1:  return 'Weak';
    case 2:  return 'Fair';
    case 3:  return 'Good';
    case 4:  return 'Strong';
    case 5:  return 'Very Strong';
    default: return '';
  }
}

// Validator function (for Form)

String? validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Password is required';
  for (final req in passwordRequirements) {
    if (!req.test(v)) {
      return 'Password must include: ${req.label}';
    }
  }
  return null;
}
