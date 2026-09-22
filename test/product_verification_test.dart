import 'package:flutter_test/flutter_test.dart';
import 'package:certus/core/product_lookup_service.dart';
import 'package:certus/core/rule_engine.dart';
import 'package:certus/core/validators.dart';

void main() {
  group('Product Lookup & Statutory Verification Tests', () {
    test('Validates EAN-13 format, checksum and GS1 India 890 prefix', () {
      // Parle-G EAN-13 (8901764012273)
      const parleBarcode = '8901764012273';
      expect(isValidEan13(parleBarcode), isTrue);
      expect(isGs1IndiaPrefix(parleBarcode), isTrue);

      // Dove Soap EAN-13 (8901030824968)
      const doveBarcode = '8901030824968';
      expect(isValidEan13(doveBarcode), isTrue);
      expect(isGs1IndiaPrefix(doveBarcode), isTrue);

      // Corrupted Check Digit (8901764012270 has wrong check digit 0 instead of 3)
      const invalidChecksumBarcode = '8901764012270';
      expect(isValidEan13(invalidChecksumBarcode), isFalse);
    });

    test('ProductLookupService resolves authentic products from offline DB without hallucinations', () async {
      final mockOfflineDb = {
        'products': {
          '8900000000019': {
            'name': 'Heritage Pure Cow Ghee',
            'brand': 'Heritage',
            'category': 'Dairy Products',
            'description': 'Pure cow ghee prepared from fresh milk cream.',
            'manufacturer': 'Heritage Foods Ltd',
          },
          '8901030824968': 'Dove Cream Beauty Bathing Bar',
        }
      };

      final service = ProductLookupService();

      // Look up code present in offline DB
      final offlineResult = await service.lookup('8900000000019', offlineDb: mockOfflineDb);
      expect(offlineResult.isBarcodeFormatValid, isTrue);
      expect(offlineResult.hasProductInfo, isTrue);
      expect(offlineResult.productName, equals('Heritage Pure Cow Ghee'));
      expect(offlineResult.brand, equals('Heritage'));
      expect(offlineResult.description, contains('Pure cow ghee'));
      expect(offlineResult.sourceName, contains('Offline Registry'));

      // Look up an unrecorded barcode (strict zero-hallucination test)
      final unknownResult = await service.lookup('8909999999995', offlineDb: mockOfflineDb);
      // Since it's not in DB and offline, description must NOT be hallucinated
      expect(unknownResult.productName, isNull);
      expect(unknownResult.description, isNull);
      expect(
        unknownResult.statusMessage,
        anyOf(
          contains('Product information could not be found'),
          contains('Online product information is unavailable'),
        ),
      );
    });

    test('verifyProduct produces explainable VERIFIED verdict on compliant barcode', () {
      final findings = [
        Finding('P-10', Severity.fail, 'p10_barcode_checksum', 'GS1', '1.0', {}, passed: true, findingName: 'Barcode Checksum'),
        Finding('P-10b', Severity.info, 'p10b_gs1_india_prefix', 'GS1 India', '1.0', {}, passed: true, findingName: 'GS1 India Prefix'),
        Finding('P-05', Severity.warn, 'p05_mrp_missing', 'LMPC', '1.0', {}, passed: true, findingName: 'Mandatory MRP'),
      ];

      final doc = {
        'barcode': '8901764012273',
        'mrp': '₹10.00',
        'is_food': true,
        'fssai_number': '10012021000071',
      };

      final result = verifyProduct(
        findings: findings,
        doc: doc,
        barcode: '8901764012273',
        isBarcodeFormatValid: true,
        isChecksumValid: true,
        isGs1India: true,
      );

      expect(result.verdict, equals('VERIFIED'));
      expect(result.reason, contains('conform to Legal Metrology and GS1 standards'));
      expect(result.barcodeFormatValid, isTrue);
      expect(result.checksumValid, isTrue);
      expect(result.gs1IndiaValid, isTrue);
      expect(result.itemChecks['Barcode format'], contains('✓ Valid'));
      expect(result.itemChecks['EAN-13 checksum'], contains('✓ Valid'));
      expect(result.itemChecks['GS1 prefix'], contains('✓ India (890)'));
      // Verifies the explicit legal distinction between barcode format and physical authenticity
      expect(result.disclaimer, contains('A valid barcode only proves that the barcode passes'));
      expect(result.disclaimer, contains('does not certify physical product authenticity'));
    });

    test('verifyProduct produces REVIEW REQUIRED on checksum mismatch', () {
      final findings = [
        Finding('P-10', Severity.fail, 'p10_barcode_checksum', 'GS1', '1.0', {}, passed: false, findingName: 'Barcode Checksum'),
      ];

      final doc = {
        'barcode': '8901764012270', // Corrupted checksum
      };

      final result = verifyProduct(
        findings: findings,
        doc: doc,
        barcode: '8901764012270',
        isBarcodeFormatValid: true, // 13-digit format syntax recognized
        isChecksumValid: false, // Check digit fails
        isGs1India: true,
      );

      expect(result.verdict, equals('REVIEW REQUIRED'));
      expect(result.checksumValid, isFalse);
      expect(result.itemChecks['EAN-13 checksum'], contains('❌ Checksum Failed'));
      expect(result.reason, contains('modulo-10 checksum validation'));
    });

    test('verifyProduct produces UNABLE TO VERIFY on missing/unreadable barcode', () {
      final result = verifyProduct(
        findings: [],
        doc: {},
        barcode: null,
        isBarcodeFormatValid: false,
        isChecksumValid: false,
        isGs1India: false,
      );

      expect(result.verdict, equals('UNABLE TO VERIFY'));
      expect(result.reason, contains('Barcode could not be read'));
      expect(result.itemChecks['Barcode format'], contains('Missing'));
    });
  });
}

