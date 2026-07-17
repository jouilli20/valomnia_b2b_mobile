class UserProfile {
  const UserProfile({required this.name, required this.email});

  final String? name;
  final String? email;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final firstName = _firstValue(json, const [
      'firstName',
      'firstname',
      'first_name',
      'prenom',
      'prename',
    ]);
    final lastName = _firstValue(json, const [
      'lastName',
      'lastname',
      'last_name',
      'nom',
      'surname',
    ]);

    return UserProfile(
      name:
          _firstValue(json, const [
            'user_name',
            'userName',
            'fullName',
            'full_name',
            'displayName',
            'display_name',
            'name',
          ]) ??
          _joinName(firstName, lastName),
      email: _firstValue(json, const [
        'user_email',
        'userEmail',
        'email',
        'mail',
        'username',
        'login',
      ]),
    );
  }

  UserProfile mergeFallback(UserProfile fallback) {
    return UserProfile(
      name: name ?? fallback.name,
      email: email ?? fallback.email,
    );
  }
}

String? _firstValue(Map<String, dynamic>? source, List<String> keys) {
  if (source == null) return null;

  for (final key in keys) {
    final value = _clean(source[key]);
    if (value != null) return value;
  }

  for (final key in ['data', 'user', 'profile', 'result']) {
    final nested = source[key];
    if (nested is Map) {
      final value = _firstValue(Map<String, dynamic>.from(nested), keys);
      if (value != null) return value;
    }
  }

  return null;
}

String? _joinName(String? firstName, String? lastName) {
  final parts = [firstName, lastName]
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty);
  final name = parts.join(' ');
  return name.isEmpty ? null : name;
}

String? _clean(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}
