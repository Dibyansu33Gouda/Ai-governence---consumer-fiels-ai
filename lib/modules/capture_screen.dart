import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'result_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class CaptureScreen extends StatefulWidget {
  final String documentType;
  const CaptureScreen({super.key, required this.documentType});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _errorMessage = "Camera Permission Denied.";
          _isInitializing = false;
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = "No Camera Detected on Device.";
          _isInitializing = false;
        });
        return;
      }
      
      _controller = CameraController(
        cameras.first, 
        ResolutionPreset.max,
        enableAudio: false,
      );
      
      await _controller!.initialize();
      await _controller!.setFocusMode(FocusMode.auto);
      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Camera Init Error: $e";
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) return;
    
    setState(() => _isProcessing = true);
    try {
      final image = await _controller!.takePicture();
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final humanTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      final newPath = '${dir.path}/certus_$timestamp.jpg';
      
      await File(image.path).copy(newPath);
      
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) => ResultScreen(imagePath: newPath, documentType: widget.documentType, timestamp: humanTimestamp)
      ));
    } catch (e) {
      print("Capture Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Capture failed: $e", style: const TextStyle(color: Colors.white))));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFD600)))
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('ERROR'), backgroundColor: Colors.transparent),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFF3333), fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('SCAN: ${widget.documentType.toUpperCase()}'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: widget.documentType == 'product' ? 250 : 450,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFFD600), width: 3),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _capture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD600),
                    border: Border.all(color: Colors.black, width: 4),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: _isProcessing 
                      ? const CircularProgressIndicator(color: Colors.black)
                      : null,
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 130,
            left: 0,
            right: 0,
            child: Text(
              "ALIGN TARGET WITHIN FRAME",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFFD600),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 2.0,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



