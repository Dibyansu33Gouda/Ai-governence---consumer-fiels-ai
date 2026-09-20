String maskAadhaar(String s) {
  final d = s.replaceAll(RegExp(r'\D'), '');
  return d.length == 12 ? 'XXXX XXXX ${d.substring(8)}' : s;
}

String maskPan(String s) => s.length == 10 ? 'XXXXXX${s.substring(6)}' : s;

String maskPhone(String s) {
  final d = s.replaceAll(RegExp(r'\D'), '');
  return d.length >= 10 ? '${'X' * (d.length - 3)}${d.substring(d.length - 3)}' : s;
}

String maskAll(String text) => text
    .replaceAllMapped(RegExp(r'\b\d{4}\s?\d{4}\s?\d{4}\b'), (m) => maskAadhaar(m[0]!))
    .replaceAllMapped(RegExp(r'\b[A-Z]{5}\d{4}[A-Z]\b'), (m) => maskPan(m[0]!))
    .replaceAllMapped(RegExp(r'\b(?:\+?91[\-\s]?)?[6-9]\d{9}\b'), (m) => maskPhone(m[0]!));
