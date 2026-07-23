import 'dart:convert';
import 'package:flutter/services.dart';

class CurriculumIndex {
  final List<SkillSummary> skills;

  CurriculumIndex({required this.skills});

  factory CurriculumIndex.fromJson(List<dynamic> jsonList) {
    return CurriculumIndex(
      skills: jsonList.map((s) => SkillSummary.fromJson(s as Map<String, dynamic>)).toList(),
    );
  }

  static Future<CurriculumIndex> load() async {
    final String response = await rootBundle.loadString('assets/data/curriculum/index.json');
    return CurriculumIndex.fromJson(json.decode(response) as List<dynamic>);
  }
}

class SkillSummary {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String file;

  SkillSummary({
    required this.id, 
    required this.title, 
    required this.subtitle, 
    required this.icon, 
    required this.file
  });

  factory SkillSummary.fromJson(Map<String, dynamic> json) {
    return SkillSummary(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['description'] ?? '',
      icon: json['icon'] ?? 'assets/images/skills/s0.png',
      file: json['file_path'] ?? json['file'] ?? '',
    );
  }
}

class SkillDetail {
  final String id;
  final String title;
  final List<ActivityNode> activities;

  SkillDetail({required this.id, required this.title, required this.activities});

  factory SkillDetail.fromJson(dynamic decodedJson, String fallbackId, String fallbackTitle) {
    if (decodedJson is List) {
      if (decodedJson.isNotEmpty &&
          decodedJson.first is Map &&
          (decodedJson.first as Map).containsKey('activities')) {
        // Root is a list wrapping the skill object: [{ id, title, activities: [...] }]
        final skillMap = decodedJson.first as Map<String, dynamic>;
        final String id = skillMap['id']?.toString() ?? fallbackId;
        final String title = skillMap['title']?.toString() ?? fallbackTitle;
        final List<dynamic> activitiesList = skillMap['activities'] as List<dynamic>? ?? [];
        return SkillDetail(
          id: id,
          title: title,
          activities: activitiesList
              .map((a) => ActivityNode.fromJson(a as Map<String, dynamic>))
              .toList(),
        );
      } else {
        // Root is a direct list of activity nodes
        return SkillDetail(
          id: fallbackId,
          title: fallbackTitle,
          activities: decodedJson
              .map((a) => ActivityNode.fromJson(a as Map<String, dynamic>))
              .toList(),
        );
      }
    } else if (decodedJson is Map) {
      // Root is a single skill object: { id, title, activities: [...] }
      final skillMap = decodedJson as Map<String, dynamic>;
      final String id = skillMap['id']?.toString() ?? fallbackId;
      final String title = skillMap['title']?.toString() ?? fallbackTitle;
      final List<dynamic> activitiesList = skillMap['activities'] as List<dynamic>? ?? [];
      return SkillDetail(
        id: id,
        title: title,
        activities: activitiesList
            .map((a) => ActivityNode.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
    }

    return SkillDetail(id: fallbackId, title: fallbackTitle, activities: []);
  }

  static Future<SkillDetail> load(String fileName) async {
    final String response = await rootBundle.loadString('assets/data/curriculum/$fileName');
    return SkillDetail.fromJson(json.decode(response), fileName.replaceAll('.json', ''), 'Skill Details');
  }
}

class ActivityNode {
  final String id;
  final String title;
  final List<String> telemetryTags;
  final String templateType;
  final List<Map<String, dynamic>> rounds;

  ActivityNode({
    required this.id, 
    required this.title, 
    required this.telemetryTags, 
    required this.templateType, 
    required this.rounds
  });

  factory ActivityNode.fromJson(Map<String, dynamic> json) {
    return ActivityNode(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      telemetryTags: json['telemetry_tags'] != null
          ? List<String>.from(json['telemetry_tags'] as Iterable)
          : <String>[],
      templateType: json['template_type']?.toString() ?? '',
      rounds: json['rounds'] != null
          ? List<Map<String, dynamic>>.from(
              (json['rounds'] as Iterable).map((r) => Map<String, dynamic>.from(r as Map)))
          : <Map<String, dynamic>>[],
    );
  }
}
