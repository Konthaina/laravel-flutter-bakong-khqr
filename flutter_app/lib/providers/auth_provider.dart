import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService apiService;
  
  bool _isLoggedIn = false;
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider({required this.apiService});

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initAuth() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      if (_token != null) {
        _isLoggedIn = true;
        _user = _decodeUserData(prefs.getString('user_data'));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.post(
        '/auth/login',
        {'email': email, 'password': password},
        withAuth: false,
      );

      _token = response['token'];
      _user = response['user'];
      _isLoggedIn = true;

      await apiService.setToken(_token!);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_user));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.post(
        '/auth/register',
        {'name': name, 'email': email, 'password': password},
        withAuth: false,
      );

      _token = response['token'];
      _user = response['user'];
      _isLoggedIn = true;

      await apiService.setToken(_token!);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_user));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void updateUserData(Map<String, dynamic> userData) {
    _user = userData;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _user?['id'];
      if (userId == null) {
        _error = 'User ID not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await apiService.post(
        '/users/$userId/profile',
        profileData,
      );

      if (response['user'] != null) {
        _user = response['user'];
      } else if (response['profile'] != null) {
        // Update profile data in user object
        if (_user != null) {
          _user!['profile'] = response['profile'];
        }
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_user));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _token = null;
    _user = null;
    await apiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    notifyListeners();
  }

  Map<String, dynamic>? _decodeUserData(String? data) {
    if (data == null) return null;
    try {
      return jsonDecode(data);
    } catch (e) {
      return null;
    }
  }
}
