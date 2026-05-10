import 'package:equatable/equatable.dart';

enum UserRole { user, sadmin }

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final UserRole role;
  final int credits;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.role = UserRole.user,
    this.credits = 0,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSuperAdmin => role == UserRole.sadmin;
  bool get hasCredits => credits > 0;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      role: json['role'] == 'sadmin' ? UserRole.sadmin : UserRole.user,
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'display_name': displayName,
    'role': role == UserRole.sadmin ? 'sadmin' : 'user',
    'credits': credits,
    'avatar_url': avatarUrl,
  };

  UserProfile copyWith({
    String? displayName,
    UserRole? role,
    int? credits,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      credits: credits ?? this.credits,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, email, displayName, role, credits, avatarUrl];
}
