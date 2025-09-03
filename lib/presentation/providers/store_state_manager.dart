import 'package:flutter/foundation.dart';
import '../../domain/entities/store.dart';

class StoreStateManager extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _infoMessage;
  List<Store> _searchResults = [];
  List<Store> _swipeStores = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get infoMessage => _infoMessage;
  List<Store> get searchResults => List.unmodifiable(_searchResults);
  List<Store> get swipeStores => List.unmodifiable(_swipeStores);

  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void setError(String errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  void setInfoMessage(String message) {
    _infoMessage = message;
    notifyListeners();
  }

  void clearInfoMessage() {
    if (_infoMessage != null) {
      _infoMessage = null;
      notifyListeners();
    }
  }

  void updateSearchResults(List<Store> results) {
    _searchResults = List.from(results);
    notifyListeners();
  }

  void updateSwipeStores(List<Store> stores) {
    _swipeStores = List.from(stores);
    notifyListeners();
  }
}