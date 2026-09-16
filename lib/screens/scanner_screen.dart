import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/detection_record.dart';
import '../services/waste_classifier.dart';
import '../state/ecoscan_store.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  final ImageLabeler _labeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.35),
  );
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _flashEnabled = false;
  String? _error;
  DetectionRecord? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final camera = _cameraController;
      _cameraController = null;
      unawaited(camera?.dispose());
    } else if (state == AppLifecycleState.resumed &&
        _cameraController == null) {
      unawaited(_initializeCamera());
    }
  }

  Future<void> _initializeCamera({int? cameraIndex}) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('cameraNotFound', 'Nenhuma câmera encontrada.');
      }
      var selectedIndex = cameraIndex;
      selectedIndex ??= _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      if (selectedIndex < 0 || selectedIndex >= _cameras.length) {
        selectedIndex = 0;
      }

      final oldCamera = _cameraController;
      _cameraController = null;
      await oldCamera?.dispose();

      final camera = CameraController(
        _cameras[selectedIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _cameraController = camera;
      await camera.initialize();
      try {
        await camera.setFocusMode(FocusMode.auto);
      } catch (_) {}
      try {
        await camera.setExposureMode(ExposureMode.auto);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _flashEnabled = false;
      });
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = _cameraErrorMessage(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Não foi possível iniciar a câmera. Confira a permissão do aplicativo.';
      });
    }
  }

  Future<void> _toggleFlash() async {
    final camera = _cameraController;
    if (camera == null || !camera.value.isInitialized) return;
    final enabled = !_flashEnabled;
    try {
      await camera.setFlashMode(enabled ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _flashEnabled = enabled);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O flash não está disponível nesta câmera.'),
          ),
        );
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isProcessing) return;
    final current = _cameraController?.description;
    final index = _cameras.indexWhere((camera) => camera.name == current?.name);
    await _initializeCamera(cameraIndex: (index + 1) % _cameras.length);
  }

  Future<void> _captureAndAnalyze() async {
    final camera = _cameraController;
    if (camera == null || !camera.value.isInitialized || _isProcessing) return;
    setState(() {
      _isProcessing = true;
      _result = null;
    });

    XFile? temporaryPhoto;
    try {
      await camera.setFlashMode(_flashEnabled ? FlashMode.auto : FlashMode.off);
      temporaryPhoto = await camera.takePicture();
      final documents = await getApplicationDocumentsDirectory();
      final scansDirectory = Directory(
        path.join(documents.path, 'ecoscan_scans'),
      );
      await scansDirectory.create(recursive: true);
      final now = DateTime.now();
      final savedPath = path.join(
        scansDirectory.path,
        'scan_${now.microsecondsSinceEpoch}.jpg',
      );
      await File(temporaryPhoto.path).copy(savedPath);

      final labels = await _labeler.processImage(
        InputImage.fromFilePath(savedPath),
      );
      final classification = WasteClassifier.fromMlLabels(labels);
      final record = DetectionRecord(
        id: now.microsecondsSinceEpoch.toString(),
        name: classification.name,
        category: classification.category,
        bin: classification.bin,
        destination: classification.destination,
        confidence: classification.confidence,
        imagePath: savedPath,
        detectedAt: now,
      );
      if (!mounted) return;
      await context.read<EcoScanStore>().addDetection(record);
      if (mounted) setState(() => _result = record);
    } on CameraException catch (error) {
      if (mounted) _showError(_cameraErrorMessage(error));
    } catch (_) {
      if (mounted) {
        _showError(
          'Não foi possível analisar esta foto. Tente novamente com mais luz.',
        );
      }
    } finally {
      if (temporaryPhoto != null) {
        try {
          await File(temporaryPhoto.path).delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final camera = _cameraController;
    _cameraController = null;
    unawaited(camera?.dispose());
    unawaited(_labeler.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camera = _cameraController;
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (camera != null && camera.value.isInitialized)
              _CameraFill(controller: camera)
            else
              _CameraPlaceholder(
                isLoading: _isLoading,
                error: _error,
                onRetry: _initializeCamera,
              ),
            const _ScannerFrame(),
            Positioned(
              top: 14,
              left: 18,
              right: 18,
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scanner inteligente',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Centralize um objeto reciclável',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  _CameraAction(
                    tooltip: 'Flash',
                    onPressed: _toggleFlash,
                    icon: _flashEnabled
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                  ),
                  const SizedBox(width: 8),
                  _CameraAction(
                    tooltip: 'Trocar câmera',
                    onPressed: _switchCamera,
                    icon: Icons.cameraswitch_rounded,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_result case final result?) ...[
                    _ScanResultCard(
                      record: result,
                      onClose: () => setState(() => _result = null),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (_isProcessing)
                    const _ProcessingCard()
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: camera?.value.isInitialized == true
                              ? _captureAndAnalyze
                              : null,
                          child: Container(
                            width: 78,
                            height: 78,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                              ),
                              child: Icon(
                                Icons.center_focus_strong_rounded,
                                color: AppColors.background,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 9),
                  const Text(
                    'Toque para fotografar e analisar',
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _cameraErrorMessage(CameraException error) {
    if (error.code.toLowerCase().contains('accessdenied')) {
      return 'Permita o uso da câmera nas configurações do celular.';
    }
    return error.description ?? 'Não foi possível acessar a câmera.';
  }
}

class _CameraFill extends StatelessWidget {
  const _CameraFill({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return CameraPreview(controller);
    final scale = size.aspectRatio * previewSize.aspectRatio;
    return ClipRect(
      child: Transform.scale(
        scale: scale < 1 ? 1 / scale : scale,
        child: Center(child: CameraPreview(controller)),
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.76,
          height: MediaQuery.sizeOf(context).width * 0.76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.86),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 30,
                spreadRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraAction extends StatelessWidget {
  const _CameraAction({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(backgroundColor: const Color(0xB20A0F0C)),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final bool isLoading;
  final String? error;
  final Future<void> Function({int? cameraIndex}) onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Preparando a câmera…'),
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: AppColors.muted,
              size: 54,
            ),
            const SizedBox(height: 16),
            Text(error ?? 'Câmera indisponível', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingCard extends StatelessWidget {
  const _ProcessingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xE6101A13),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            'Analisando no aparelho…',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ScanResultCard extends StatelessWidget {
  const _ScanResultCard({required this.record, required this.onClose});

  final DetectionRecord record;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xF2101A13),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF356344)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.file(
              File(record.imagePath),
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.category} · Lixeira ${record.bin}',
                  style: const TextStyle(color: AppColors.primary),
                ),
                const SizedBox(height: 5),
                Text(
                  record.destination,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
