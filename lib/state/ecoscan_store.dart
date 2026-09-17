import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/detection_record.dart';
import '../models/eco_point.dart';

class EcoScanStore extends ChangeNotifier {
  EcoScanStore._(this._preferences);
  final SharedPreferences _preferences;
  String? userId;
  final List<DetectionRecord> _detections = [];
  List<DetectionRecord> get detections => List.unmodifiable(_detections);
  int get scanCount => _detections.length;
  String get _detectionsKey =>
      'ecoscan.detections.v2.${userId ?? 'signed-out'}';
  String get _photoKey => 'ecoscan.profile.v2.${userId ?? 'signed-out'}';
  String get profilePhoto => _preferences.getString(_photoKey) ?? '';
  bool get darkMode => _preferences.getBool('ecoscan.dark') ?? true;
  bool get sounds => _preferences.getBool('ecoscan.sounds') ?? true;
  bool get notifications => _preferences.getBool('ecoscan.notices') ?? true;
  bool get exploredMap =>
      _preferences.getBool('ecoscan.map.${userId ?? ''}') ?? false;

  static Future<EcoScanStore> load() async =>
      EcoScanStore._(await SharedPreferences.getInstance());

  void switchUser(String? uid) {
    if (uid == userId) return;
    userId = uid;
    _detections.clear();
    if (uid != null) {
      try {
        final decoded = jsonDecode(
          _preferences.getString(_detectionsKey) ?? '[]',
        );
        if (decoded is List) {
          _detections.addAll(
            decoded.whereType<Map>().map(
              (e) => DetectionRecord.fromJson(Map<String, dynamic>.from(e)),
            ),
          );
          _detections.sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
        }
      } catch (_) {
        _detections.clear();
      }
    }
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    await _preferences.setBool('ecoscan.dark', value);
    notifyListeners();
  }

  Future<void> setSounds(bool value) async {
    await _preferences.setBool('ecoscan.sounds', value);
    notifyListeners();
  }

  Future<void> setNotifications(bool value) async {
    await _preferences.setBool('ecoscan.notices', value);
    notifyListeners();
  }

  Future<void> markMapExplored() async {
    if (userId == null) return;
    await _preferences.setBool('ecoscan.map.${userId!}', true);
    notifyListeners();
  }

  Future<void> setProfilePhoto(String path) async {
    if (userId == null) return;
    final oldPath = profilePhoto;
    await _preferences.setString(_photoKey, path);
    notifyListeners();
    if (oldPath != path) await _deleteImage(oldPath);
  }

  Future<void> addDetection(DetectionRecord record) async {
    if (userId == null) throw StateError('Entre na sua conta antes de salvar.');
    final owner = userId;
    final next = [record, ..._detections];
    final success = await _preferences.setString(
      _detectionsKey,
      jsonEncode(next.map((d) => d.toJson()).toList()),
    );
    if (!success) throw StateError('Não foi possível salvar a análise.');
    if (userId != owner) return;
    _detections.insert(0, record);
    notifyListeners();
  }

  Future<void> removeDetection(DetectionRecord record) async {
    if (userId == null) return;
    final owner = userId;
    final next = _detections.where((d) => d.id != record.id).toList();
    final success = await _preferences.setString(
      _detectionsKey,
      jsonEncode(next.map((d) => d.toJson()).toList()),
    );
    if (!success) throw StateError('Não foi possível excluir a análise.');
    if (userId == owner) {
      _detections
        ..clear()
        ..addAll(next);
      notifyListeners();
    }
    await _deleteImage(record.imagePath);
  }

  Future<void> clearHistory() async {
    if (userId == null) return;
    final owner = userId;
    final images = _detections.map((d) => d.imagePath).toList();
    if (!await _preferences.remove(_detectionsKey)) {
      throw StateError('Não foi possível limpar o histórico.');
    }
    if (userId == owner) {
      _detections.clear();
      notifyListeners();
    }
    for (final image in images) {
      await _deleteImage(image);
    }
  }

  Future<List<EcoPoint>> loadCachedEcoPoints() async {
    try {
      final data = jsonDecode(
        _preferences.getString('ecoscan_flutter_ecopoints_v1') ?? '[]',
      ) as List;
      return data
          .whereType<Map>()
          .map((e) => EcoPoint.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveEcoPoints(Iterable<EcoPoint> points) async {
    await _preferences.setString(
      'ecoscan_flutter_ecopoints_v1',
      jsonEncode(points.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> _deleteImage(String imagePath) async {
    if (imagePath.isEmpty ||
        kIsWeb ||
        imagePath.startsWith('data:image/') ||
        imagePath.startsWith('http://') ||
        imagePath.startsWith('https://')) {
      return;
    }
    try {
      final documents = await getApplicationDocumentsDirectory();
      final root = p.join(documents.path, 'ecoscan');
      if (!p.isWithin(root, p.normalize(imagePath))) return;
      final file = File(imagePath);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
