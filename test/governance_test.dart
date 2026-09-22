import 'package:flutter_test/flutter_test.dart';
import 'package:certus/core/rule_engine.dart';
import 'package:certus/core/audit_service.dart';

void main() {
  group('Governance Engine & Risk Scoring Tests', () {
    test('Calculates High Risk on GST Tax Math Mismatch and Invalid GSTIN', () {
      final findings = [
        Finding(
          'G-04',
          Severity.fail,
          'g04_gstin_checksum',
          'GSTIN structure',
          '0.1.0',
          {},
          passed: false,
          findingName: 'GSTIN Format & Checksum Verification',
        ),
      ];

      final doc = {
        'supplier_gstin': '27AAPFU0939F1ZX',
        'taxable_value': '1000',
        'gst_rate': '18',
        'total_tax': '280', // Expected 180, difference 100
        'grand_total': '1280',
      };

      final assessment = assessDocumentRisk(
        findings: findings,
        docType: 'invoice',
        doc: doc,
        ocrText: 'Sample OCR Invoice Text',
      );

      expect(assessment.level, 'HIGH');
      expect(assessment.score, greaterThanOrEqualTo(70));
      expect(assessment.primaryReason, contains('The calculated GST amount is ₹180, but the invoice shows ₹280'));
      expect(assessment.checklist['GSTIN Checksum'], isFalse);
      expect(assessment.checklist['Invoice Tax Math'], isFalse);
    });

    test('Calculates Passed / Zero Risk on fully compliant product', () {
      final findings = [
        Finding('L-01', Severity.info, 'mfg', 'LMPC', '1.0', {}, passed: true),
        Finding('L-02', Severity.info, 'qty', 'LMPC', '1.0', {}, passed: true),
        Finding('L-03', Severity.info, 'mrp', 'LMPC', '1.0', {}, passed: true),
        Finding('L-04', Severity.info, 'date', 'LMPC', '1.0', {}, passed: true),
        Finding('L-05', Severity.info, 'care', 'LMPC', '1.0', {}, passed: true),
      ];

      final doc = {
        'brand': 'Dove',
        'net_quantity': '100g',
        'mrp': '65',
        'mfg_date': '01/2026',
        'customer_care': 'care@unilever.com',
      };

      final assessment = assessDocumentRisk(
        findings: findings,
        docType: 'product',
        doc: doc,
        ocrText: 'Dove soap packaging text',
      );

      expect(assessment.level, 'PASSED');
      expect(assessment.score, 0);
      expect(assessment.checklist['Manufacturer Details'], isTrue);
      expect(assessment.checklist['Net Quantity Metric'], isTrue);
      expect(assessment.checklist['Customer Care Contact'], isTrue);
    });

    test('AuditRecord serialization and deserialization', () {
      final record = AuditRecord(
        id: 'test_1',
        timestamp: '2026-09-22T20:00:00Z',
        dateFormatted: 'Today, 20:00',
        documentType: 'invoice',
        title: 'Wholesale Invoice',
        riskScore: 82,
        riskLevel: 'HIGH',
        verdict: 'CHECK_THESE',
        primaryReason: 'GST tax mismatch',
        checklistPassed: ['Supplier Details'],
        checklistFailed: ['Tax Math'],
        extractedData: {'taxable': '1000'},
      );

      final json = record.toJson();
      final fromJson = AuditRecord.fromJson(json);

      expect(fromJson.id, 'test_1');
      expect(fromJson.riskScore, 82);
      expect(fromJson.riskLevel, 'HIGH');
      expect(fromJson.checklistFailed, contains('Tax Math'));
    });
  });
}

