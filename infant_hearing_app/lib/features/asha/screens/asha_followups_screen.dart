import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/asha_provider.dart';
import 'package:infant_hearing_app/core/theme/app_colors.dart';
import 'package:infant_hearing_app/core/theme/app_spacing.dart';
import 'package:infant_hearing_app/core/theme/app_text_styles.dart';
import 'package:infant_hearing_app/shared/widgets/app_button.dart';
import 'package:infant_hearing_app/shared/widgets/app_text_field.dart';
import 'package:infant_hearing_app/data/models/v2/child.dart';
import 'package:infant_hearing_app/data/models/v2/followup.dart';

/// ASHA follow-up tracking screen: lists scheduled follow-ups and lets the
/// worker mark them complete or schedule new ones.
class AshaFollowupsScreen extends StatelessWidget {
  const AshaFollowupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Follow-ups', style: AppTextStyles.h3),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScheduleSheet(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Schedule', style: TextStyle(color: Colors.white)),
      ),
      body: Consumer<AshaProvider>(
        builder: (context, provider, _) {
          final followups = provider.followups;
          if (followups.isEmpty) {
            return _buildEmptyState(context);
          }
          final childrenById = {for (final c in provider.children) c.childId: c.name};
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.l),
            itemCount: followups.length,
            itemBuilder: (context, index) {
              final followup = followups[index];
              return _FollowupCard(
                followup: followup,
                childName: childrenById[followup.childId] ?? 'Infant',
                onComplete: () async {
                  await provider.completeFollowup(followup.followupId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Follow-up marked complete')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('No follow-ups scheduled', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Tap Schedule to create a follow-up visit for an infant.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showScheduleSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ScheduleFollowupSheet(),
    );
  }
}

class _ScheduleFollowupSheet extends StatefulWidget {
  const _ScheduleFollowupSheet();

  @override
  State<_ScheduleFollowupSheet> createState() => _ScheduleFollowupSheetState();
}

class _ScheduleFollowupSheetState extends State<_ScheduleFollowupSheet> {
  final _notesController = TextEditingController();
  Child? _selectedInfant;
  DateTime _visitDate = DateTime.now().add(const Duration(days: 7));
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _visitDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_selectedInfant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an infant')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final provider = context.read<AshaProvider>();
      await provider.scheduleFollowup(
        infant: _selectedInfant!,
        visitDate: _visitDate,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Follow-up scheduled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AshaProvider>();
    final infants = provider.children;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.l,
        right: AppSpacing.l,
        top: AppSpacing.l,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Text('Schedule Follow-up', style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.l),
          DropdownButtonFormField<Child>(
            initialValue: _selectedInfant,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Infant',
              border: OutlineInputBorder(),
            ),
            items: infants
                .map((c) => DropdownMenuItem<Child>(
                      value: c,
                      child: Text(
                        c.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedInfant = value),
          ),
          const SizedBox(height: AppSpacing.m),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(AppSpacing.radiusM),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Visit date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today_rounded),
              ),
              child: Text(DateFormat('dd MMM yyyy').format(_visitDate)),
            ),
          ),
          const SizedBox(height: AppSpacing.m),
          AppTextField(
            controller: _notesController,
            label: 'Notes',
            hint: 'Optional notes for this visit',
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: AppPrimaryButton(
              label: _submitting ? 'Scheduling…' : 'Schedule Follow-up',
              isLoading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowupCard extends StatelessWidget {
  final Followup followup;
  final String childName;
  final VoidCallback onComplete;

  const _FollowupCard({
    required this.followup,
    required this.childName,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(followup.visitDate);
    final initial = childName.isNotEmpty ? childName[0] : '?';
    final overdue = followup.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
        border: Border.all(
          color: overdue
              ? AppColors.error.withValues(alpha: 0.4)
              : AppColors.border.withValues(alpha: 0.5),
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(childName, style: AppTextStyles.subheading1),
                    Text(dateStr, style: AppTextStyles.caption),
                  ],
                ),
              ),
              if (followup.completed)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 22)
              else if (overdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'OVERDUE',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'UPCOMING',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (followup.notes != null && followup.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.m),
            Text(
              followup.notes!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (!followup.completed) ...[
            const SizedBox(height: AppSpacing.m),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.m),
            SizedBox(
              width: double.infinity,
              child: AppPrimaryButton(
                label: 'Mark Complete',
                onPressed: onComplete,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
