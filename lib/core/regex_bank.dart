final reGstin = RegExp(r'\b\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]\b');
final reMrp = RegExp(
  r'(?:MRP|M\.R\.P\.?|Max(?:imum)?\.?\s*Retail\s*Price)[^0-9₹R]{0,15}(?:Rs\.?|₹|INR)?\s*([0-9]{1,6}(?:[.,][0-9]{1,2})?)',
  caseSensitive: false);
final reNetQty = RegExp(
  r'(?:Net\s*(?:Wt|Weight|Qty|Quantity|Contents?)\.?)\s*[:.\-]?\s*([0-9]+(?:\.[0-9]+)?)\s*(kg|g|gm|gms|mg|l|ltr|litre|ml|pcs|nos|n)\b',
  caseSensitive: false);
final reFssai = RegExp(r'(?:FSSAI|Lic(?:ence)?\.?\s*No\.?)[^0-9]{0,12}(\d{14})',
  caseSensitive: false);
final reBisHuid = RegExp(r'\b[A-Z0-9]{6}\b', caseSensitive: false); // BIS HUID for jewellery
final rePhone = RegExp(r'(?:\+?91[\-\s]?)?[6-9]\d{9}|1800[\-\s]?\d{3}[\-\s]?\d{4}');
final reEmail = RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}');
final rePin   = RegExp(r'\b[1-9]\d{5}\b');
final reMfg = RegExp(
  r'(?:Mfg|Mfd|Manufactured|Packed|Pkd)\.?\s*(?:on|date|dt)?\.?[:\-\s]*([0-9]{1,2}[/\-.][0-9]{2,4}|[A-Za-z]{3,9}[\s.,\-]*[0-9]{2,4})',
  caseSensitive: false);
final reExp = RegExp(
  r'(?:Exp(?:iry)?|Best\s*Before|Use\s*By)\.?\s*(?:date|dt)?\.?[:\-\s]*([0-9]{1,2}[/\-.][0-9]{2,4}|[A-Za-z]{3,9}[\s.,\-]*[0-9]{2,4})',
  caseSensitive: false);
