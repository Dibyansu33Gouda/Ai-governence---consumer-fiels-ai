import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'capture_screen.dart';
import 'ask_screen.dart';
import '../core/audit_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  String _currentTime = "";
  Map<String, int> _metrics = {
    'products': 12,
    'invoices': 8,
    'forms': 4,
    'issues': 5,
    'highRisk': 2,
  };
  List<AuditRecord> _history = [];

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
    _loadAuditData();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('HH:mm:ss').format(DateTime.now());
      });
    }
  }

  Future<void> _loadAuditData() async {
    try {
      final metrics = await AuditService().getSummaryMetrics();
      final history = await AuditService().getHistory();
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _history = history;
        });
      }
    } catch (_) {}
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
          // Background grid pattern effect
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
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: const Color(0xFFFFD600),
                        child: const Text("AI COMPLIANCE & GOVERNANCE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Sovereign Field\nAuditor.",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Scrollable Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadAuditData,
                    color: const Color(0xFFFFD600),
                    backgroundColor: const Color(0xFF141414),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // 1. VERIFICATION SUMMARY ANALYTICS DASHBOARD (Feature 8)
                        _buildVerificationSummaryCard(),
                        const SizedBox(height: 20),

                        const Text("SELECT TARGET FOR VERIFICATION:", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                        const SizedBox(height: 12),

                        // Action Cards
                        _buildLargeActionCard(
                          context,
                          title: 'PRODUCT VALIDATION',
                          subtitle: 'Scan barcodes, FSSAI licenses, and MRP rules to detect counterfeit packaging.',
                          icon: Icons.qr_code_scanner,
                          docType: 'product',
                          isPrimary: true,
                        ),
                        const SizedBox(height: 14),
                        _buildLargeActionCard(
                          context,
                          title: 'TAX INVOICE AUDIT',
                          subtitle: 'Verify GSTIN registration, bill of supply rules, and tax line-item math.',
                          icon: Icons.receipt_long,
                          docType: 'invoice',
                          isPrimary: false,
                        ),
                        const SizedBox(height: 14),
                        _buildLargeActionCard(
                          context,
                          title: 'GOVT KYC FORM',
                          subtitle: 'Extract and validate PAN, Aadhaar, and Driving License identity structures.',
                          icon: Icons.badge,
                          docType: 'form',
                          isPrimary: false,
                        ),
                        const SizedBox(height: 24),

                        // 2. AUDIT HISTORY LIST (Feature 7)
                        _buildAuditHistorySection(),
                        const SizedBox(height: 110), // padding for fixed bottom bar
                      ],
                    ),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.9), offset: const Offset(0, -10), blurRadius: 20),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AskScreen(contextText: ""))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF141414),
                  foregroundColor: const Color(0xFFFFD600),
                  side: const BorderSide(color: Color(0xFFFFD600), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.mic, size: 26),
                    SizedBox(width: 10),
                    Text("OPEN VOICE & KEYBOARD AI", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // FEATURE 8: VERIFICATION SUMMARY ANALYTICS CARD
  // ----------------------------------------------------
  Widget _buildVerificationSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.insights, color: Color(0xFFFFD600), size: 16),
                  SizedBox(width: 8),
                  Text(
                    "VERIFICATION SUMMARY",
                    style: TextStyle(color: Color(0xFFFFD600), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2, fontFamily: 'monospace'),
                  ),
                ],
              ),
              Text("SOVEREIGN LOG", style: TextStyle(color: Color(0xFF00FF66), fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildMetricTile("Products", "${_metrics['products'] ?? 0}", const Color(0xFF00E5FF))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile("Invoices", "${_metrics['invoices'] ?? 0}", const Color(0xFF00FF66))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile("Govt Forms", "${_metrics['forms'] ?? 0}", const Color(0xFFFFD600))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMetricTile("Potential Issues", "${_metrics['issues'] ?? 0}", const Color(0xFFFF9800))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile("High-Risk Blockers", "${_metrics['highRisk'] ?? 0}", const Color(0xFFFF3333))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(left: BorderSide(color: color, width: 3)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // FEATURE 7: AUDIT HISTORY SECTION
  // ----------------------------------------------------
  Widget _buildAuditHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("RECENT VERIFICATION AUDIT TRAIL:", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            Text("LOCAL STORAGE", style: TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace')),
          ],
        ),
        const SizedBox(height: 12),
        if (_history.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text("No audit records stored yet. Run a scan to build history.", style: TextStyle(color: Colors.white54, fontSize: 12)),
            ),
          )
        else
          ..._history.take(6).map((record) {
            Color badgeColor = const Color(0xFF00FF66);
            if (record.riskLevel == 'HIGH') {
              badgeColor = const Color(0xFFFF3333);
            } else if (record.riskLevel == 'MEDIUM') {
              badgeColor = const Color(0xFFFFD600);
            } else if (record.riskLevel == 'LOW') {
              badgeColor = const Color(0xFF00E5FF);
            }

            IconData docIcon = Icons.qr_code_scanner;
            if (record.documentType == 'invoice') docIcon = Icons.receipt_long;
            if (record.documentType == 'form') docIcon = Icons.badge;

            return GestureDetector(
              onTap: () => _showAuditRecordDetails(record),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  border: Border.all(color: const Color(0xFF222222)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFF0A0A0A), borderRadius: BorderRadius.circular(4)),
                      child: Icon(docIcon, color: badgeColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(record.dateFormatted, style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace')),
                              const SizedBox(width: 6),
                              Text("• ${record.documentType.toUpperCase()}", style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record.title,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: badgeColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        "${record.riskLevel} ${record.riskScore}",
                        style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showAuditRecordDetails(AuditRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E0E0E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Color(0xFFFFD600), width: 1.5),
      ),
      builder: (ctx) {
        Color badgeColor = const Color(0xFF00FF66);
        if (record.riskLevel == 'HIGH') {
          badgeColor = const Color(0xFFFF3333);
        } else if (record.riskLevel == 'MEDIUM') {
          badgeColor = const Color(0xFFFFD600);
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("AUDIT RECORD DETAILS", style: TextStyle(color: Color(0xFFFFD600), fontWeight: FontWeight.w900, letterSpacing: 1.2, fontSize: 12, fontFamily: 'monospace')),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white54, size: 20)),
                ],
              ),
              const SizedBox(height: 12),
              Text(record.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text("Verified on ${record.dateFormatted} (${record.documentType.toUpperCase()})", style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace')),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  border: Border(left: BorderSide(color: badgeColor, width: 3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("RISK ASSESSMENT: ${record.riskLevel} (${record.riskScore}/100)", style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(record.primaryReason, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
              if (record.checklistFailed.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text("FAILED STATUTORY CHECKS:", style: TextStyle(color: Color(0xFFFF3333), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...record.checklistFailed.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Icon(Icons.cancel, color: Color(0xFFFF3333), size: 14),
                    const SizedBox(width: 6),
                    Text(c, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                )),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLargeActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required String docType, required bool isPrimary}) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (context) => CaptureScreen(documentType: docType)));
        _loadAuditData(); // Refresh history upon returning from scan
      },
      child: Container(
        padding: const EdgeInsets.all(22),
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
                Icon(icon, size: 44, color: isPrimary ? Colors.black : const Color(0xFFFFD600)),
                Icon(Icons.arrow_forward_rounded, size: 26, color: isPrimary ? Colors.black54 : Colors.white30),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                color: isPrimary ? Colors.black : Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: isPrimary ? Colors.black87 : Colors.white54,
                fontSize: 13,
                height: 1.35,
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
