import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'capture_screen.dart';
import 'ask_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  String _currentTime = "";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('CERTUS', style: TextStyle(letterSpacing: 2.0)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  border: Border.all(color: const Color(0xFF00FF66), width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Color(0xFF00FF66), size: 8),
                    const SizedBox(width: 6),
                    Text('SYSTEM ACTIVE | $_currentTime', style: const TextStyle(color: Color(0xFF00FF66), fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          // Background grid pattern effect (Subtle)
          Positioned.fill(
            child: Opacity(
              opacity: 0.03,
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Spacious Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: const Color(0xFFFFD600),
                        child: const Text("AI COMPLIANCE ENGINE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Select target\nfor verification.",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Real-time auditing of consumer goods, tax invoices, and KYC documents using edge-AI.",
                        style: TextStyle(color: Colors.white54, fontSize: 16, height: 1.4),
                      ),
                    ],
                  ),
                ),
                
                // Spacious Scrollable Cards
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildLargeActionCard(
                        context,
                        title: 'PRODUCT VALIDATION',
                        subtitle: 'Scan barcodes, FSSAI licenses, and MRP rules to detect counterfeit packaging.',
                        icon: Icons.qr_code_scanner,
                        docType: 'product',
                        isPrimary: true,
                      ),
                      const SizedBox(height: 16),
                      _buildLargeActionCard(
                        context,
                        title: 'TAX INVOICE AUDIT',
                        subtitle: 'Verify GSTIN registration, bill of supply rules, and total taxation bounds.',
                        icon: Icons.receipt_long,
                        docType: 'invoice',
                        isPrimary: false,
                      ),
                      const SizedBox(height: 16),
                      _buildLargeActionCard(
                        context,
                        title: 'GOVT KYC FORM',
                        subtitle: 'Extract and validate PAN, Aadhaar, and Driving License identity structures.',
                        icon: Icons.badge,
                        docType: 'form',
                        isPrimary: false,
                      ),
                      const SizedBox(height: 100), // padding for bottom bar
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Fixed Bottom Voice Assistant Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.8), offset: const Offset(0, -10), blurRadius: 20),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AskScreen(contextText: ""))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF141414),
                  foregroundColor: const Color(0xFFFFD600),
                  side: const BorderSide(color: Color(0xFFFFD600), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, size: 28),
                    SizedBox(width: 12),
                    Text("OPEN VOICE ASSISTANT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required String docType, required bool isPrimary}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => CaptureScreen(documentType: docType)));
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFFFD600) : const Color(0xFF141414),
          border: isPrimary ? null : Border.all(color: const Color(0xFF2A2A2A), width: 1),
          borderRadius: BorderRadius.circular(2),
          boxShadow: isPrimary ? [
            BoxShadow(color: const Color(0xFFFFD600).withOpacity(0.2), offset: const Offset(0, 8), blurRadius: 16)
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 48, color: isPrimary ? Colors.black : const Color(0xFFFFD600)),
                Icon(Icons.arrow_forward_rounded, size: 28, color: isPrimary ? Colors.black54 : Colors.white30),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                color: isPrimary ? Colors.black : Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: isPrimary ? Colors.black87 : Colors.white54,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    double step = 30.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
