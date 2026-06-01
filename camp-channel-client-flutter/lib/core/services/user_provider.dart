import 'package:flutter/material.dart';
import 'storage_service.dart';

class UserProvider extends ChangeNotifier {
  int _unreadCount = 0;
  String _role = 'user';
  String _avatarUrl = '';

  int get unreadCount => _unreadCount;
  String get role => _role;
  bool get isAdmin => _role == 'admin';
  String get avatarUrl => _avatarUrl;

  void setUnreadCount(int count) {
    _unreadCount = count;
    notifyListeners();
  }

  void setRole(String role) {
    _role = role;
    notifyListeners();
  }

  void updateAvatar(String url) {
    _avatarUrl = url;
    notifyListeners();
  }

  void refreshFromStorage() {
    _role = StorageService.getRole();
    _avatarUrl = StorageService.getAvatarUrl() ?? '';
    notifyListeners();
  }
}
