enum Severity { info, warn, fail }

class Finding {
  final String ruleId, messageKey, cite, rulebookVersion;
  final Severity severity;
  final Map<String, String> args;
  final bool passed;
  Finding(this.ruleId, this.severity, this.messageKey, this.cite,
      this.rulebookVersion, this.args, {this.passed = false});
}

typedef Validator = bool Function(Map<String, dynamic> doc, Map<String, dynamic> node);

class RuleEngine {
  final Map<String, Validator> validators;
  RuleEngine(this.validators);

  List<Finding> run(Map<String, dynamic> book, String docType, Map<String, dynamic> doc) {
    final out = <Finding>[];
    for (final r in (book['rules'] as List).cast<Map<String, dynamic>>()) {
      if (r['applies_to'] != docType) continue;
      
      final when = r['when'] as Map<String, dynamic>?;
      if (when != null && !_eval(when, doc)) {
         // Not applicable
         continue;
      }
      
      bool didPass = _eval(r['check'] as Map<String, dynamic>, doc);
      
      if (didPass) {
         out.add(Finding(r['id'], Severity.info, r['message_key'], r['cite'] ?? '', book['version'], _args(r, doc), passed: true));
      } else {
         out.add(Finding(r['id'], Severity.values.byName(r['severity']), r['message_key'], r['cite'] ?? '', book['version'], _args(r, doc), passed: false));
      }
    }
    return out;
  }

  Map<String, String> _args(Map<String, dynamic> r, Map<String, dynamic> doc) {
    final f = (r['check'] as Map<String, dynamic>)['field'];
    return f == null ? {} : {'field': '$f', 'value': '${doc[f] ?? ''}'};
  }

  dynamic _val(dynamic ref, Map<String, dynamic> doc) =>
      (ref is String && ref == r'$today') ? DateTime.now() : (doc[ref] ?? ref);

  bool _eval(Map<String, dynamic> n, Map<String, dynamic> doc) {
    switch (n['op']) {
      case 'exists':
        final v = doc[n['field']];
        return v != null && v.toString().trim().isNotEmpty;
      case 'equals':
        return doc[n['field']]?.toString() == n['value']?.toString();
      case 'regex':
        final v = doc[n['field']]?.toString();
        return v == null || RegExp(n['pattern']).hasMatch(v);
      case 'lte':
      case 'gte':
        final a = doc[n['field']];
        final b = _val(n['other'] ?? n['value'], doc);
        if (a == null || b == null) return true;
        final c = _cmp(a, b);
        return n['op'] == 'lte' ? c <= 0 : c >= 0;
      case 'validator':
        return validators[n['name']]!(doc, n);
      case 'all':
        return (n['items'] as List).every((x) => _eval(x, doc));
      case 'any':
        return (n['items'] as List).any((x) => _eval(x, doc));
      case 'not':
        return !_eval(n['item'], doc);
      default:
        throw ArgumentError('unknown op ${n['op']}');
    }
  }

  int _cmp(dynamic a, dynamic b) {
    if (a is DateTime && b is DateTime) return a.compareTo(b);
    return num.parse('$a').compareTo(num.parse('$b'));
  }
}
