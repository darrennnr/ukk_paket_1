// lib/services/user_services.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import '../main.dart';
import 'auth_services.dart';
import 'log_services.dart';

class UserService {
  final String _table = 'users';
  final LogService _logService = LogService();
  final AuthService _authService = AuthService();

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // GetAllUsers dengan pagination & search (OPTIMIZED)
  Future<List<UserModel>> getAllUsers({String? query}) async {
    if (query == null || query.isEmpty) {
      // Jika tidak ada search, ambil semua
      final response = await supabase
          .from(_table)
          .select('*, role(*)')
          .order('nama_lengkap', ascending: true);

      return (response as List).map((e) => UserModel.fromJson(e)).toList();
    }

    // Jika ada search, lakukan 3 query terpisah dan gabungkan
    final searchPattern = '%$query%';

    final byName = await supabase
        .from(_table)
        .select('*, role(*)')
        .ilike('nama_lengkap', searchPattern);

    final byUsername = await supabase
        .from(_table)
        .select('*, role(*)')
        .ilike('username', searchPattern);

    final byEmail = await supabase
        .from(_table)
        .select('*, role(*)')
        .ilike('email', searchPattern);

    // Gabungkan dan hapus duplikat berdasarkan user_id
    final Map<int, UserModel> userMap = {};

    for (var item in [...byName, ...byUsername, ...byEmail]) {
      final user = UserModel.fromJson(item);
      userMap[user.userId] = user;
    }

    // Convert ke list dan sort
    final users = userMap.values.toList();
    users.sort((a, b) => a.namaLengkap.compareTo(b.namaLengkap));

    return users;
  }

  // Create User
  Future<void> createUser(UserModel user) async {

    final data = user.toInsertJson();

    final response = await supabase.from(_table).insert(data).select().single();
    final newUser = UserModel.fromJson(response);

    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      await _logService.logActivity(
        userId: currentUser.userId,
        aktivitas: 'Create User',
        tabelTerkait: _table,
        idTerkait: newUser.userId,
        deskripsi: 'Menambahkan user: ${newUser.username}',
      );
    }
  }

  // Update User
  Future<void> updateUser(UserModel user) async {
    final data = user.toInsertJson();

    if (user.password.isNotEmpty) {
      data['password'] = _hashPassword(user.password);
    } else {
      data.remove('password');
    }

    await supabase.from(_table).update(data).eq('user_id', user.userId);

    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      await _logService.logActivity(
        userId: currentUser.userId,
        aktivitas: 'Update User',
        tabelTerkait: _table,
        idTerkait: user.userId,
      );
    }
  }

  // Delete User
  Future<void> deleteUser(int userId) async {
    await supabase.from(_table).delete().eq('user_id', userId);

    final currentUser = await _authService.getCurrentUser();
    if (currentUser != null) {
      await _logService.logActivity(
        userId: currentUser.userId,
        aktivitas: 'Delete User',
        tabelTerkait: _table,
        idTerkait: userId,
      );
    }
  }
}
