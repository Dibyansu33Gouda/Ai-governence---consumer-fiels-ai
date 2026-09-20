import 'package:flutter/material.dart';
import 'capture_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Text(
              'What would you like to verify?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            _buildPrimaryButton(context, 'Scan Product', Icons.inventory_2, 'product'),
            const SizedBox(height: 16),
            _buildPrimaryButton(context, 'Scan Bill', Icons.receipt_long, 'bill'),
            const SizedBox(height: 16),
            _buildPrimaryButton(context, 'Scan Form', Icons.description, 'form'),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const CaptureScreen(documentType: 'auto')));
              },
              icon: const Icon(Icons.document_scanner),
              label: const Text('Auto-detect Scan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2C3E50),
                side: const BorderSide(color: Color(0xFF2C3E50)),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context, String label, IconData icon, String type) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => CaptureScreen(documentType: type)));
      },
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontSize: 18)),
    );
  }
}
