import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/detection_record.dart';
import '../models/eco_point.dart';

class EcoScanStore extends ChangeNotifier {
  EcoScanStore._(this._preferences);

  static const _detectionsKey = 'ecoscan_flutter_detections_v1';
  static const _ecoPointsKey = 'ecoscan_flutter_ecopoints_v1';

  final SharedPreferences _preferences;
  final List<DetectionRecord> _detections = [];

  List<DetectionRecord> get detections => List.unmodifiable(_detections);
  int get scanCount => _detections.length;

  static Future<EcoScanStore> load() async {
    final preferences = await SharedPreferences.getInstance();
    final store = EcoScanStore._(preferences);
    store._restoreDetections();
    return store;
  }

  void _restoreDetections() {
    try {
      final decoded = jsonDecode(
        _preferences.getString(_detectionsKey) ?? '[]',
      );
      if (decoded is List) {
        _detections
          ..clear()
          ..addAll(
            decoded.whereType<Map>().map(
              (item) =>
                  DetectionRecord.fromJson(Map<String, dynamic>.from(item)),
            ),
          );
        _detections.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
      }
    } catch (_) {
      _detections.clear();
    }
  }

  Future<void> addDetection(DetectionRecord record) async {
    _detections.insert(0, record);
    notifyListeners();
    await _saveDetections();
  }

  Future<void> removeDetection(DetectionRecord record) async {
    _detections.removeWhere((item) => item.id == record.id);
    notifyListeners();
    await _saveDetections();
    await _deleteImage(record.imagePath);
  }

  Future<void> clearHistory() async {
    final imagePaths = _detections.map((item) => item.imagePath).toList();
    _detections.clear();
    notifyListeners();
    await _preferences.remove(_detectionsKey);
    for (final path in imagePaths) {
      await _deleteImage(path);
    }
  }

  Future<void> _saveDetections() {
    return _preferences.setString(
      _detectionsKey,
      jsonEncode(_detections.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<EcoPoint>> loadCachedEcoPoints() async {
    try {
      final decoded = jsonDecode(_preferences.getString(_ecoPointsKey) ?? '[]');
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => EcoPoint.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveEcoPoints(Iterable<EcoPoint> points) {
    return _preferences.setString(
      _ecoPointsKey,
      jsonEncode(points.map((point) => point.toJson()).toList()),
    );
  }

  static Future<void> _deleteImage(String path) async {
    if (path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // O histórico já foi removido; uma falha ao apagar a foto não bloqueia a interface.
    }
  }
}
