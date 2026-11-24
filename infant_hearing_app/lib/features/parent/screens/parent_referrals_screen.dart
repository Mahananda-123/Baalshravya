import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/parent_provider.dart';
import '../../baby/providers/baby_provider.dart';
import 'package:infant_hearing_app/core/theme/app_colors.dart';
import 'package:infant_hearing_app/core/theme/app_spacing.dart';
import 'package:infant_hearing_app/core/theme/app_text_styles.dart';
import 'package:infant_hearing_app/data/models/v2/referral.dart';

/// Parent view of their baby's referrals. The parent can see the referral
/// details and respond (e.g. mark as attended / tested).
class ParentReferralsScreen extends StatelessWidget {
  const ParentReferralsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final baby = context.watch<BabyProvider>().baby;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Referrals', style: AppTextStyles.h3),
      ),
      body: baby == null
          ? _buildNoBaby(context)
          : StreamBuilder<List<Referral>>(
              stream: context
                  .read<ParentProvider>()
                  .firestoreService
                  .getReferralsForChild(baby.childId),
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
                final referrals = snapshot.data!;
                if (referrals.isEmpty) {
                  return _buildMessage(
                    context,
                    icon: Icons.medical_information_rounded,
                    title: 'No referrals',
                    subtitle: 'Your baby has no active referrals.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  itemCount: referrals.length,
                  itemBuilder: (context, index) {
                    final referral = referrals[index];
                    return _ParentReferralCard(referral: referral);
                  },
                );
              },
            ),
    );
  }

  Widget _buildNoBaby(BuildContext context) {
    return _buildMessage(
      context,
      icon: Icons.child_care_rounded,
      title: 'No baby registered',
      subtitle: 'Register your baby to view referrals.',
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

class _ParentReferralCard extends StatelessWidget {
  final Referral referral;
  const _ParentReferralCard({required this.referral});

  Color get _statusColor {
    switch (referral.status) {
      case 'pending':
        return AppColors.warning;
      case 'scheduled':
        return AppColors.primary;
      case 'visited':
        return AppColors.secondary;
      case 'tested':
        return AppColors.accent;
      case 'resolved':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _respond(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Text('Respond to referral', style: AppTextStyles.h3),
            ),
            ListTile(
              leading: const Icon(Icons.event_available_rounded,
                  color: AppColors.primary),
              title: const Text('I have scheduled a visit'),
              onTap: () => Navigator.of(ctx).pop('scheduled'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.secondary),
              title: const Text('I have attended the visit'),
              onTap: () => Navigator.of(ctx).pop('visited'),
            ),
            ListTile(
              leading: const Icon(Icons.science_rounded,
                  color: AppColors.accent),
              title: const Text('Testing has been done'),
              onTap: () => Navigator.of(ctx).pop('tested'),
            ),
            const SizedBox(height: AppSpacing.m),
          ],
        ),
      ),
    );

    if (selected == null) return;
    if (!context.mounted) return;

    try {
      await context
          .read<ParentProvider>()
          .firestoreService
          .updateReferralStatus(referral.referralId, selected);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Referral updated to $selected')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(referral.date);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXL),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  referral.status.toUpperCase(),
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(dateStr, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Text(referral.reason, style: AppTextStyles.subheading1),
          const SizedBox(height: AppSpacing.xs),
          Text(
            referral.hospital,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.m),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.m),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: referral.isResolved ? null : () => _respond(context),
              icon: const Icon(Icons.reply_rounded),
              label: const Text('Respond'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
