import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/curriculum_models.dart';
import '../../services/therapist_dashboard_service.dart';
import '../../widgets/app_loading_indicator.dart';
import '../games/game_factory.dart';

class TherapistAdaptiveEvidenceView extends StatefulWidget {
  const TherapistAdaptiveEvidenceView({
    super.key,
    required this.student,
    this.initialData,
  });

  final Map<String, dynamic> student;
  final Map<String, dynamic>? initialData;

  @override
  State<TherapistAdaptiveEvidenceView> createState() =>
      _TherapistAdaptiveEvidenceViewState();
}

class _TherapistAdaptiveEvidenceViewState
    extends State<TherapistAdaptiveEvidenceView> {
  final _service = TherapistDashboardService();
  Map<String, dynamic>? _adaptive;
  bool _loading = false;
  String? _error;
  int _window = 20;

  String get _studentId =>
      widget.student['student_id']?.toString() ??
      widget.student['id']?.toString() ??
      widget.student['_id']?.toString() ??
      '';

  @override
  void initState() {
    super.initState();
    _adaptive = widget.initialData;
    if (_adaptive == null) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant TherapistAdaptiveEvidenceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_window == 20 &&
        widget.initialData != null &&
        !identical(widget.initialData, oldWidget.initialData)) {
      _adaptive = widget.initialData;
      _error = null;
    }
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    if (_studentId.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'This learner does not have a valid student identifier.';
        });
      }
      return;
    }
    try {
      final adaptive = await _service.getC4Adaptive(
        _studentId,
        window: _window,
      );
      if (!mounted) return;
      setState(() {
        _adaptive = adaptive;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _adaptive == null) return _buildLoadingPage();
    if (_error != null && _adaptive == null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    return _buildEvidencePage();
  }

  Widget _buildLoadingPage() => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
    children: [
      const SizedBox(height: 56),
      const AppLoadingIndicator(),
      const SizedBox(height: 18),
      Text(
        'Preparing adaptive support evidence…',
        textAlign: TextAlign.center,
        style: _label(14, color: _EvidenceColors.navy),
      ),
      const SizedBox(height: 6),
      Text(
        'Loading the learner’s latest observed tasks and support outcomes.',
        textAlign: TextAlign.center,
        style: _body(11),
      ),
    ],
  );

  Widget _buildEvidencePage() {
    final data = _adaptive ?? <String, dynamic>{};
    final summary = _map(data['summary']);
    final kcs = _list(data['knowledge_components']);
    final trend = _list(data['mastery_trend']);
    final effectiveness = _list(data['support_effectiveness']);
    final targets = _list(data['recurring_targets']);
    final plan = _map(data['next_session_plan']);
    final policy = _map(data['policy_status']);
    final latestPolicy = _map(data['latest_policy_decision']);
    final quality = _map(data['data_quality']);
    final history = _list(data['history']);
    final primaryName =
        summary['primary_focus_name']?.toString() ?? 'More evidence needed';
    final primaryMastery = _number(summary['primary_mastery']);
    final supportRate = _number(summary['support_dependence_rate']);
    final transferRate = _number(summary['independent_transfer_rate']);
    final coreTasks = _integer(summary['core_tasks']);
    final supportedTasks = _integer(summary['supported_core_tasks']);
    final confirmationTasks = _integer(summary['confirmation_tasks']);
    final independentConfirmations = _integer(
      summary['independent_confirmations'],
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Adaptive support evidence',
                style: _display(27, FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _showWindowSheet,
              style: OutlinedButton.styleFrom(
                foregroundColor: _EvidenceColors.blue,
                side: const BorderSide(color: _EvidenceColors.blueBorder),
                backgroundColor: Colors.white.withValues(alpha: .72),
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 19),
              label: Text(
                'Last $_window',
                style: _label(12, color: _EvidenceColors.blue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Align(
          alignment: Alignment.centerRight,
          child: _EvidenceScopeChip(
            policy: policy,
            onTap: () => _showPolicySheet(policy, latestPolicy, quality),
          ),
        ),
        const SizedBox(height: 14),
        _PrimaryFocusCard(
          title: primaryName,
          mastery: primaryMastery,
          supported: supportedTasks,
          coreTasks: coreTasks,
          independentConfirmations: independentConfirmations,
          confirmationTasks: confirmationTasks,
          onTap: () => _showPrimaryFocusSheet(summary, plan),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.school_rounded,
                label: 'Mastery',
                value: _percent(primaryMastery),
                caption: 'BKT estimate',
                color: _EvidenceColors.green,
                tint: _EvidenceColors.greenTint,
                onTap: () => _showMetricSheet(
                  title: 'Current mastery estimate',
                  icon: Icons.school_rounded,
                  color: _EvidenceColors.green,
                  value: _percent(primaryMastery),
                  explanation:
                      'The BKT estimate summarizes the learner’s observed responses for $primaryName. It is a learning estimate, not a diagnosis.',
                  evidence: '${trend.length} recent matching observations',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                icon: Icons.verified_rounded,
                label: 'Independent transfer',
                value: _percent(transferRate),
                caption:
                    '$independentConfirmations / $confirmationTasks confirmations',
                color: _EvidenceColors.blue,
                tint: _EvidenceColors.blueTint,
                onTap: () => _showMetricSheet(
                  title: 'Independent transfer',
                  icon: Icons.verified_rounded,
                  color: _EvidenceColors.blue,
                  value: _percent(transferRate),
                  explanation:
                      'How often the learner completed a fresh confirmation item correctly on the first try without an app scaffold.',
                  evidence:
                      '$independentConfirmations independent successes from $confirmationTasks completed confirmation tasks',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                icon: Icons.people_alt_rounded,
                label: 'Support dependence',
                value: _percent(supportRate),
                caption: '$supportedTasks / $coreTasks tasks',
                color: _EvidenceColors.amber,
                tint: _EvidenceColors.amberTint,
                onTap: () => _showMetricSheet(
                  title: 'Support dependence',
                  icon: Icons.people_alt_rounded,
                  color: _EvidenceColors.amber,
                  value: _percent(supportRate),
                  explanation:
                      'The share of recent core tasks completed after the app provided a scaffold or guided support.',
                  evidence:
                      '$supportedTasks supported outcomes from $coreTasks observed core tasks',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MasteryTrendCard(
          points: trend,
          status: _masteryStatus(primaryMastery),
          onTap: () => _showTrendSheet(primaryName, trend),
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Skill evidence'),
        const SizedBox(height: 10),
        _SkillEvidenceCard(
          skills: kcs,
          onTap: (skill) => _showSkillSheet(skill, history),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(child: _SectionTitle('Which support worked?')),
            Text('Next independent success', style: _body(11)),
          ],
        ),
        const SizedBox(height: 10),
        _SupportEvidenceCard(
          rows: effectiveness,
          onTap: (row) => _showSupportSheet(row),
        ),
        const SizedBox(height: 20),
        const _SectionTitle('Recurring targets'),
        const SizedBox(height: 10),
        _RecurringTargets(
          targets: targets,
          onTap: (target) => _showTargetSheet(target),
        ),
        const SizedBox(height: 16),
        _NextSessionCard(
          plan: plan,
          canStart: plan['practice_available'] == true,
          onStart: () => _showPracticePlan(plan),
          onTrace: () => _showDecisionTrace(history, latestPolicy, policy),
        ),
        const SizedBox(height: 12),
        _EvidenceFooter(
          decisions: _integer(quality['policy_rows']),
          linked: _integer(quality['policy_rows_with_outcomes']),
          model: policy['model_version']?.toString(),
          onTap: () => _showDataQualitySheet(data, quality),
        ),
        const SizedBox(height: 12),
        Text(
          'Model estimates guide learning support; they are not a diagnosis.\nSynthetic simulation demonstrates system behaviour, not child efficacy.',
          textAlign: TextAlign.center,
          style: _body(10, color: _EvidenceColors.muted, height: 1.35),
        ),
      ],
    );
  }

  Future<void> _showWindowSheet() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProfessionalSheet(
        title: 'Evidence window',
        subtitle: 'Choose how many recent adaptive decisions to summarize.',
        icon: Icons.tune_rounded,
        color: _EvidenceColors.blue,
        child: Column(
          children: [10, 20, 50].map((value) {
            final active = value == _window;
            return ListTile(
              onTap: () => Navigator.pop(context, value),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: active ? _EvidenceColors.blueTint : null,
              leading: Icon(
                active ? Icons.radio_button_checked : Icons.radio_button_off,
                color: _EvidenceColors.blue,
              ),
              title: Text('Last $value decisions', style: _label(15)),
              subtitle: Text(
                value == 10
                    ? 'A focused recent view'
                    : value == 20
                    ? 'Recommended balanced view'
                    : 'A broader evidence view',
                style: _body(11),
              ),
            );
          }).toList(),
        ),
      ),
    );
    if (selected != null && selected != _window && mounted) {
      setState(() => _window = selected);
      await _load();
    }
  }

  Future<void> _showPolicySheet(
    Map<String, dynamic> policy,
    Map<String, dynamic> latest,
    Map<String, dynamic> quality,
  ) => _showSheet(
    title: 'Evidence and policy status',
    subtitle: 'How to interpret the adaptive support shown on this page.',
    icon: Icons.info_outline_rounded,
    color: _EvidenceColors.blue,
    child: Column(
      children: [
        _DetailRow('Applied policy', policy['applied_policy']),
        _DetailRow('Policy mode', policy['mode']),
        _DetailRow('Model', policy['model_version']),
        _DetailRow('Validation', policy['model_validation_status']),
        _DetailRow(
          'Controls live adaptation',
          policy['controls_live_adaptation'] == true ? 'Yes' : 'No',
        ),
        _DetailRow('Latest item', latest['item_id']),
        _DetailRow(
          'Model recommendation',
          _friendlyAction(latest['model_recommendation']),
        ),
        _DetailRow('Applied action', _friendlyAction(latest['applied_action'])),
        _DetailRow('Linked outcomes', quality['policy_rows_with_outcomes']),
        const SizedBox(height: 10),
        _Callout(
          text:
              policy['evidence_scope']?.toString() ??
              'No action-policy evidence is currently available.',
          color: _EvidenceColors.blue,
        ),
      ],
    ),
  );

  Future<void> _showPrimaryFocusSheet(
    Map<String, dynamic> summary,
    Map<String, dynamic> plan,
  ) => _showSheet(
    title: summary['primary_focus_name']?.toString() ?? 'Primary focus',
    subtitle: 'Why this area is presented first for clinical review.',
    icon: Icons.track_changes_rounded,
    color: _EvidenceColors.coral,
    child: Column(
      children: [
        _DetailRow(
          'Current mastery',
          _percent(_number(summary['primary_mastery'])),
        ),
        _DetailRow('Observed core tasks', summary['core_tasks']),
        _DetailRow('Tasks needing support', summary['supported_core_tasks']),
        _DetailRow('Fresh confirmations', summary['confirmation_tasks']),
        _DetailRow(
          'Independent confirmations',
          summary['independent_confirmations'],
        ),
        const SizedBox(height: 10),
        _Callout(
          text:
              plan['evidence']?.toString() ??
              'More evidence is needed before selecting a focus.',
          color: _EvidenceColors.coral,
        ),
      ],
    ),
  );

  Future<void> _showMetricSheet({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required String explanation,
    required String evidence,
  }) => _showSheet(
    title: title,
    subtitle: value,
    icon: icon,
    color: color,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          explanation,
          style: _body(14, color: _EvidenceColors.navy, height: 1.55),
        ),
        const SizedBox(height: 14),
        _Callout(text: evidence, color: color),
      ],
    ),
  );

  Future<void> _showTrendSheet(
    String focus,
    List<Map<String, dynamic>> trend,
  ) => _showSheet(
    title: '$focus mastery trend',
    subtitle: 'Chronological BKT estimates for matching recent observations.',
    icon: Icons.show_chart_rounded,
    color: _EvidenceColors.blue,
    child: trend.isEmpty
        ? Text(
            'No matching mastery observations are available.',
            style: _body(13),
          )
        : Column(
            children: trend.asMap().entries.map((entry) {
              final row = entry.value;
              return _DetailRow(
                'Observation ${entry.key + 1} · ${row['item_id'] ?? 'task'}',
                _percent(_number(row['value'])),
              );
            }).toList(),
          ),
  );

  Future<void> _showSkillSheet(
    Map<String, dynamic> skill,
    List<Map<String, dynamic>> history,
  ) {
    final id = skill['id']?.toString();
    final matching = history
        .where((row) => row['knowledge_component_id'] == id)
        .toList();
    return _showSheet(
      title: skill['name']?.toString() ?? 'Skill evidence',
      subtitle: '${_percent(_number(skill['mastery']))} current BKT estimate',
      icon: _skillIcon(id),
      color: _statusColor(_number(skill['mastery'])),
      child: Column(
        children: [
          _DetailRow('Knowledge component', id),
          _DetailRow(
            'Current status',
            _masteryStatus(_number(skill['mastery'])),
          ),
          _DetailRow('Matching recent decisions', matching.length),
          if (matching.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...matching.reversed
                .take(5)
                .map(
                  (row) => _DetailRow(
                    row['item_id']?.toString() ?? 'Task',
                    '${_percent(_number(row['mastery_after']))} · ${_friendlyDecision(row['decision'])}',
                  ),
                ),
          ],
        ],
      ),
    );
  }

  Future<void> _showSupportSheet(Map<String, dynamic> row) => _showSheet(
    title: _friendlyAction(row['action']),
    subtitle: 'Observed follow-up evidence for this learner.',
    icon: _actionIcon(row['action']),
    color: _actionColor(row['action']),
    child: Column(
      children: [
        _DetailRow('Times selected', row['uses']),
        _DetailRow('Linked follow-up checks', row['outcomes']),
        _DetailRow('Independent successes', row['independent_successes']),
        _DetailRow(
          'Next independent success',
          _percent(_number(row['next_independent_success_rate'])),
        ),
        const SizedBox(height: 10),
        const _Callout(
          text:
              'This is descriptive follow-up evidence. It does not prove that the scaffold caused the later outcome.',
          color: _EvidenceColors.amber,
        ),
      ],
    ),
  );

  Future<void> _showTargetSheet(Map<String, dynamic> target) => _showSheet(
    title: 'Recurring target: ${target['unit'] ?? '—'}',
    subtitle: 'A target recorded during more than one recent struggle event.',
    icon: Icons.center_focus_strong_rounded,
    color: _EvidenceColors.coral,
    child: Column(
      children: [
        _DetailRow('Observed struggles', target['observations']),
        _DetailRow(
          'Activities',
          (target['activities'] as List? ?? []).join(', '),
        ),
        _DetailRow(
          'Last observed',
          _shortDate(target['last_observed_at']?.toString()),
        ),
        const SizedBox(height: 10),
        const _Callout(
          text:
              'Use this target to guide a short discrimination activity, then check it with a fresh equivalent item.',
          color: _EvidenceColors.coral,
        ),
      ],
    ),
  );

  Future<void> _showDecisionTrace(
    List<Map<String, dynamic>> history,
    Map<String, dynamic> latestPolicy,
    Map<String, dynamic> policy,
  ) => _showSheet(
    title: 'Adaptive decision trace',
    subtitle:
        'Newest evidence is shown last. Tap-and-support decisions remain descriptive.',
    icon: Icons.account_tree_outlined,
    color: _EvidenceColors.blue,
    expanded: true,
    child: Column(
      children: [
        if (latestPolicy.isNotEmpty) ...[
          _DecisionPolicyCard(policy: policy, latest: latestPolicy),
          const SizedBox(height: 14),
        ],
        if (history.isEmpty)
          Text('No adaptive decisions are available.', style: _body(13))
        else
          ...history.asMap().entries.map(
            (entry) => _TraceRow(index: entry.key + 1, row: entry.value),
          ),
      ],
    ),
  );

  Future<void> _showDataQualitySheet(
    Map<String, dynamic> data,
    Map<String, dynamic> quality,
  ) => _showSheet(
    title: 'Evidence quality and provenance',
    subtitle: 'What is available, what is missing, and how to interpret it.',
    icon: Icons.analytics_outlined,
    color: _EvidenceColors.slate,
    child: Column(
      children: [
        _DetailRow('Data origin', data['data_origin']),
        _DetailRow('Validation status', data['validation_status']),
        _DetailRow('Reporting period', data['reporting_period']),
        _DetailRow('Available decisions', quality['available_decision_rows']),
        _DetailRow('Displayed window', quality['window_size']),
        _DetailRow('Policy decisions', quality['policy_rows']),
        _DetailRow('Linked outcomes', quality['policy_rows_with_outcomes']),
        _DetailRow(
          'Immediate responses',
          quality['policy_rows_with_proximal_outcomes'],
        ),
        _DetailRow('C3 pipeline', quality['c3_pipeline_status']),
        const SizedBox(height: 10),
        _Callout(
          text:
              quality['calibration_warning']?.toString() ??
              'Missing measurements remain unavailable rather than becoming zero.',
          color: _EvidenceColors.slate,
        ),
      ],
    ),
  );

  Future<void> _showPracticePlan(Map<String, dynamic> plan) async {
    await _showSheet(
      title: 'Next session plan',
      subtitle: plan['focus_name']?.toString() ?? 'Reviewed practice',
      icon: Icons.assignment_turned_in_rounded,
      color: _EvidenceColors.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan['instruction']?.toString() ?? 'No plan is available yet.',
            style: _body(14, color: _EvidenceColors.navy, height: 1.55),
          ),
          const SizedBox(height: 12),
          _Callout(
            text: plan['evidence']?.toString() ?? '',
            color: _EvidenceColors.blue,
          ),
          const SizedBox(height: 12),
          const _PracticeStep(
            number: '1',
            title: 'Reviewed equivalent tasks',
            detail:
                'Use generic confirmation items at the same intended difficulty.',
          ),
          const SizedBox(height: 9),
          const _PracticeStep(
            number: '2',
            title: 'Protected practice mode',
            detail:
                'This practice does not change normal curriculum position or mastery.',
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: plan['practice_available'] == true
                  ? () {
                      Navigator.pop(context);
                      _startReviewedPractice(plan);
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: _EvidenceColors.blue,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                'Start targeted practice',
                style: _label(15, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startReviewedPractice(Map<String, dynamic> plan) async {
    final parts = (plan['activity_id']?.toString() ?? '').split('.');
    if (parts.length != 2) return;
    final skill = int.tryParse(parts[0]);
    final activityNumber = int.tryParse(parts[1]);
    if (skill == null || activityNumber == null) return;
    try {
      final raw = await rootBundle.loadString(
        'assets/data/curriculum/skill_$skill.json',
      );
      final detail = SkillDetail.fromJson(
        json.decode(raw),
        'skill_$skill',
        'Skill $skill',
      );
      ActivityNode? activity;
      for (final candidate in detail.activities) {
        if (candidate.id == 'act_$activityNumber') {
          activity = candidate;
          break;
        }
      }
      if (activity == null || !mounted) return;
      activity.skillId = 'skill_$skill';
      activity.skillTitle = detail.title;
      final safePractice = activity.asParentPractice();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              GameFactory.buildGame(safePractice, studentData: widget.student),
        ),
      );
      if (mounted) await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open reviewed practice: $error')),
      );
    }
  }

  Future<void> _showSheet({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget child,
    bool expanded = false,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => expanded
        ? DraggableScrollableSheet(
            initialChildSize: .82,
            minChildSize: .5,
            maxChildSize: .94,
            expand: false,
            builder: (_, controller) => _ProfessionalSheet(
              title: title,
              subtitle: subtitle,
              icon: icon,
              color: color,
              scrollController: controller,
              child: child,
            ),
          )
        : _ProfessionalSheet(
            title: title,
            subtitle: subtitle,
            icon: icon,
            color: color,
            child: child,
          ),
  );
}

class _EvidenceColors {
  static const surface = Color(0xFFFFFEF8);
  static const navy = Color(0xFF102859);
  static const muted = Color(0xFF68738B);
  static const line = Color(0xFFE7E0D1);
  static const blue = Color(0xFF1478F2);
  static const blueBorder = Color(0xFF8BC5FF);
  static const blueTint = Color(0xFFE8F4FF);
  static const green = Color(0xFF16964A);
  static const greenTint = Color(0xFFE8F8E9);
  static const amber = Color(0xFFD57A08);
  static const amberTint = Color(0xFFFFF2D8);
  static const coral = Color(0xFFF0444C);
  static const coralTint = Color(0xFFFFECEB);
  static const slate = Color(0xFF6D778B);
}

TextStyle _display(
  double size,
  FontWeight weight, {
  Color? color,
  double height = 1.2,
}) => GoogleFonts.nunitoSans(
  fontSize: size,
  fontWeight: weight,
  color: color ?? _EvidenceColors.navy,
  height: height,
  letterSpacing: -.25,
);

TextStyle _label(
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w700,
}) => GoogleFonts.nunitoSans(
  fontSize: size,
  fontWeight: weight,
  color: color ?? _EvidenceColors.navy,
  height: 1.25,
);

TextStyle _body(
  double size, {
  Color? color,
  double height = 1.4,
  FontWeight weight = FontWeight.w500,
}) => GoogleFonts.nunitoSans(
  fontSize: size,
  fontWeight: weight,
  color: color ?? _EvidenceColors.muted,
  height: height,
  letterSpacing: .05,
);

class _EvidenceScopeChip extends StatelessWidget {
  const _EvidenceScopeChip({required this.policy, required this.onTap});
  final Map<String, dynamic> policy;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final simulation = policy['applied_policy'] == 'synthetic_model_simulation';
    final label = simulation
        ? 'Research simulation'
        : policy.isEmpty
        ? 'Evidence unavailable'
        : 'Descriptive evidence';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .76),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _EvidenceColors.blueBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: _label(10, color: _EvidenceColors.blue)),
            const SizedBox(width: 5),
            const Icon(
              Icons.info_outline_rounded,
              size: 17,
              color: _EvidenceColors.blue,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryFocusCard extends StatelessWidget {
  const _PrimaryFocusCard({
    required this.title,
    required this.mastery,
    required this.supported,
    required this.coreTasks,
    required this.independentConfirmations,
    required this.confirmationTasks,
    required this.onTap,
  });
  final String title;
  final double? mastery;
  final int supported, coreTasks;
  final int independentConfirmations, confirmationTasks;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: _EvidenceColors.surface,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _EvidenceColors.coral.withValues(alpha: .45),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: _EvidenceColors.coralTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.track_changes_rounded,
                color: _EvidenceColors.coral,
                size: 35,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Primary focus: $title',
                    style: _display(
                      19,
                      FontWeight.w800,
                      color: _EvidenceColors.coral,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mastery ${_percent(mastery)} · support needed in $supported of $coreTasks recent tasks · independent confirmation $independentConfirmations of $confirmationTasks.',
                    style: _body(14, color: _EvidenceColors.navy, height: 1.45),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _EvidenceColors.coral,
            ),
          ],
        ),
      ),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
    required this.tint,
    required this.onTap,
  });
  final IconData icon;
  final String label, value, caption;
  final Color color, tint;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: _EvidenceColors.surface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 155,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 23),
            ),
            const SizedBox(height: 8),
            Text(label, maxLines: 2, style: _label(12)),
            const Spacer(),
            Text(value, style: _display(24, FontWeight.w800, color: color)),
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _body(10),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MasteryTrendCard extends StatelessWidget {
  const _MasteryTrendCard({
    required this.points,
    required this.status,
    required this.onTap,
  });
  final List<Map<String, dynamic>> points;
  final String status;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: _EvidenceColors.surface,
    borderRadius: BorderRadius.circular(24),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _EvidenceColors.amber.withValues(alpha: .35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Mastery trend', style: _display(20, FontWeight.w800)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _EvidenceColors.amberTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: _label(11, color: _EvidenceColors.amber),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (points.isEmpty)
              SizedBox(
                height: 140,
                child: Center(
                  child: Text(
                    'Complete more matching tasks to create this trend.',
                    style: _body(12),
                  ),
                ),
              )
            else
              SizedBox(
                height: 185,
                width: double.infinity,
                child: CustomPaint(
                  painter: _MasteryTrendPainter(
                    values: points
                        .map((row) => _number(row['value']) ?? 0)
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _MasteryTrendPainter extends CustomPainter {
  const _MasteryTrendPainter({required this.values});
  final List<double> values;
  @override
  void paint(Canvas canvas, Size size) {
    final left = 38.0,
        right = size.width - 12,
        top = 14.0,
        bottom = size.height - 28;
    final grid = Paint()
      ..color = const Color(0xFFDDE3EA)
      ..strokeWidth = 1;
    final labelStyle = _body(9, color: _EvidenceColors.muted);
    for (var index = 0; index <= 4; index++) {
      final y = top + (bottom - top) * index / 4;
      canvas.drawLine(Offset(left, y), Offset(right, y), grid);
      _paintText(canvas, '${100 - index * 25}', Offset(2, y - 7), labelStyle);
    }
    final xStep = values.length <= 1
        ? 0.0
        : (right - left) / (values.length - 1);
    final line = Path();
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1 ? (left + right) / 2 : left + xStep * index;
      final y = bottom - values[index].clamp(0, 1) * (bottom - top);
      if (index == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
    }
    if (values.length > 1) {
      final fill = Path.from(line)
        ..lineTo(right, bottom)
        ..lineTo(left, bottom)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x553A9BFF), Color(0x053A9BFF)],
          ).createShader(Rect.fromLTRB(left, top, right, bottom)),
      );
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = _EvidenceColors.blue
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1 ? (left + right) / 2 : left + xStep * index;
      final y = bottom - values[index].clamp(0, 1) * (bottom - top);
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = _EvidenceColors.blue);
      _paintText(
        canvas,
        '${(values[index] * 100).round()}',
        Offset(x - 8, y - 22),
        _label(10, color: _EvidenceColors.navy),
      );
      _paintText(
        canvas,
        'S${index + 1}',
        Offset(x - 7, bottom + 8),
        labelStyle,
      );
    }
  }

  static void _paintText(
    Canvas canvas,
    String value,
    Offset offset,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _MasteryTrendPainter old) =>
      old.values != values;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: _display(21, FontWeight.w800));
}

class _SkillEvidenceCard extends StatelessWidget {
  const _SkillEvidenceCard({required this.skills, required this.onTap});
  final List<Map<String, dynamic>> skills;
  final ValueChanged<Map<String, dynamic>> onTap;
  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return const _EmptyEvidenceCard(
        icon: Icons.school_outlined,
        text: 'No skill mastery estimates are available yet.',
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _panelDecoration(),
      child: Column(
        children: skills.map((skill) {
          final value = _number(skill['mastery']);
          final color = _statusColor(value);
          return InkWell(
            onTap: () => onTap(skill),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _skillIcon(skill['id']?.toString()),
                      color: color,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      skill['name']?.toString() ?? 'Skill',
                      style: _label(14),
                    ),
                  ),
                  Text(
                    _percent(value),
                    style: _display(19, FontWeight.w800, color: color),
                  ),
                  const SizedBox(width: 9),
                  Container(
                    width: 94,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _masteryStatus(value),
                      maxLines: 1,
                      style: _label(10, color: color),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _EvidenceColors.muted,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SupportEvidenceCard extends StatelessWidget {
  const _SupportEvidenceCard({required this.rows, required this.onTap});
  final List<Map<String, dynamic>> rows;
  final ValueChanged<Map<String, dynamic>> onTap;
  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyEvidenceCard(
        icon: Icons.support_outlined,
        text: 'No linked scaffold outcomes are available yet.',
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _panelDecoration(),
      child: Column(
        children: rows.map((row) {
          final color = _actionColor(row['action']);
          final rate = _number(row['next_independent_success_rate']);
          return InkWell(
            onTap: () => onTap(row),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _actionIcon(row['action']),
                      color: color,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_friendlyAction(row['action']), style: _label(14)),
                        Text(
                          '${row['uses'] ?? 0} uses · ${row['outcomes'] ?? 0} linked checks',
                          style: _body(10),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: rate?.clamp(0, 1),
                        minHeight: 9,
                        backgroundColor: const Color(0xFFE8EBF0),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  SizedBox(
                    width: 40,
                    child: Text(
                      _percent(rate),
                      textAlign: TextAlign.right,
                      style: _label(13, color: color),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RecurringTargets extends StatelessWidget {
  const _RecurringTargets({required this.targets, required this.onTap});
  final List<Map<String, dynamic>> targets;
  final ValueChanged<Map<String, dynamic>> onTap;
  @override
  Widget build(BuildContext context) {
    if (targets.isEmpty) {
      return const _EmptyEvidenceCard(
        icon: Icons.center_focus_weak_rounded,
        text:
            'No recurring struggled target is present in this evidence window.',
      );
    }
    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: targets
          .map(
            (target) => InkWell(
              onTap: () => onTap(target),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: _EvidenceColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _EvidenceColors.coral.withValues(alpha: .35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      target['unit']?.toString() ?? '—',
                      style: _display(
                        16,
                        FontWeight.w800,
                        color: _EvidenceColors.coral,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '· ${target['observations'] ?? 0} observations',
                      style: _body(11, color: _EvidenceColors.navy),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: _EvidenceColors.muted,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({
    required this.plan,
    required this.canStart,
    required this.onStart,
    required this.onTrace,
  });
  final Map<String, dynamic> plan;
  final bool canStart;
  final VoidCallback onStart, onTrace;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: _EvidenceColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _EvidenceColors.blueBorder, width: 1.3),
    ),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: _EvidenceColors.blueTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_turned_in_rounded,
                color: _EvidenceColors.blue,
                size: 28,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Next session plan',
                    style: _display(
                      21,
                      FontWeight.w800,
                      color: _EvidenceColors.blue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    plan['instruction']?.toString() ??
                        'Continue normal activities while more evidence is collected.',
                    style: _body(13, color: _EvidenceColors.navy, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: canStart ? onStart : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _EvidenceColors.blue,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(
                  'Start targeted practice',
                  style: _label(13, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onTrace,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _EvidenceColors.blue,
                  side: const BorderSide(color: _EvidenceColors.blue),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: const Icon(Icons.description_outlined),
                label: Text(
                  'Decision trace',
                  style: _label(13, color: _EvidenceColors.blue),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _EvidenceFooter extends StatelessWidget {
  const _EvidenceFooter({
    required this.decisions,
    required this.linked,
    required this.model,
    required this.onTap,
  });
  final int decisions, linked;
  final String? model;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: _EvidenceColors.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _EvidenceColors.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.bar_chart_rounded, color: _EvidenceColors.slate),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                '$decisions policy decisions · $linked linked outcomes · ${model ?? 'model unavailable'}',
                maxLines: 2,
                style: _body(11, color: _EvidenceColors.navy),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _EvidenceColors.navy,
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyEvidenceCard extends StatelessWidget {
  const _EmptyEvidenceCard({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: _panelDecoration(),
    child: Row(
      children: [
        Icon(icon, color: _EvidenceColors.muted),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: _body(12))),
      ],
    ),
  );
}

class _ProfessionalSheet extends StatelessWidget {
  const _ProfessionalSheet({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
    this.scrollController,
  });
  final String title, subtitle;
  final IconData icon;
  final Color color;
  final Widget child;
  final ScrollController? scrollController;
  @override
  Widget build(BuildContext context) {
    final content = <Widget>[
      Center(
        child: Container(
          width: 44,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFFD9DDE5),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
      const SizedBox(height: 18),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _display(22, FontWeight.w800)),
                const SizedBox(height: 3),
                Text(subtitle, style: _body(12)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: _EvidenceColors.muted),
          ),
        ],
      ),
      const SizedBox(height: 18),
      child,
      SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
    ];
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * .88,
      ),
      decoration: const BoxDecoration(
        color: _EvidenceColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: scrollController == null
          ? SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(mainAxisSize: MainAxisSize.min, children: content),
            )
          : ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              children: content,
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final dynamic value;
  @override
  Widget build(BuildContext context) {
    final shown = value?.toString().trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: _body(12))),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              shown == null || shown.isEmpty ? 'Unavailable' : shown,
              textAlign: TextAlign.right,
              style: _label(12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: .18)),
    ),
    child: Text(
      text,
      style: _body(12, color: _EvidenceColors.navy, height: 1.45),
    ),
  );
}

class _PracticeStep extends StatelessWidget {
  const _PracticeStep({
    required this.number,
    required this.title,
    required this.detail,
  });
  final String number, title, detail;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: _EvidenceColors.blueTint,
          shape: BoxShape.circle,
        ),
        child: Text(number, style: _label(14, color: _EvidenceColors.blue)),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _label(13)),
            Text(detail, style: _body(11)),
          ],
        ),
      ),
    ],
  );
}

class _DecisionPolicyCard extends StatelessWidget {
  const _DecisionPolicyCard({required this.policy, required this.latest});
  final Map<String, dynamic> policy, latest;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _EvidenceColors.blueTint,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _EvidenceColors.blueBorder),
    ),
    child: Column(
      children: [
        _DetailRow(
          'Execution source',
          latest['execution_source'] ?? policy['applied_policy'],
        ),
        _DetailRow(
          'Model suggested',
          _friendlyAction(latest['model_recommendation']),
        ),
        _DetailRow('App applied', _friendlyAction(latest['applied_action'])),
        _DetailRow('Ranking margin', latest['model_confidence']),
      ],
    ),
  );
}

class _TraceRow extends StatelessWidget {
  const _TraceRow({required this.index, required this.row});
  final int index;
  final Map<String, dynamic> row;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(13),
    decoration: _panelDecoration(),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _EvidenceColors.blue,
            shape: BoxShape.circle,
          ),
          child: Text('$index', style: _label(12, color: Colors.white)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${row['item_id'] ?? 'Task'} · ${_friendlyDecision(row['decision'])}',
                style: _label(13),
              ),
              const SizedBox(height: 3),
              Text(
                'Mastery ${_percent(_number(row['mastery_after']))} · difficulty ${_compact(row['selected_difficulty'])} · scaffold ${row['scaffold_level'] ?? 0}',
                style: _body(10),
              ),
              if ((row['reason']?.toString() ?? '').isNotEmpty)
                Text(
                  row['reason'].toString(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: _body(10, color: _EvidenceColors.muted),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 72, 16, 28),
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: _panelDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 46,
              color: _EvidenceColors.coral,
            ),
            const SizedBox(height: 12),
            Text(
              'Adaptive evidence is unavailable',
              textAlign: TextAlign.center,
              style: _display(20, FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(message, textAlign: TextAlign.center, style: _body(12)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    ],
  );
}

BoxDecoration _panelDecoration() => BoxDecoration(
  color: _EvidenceColors.surface,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: _EvidenceColors.line),
  boxShadow: [
    BoxShadow(
      color: _EvidenceColors.navy.withValues(alpha: .035),
      blurRadius: 14,
      offset: const Offset(0, 5),
    ),
  ],
);

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value.whereType<Map>().map(Map<String, dynamic>.from).toList();
}

double? _number(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
int _integer(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
String _percent(double? value) =>
    value == null ? '—' : '${(value * 100).round()}%';
String _compact(dynamic value) {
  final number = _number(value);
  return number == null ? '—' : number.toStringAsFixed(2);
}

String _masteryStatus(double? value) => value == null
    ? 'Unavailable'
    : value >= .7
    ? 'Stable'
    : value >= .5
    ? 'Developing'
    : 'Needs support';
Color _statusColor(double? value) => value == null
    ? _EvidenceColors.slate
    : value >= .7
    ? _EvidenceColors.green
    : value >= .5
    ? _EvidenceColors.blue
    : _EvidenceColors.amber;

IconData _skillIcon(String? id) {
  final value = id ?? '';
  if (value.contains('PHONEME') || value.contains('AUDITORY')) {
    return Icons.volume_up_rounded;
  }
  if (value.contains('WORD') || value.contains('SPELL')) {
    return Icons.abc_rounded;
  }
  if (value.contains('SENTENCE') || value.contains('READING')) {
    return Icons.menu_book_rounded;
  }
  if (value.contains('VISUAL')) return Icons.image_search_rounded;
  return Icons.text_fields_rounded;
}

String _friendlyAction(dynamic raw) {
  const labels = {
    'RETRY_CURRENT': 'Retry current task',
    'SCAFFOLD_REMOVE_DISTRACTOR': 'Remove distractor',
    'SCAFFOLD_DISABLE_DISTRACTOR': 'Lock distractor',
    'SCAFFOLD_HIGHLIGHT_CORRECT': 'Highlight answer',
    'SCAFFOLD_HIGHLIGHT_DESTINATION': 'Highlight destination',
    'SCAFFOLD_REVEAL_FIRST_TOKEN': 'Reveal next token',
    'SCAFFOLD_REPLAY_INSTRUCTION': 'Replay instruction',
    'SCAFFOLD_SLOW_AUDIO': 'Slow audio',
  };
  final key = raw?.toString();
  return labels[key] ??
      key?.replaceAll('_', ' ').toLowerCase() ??
      'Unavailable';
}

IconData _actionIcon(dynamic action) {
  final key = action?.toString() ?? '';
  if (key.contains('REPLAY') || key.contains('AUDIO')) {
    return Icons.play_circle_fill_rounded;
  }
  if (key.contains('HIGHLIGHT')) return Icons.lightbulb_rounded;
  if (key.contains('REMOVE') || key.contains('DISABLE')) {
    return Icons.settings_rounded;
  }
  if (key.contains('TOKEN')) return Icons.format_list_numbered_rounded;
  return Icons.replay_circle_filled_rounded;
}

Color _actionColor(dynamic action) {
  final key = action?.toString() ?? '';
  if (key.contains('REPLAY') || key.contains('AUDIO')) {
    return _EvidenceColors.blue;
  }
  if (key.contains('HIGHLIGHT')) return _EvidenceColors.amber;
  if (key.contains('REMOVE') || key.contains('DISABLE')) {
    return _EvidenceColors.green;
  }
  return _EvidenceColors.slate;
}

String _friendlyDecision(dynamic raw) {
  final value = raw?.toString() ?? 'Unavailable';
  return value.replaceAll('_', ' ').toLowerCase();
}

String _shortDate(String? raw) {
  final date = raw == null ? null : DateTime.tryParse(raw)?.toLocal();
  if (date == null) return 'Unavailable';
  return '${date.day}/${date.month}/${date.year}';
}
