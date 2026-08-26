import 'package:flutter/material.dart';

class RailLine {
  final String id;
  final String code;
  final String name;
  final String shortName;
  final String colour;
  final String operator;
  final String dataKey;
  final String seriesId;
  final int sortOrder;

  const RailLine({
    required this.id,
    required this.code,
    required this.name,
    required this.shortName,
    required this.colour,
    required this.operator,
    required this.dataKey,
    required this.seriesId,
    required this.sortOrder,
  });

  bool get sharesSeries => seriesId != id;

  Color get displayColour {
    final hex = colour.replaceFirst('#', '');
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return const Color(0xFF6B7280);
    return Color(0xFF000000 | value);
  }

  factory RailLine.fromJson(Map<String, dynamic> json) {
    return RailLine(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      shortName: json['short_name'] as String,
      colour: json['colour'] as String,
      operator: json['operator'] as String,
      dataKey: json['data_key'] as String,
      seriesId: json['series_id'] as String,
      sortOrder: (json['sort_order'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'short_name': shortName,
        'colour': colour,
        'operator': operator,
        'data_key': dataKey,
        'series_id': seriesId,
        'sort_order': sortOrder,
      };
}
