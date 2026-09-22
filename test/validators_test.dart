import 'package:flutter_test/flutter_test.dart';
import 'package:certus/core/validators.dart';

void main() {
  group('Validators Test', () {
    test('GSTIN validation', () {
      expect(isValidGstin('27AAPFU0939F1ZV'), isTrue);
      expect(isValidGstin('27AAPFU0939F1ZX'), isFalse);
      
      // additional cases
      expect(isValidGstin('06AAAAA0000A1Z6'), isTrue);
    });

    test('EAN-13 validation', () {
      expect(isValidEan13('4006381333931'), isTrue);
      expect(isValidEan13('4006381333932'), isFalse);
    });
    
    test('PAN entity validation', () {
      expect(panEntityOk('27AAPFU0939F1ZV'), isTrue); // 'F' is in the set
    });
  });
}
