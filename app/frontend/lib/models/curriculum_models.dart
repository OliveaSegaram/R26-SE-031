import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../services/student_service.dart';

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
  final int totalActivities;
  final String imagePath;
  final String colorHex;
  final String emoji;
  final String audioUrl;

  SkillSummary({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.file,
    this.totalActivities = 0,
    this.imagePath = 'assets/images/skills/s0.png',
    this.colorHex = '#4A90D9',
    this.emoji = '⭐',
    this.audioUrl = '',
  });

  /// Parses the colorHex string (e.g. "#4A90D9") into a Flutter Color.
  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  factory SkillSummary.fromJson(Map<String, dynamic> json) {
    return SkillSummary(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['description'] ?? '',
      icon: json['icon'] ?? 'assets/images/skills/s0.png',
      file: json['file_path'] ?? json['file'] ?? '',
      totalActivities: json['total_activities'] ?? 0,
      imagePath: json['image_path'] ?? 'assets/images/skills/s0.png',
      colorHex: json['color_hex'] ?? '#4A90D9',
      emoji: json['emoji'] ?? '⭐',
      audioUrl: json['audio_url'] ?? json['audio_path'] ?? json['audio'] ?? '',
    );
  }
}

class SkillDetail {
  final String id;
  final String title;
  final String introText;
  final String audioUrl;
  final List<ActivityNode> activities;

  SkillDetail({
    required this.id,
    required this.title,
    this.introText = '',
    this.audioUrl = '',
    required this.activities,
  });

  factory SkillDetail.fromJson(dynamic decodedJson, String fallbackId, String fallbackTitle) {
    if (decodedJson is List) {
      if (decodedJson.isNotEmpty &&
          decodedJson.first is Map &&
          (decodedJson.first as Map).containsKey('activities')) {
        final skillMap = decodedJson.first as Map<String, dynamic>;
        final String id = skillMap['id']?.toString() ?? fallbackId;
        final String title = skillMap['title']?.toString() ?? fallbackTitle;
        final String introText = skillMap['intro_text']?.toString() ?? skillMap['description']?.toString() ?? '';
        final String audioUrl = skillMap['audio_url']?.toString() ?? skillMap['intro_audio_url']?.toString() ?? '';
        final List<dynamic> activitiesList = skillMap['activities'] as List<dynamic>? ?? [];
        return SkillDetail(
          id: id,
          title: title,
          introText: introText,
          audioUrl: audioUrl,
          activities: activitiesList
              .map((a) => ActivityNode.fromJson(a as Map<String, dynamic>))
              .toList(),
        );
      } else {
        return SkillDetail(
          id: fallbackId,
          title: fallbackTitle,
          introText: '',
          audioUrl: '',
          activities: decodedJson
              .map((a) => ActivityNode.fromJson(a as Map<String, dynamic>))
              .toList(),
        );
      }
    } else if (decodedJson is Map) {
      final skillMap = decodedJson as Map<String, dynamic>;
      final String id = skillMap['id']?.toString() ?? fallbackId;
      final String title = skillMap['title']?.toString() ?? fallbackTitle;
      final String introText = skillMap['intro_text']?.toString() ?? skillMap['description']?.toString() ?? '';
      final String audioUrl = skillMap['audio_url']?.toString() ?? skillMap['intro_audio_url']?.toString() ?? '';
      final List<dynamic> activitiesList = skillMap['activities'] as List<dynamic>? ?? [];
      return SkillDetail(
        id: id,
        title: title,
        introText: introText,
        audioUrl: audioUrl,
        activities: activitiesList
            .map((a) => ActivityNode.fromJson(a as Map<String, dynamic>))
            .toList(),
      );
    }

    return SkillDetail(id: fallbackId, title: fallbackTitle, introText: '', audioUrl: '', activities: []);
  }

  static Future<SkillDetail> load(String fileName) async {
    final skillId = fileName.replaceAll('.json', '');
    String responseData = '';
    
    try {
      // 1. Try fetching from CMS backend first
      final url = Uri.parse('http://10.0.2.2:8015/api/v1/auth/activities/$skillId');
      final res = await http.get(url).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        // If it's a valid skill with activities, use it
        if (decoded is Map && decoded.containsKey('activities') && (decoded['activities'] as List).isNotEmpty) {
          responseData = res.body;
        }
      }
    } catch (e) {
      // Ignore network errors and fallback to local
    }

    // 2. Fallback to local hardcoded JSON if backend failed or returned empty
    if (responseData.isEmpty) {
      responseData = await rootBundle.loadString('assets/data/curriculum/$fileName');
    }

    final skillDetail = SkillDetail.fromJson(json.decode(responseData), skillId, 'Skill Details');

    List<ActivityNode> resolvedActivities = [];
    for (var activity in skillDetail.activities) {
      if (activity.filePath.isNotEmpty) {
        try {
          final String actResponse = await rootBundle.loadString('assets/data/curriculum/${activity.filePath}');
          final Map<String, dynamic> actJson = json.decode(actResponse);
          resolvedActivities.add(ActivityNode.fromJson(actJson));
        } catch (e) {
          resolvedActivities.add(activity);
        }
      } else {
        resolvedActivities.add(activity);
      }
    }

    return SkillDetail(
      id: skillDetail.id,
      title: skillDetail.title,
      introText: skillDetail.introText,
      audioUrl: skillDetail.audioUrl,
      activities: resolvedActivities,
    );
  }
}

class ActivityNode {
  final String id;
  final String title;
  final String description;
  final String introText;
  final String audioUrl;
  final String filePath;
  final List<String> telemetryTags;
  final String templateType;
  final List<Map<String, dynamic>> rounds;

  ActivityNode({
    required this.id, 
    required this.title, 
    this.description = '',
    this.introText = '',
    this.audioUrl = '',
    this.filePath = '',
    required this.telemetryTags, 
    required this.templateType, 
    required this.rounds
  });

  factory ActivityNode.fromJson(Map<String, dynamic> json) {
    return ActivityNode(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      introText: json['intro_text']?.toString() ?? json['description']?.toString() ?? '',
      audioUrl: json['audio_url']?.toString() ?? json['intro_audio_url']?.toString() ?? '',
      filePath: json['file_path']?.toString() ?? '',
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
