import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:confetti/confetti.dart';
import '../models/timeline_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';
import '../widgets/fade_slide_in.dart';
import 'suppliers_screen.dart';

class TimelineDetailScreen extends StatefulWidget {
  final String timelineKey;
  const TimelineDetailScreen({super.key, required this.timelineKey});

  @override
  State<TimelineDetailScreen> createState() => _TimelineDetailScreenState();
}

class _TimelineDetailScreenState extends State<TimelineDetailScreen> {
  late Box<TimelineModel> _box;
  late ConfettiController _confettiController;
  Map<String, dynamic>? _campaign;
  bool _isLoadingCampaign = true;

  @override
  void initState() {
    super.initState();
    _box = Hive.box<TimelineModel>("timelines");
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadCampaign();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadCampaign() async {
    final farmerId = await AuthService.getUserId();
    if (farmerId == null) {
      setState(() => _isLoadingCampaign = false);
      return;
    }
    final result = await ApiService.getMyCampaigns(farmerId);
    if (result["success"] == true) {
      final campaigns = (result["data"] as List);
      final match = campaigns.where((c) => c["timelineRef"] == widget.timelineKey).toList();
      setState(() {
        _campaign = match.isNotEmpty ? match.first : null;
        _isLoadingCampaign = false;
      });
    } else {
      setState(() => _isLoadingCampaign = false);
    }
  }

  Future<void> _openRequestFundingDialog(TimelineModel timeline) async {
    final goalController = TextEditingController();
    final returnController = TextEditingController(text: "10");
    final descriptionController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text("Request Crop Funding"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: goalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Funding goal (LKR)"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: returnController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Return offered to investors (%)"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Why do you need this funding?"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Submit")),
        ],
      ),
    );

    if (confirmed != true) return;
    final goal = double.tryParse(goalController.text);
    final returnPct = double.tryParse(returnController.text);
    if (goal == null || returnPct == null || descriptionController.text.trim().isEmpty) return;

    final farmerId = await AuthService.getUserId() ?? "";
    final result = await ApiService.createCampaign(
      farmerId: farmerId,
      timelineRef: timeline.localId,
      cropType: timeline.cropType,
      description: descriptionController.text.trim(),
      fundingGoalLkr: goal,
      returnPercentage: returnPct,
      deadline: timeline.expectedHarvestDate,
    );

    if (!mounted) return;

    if (result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Funding campaign created! Investors can now find and pledge to it.")),
      );
      _loadCampaign();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Failed to create campaign.")),
      );
    }
  }

  Future<void> _toggleMilestone(TimelineModel timeline, int index) async {
    final milestone = timeline.milestones[index];
    milestone.isCompleted = !milestone.isCompleted;
    milestone.completedAt = milestone.isCompleted ? DateTime.now() : null;

    timeline.lastLocalModifiedAt = DateTime.now();
    timeline.syncStatus = "pending";

    await timeline.save();
    setState(() {});
    HapticFeedback.lightImpact();

    // Celebrate when the farmer completes the very last remaining step —
    // a small "advanced animation" payoff for finishing the whole timeline.
    final allComplete = timeline.milestones.every((m) => m.isCompleted);
    if (allComplete && milestone.isCompleted) {
      HapticFeedback.mediumImpact();
      _confettiController.play();
    }
  }

  Widget _buildFundingCard(TimelineModel timeline) {
    if (_isLoadingCampaign) {
      return const SizedBox.shrink();
    }

    if (_campaign == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.indigoLight, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              const Icon(Icons.volunteer_activism_rounded, color: AppColors.indigo),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocale.instance.t("needFundsQuestion"),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
                ),
              ),
              TextButton(
                onPressed: () => _openRequestFundingDialog(timeline),
                style: TextButton.styleFrom(foregroundColor: AppColors.indigo),
                child: Text(AppLocale.instance.t("requestFunding"), style: const TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
        ),
      );
    }

    final goal = (_campaign!["fundingGoalLkr"] as num).toDouble();
    final raised = (_campaign!["amountRaisedLkr"] as num).toDouble();
    final progress = goal > 0 ? (raised / goal).clamp(0.0, 1.0) : 0.0;
    final status = _campaign!["status"] as String;

    final statusColor = {
      "open": AppColors.indigo,
      "funded": AppColors.forest,
      "repaid": AppColors.forest,
      "failed": AppColors.danger,
      "cancelled": AppColors.inkMuted,
    }[status] ?? AppColors.inkMuted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.indigoLight, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.volunteer_activism_rounded, color: AppColors.indigo, size: 18),
                const SizedBox(width: 8),
                const Text("Crop Funding Campaign", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(status.toUpperCase(), style: const TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: progress, backgroundColor: Colors.white, color: AppColors.indigo, minHeight: 7),
            ),
            const SizedBox(height: 6),
            Text(
              "LKR ${raised.toStringAsFixed(0)} raised of LKR ${goal.toStringAsFixed(0)} \u00b7 ${_campaign!["pledges"]?.length ?? 0} investor(s)",
              style: const TextStyle(fontSize: 11.5, color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeline = _box.get(widget.timelineKey);

    if (timeline == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Timeline")),
        body: const Center(child: Text("Timeline not found.")),
      );
    }

    final today = DateTime.now();
    final dayNumber = today.difference(timeline.plantingDate).inDays;
    final totalDays = timeline.expectedHarvestDate.difference(timeline.plantingDate).inDays;

    return Scaffold(
      appBar: AppBar(
        title: Text(timeline.cropType),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: "Nearby Suppliers & Rentals",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SuppliersScreen())),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            decoration: const BoxDecoration(
              color: AppColors.forest,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${AppLocale.instance.t("dayOf")} $dayNumber / $totalDays",
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: timeline.progressPercent / 100,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    color: AppColors.gold,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text("${timeline.progressPercent.round()}% ${AppLocale.instance.t("complete")}", style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
              ],
            ),
          ),
          _buildFundingCard(timeline),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: timeline.milestones.length,
              itemBuilder: (context, index) {
                final milestone = timeline.milestones[index];
                final isOverdue = !milestone.isCompleted && dayNumber > milestone.day;

                return FadeSlideIn(
                  delayMs: index * 40,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isOverdue ? AppColors.dangerLight : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isOverdue ? const Color(0xFFF3C9C9) : AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            value: milestone.isCompleted,
                            onChanged: (_) => _toggleMilestone(timeline, index),
                            activeColor: AppColors.forest,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            title: Text(
                              "${AppLocale.instance.t("dayOf")} ${milestone.day}: ${milestone.localizedTitle}",
                              style: TextStyle(
                                decoration: milestone.isCompleted ? TextDecoration.lineThrough : null,
                                color: milestone.isCompleted ? AppColors.inkMuted : AppColors.ink,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5,
                              ),
                            ),
                            subtitle: Text(
                              milestone.localizedDescription + (isOverdue ? "\n${AppLocale.instance.t("overdue")}" : ""),
                              style: TextStyle(color: isOverdue ? AppColors.danger : AppColors.inkMuted, fontSize: 12.5),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 10, right: 6),
                          child: IconButton(
                            icon: const Icon(Icons.volume_up_rounded, size: 19, color: AppColors.forest),
                            tooltip: "Read aloud",
                            onPressed: () => VoiceService.speak("${milestone.localizedTitle}. ${milestone.localizedDescription}"),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 3.14 / 2, // downward
              maxBlastForce: 12,
              minBlastForce: 6,
              emissionFrequency: 0.08,
              numberOfParticles: 24,
              gravity: 0.25,
              colors: const [AppColors.forest, AppColors.gold, AppColors.indigo, Colors.white],
            ),
          ),
        ],
      ),
    );
  }
}
