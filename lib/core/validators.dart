const _cp = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

/// GSTIN: 15 chars. Structure plus check character (base-36 weighted sum).
bool isValidGstin(String raw) {
  final g = raw.trim().toUpperCase();
  final shape = RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$');
  if (!shape.hasMatch(g)) return false;
  var sum = 0;
  for (var i = 0; i < 14; i++) {
    final v = _cp.indexOf(g[i]);
    final p = v * (i.isEven ? 1 : 2);
    sum += (p ~/ 36) + (p % 36);
  }
  final check = (36 - (sum % 36)) % 36;
  return _cp[check] == g[14];
}

/// EAN-13 / GS1 Digital Link / QR Code format validator
bool isValidEan13(String s) {
  final clean = s.trim();
  if (clean.isEmpty) return false;
  // If it's a URL or QR code digital link, it is a valid packaging identifier
  if (clean.startsWith('http://') || clean.startsWith('https://')) return true;
  
  if (!RegExp(r'^\d{13}$').hasMatch(clean)) {
    // Also accept 8-digit EAN-8 or 12-digit UPC-A
    if (RegExp(r'^\d{8}$').hasMatch(clean) || RegExp(r'^\d{12}$').hasMatch(clean)) return true;
    return false;
  }
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final d = int.parse(clean[i]);
    sum += i.isEven ? d : d * 3;
  }
  return (10 - (sum % 10)) % 10 == int.parse(clean[12]);
}

/// Check if EAN-13 barcode has the GS1 India prefix (890) or is an authorized Indian Digital Link
bool isGs1IndiaPrefix(String s) {
  final clean = s.trim();
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return true; // Authorized Digital Link
  }
  return isValidEan13(clean) && clean.startsWith('890');
}

/// FSSAI Structure: Must be exactly 14 digits.
bool isFssaiShape(String s) {
  final clean = s.replaceAll(RegExp(r'[^0-9]'), '');
  return clean.length == 14;
}

/// BIS HUID Structure (Jewellery): 6-character alphanumeric.
bool isBisHuidShape(String s) => RegExp(r'^[A-Z0-9]{6}$', caseSensitive: false).hasMatch(s.trim());

const panEntityTypes = {'P','C','H','F','A','T','B','L','J','G'};
bool panEntityOk(String gstin) =>
    gstin.length == 15 && panEntityTypes.contains(gstin[5]);
