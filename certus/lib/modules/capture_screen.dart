import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
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

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _controller = CameraController(_cameras[0], ResolutionPreset.max);
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
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Scan ${widget.documentType}'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          CameraPreview(_controller!),
          // Frame guide
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE67E22), width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
            width: MediaQuery.of(context).size.width * 0.85,
            height: MediaQuery.of(context).size.height * 0.6,
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
                  MaterialPageRoute(builder: (context) => ResultScreen(imagePath: image.path, documentType: widget.documentType)),
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
