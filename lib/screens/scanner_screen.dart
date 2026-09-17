import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/detection_record.dart';
import '../models/material_guide.dart';
import '../services/scan_service.dart';
import '../services/waste_classifier.dart';
import '../state/eco_point_controller.dart';
import '../state/ecoscan_store.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  final _scanner = ScanService();
  final _picker = ImagePicker();
  CameraController? _camera;
  List<CameraDescription> _cameras = [];
  Future<void> _cameraQueue = Future.value();
  Future<void>? _scanTask;
  Timer? _liveTimer;
  bool _active = true;
  bool _selecting = false;
  bool _loading = true;
  bool _busy = false;
  bool _live = !kIsWeb;
  bool _flash = false;
  bool _saved = false;
  bool _saving = false;
  int _revision = 0;
  int _cameraIndex = 0;
  int _liveFailures = 0;
  String? _cameraError;
  String? _scanError;
  String? _photoPath;
  Uint8List? _photoBytes;
  String _source = 'camera';
  WasteClassification? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_boot());
  }

  Future<void> _boot() async {
    // Android may kill the process while its gallery picker is open.
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final lost = await _picker.retrieveLostData();
        if (!mounted) return;
        if (lost.files?.isNotEmpty == true) {
          _live = false;
          await _analyzeFile(lost.files!.first, fromGallery: true);
        } else if (lost.exception != null) {
          setState(
            () => _scanError =
                'Não foi possível recuperar a foto. Selecione-a novamente.',
          );
        }
      } catch (_) {}
    }
    if (mounted) await _openCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _active = true;
      if (!_selecting) unawaited(_openCamera());
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _active = false;
      _revision++;
      _liveTimer?.cancel();
      unawaited(_releaseCamera());
    }
  }

  Future<void> _releaseCamera() {
    _cameraQueue = _cameraQueue.then((_) async {
      final scan = _scanTask;
      if (scan != null) {
        try {
          await scan;
        } catch (_) {}
      }
      final camera = _camera;
      _camera = null;
      if (camera != null) {
        try {
          await camera.dispose();
        } catch (_) {}
      }
    });
    return _cameraQueue;
  }

  Future<void> _openCamera({bool switchLens = false}) {
    final request = ++_revision;
    _liveTimer?.cancel();
    _cameraQueue = _cameraQueue.then((_) async {
      if (!mounted || !_active || _selecting) return;
      setState(() {
        _loading = true;
        _cameraError = null;
      });
      try {
        if (_scanTask != null) await _scanTask;
        if (_cameras.isEmpty) {
          _cameras = await availableCameras();
          final back = _cameras.indexWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
          );
          _cameraIndex = back < 0 ? 0 : back;
        } else if (switchLens && _cameras.length > 1) {
          _cameraIndex = (_cameraIndex + 1) % _cameras.length;
        }
        if (_cameras.isEmpty) {
          throw CameraException('NoCamera', 'Nenhuma câmera encontrada.');
        }
        final previous = _camera;
        _camera = null;
        await previous?.dispose();
        if (!mounted || !_active || request != _revision) return;
        final camera = CameraController(
          _cameras[_cameraIndex],
          ResolutionPreset.high,
          enableAudio: false,
        );
        _camera = camera;
        await camera.initialize();
        if (!mounted || !_active || request != _revision) {
          _camera = null;
          await camera.dispose();
          return;
        }
        if (!kIsWeb) {
          try {
            await camera.setFocusMode(FocusMode.auto);
          } catch (_) {}
          try {
            await camera.setExposureMode(ExposureMode.auto);
          } catch (_) {}
          try {
            await camera.setFlashMode(FlashMode.off);
          } catch (_) {}
        }
        if (!mounted || !_active || request != _revision) return;
        setState(() {
          _loading = false;
          _flash = false;
        });
        _scheduleLive();
      } on CameraException catch (error) {
        if (mounted) {
          setState(() {
            _loading = false;
            _cameraError = error.code.toLowerCase().contains('denied')
                ? (kIsWeb
                      ? 'Permita a câmera nas permissões deste site no navegador. Você também pode selecionar uma foto.'
                      : 'Permita a câmera nas configurações do celular. Você também pode selecionar uma foto.')
                : 'Não foi possível abrir a câmera. Tente novamente ou escolha uma foto.';
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _loading = false;
            _cameraError = 'A câmera não respondeu. Tente novamente.';
          });
        }
      }
    });
    return _cameraQueue;
  }

  void _scheduleLive() {
    _liveTimer?.cancel();
    if (!_scanner.supportsAutomaticLabeling ||
        !_live ||
        !_active ||
        !mounted ||
        _selecting ||
        _saving) {
      return;
    }
    _liveTimer = Timer(const Duration(milliseconds: 2400), () {
      if (!_busy && _camera?.value.isInitialized == true) {
        unawaited(_capture(automatic: true));
      } else {
        _scheduleLive();
      }
    });
  }

  Future<void> _capture({bool automatic = false}) async {
    if (_busy ||
        _saving ||
        _selecting ||
        !_active ||
        _camera?.value.isInitialized != true) {
      return;
    }
    _liveTimer?.cancel();
    if (!automatic) {
      _live = false;
      _revision++;
    }
    final request = _revision;
    setState(() {
      _busy = true;
      _scanError = null;
    });
    final operation = _captureWork(request, automatic);
    _scanTask = operation;
    try {
      await operation;
    } finally {
      _scanTask = null;
      if (mounted) setState(() => _busy = false);
      _scheduleLive();
    }
  }

  Future<void> _captureWork(int request, bool automatic) async {
    XFile? photo;
    try {
      photo = await _camera!.takePicture();
      final analysis = await _scanner.analyzeFile(photo);
      if (!mounted || request != _revision || !_active) {
        await _deleteTemp(analysis.imagePath);
        return;
      }
      _liveFailures = 0;
      await _accept(analysis, fromGallery: false);
    } catch (error) {
      if (!mounted || request != _revision) return;
      _liveFailures++;
      setState(() {
        _scanError = _errorText(error);
        if (!automatic || _liveFailures >= 3) _live = false;
      });
    } finally {
      if (photo != null && !kIsWeb) {
        try {
          await File(photo.path).delete();
        } catch (_) {}
      }
    }
  }

  Future<void> _analyzeFile(
    XFile file, {
    required bool fromGallery,
  }) async {
    if (_busy || !mounted) return;
    final request = ++_revision;
    setState(() {
      _busy = true;
      _scanError = null;
      _live = false;
    });
    final operation = () async {
      try {
        final analysis = await _scanner.analyzeFile(file);
        if (!mounted || request != _revision) {
          await _deleteTemp(analysis.imagePath);
          return;
        }
        await _accept(analysis, fromGallery: fromGallery);
      } catch (error) {
        if (mounted) setState(() => _scanError = _errorText(error));
      }
    }();
    _scanTask = operation;
    try {
      await operation;
    } finally {
      _scanTask = null;
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accept(ScanResult result, {required bool fromGallery}) async {
    final previous = _photoPath;
    setState(() {
      _photoPath = result.imagePath;
      _photoBytes = result.imageBytes;
      _result = result.classification;
      _source = fromGallery ? 'gallery' : 'camera';
      _saved = false;
      _scanError = null;
    });
    if (previous != null && previous != result.imagePath) {
      await _deleteTemp(previous);
    }
  }

  Future<void> _selectPhoto() async {
    if (_busy || _saving || _selecting) return;
    setState(() {
      _selecting = true;
      _live = false;
      _scanError = null;
    });
    _revision++;
    _liveTimer?.cancel();
    await _releaseCamera();
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 94,
      );
      if (!mounted) return;
      if (photo != null) await _analyzeFile(photo, fromGallery: true);
    } on PlatformException {
      if (mounted) {
        setState(
          () => _scanError =
              'Não foi possível abrir a galeria. Confira a permissão de fotos.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _scanError = 'Não foi possível selecionar a foto.');
      }
    } finally {
      _selecting = false;
      if (mounted && _active) unawaited(_openCamera());
    }
  }

  Future<void> _toggleFlash() async {
    if (kIsWeb) {
      _notice('O flash pelo navegador depende do suporte da câmera e fica desativado no modo Web.');
      return;
    }
    final camera = _camera;
    if (camera?.value.isInitialized != true || _busy) return;
    try {
      await camera!.setFlashMode(_flash ? FlashMode.off : FlashMode.torch);
      if (mounted) setState(() => _flash = !_flash);
    } catch (_) {
      if (mounted) _notice('O flash não está disponível nesta câmera.');
    }
  }

  Future<void> _focus(TapDownDetails details, Size size) async {
    if (kIsWeb) return;
    final camera = _camera;
    if (camera?.value.isInitialized != true || _busy) return;
    final point = Offset(
      (details.localPosition.dx / size.width).clamp(0, 1),
      (details.localPosition.dy / size.height).clamp(0, 1),
    );
    try {
      await camera!.setFocusPoint(point);
      await camera.setExposurePoint(point);
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_saving ||
        _busy ||
        _saved ||
        _result?.isKnown != true ||
        _photoPath == null) {
      return;
    }
    final store = context.read<EcoScanStore>();
    final uid = store.userId;
    if (uid == null) return;
    final result = _result!;
    final image = _photoPath!;
    final location = _source == 'camera'
        ? context.read<EcoPointController>().userLocation
        : null;
    setState(() {
      _saving = true;
      _live = false;
    });
    _liveTimer?.cancel();
    String? savedPath;
    try {
      final now = DateTime.now();
      if (kIsWeb) {
        final bytes = _photoBytes;
        savedPath = bytes == null ? '' : await _scanner.historyDataUrl(bytes);
      } else {
        final documents = await getApplicationDocumentsDirectory();
        final folder = Directory(p.join(documents.path, 'ecoscan', uid, 'scans'));
        await folder.create(recursive: true);
        savedPath = p.join(folder.path, '${now.microsecondsSinceEpoch}.jpg');
        await File(image).copy(savedPath);
        if (!mounted || store.userId != uid) {
          await File(savedPath).delete();
          return;
        }
      }
      if (!mounted || store.userId != uid) return;
      final persistedImage = savedPath ?? '';
      await store.addDetection(
        DetectionRecord(
          id: now.microsecondsSinceEpoch.toString(),
          name: result.category,
          category: result.category,
          bin: result.bin,
          destination: result.destination,
          confidence: result.confidence,
          imagePath: persistedImage,
          detectedAt: now,
          source: _source,
          confirmedByUser: result.isManual,
          latitude: location?.latitude,
          longitude: location?.longitude,
        ),
      );
      if (mounted) {
        setState(() => _saved = true);
        if (store.sounds) unawaited(SystemSound.play(SystemSoundType.click));
        if (store.notifications) _notice('Análise salva no histórico.');
      }
    } catch (_) {
      if (!kIsWeb && savedPath != null && savedPath.isNotEmpty) {
        try {
          await File(savedPath).delete();
        } catch (_) {}
      }
      if (mounted) _notice('Não foi possível salvar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _choose(MaterialGuide choice) {
    _liveTimer?.cancel();
    _revision++;
    setState(() {
      _live = false;
      _saved = false;
      _result = (_result ?? WasteClassifier.unknown).confirmed(choice);
    });
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  static String _errorText(Object error) => error is FormatException
      ? error.message
      : 'A análise não terminou. Aproxime o material, melhore a luz e tente novamente.';
  static Future<void> _deleteTemp(String path) async {
    if (kIsWeb || path.isEmpty) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }

  @override
  void dispose() {
    _active = false;
    _revision++;
    _liveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(
      _releaseCamera().then((_) async {
        await _scanner.close();
        final photo = _photoPath;
        if (photo != null) await _deleteTemp(photo);
      }),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final camera = _camera;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Scanner',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    FilterChip(
                      label: Text(_live ? '● AO VIVO' : 'Foto'),
                      selected: _live,
                      onSelected: kIsWeb || _busy || _saving
                          ? null
                          : (live) {
                              setState(() {
                                _live = live;
                                _scanError = null;
                                _liveFailures = 0;
                              });
                              if (live) {
                                _scheduleLive();
                              } else {
                                _liveTimer?.cancel();
                              }
                            },
                    ),
                    IconButton(
                      tooltip: 'Flash',
                      onPressed: kIsWeb || _busy ? null : _toggleFlash,
                      icon: Icon(_flash ? Icons.flash_on : Icons.flash_off),
                    ),
                    IconButton(
                      tooltip: 'Trocar câmera',
                      onPressed: _busy || _cameras.length < 2
                          ? null
                          : () => _openCamera(switchLens: true),
                      icon: const Icon(Icons.cameraswitch_outlined),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: (constraints.maxHeight * 0.48).clamp(230.0, 460.0),
                child: ColoredBox(
                  color: Colors.black,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (!_live && _photoBytes != null)
                        Image.memory(
                          _photoBytes!,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.image_outlined,
                            color: Colors.white,
                          ),
                        )
                      else if (camera?.value.isInitialized == true)
                        Center(
                          child: AspectRatio(
                            aspectRatio:
                                MediaQuery.orientationOf(context) ==
                                    Orientation.portrait
                                ? 1 / camera!.value.aspectRatio
                                : camera!.value.aspectRatio,
                            child: CameraPreview(
                              camera,
                              child: LayoutBuilder(
                                builder: (context, box) => GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (details) =>
                                      _focus(details, box.biggest),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_loading && _photoBytes == null)
                        const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text(
                                'Abrindo câmera…',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      if (_cameraError != null && _photoBytes == null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.no_photography_outlined,
                                  size: 38,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _cameraError!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                TextButton(
                                  onPressed: () => _openCamera(),
                                  child: const Text('Tentar novamente'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_live && camera?.value.isInitialized == true)
                        IgnorePointer(
                          child: Center(
                            child: FractionallySizedBox(
                              widthFactor: 0.76,
                              heightFactor: 0.78,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_busy)
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(minHeight: 3),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed:
                                _busy ||
                                    _saving ||
                                    _selecting ||
                                    camera?.value.isInitialized != true
                                ? null
                                : () => _capture(),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: Text(_busy ? 'Analisando…' : 'Fotografar'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _busy || _saving || _selecting
                                ? null
                                : _selectPhoto,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Galeria'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_scanError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _scanError!,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    if (result == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          kIsWeb
                              ? 'No navegador, fotografe ou escolha uma imagem e confirme o material. A detecção automática por ML Kit fica disponível no Android/iOS.'
                              : 'Aponte para um material por vez ou selecione uma imagem. O resultado mostra o material e a lixeira indicada.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    else ...[
                      _MaterialResult(result: result),
                      const SizedBox(height: 12),
                      Text(
                        result.isKnown
                            ? 'O material é outro? Toque para corrigir.'
                            : 'Qual é o material? Toque para confirmar.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final material in MaterialGuide.all)
                            ChoiceChip(
                              label: Text(material.name),
                              selected: result.material?.id == material.id,
                              avatar: Icon(
                                Icons.circle,
                                size: 12,
                                color: material.color,
                              ),
                              onSelected: _busy || _saving
                                  ? null
                                  : (_) => _choose(material),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _busy || _saving || _saved || !result.isKnown
                            ? null
                            : _save,
                        icon: Icon(
                          _saved ? Icons.check : Icons.bookmark_add_outlined,
                        ),
                        label: Text(
                          _saved
                              ? 'Salvo no histórico'
                              : _saving
                              ? 'Salvando…'
                              : 'Salvar análise',
                        ),
                      ),
                    ],
                    if (!kIsWeb && !_live)
                      TextButton.icon(
                        onPressed: _busy || _saving
                            ? null
                            : () {
                                setState(() {
                                  _live = true;
                                  _scanError = null;
                                });
                                if (_camera?.value.isInitialized != true) {
                                  unawaited(_openCamera());
                                } else {
                                  _scheduleLive();
                                }
                              },
                        icon: const Icon(Icons.center_focus_strong),
                        label: const Text('Voltar ao scanner ao vivo'),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MaterialResult extends StatelessWidget {
  const _MaterialResult({required this.result});
  final WasteClassification result;
  @override
  Widget build(BuildContext context) {
    final color = result.material?.color ?? AppColors.muted;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.isManual
                ? 'CONFIRMADO POR VOCÊ'
                : result.isKnown
                ? 'MATERIAL SUGERIDO'
                : 'PRECISA DE CONFIRMAÇÃO',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.name,
            style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (result.isKnown)
            Row(
              children: [
                Icon(
                  result.material!.id == 'electronic' ||
                          result.material!.id == 'special'
                      ? Icons.location_on
                      : Icons.delete_rounded,
                  color: color,
                  size: 42,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.bin == 'Coleta especial'
                        ? result.bin
                        : 'Lixeira ${result.bin.toLowerCase()}',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          Text(result.destination, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}
