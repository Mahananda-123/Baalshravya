import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../providers/asha_provider.dart';
import 'package:infant_hearing_app/core/theme/app_colors.dart';
import 'package:infant_hearing_app/core/theme/app_spacing.dart';
import 'package:infant_hearing_app/core/theme/app_text_styles.dart';
import 'package:infant_hearing_app/core/constants/route_constants.dart';
import 'package:infant_hearing_app/data/models/v2/child.dart';

/// Lists every infant assigned to the ASHA worker with their screening status.
class AshaAllScreeningsScreen extends StatelessWidget {
  const AshaAllScreeningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AshaProvider>(
      builder: (context, provider, _) {
        final children = provider.children;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('All Screenings', style: AppTextStyles.h3),
            backgroundColor: AppColors.surface,
            elevation: 0,
          ),
          body: children.isEmpty
              ? const Center(child: Text('No infants registered yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  itemCount: children.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
                  itemBuilder: (context, index) {
                    final infant = children[index];
                    return _InfantListTile(infant: infant);
                  },
                ),
        );
      },
    );
  }
}

class _InfantListTile extends StatelessWidget {
  final Child infant;
  const _InfantListTile({required this.infant});

  Color get _statusColor {
    switch (infant.status) {
      case 'pass':
        return AppColors.success;
      case 'refer':
        return AppColors.error;
      case 'monitor':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _statusLabel {
    switch (infant.status) {
      case 'pass':
        return 'PASS';
      case 'refer':
        return 'REFER';
      case 'monitor':
        return 'MONITOR';
      default:
        return 'NEW';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusL),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        onTap: () => context.push(
          RouteConstants.ashaInfantDetail,
          extra: {'infant': infant},
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusL),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  infant.name.isEmpty ? '?' : infant.name[0],
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(infant.name, style: AppTextStyles.subheading1),
                    Text(
                      '${infant.ageMonths} mo • ${infant.gender} • ${infant.village ?? 'N/A'}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
