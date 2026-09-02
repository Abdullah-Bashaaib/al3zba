import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ezba_period.dart';

class StorageService {
  static const String _keyPeriods = 'ezba_periods_v1';
  static const String _keyActivePeriodId = 'ezba_active_period_id';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  List<EzbaPeriod> loadPeriods() {
    final String? data = _prefs.getString(_keyPeriods);
    if (data == null || data.isEmpty) {
      final defaultPeriod = EzbaPeriod.createDefault();
      savePeriods([defaultPeriod]);
      saveActivePeriodId(defaultPeriod.id);
      return [defaultPeriod];
    }

    try {
      final List<dynamic> list = jsonDecode(data) as List<dynamic>;
      final periods = list
          .map((item) => EzbaPeriod.fromJson(item as Map<String, dynamic>))
          .toList();
      if (periods.isEmpty) {
        final defaultPeriod = EzbaPeriod.createDefault();
        savePeriods([defaultPeriod]);
        saveActivePeriodId(defaultPeriod.id);
        return [defaultPeriod];
      }
      return periods;
    } catch (e) {
      final defaultPeriod = EzbaPeriod.createDefault();
      return [defaultPeriod];
    }
  }

  Future<void> savePeriods(List<EzbaPeriod> periods) async {
    final jsonList = periods.map((p) => p.toJson()).toList();
    await _prefs.setString(_keyPeriods, jsonEncode(jsonList));
  }

  String? getActivePeriodId() {
    return _prefs.getString(_keyActivePeriodId);
  }

  Future<void> saveActivePeriodId(String periodId) async {
    await _prefs.setString(_keyActivePeriodId, periodId);
  }
}
