import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phone-level choices: low-data mode, simple mode, and a running count of the data the app used this month.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  /// The version of THIS app. Raise it (and pubspec.yaml) with every release; the server can demand a minimum.
  static const String appVersion = "1.1.0";

  bool lowData = false;
  bool simpleMode = false;
  int bytesThisMonth = 0;
  String _month = "";

  String get _thisMonth => DateTime.now().toIso8601String().substring(0, 7);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    lowData = p.getBool("low_data") ?? false;
    simpleMode = p.getBool("simple_mode") ?? false;
    _month = p.getString("data_month") ?? _thisMonth;
    bytesThisMonth = _month == _thisMonth ? (p.getInt("data_bytes") ?? 0) : 0;
    notifyListeners();
  }

  Future<void> setLowData(bool v) async {
    lowData = v;
    (await SharedPreferences.getInstance()).setBool("low_data", v);
    notifyListeners();
  }

  Future<void> setSimpleMode(bool v) async {
    simpleMode = v;
    (await SharedPreferences.getInstance()).setBool("simple_mode", v);
    notifyListeners();
  }

  int _unsaved = 0;
  void addBytes(int n) {
    if (_month != _thisMonth) {
      _month = _thisMonth;
      bytesThisMonth = 0;
    }
    bytesThisMonth += n;
    _unsaved += n;
    if (_unsaved > 20000) {
      _unsaved = 0;
      SharedPreferences.getInstance().then((p) {
        p.setString("data_month", _month);
        p.setInt("data_bytes", bytesThisMonth);
      });
    }
  }

  String get usageText {
    final mb = bytesThisMonth / (1024 * 1024);
    return mb < 1 ? "${(bytesThisMonth / 1024).round()} KB" : "${mb.toStringAsFixed(1)} MB";
  }
}
