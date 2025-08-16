class User {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String? role;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.role,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: (json['fullName'] ?? json['full_name']) as String,
      role: json['role'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get initials {
    List<String> nameParts = fullName.split(' ');
    if (nameParts.isEmpty) return '';
    if (nameParts.length == 1) return nameParts[0][0].toUpperCase();
    return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    String? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}