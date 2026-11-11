import 'package:flutter/material.dart';

/// Icon + màu minh họa cho từng kịch bản (thay cho emoji).
class ScenarioStyle {
  final IconData icon;
  final Color color;
  const ScenarioStyle(this.icon, this.color);

  static const Map<String, ScenarioStyle> _styles = {
    'coffee_shop': ScenarioStyle(Icons.local_cafe_rounded, Color(0xFF92400E)),
    'hotel_checkin': ScenarioStyle(Icons.hotel_rounded, Color(0xFF2563EB)),
    'directions': ScenarioStyle(Icons.directions_walk_rounded, Color(0xFF16A34A)),
    'shopping_clothes': ScenarioStyle(Icons.checkroom_rounded, Color(0xFFDB2777)),
    'job_interview': ScenarioStyle(Icons.work_rounded, Color(0xFF475569)),
    'pharmacy': ScenarioStyle(Icons.medication_rounded, Color(0xFF0D9488)),
    'product_return': ScenarioStyle(Icons.assignment_return_rounded, Color(0xFFEA580C)),
  };

  static ScenarioStyle of(String id) =>
      _styles[id] ?? const ScenarioStyle(Icons.chat_rounded, Color(0xFF0D9488));
}

