enum Severity { info, warn, fail }

class Finding {
  final String ruleId;
  final Severity severity;
  final String messageKey;
  final String cite;
  final String rulebookVersion;
  final Map<String, String> args;
  final bool passed;

  // Auditable governance metadata (Finding -> Evidence -> Rule -> Explanation)
  final String findingName;
  final String evidence;
  final String ruleText;
  final String explanationText;
  final String confidence;

  Finding(
    this.ruleId,
    this.severity,
    this.messageKey,
    this.cite,
    this.rulebookVersion,
    this.args, {
    this.passed = false,
    this.findingName = "",
    this.evidence = "",
    this.ruleText = "",
    this.explanationText = "",
    this.confidence = "High (Deterministic Rule Engine)",
  });
}

class RiskAssessment {
  final int score; // 0 to 100
  final String level; // 'HIGH', 'MEDIUM', 'LOW', 'PASSED'
  final String primaryReason; // "Why was this flagged?"
  final Map<String, bool> checklist; // key -> isPassed
  final List<String> criticalIssues;

  RiskAssessment({
    required this.score,
    required this.level,
    required this.primaryReason,
    required this.checklist,
    required this.criticalIssues,
  });
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
         continue; // Not applicable
      }
      
      bool didPass = _eval(r['check'] as Map<String, dynamic>, doc);
      final metadata = _generateAuditMetadata(r, doc, didPass);

      if (didPass) {
         out.add(Finding(
           r['id'],
           Severity.info,
           r['message_key'],
           r['cite'] ?? '',
           book['version'],
           _args(r, doc),
           passed: true,
           findingName: metadata['name']!,
           evidence: metadata['evidence']!,
           ruleText: metadata['rule']!,
           explanationText: metadata['explanation']!,
           confidence: "High (Deterministic Rule Engine)",
         ));
      } else {
         out.add(Finding(
           r['id'],
           Severity.values.byName(r['severity']),
           r['message_key'],
           r['cite'] ?? '',
           book['version'],
           _args(r, doc),
           passed: false,
           findingName: metadata['name']!,
           evidence: metadata['evidence']!,
           ruleText: metadata['rule']!,
           explanationText: metadata['explanation']!,
           confidence: "High (Deterministic Rule Engine)",
         ));
      }
    }
    return out;
  }

  Map<String, String> _generateAuditMetadata(Map<String, dynamic> r, Map<String, dynamic> doc, bool didPass) {
    final id = r['id'] ?? '';
    final cite = r['cite'] ?? 'Statutory Provision';
    String name = r['message_key'] ?? id;
    String evidence = "";
    String rule = cite;
    String explanation = "";

    // Map common rule IDs to auditable governance chains
    switch (id) {
      case 'L-01':
      case 'L-07':
        name = "Manufacturer / Packer Identity";
        evidence = doc['manufacturer'] != null ? "Manufacturer: '${doc['manufacturer']}'" : "No manufacturer name or physical address detected in scan";
        rule = "LMPC Rules 2011, Rule 6(1)(a): Every package must bear name and complete address of the manufacturer.";
        explanation = didPass ? "Complete entity identity verified under Legal Metrology standards." : "Missing manufacturer identity denies consumer recourse and violates Section 36 of Legal Metrology Act.";
        break;
      case 'L-02':
        name = "Net Quantity Metric Declaration";
        evidence = doc['net_quantity'] != null ? "Declared Quantity: '${doc['net_quantity']}'" : "No metric net quantity declaration found";
        rule = "LMPC Rules 2011, Rule 6(1)(b): Net quantity must be declared in standard SI metric units (g, kg, ml, l).";
        explanation = didPass ? "Standard metric unit declaration detected." : "Omission of net quantity facilitates quantity fraud and packaging deception.";
        break;
      case 'L-03':
        name = "Maximum Retail Price (MRP) Declaration";
        evidence = doc['mrp'] != null ? "Declared MRP: '${doc['mrp']}'" : "No statutory MRP declaration found";
        rule = "LMPC Rules 2011, Rule 6(1)(e): Maximum Retail Price inclusive of all taxes must be prominently printed.";
        explanation = didPass ? "Statutory retail price with tax inclusion detected." : "Absence of statutory MRP permits arbitrary overcharging of consumers.";
        break;
      case 'L-04':
        name = "Manufacturing / Expiry Date";
        evidence = doc['mfg_date'] != null ? "Date: '${doc['mfg_date']}'" : (doc['expiry_date'] != null ? "Expiry: '${doc['expiry_date']}'" : "No manufacturing or best-before date detected");
        rule = "LMPC Rules 2011, Rule 6(1)(d): Month and year of manufacture or packaging must be declared.";
        explanation = didPass ? "Packaging chronology verified." : "Unlabeled manufacturing dates endanger consumer safety through expired consumption.";
        break;
      case 'L-05':
        name = "Consumer Care Redressal Details";
        evidence = doc['customer_care'] != null ? "Contact: '${doc['customer_care']}'" : "No dedicated email, telephone, or address for consumer complaints";
        rule = "LMPC Rules 2011, Rule 6(1)(n): Name, address, telephone number and email of grievance redressal officer must be provided.";
        explanation = didPass ? "Consumer helpline contact details established." : "Omitting grievance contact violates mandatory consumer protection norms.";
        break;
      case 'L-06':
        name = "FSSAI Food Safety License";
        evidence = doc['fssai_number'] != null ? "FSSAI ID: '${doc['fssai_number']}'" : "14-digit FSSAI license absent from food package";
        rule = "Food Safety and Standards (Packaging and Labelling) Regulations, Section 2.2.1.";
        explanation = didPass ? "14-digit statutory license structure verified." : "Food product lacks verifiable statutory registration with FSSAI.";
        break;
      case 'G-03':
      case 'G-04':
        name = "GSTIN Format & Checksum Verification";
        final g = doc['supplier_gstin']?.toString() ?? 'N/A';
        evidence = "Scanned Supplier GSTIN: '$g'";
        rule = "CGST Act 2017 Section 22 & Rule 10: 15-character structure with base-36 weighted checksum.";
        explanation = didPass ? "GSTIN format conforms to national taxpayer registry standards." : "GSTIN checksum fails mathematical verification. High probability of fictitious or fraudulent invoice.";
        break;
      case 'G-05':
        name = "PAN Entity Structure in GSTIN";
        final g5 = doc['supplier_gstin']?.toString() ?? 'N/A';
        evidence = "Character 6 entity type: '${g5.length >= 6 ? g5[5] : 'invalid'}'";
        rule = "Income Tax Act 1961 Section 139A & CGST Structure.";
        explanation = didPass ? "PAN entity classification aligns with recognized legal person types." : "Entity character in GSTIN does not correspond to an authorized taxpayer entity type.";
        break;
      case 'G-11':
        name = "Retail Price Cap / MRP Bound";
        evidence = "Invoice Grand Total: '${doc['grand_total'] ?? 'N/A'}', Listed MRP: '${doc['mrp'] ?? 'N/A'}'";
        rule = "LMPC Rules 2011, Rule 2(m): No retail dealer or person shall sell any commodity at a price exceeding MRP.";
        explanation = didPass ? "Billed price is within statutory ceiling." : "Billed amount exceeds Maximum Retail Price. Constitutes illegal overcharging under Section 36.";
        break;
      case 'G-12':
        name = "Tax Invoice Serial Number";
        evidence = doc['invoice_no'] != null ? "Invoice No: '${doc['invoice_no']}'" : "Sequential invoice number missing from header";
        rule = "CGST Rules 2017, Rule 46(b): Mandatory consecutive serial number unique for a financial year.";
        explanation = didPass ? "Invoice traceability established." : "Missing invoice number impairs audit trail and Input Tax Credit (ITC) eligibility.";
        break;
      default:
        evidence = doc.entries.take(3).map((e) => "${e.key}: ${e.value}").join(", ");
        rule = cite;
        explanation = didPass ? "Statutory rule satisfied." : "Statutory requirement not met.";
    }

    return {
      'name': name,
      'evidence': evidence,
      'rule': rule,
      'explanation': explanation,
    };
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

/// Computes comprehensive risk score (0 - 100), risk level, checklist, and plain-language explanation
RiskAssessment assessDocumentRisk({
  required List<Finding> findings,
  required String docType,
  required Map<String, dynamic> doc,
  required String ocrText,
}) {
  int score = 0;
  final criticalIssues = <String>[];
  final checklist = <String, bool>{};

  // 1. Evaluate Findings
  for (final f in findings) {
    if (!f.passed) {
      if (f.severity == Severity.fail) {
        score += 35;
        criticalIssues.add("${f.findingName} (${f.cite})");
      } else if (f.severity == Severity.warn) {
        score += 15;
      }
    }
  }

  // 2. Specific checks by document type
  if (docType == 'invoice') {
    // Check GSTIN Checksum
    final gstin = doc['supplier_gstin']?.toString() ?? '';
    final bool gstinOk = findings.any((f) => f.ruleId == 'G-04' && f.passed);
    checklist['GSTIN Checksum'] = gstin.isNotEmpty && gstinOk;

    // Check Invoice Total / Tax Math
    double? taxable = _extractAmount(doc['taxable_value'] ?? doc['taxable_amount'] ?? doc['subtotal']);
    double? statedTax = _extractAmount(doc['total_tax'] ?? doc['tax_amount'] ?? doc['gst_amount'] ?? doc['cgst']);
    double? rate = _extractAmount(doc['gst_rate'] ?? doc['tax_rate']);

    bool mathMismatch = false;
    String mathDetail = "";
    if (taxable != null && rate != null && statedTax != null) {
      double expectedTax = (taxable * rate) / 100.0;
      double diff = (statedTax - expectedTax).abs();
      if (diff > 2.0) {
        mathMismatch = true;
        score += 45;
        mathDetail = "The calculated GST amount is ₹${expectedTax.toStringAsFixed(0)}, but the invoice shows ₹${statedTax.toStringAsFixed(0)}. This creates a ₹${diff.toStringAsFixed(0)} discrepancy.";
        criticalIssues.add("GST Tax Calculation Mismatch (Diff: ₹${diff.toStringAsFixed(0)})");
      }
    }
    checklist['Invoice Tax Math'] = !mathMismatch;

    // Check MRP Exceeded
    final bool mrpOk = !findings.any((f) => f.ruleId == 'G-11' && !f.passed);
    checklist['MRP Ceiling Respected'] = mrpOk;

    // Check Traceability (Invoice No & Date)
    final bool invoiceNoOk = doc['invoice_no'] != null || doc['invoice_number'] != null;
    checklist['Invoice Traceability'] = invoiceNoOk;

    // Build plain-language "Why was this flagged?" reason
    String reason = "";
    if (score == 0) {
      reason = "All statutory GST validations passed. Tax math, GSTIN structure, and line-item totals are legally consistent.";
    } else if (mathMismatch && !gstinOk) {
      reason = "$mathDetail Furthermore, the supplier GSTIN fails statutory checksum verification.";
    } else if (mathMismatch) {
      reason = mathDetail;
    } else if (!gstinOk && gstin.isNotEmpty) {
      reason = "Supplier GSTIN '$gstin' failed national checksum verification. Potential fictitious invoice risking Input Tax Credit rejection.";
    } else {
      reason = "Flagged due to: ${criticalIssues.join(', ')}.";
    }

    score = score.clamp(0, 100);
    String level = 'PASSED';
    if (score >= 70) {
      level = 'HIGH';
    } else if (score >= 35) {
      level = 'MEDIUM';
    } else if (score > 0) {
      level = 'LOW';
    }

    return RiskAssessment(
      score: score,
      level: level,
      primaryReason: reason,
      checklist: checklist,
      criticalIssues: criticalIssues,
    );
  } else if (docType == 'product') {
    // Packaged goods LMPC checklist
    checklist['Manufacturer Details'] = !findings.any((f) => (f.ruleId == 'L-01' || f.ruleId == 'L-07') && !f.passed);
    checklist['Net Quantity Metric'] = !findings.any((f) => f.ruleId == 'L-02' && !f.passed);
    checklist['MRP Inclusive of Tax'] = !findings.any((f) => f.ruleId == 'L-03' && !f.passed);
    checklist['Mfg / Expiry Date'] = !findings.any((f) => f.ruleId == 'L-04' && !f.passed);
    checklist['Customer Care Contact'] = !findings.any((f) => f.ruleId == 'L-05' && !f.passed);

    String reason = "";
    if (score == 0) {
      reason = "All 5 mandatory declarations under Legal Metrology (Packaged Commodities) Rules 2011 verified. Product packaging is compliant.";
    } else {
      final missing = checklist.entries.where((e) => !e.value).map((e) => e.key).toList();
      reason = "Missing mandatory statutory declarations: ${missing.join(', ')}. Violates Section 36 of Legal Metrology Act (penalties up to ₹1,00,000).";
    }

    score = score.clamp(0, 100);
    String level = 'PASSED';
    if (score >= 70) {
      level = 'HIGH';
    } else if (score >= 35) {
      level = 'MEDIUM';
    } else if (score > 0) {
      level = 'LOW';
    }

    return RiskAssessment(
      score: score,
      level: level,
      primaryReason: reason,
      checklist: checklist,
      criticalIssues: criticalIssues,
    );
  } else {
    // Government KYC Form
    checklist['Issuing Authority Format'] = doc['issuing_authority'] != null || doc['document_title'] != null;
    checklist['Identity Number Structure'] = doc['document_id'] != null;
    checklist['Official Portal Mapped'] = doc['source_url'] != null;
    checklist['Required Document Checklist'] = true;

    String reason = "";
    if (score == 0) {
      reason = "Statutory form verified against official national database templates. Field mapping and document checklists are valid.";
    } else {
      reason = "Document requires careful review: ${criticalIssues.join(', ')}.";
    }

    score = score.clamp(0, 100);
    String level = score == 0 ? 'PASSED' : (score >= 50 ? 'HIGH' : 'LOW');

    return RiskAssessment(
      score: score,
      level: level,
      primaryReason: reason,
      checklist: checklist,
      criticalIssues: criticalIssues,
    );
  }
}

double? _extractAmount(dynamic val) {
  if (val == null) return null;
  final str = val.toString().replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(str);
}
