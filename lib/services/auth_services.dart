// lib/services/auth_services.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../main.dart';
import 'log_services.dart';

class AuthService {
  final LogService _logService = LogService();
  static const String _sessionKey = 'user_session';
  static const String _sessionTimeKey = 'session_time';
  static const int _sessionDuration = 24; // hours


  // Helper: Check if session is expired
  Future<bool> _isSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionTime = prefs.getInt(_sessionTimeKey);
    
    if (sessionTime == null) return true;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - sessionTime;
    final hours = diff / (1000 * 60 * 60);
    
    return hours > _sessionDuration;
  }

  // Login: Query user by username, verifikasi password hash
  Future<UserModel?> login(String username, String password) async {
    try {

      // Query manual ke tabel users
      final response = await supabase
          .from('users')
          .select('*, role(*)') // Join role
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      if (response == null) return null;

      final user = UserModel.fromJson(response);

      // Simpan sesi lokal dengan timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
      await prefs.setInt(_sessionTimeKey, DateTime.now().millisecondsSinceEpoch);

      // Log activity
      await _logService.logActivity(
        userId: user.userId,
        aktivitas: 'Login',
        deskripsi: 'User ${user.username} login',
      );

      return user;
    } catch (e) {
      // Rethrow untuk error handling di provider
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final user = await getCurrentUser();
      
      // Log activity sebelum clear session
      if (user != null) {
        await _logService.logActivity(
          userId: user.userId,
          aktivitas: 'Logout',
          deskripsi: 'User ${user.username} logout',
        );
      }

      // Clear session
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_sessionTimeKey);
    } catch (e) {
      rethrow;
    }
  }

  // Get Data User Login dengan session check
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userStr = prefs.getString(_sessionKey);

      if (userStr == null) return null;

      // Check session expiration
      final isExpired = await _isSessionExpired();
      if (isExpired) {
        await logout();
        return null;
      }

      return UserModel.fromJson(jsonDecode(userStr));
    } catch (e) {
      return null;
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    return user != null;
  }

  // Update session timestamp (call this on app resume/activity)
  Future<void> refreshSession() async {
    final user = await getCurrentUser();
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_sessionTimeKey, DateTime.now().millisecondsSinceEpoch);
    }
  }
}