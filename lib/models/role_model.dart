// lib/models/role_model.dart
class RoleModel {
  final int id;
  final String? role;

  RoleModel({
    required this.id,
    this.role,
  });

  // Factory constructor untuk membuat instance dari JSON
  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as int,
      role: json['role'] as String?,
    );
  }

  // Method untuk convert instance ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
    };
  }

  // Method untuk insert/update
  Map<String, dynamic> toInsertJson() {
    return {
      'role': role,
    };
  }

  // CopyWith method untuk immutability
  RoleModel copyWith({
    int? id,
    String? role,
  }) {
    return RoleModel(
      id: id ?? this.id,
      role: role ?? this.role,
    );
  }

  // Helper method untuk checking role
  bool isAdmin() => role?.toLowerCase() == 'admin';
  bool isPetugas() => role?.toLowerCase() == 'petugas';
  bool isPeminjam() => role?.toLowerCase() == 'peminjam';
}