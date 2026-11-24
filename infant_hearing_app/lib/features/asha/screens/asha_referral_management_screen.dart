import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/asha_provider.dart';
import 'package:infant_hearing_app/core/theme/app_colors.dart';
import 'package:infant_hearing_app/core/theme/app_spacing.dart';
import 'package:infant_hearing_app/core/theme/app_text_styles.dart';
import 'package:infant_hearing_app/data/models/v2/referral.dart';

/// ASHA referral coordination screen: lists the worker's referrals and lets
/// them advance each referral through the workflow statuses.
class AshaReferralManagementScreen extends StatelessWidget {
  const AshaReferralManagementScreen({super.key});

  static const List<String> _statuses = [
    'pending',
    'scheduled',
    'visited',
    'tested',
    'resolved',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Referral Management', style: AppTextStyles.h3),
      ),
      body: Consumer<AshaProvider>(
        builder: (context, provider, _) {
          final referrals = provider.referrals;
          if (referrals.isEmpty) {
            return _buildEmptyState(context);
          }
          final childrenById = {for (final c in provider.children) c.childId: c.name};
          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.l),
            itemCount: referrals.length,
            itemBuilder: (context, index) {
              final referral = referrals[index];
              return _ReferralCard(
                referral: referral,
                childName: childrenById[referral.childId] ?? 'Infant',
                onStatusChanged: (status) async {
                  await provider.updateReferralStatus(
                    referral.referralId,
                    status,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Referral updated to $status')),
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
                Icons.medical_information_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('No referrals yet', style: AppTextStyles.h3),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Referrals created from REFER results or the emergency referral button will appear here.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferralCard extends StatelessWidget {
  final Referral referral;
  final String childName;
  final Future<void> Function(String status) onStatusChanged;

  const _ReferralCard({
    required this.referral,
    required this.childName,
    required this.onStatusChanged,
  });

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

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy').format(referral.date);
    final initial = childName.isNotEmpty ? childName[0] : '?';

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
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.primary,
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
                    Text('$dateStr · ${referral.hospital}',
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
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
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            referral.reason,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.m),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Update status', style: AppTextStyles.caption),
              PopupMenuButton<String>(
                initialValue: referral.status,
                onSelected: (status) {
                  if (status != referral.status) {
                    onStatusChanged(status);
                  }
                },
                itemBuilder: (context) => AshaReferralManagementScreen._statuses
                    .map((s) => PopupMenuItem<String>(
                          value: s,
                          child: Text(s[0].toUpperCase() + s.substring(1)),
                        ))
                    .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Change',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
