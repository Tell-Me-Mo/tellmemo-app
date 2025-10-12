class UserProfile {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? userMetadata;

  const UserProfile({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
    this.preferences,
    this.userMetadata,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      preferences: json['preferences'] as Map<String, dynamic>?,
      userMetadata: json['user_metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'preferences': preferences,
      'user_metadata': userMetadata,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? userMetadata,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      userMetadata: userMetadata ?? this.userMetadata,
    );
  }
}

class UserPreferences {
  final String? timezone;
  final String? locale;
  final bool pushNotifications;
  final bool weeklyDigest;
  final String theme;
  final String? defaultOrganizationId;

  const UserPreferences({
    this.timezone,
    this.locale,
    this.pushNotifications = false,
    this.weeklyDigest = false,
    this.theme = 'light',
    this.defaultOrganizationId,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      timezone: json['timezone'] as String?,
      locale: json['locale'] as String?,
      pushNotifications: json['push_notifications'] as bool? ?? false,
      weeklyDigest: json['weekly_digest'] as bool? ?? false,
      theme: json['theme'] as String? ?? 'light',
      defaultOrganizationId: json['default_organization_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timezone': timezone,
      'locale': locale,
      'push_notifications': pushNotifications,
      'weekly_digest': weeklyDigest,
      'theme': theme,
      'default_organization_id': defaultOrganizationId,
    };
  }

  UserPreferences copyWith({
    String? timezone,
    String? locale,
    bool? pushNotifications,
    bool? weeklyDigest,
    String? theme,
    String? defaultOrganizationId,
  }) {
    return UserPreferences(
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      weeklyDigest: weeklyDigest ?? this.weeklyDigest,
      theme: theme ?? this.theme,
      defaultOrganizationId: defaultOrganizationId ?? this.defaultOrganizationId,
    );
  }
}