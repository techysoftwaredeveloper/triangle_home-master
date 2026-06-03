// Document Capture Camera - Fixed ColorFiltered parameter
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class DocumentCaptureCamera extends StatefulWidget {
  final String title;
  const DocumentCaptureCamera({super.key, required this.title});

  @override
  State<DocumentCaptureCamera> createState() => _DocumentCaptureCameraState();
}

class _DocumentCaptureCameraState extends State<DocumentCaptureCamera> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;

  // Auto-capture logic
  Timer? _captureTimer;
  int _countdown = 3;
  bool _isCountingDown = false;
  bool _autoCaptureEnabled = true;

  // Sensor logic for stability detection
  StreamSubscription? _userAccelSub;
  bool _isStable = false;
  DateTime? _stableStartTime;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startStabilityDetection();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    _controller = CameraController(
      _cameras![0],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  void _startStabilityDetection() {
    _userAccelSub = userAccelerometerEventStream().listen((
      UserAccelerometerEvent event,
    ) {
      // Threshold for "stable" (very little movement)
      const double threshold = 0.3;
      bool stableNow =
          event.x.abs() < threshold &&
          event.y.abs() < threshold &&
          event.z.abs() < threshold;

      if (stableNow) {
        if (!_isStable) {
          _isStable = true;
          _stableStartTime = DateTime.now();
        } else if (_stableStartTime != null &&
            _autoCaptureEnabled &&
            !_isCountingDown &&
            !_isCapturing) {
          // If stable for more than 1.5 seconds, start auto-capture
          if (DateTime.now().difference(_stableStartTime!).inMilliseconds >
              1500) {
            _startAutoCapture();
          }
        }
      } else {
        if (_isStable) {
          _isStable = false;
          _stableStartTime = null;
          if (_isCountingDown) {
            _cancelAutoCapture();
          }
        }
      }

      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _userAccelSub?.cancel();
    _captureTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    _captureTimer?.cancel();

    try {
      // Try to lock focus right before taking picture for maximum clarity
      try {
        await _controller!.setFocusMode(FocusMode.locked);
      } catch (e) {
        debugPrint('Focus lock not supported or failed: $e');
      }

      final XFile image = await _controller!.takePicture();
      
      // Reset focus mode
      try {
        await _controller!.setFocusMode(FocusMode.auto);
      } catch (e) {
        debugPrint('Focus reset failed: $e');
      }

      if (mounted) {
        Navigator.pop(context, image);
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    }
  }

  void _startAutoCapture() {
    if (_isCountingDown || _isCapturing) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isCountingDown = true;
      _countdown = 2; // Shortened for "Smart" feel
    });

    _captureTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown == 1) {
        timer.cancel();
        _takePicture();
      } else {
        setState(() {
          _countdown--;
        });
      }
    });
  }

  void _cancelAutoCapture() {
    _captureTimer?.cancel();
    setState(() {
      _isCountingDown = false;
      _countdown = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          Center(
            child: Transform.scale(
              scale: _controller!.value.aspectRatio / deviceRatio,
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
          ),

          // 2. 3:2 Overlay
          _buildOverlay(context),

          // 3. UI Controls
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const Spacer(),
                _buildCaptureStatus(),
                _buildBottomControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double overlayWidth = size.width * 0.85;
    final double overlayHeight = overlayWidth * (2 / 3); // 3:2 Ratio

    Color borderColor = Colors.white;
    if (_isCountingDown) {
      borderColor = Colors.green;
    } else if (_isStable) {
      borderColor = Colors.blue;
    }

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.7),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(color: Colors.transparent),
              ),
              Center(
                child: Container(
                  width: overlayWidth,
                  height: overlayHeight,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        Center(
          child: Container(
            width: overlayWidth,
            height: overlayHeight,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // Corner markers
        Center(
          child: SizedBox(
            width: overlayWidth + 4,
            height: overlayHeight + 4,
            child: CustomPaint(painter: _CornerPainter(color: borderColor)),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Outfit',
            ),
          ),
          IconButton(
            icon: Icon(
              _autoCaptureEnabled
                  ? Icons.auto_awesome
                  : Icons.auto_awesome_outlined,
              color: _autoCaptureEnabled ? Colors.blue : Colors.white60,
            ),
            onPressed: () {
              setState(() => _autoCaptureEnabled = !_autoCaptureEnabled);
              if (!_autoCaptureEnabled) _cancelAutoCapture();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          if (_isCountingDown)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Hold steady! Capturing in $_countdown...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else if (_isStable && _autoCaptureEnabled)
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Perfect! Keep it there',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.center_focus_strong,
                  color: Colors.white70,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Align card within the frame',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Flash toggle
          IconButton(
            icon: Icon(
              _controller?.value.flashMode == FlashMode.torch
                  ? Icons.flash_on
                  : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () {
              final newMode =
                  _controller?.value.flashMode == FlashMode.torch
                      ? FlashMode.off
                      : FlashMode.torch;
              _controller?.setFlashMode(newMode);
              setState(() {});
            },
          ),

          // Main Capture Button
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: _isCountingDown ? Colors.green : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child:
                      _isCapturing
                          ? const CircularProgressIndicator(color: Colors.blue)
                          : null,
                ),
              ),
            ),
          ),

          // Flip camera (if needed, but usually back for docs)
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke;

    const length = 30.0;

    // Top Left
    canvas.drawLine(Offset.zero, const Offset(length, 0), paint);
    canvas.drawLine(Offset.zero, const Offset(0, length), paint);

    // Top Right
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - length, 0),
      paint,
    );
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - length),
      paint,
    );

    // Bottom Right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - length, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
