import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment.dart';

class AppState extends ChangeNotifier {
  static const _activeTokenKey = 'active_token';

  Appointment? _activeToken;
  Appointment? get activeToken => _activeToken;

  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeTokenKey);
    if (raw == null) return;

    final json = jsonDecode(raw) as Map<String, dynamic>;
    _activeToken = Appointment.fromJson(json);
    notifyListeners();
  }

  Future<void> setActiveToken(Appointment appointment) async {
    _activeToken = appointment;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeTokenKey, jsonEncode(appointment.toJson()));
  }

  Future<void> clearActiveToken() async {
    _activeToken = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeTokenKey);
  }
}
