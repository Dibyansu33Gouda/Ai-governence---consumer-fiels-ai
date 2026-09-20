import 'package:flutter/foundation.dart';
import 'rule_engine.dart';

/// Runs heavy parsing and rule engine evaluation in a background Isolate
/// to ensure the UI thread stays at 60fps and animations do not stutter.
class IsolateUtils {
  static Future<List<Finding>> runRulesInBackground(
    RuleEngine engine,
    Map<String, dynamic> book, 
    String docType, 
    Map<String, dynamic> doc
  ) async {
    // Using Flutter's compute function to spawn an isolate
    // We pass a Map containing all necessary parameters
    return await compute(_ruleEngineTask, {
      'engine': engine,
      'book': book,
      'docType': docType,
      'doc': doc,
    });
  }

  static List<Finding> _ruleEngineTask(Map<String, dynamic> params) {
    final RuleEngine engine = params['engine'];
    return engine.run(
      params['book'],
      params['docType'],
      params['doc']
    );
  }
}
