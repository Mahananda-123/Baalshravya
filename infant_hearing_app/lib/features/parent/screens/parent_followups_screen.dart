import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/parent_provider.dart';
import '../../baby/providers/baby_provider.dart';
import 'package:infant_hearing_app/core/theme/app_colors.dart';
import 'package:infant_hearing_app/core/theme/app_spacing.dart';
import 'package:infant_hearing_app/core/theme/app_text_styles.dart';
import 'package:infant_hearing_app/data/models/v2/followup.dart';

/// Parent view of their baby's follow-up visits. The parent can see upcoming
/// appointments and confirm attendance.
class ParentFollowupsScreen extends StatelessWidget {
  const ParentFollowupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final baby = context.watch<BabyProvider>().baby;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Follow-ups', style: AppTextStyles.h3),
      ),
      body: baby == null
          ? _buildMessage(
              context,
              icon: Icons.child_care_rounded,
              title: 'No baby registered',
              subtitle: 'Register your baby to view follow-ups.',
            )
          : StreamBuilder<List<Followup>>(
              stream: context
                  .read<ParentProvider>()
                  .firestoreService
                  .getFollowupsForChild(baby.childId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildMessage(
                    context,
                    icon: Icons.error_outline_rounded,
                    title: 'Something went wrong',
                    subtitle: '${snapshot.error}',
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final followups = snapshot.data!;
                if (followups.isEmpty) {
                  return _buildMessage(
                    context,
                    icon: Icons.event_available_rounded,
                    title: 'No follow-ups',
                    subtitle: 'No follow-up visits are scheduled for your baby.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  itemCount: followups.length,
                  itemBuilder: (context, index) {
                    return _ParentFollowupCard(followup: followups[index]);
                  },
                );
              },
            ),
    );
  }

  Widget _buildMessage(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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
              child: Icon(icon, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(title, style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.s),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentFollowupCard extends StatelessWidget {
  final Followup followup;
  const _ParentFollowupCard({required this.followup});

  Future<void> _confirmAttendance(BuildContext context) async {
    try {
      await context
          .read<ParentProvider>()
          .firestoreService
          .completeFollowup(followup.followupId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attendance confirmed. Thank you!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(followup.visitDate);
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
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.event_rounded,
                    color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr, style: AppTextStyles.subheading1),
                    Text(
                      followup.completed ? 'Attendance confirmed' : 'Scheduled visit',
                      style: AppTextStyles.caption,
                    ),
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
              child: FilledButton.icon(
                onPressed: () => _confirmAttendance(context),
                icon: const Icon(Icons.event_available_rounded),
                label: const Text('Confirm attendance'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
