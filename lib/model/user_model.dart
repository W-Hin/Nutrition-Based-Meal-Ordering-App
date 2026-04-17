class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String role; // 'user' or 'admin'
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id:        map['id'] as String,
      email:     map['email'] as String? ?? '',
      fullName:  map['full_name'] as String? ?? '',
      phone:     map['phone'] as String? ?? '',
      role:      map['role'] as String? ?? 'user',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id':        id,
        'email':     email,
        'full_name': fullName,
        'phone':     phone,
        'role':      role,
      };

  bool get isAdmin => role == 'admin';
}
