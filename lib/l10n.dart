import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocale extends ChangeNotifier {
  static final AppLocale _i = AppLocale._();
  factory AppLocale() => _i;
  AppLocale._();

  bool _isRu = true;
  bool get isRu => _isRu;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _isRu = p.getString('lang') != 'en';
    notifyListeners();
  }

  Future<void> setRu() async {
    _isRu = true;
    (await SharedPreferences.getInstance()).setString('lang', 'ru');
    notifyListeners();
  }

  Future<void> setEn() async {
    _isRu = false;
    (await SharedPreferences.getInstance()).setString('lang', 'en');
    notifyListeners();
  }

  String t(String ru, String en) => _isRu ? ru : en;
}

String tr(String ru, String en) => AppLocale().t(ru, en);