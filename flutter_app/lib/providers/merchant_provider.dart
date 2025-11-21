import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MerchantProvider extends ChangeNotifier {
  final ApiService apiService;

  List<dynamic> _merchants = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _selectedMerchant;

  MerchantProvider({required this.apiService});

  List<dynamic> get merchants => _merchants;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get selectedMerchant => _selectedMerchant;

  Future<void> fetchMerchants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/merchant-accounts');
      _merchants = (response['data'] as List?)?.cast<dynamic>() ?? [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMerchant(Map<String, dynamic> data, int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      data['user_id'] = userId;
      final response = await apiService.post('/merchant-accounts', data);
      if (response['data'] != null) {
        _merchants.add(response['data']);
      }
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

  Future<bool> updateMerchant(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.put('/merchant-accounts/$id', data);
      await fetchMerchants();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMerchant(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await apiService.delete('/merchant-accounts/$id');
      _merchants.removeWhere((m) => m['id'] == id);
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

  void selectMerchant(Map<String, dynamic> merchant) {
    _selectedMerchant = merchant;
    notifyListeners();
  }
}
