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

/// EAN-13: weights 1,3,1,3... over the first 12 digits.
bool isValidEan13(String s) {
  if (!RegExp(r'^\d{13}$').hasMatch(s)) return false;
  var sum = 0;
  for (var i = 0; i < 12; i++) {
    final d = int.parse(s[i]);
    sum += i.isEven ? d : d * 3;
  }
  return (10 - (sum % 10)) % 10 == int.parse(s[12]);
}

bool isFssaiShape(String s) => RegExp(r'^\d{14}$').hasMatch(s);

const panEntityTypes = {'P','C','H','F','A','T','B','L','J','G'};
bool panEntityOk(String gstin) =>
    gstin.length == 15 && panEntityTypes.contains(gstin[5]);
