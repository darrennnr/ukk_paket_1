// lib\models\user_model.dart
class UserModel {
  final int userId;
  final String username;
  final String password;
  final String namaLengkap;
  final String email;
  final String? noTelepon;
  final int? roleId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Relational data (optional)
  final RoleModel? role;

  UserModel({
    required this.userId,
    required this.username,
    required this.password,
    required this.namaLengkap,
    required this.email,
    this.noTelepon,
    this.roleId,
    this.createdAt,
    this.updatedAt,
    this.role,
  });

  // Factory constructor untuk membuat instance dari JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      password: json['password'] as String,
      namaLengkap: json['nama_lengkap'] as String,
      email: json['email'] as String,
      noTelepon: json['no_telepon'] as String?,
      roleId: json['role_id'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      role: json['role'] != null 
          ? RoleModel.fromJson(json['role'] as Map<String, dynamic>)
          : null,
    );
  }

  // Method untuk convert instance ke JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'password': password,
      'nama_lengkap': namaLengkap,
      'email': email,
      'no_telepon': noTelepon,
      'role_id': roleId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Method untuk insert/update (tanpa user_id, created_at, updated_at)
  Map<String, dynamic> toInsertJson() {
    return {
      'username': username,
      'password': password,
      'nama_lengkap': namaLengkap,
      'email': email,
      'no_telepon': noTelepon,
      'role_id': roleId,
    };
  }

  // CopyWith method untuk immutability
  UserModel copyWith({
    int? userId,
    String? username,
    String? password,
    String? namaLengkap,
    String? email,
    String? noTelepon,
    int? roleId,
    DateTime? createdAt,
    DateTime? updatedAt,
    RoleModel? role,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      password: password ?? this.password,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      email: email ?? this.email,
      noTelepon: noTelepon ?? this.noTelepon,
      roleId: roleId ?? this.roleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
    );
  }
}

// Import untuk RoleModel
class RoleModel {
  final int id;
  final String? role;

  RoleModel({
    required this.id,
    this.role,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as int,
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
    };
  }
}