import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'result_screen.dart';

class CaptureScreen extends StatefulWidget {
  final String documentType;
  
  const CaptureScreen({super.key, required this.documentType});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  String _currentTimeStamp = "";
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndInit();
    _updateTimestamp();
  }

  Future<void> _checkPermissionsAndInit() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _hasPermission = true);
      _initCamera();
    }
  }

  void _updateTimestamp() {
    if (!mounted) return;
    setState(() {
      _currentTimeStamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    });
    Future.delayed(const Duration(seconds: 1), _updateTimestamp);
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _controller = CameraController(_cameras[0], ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text("Camera permission required", style: TextStyle(color: Colors.white))),
      );
    }
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE67E22))),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text('Scan ${widget.documentType}'), backgroundColor: Colors.transparent),
      body: Stack(
        alignment: Alignment.center,
        children: [
          CameraPreview(_controller!),
          Container(
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE67E22), width: 3), borderRadius: BorderRadius.circular(12)),
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.6,
          ),
          Positioned(
            bottom: 120,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black54,
              child: Text('Captured: $_currentTimeStamp', style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace')),
            ),
          ),
          Positioned(
            bottom: 40,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFFE67E22),
              onPressed: () async {
                final image = await _controller!.takePicture();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ResultScreen(imagePath: image.path, documentType: widget.documentType, timestamp: _currentTimeStamp)),
                );
              },
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 32),
            ),
          )
        ],
      ),
    );
  }
}
