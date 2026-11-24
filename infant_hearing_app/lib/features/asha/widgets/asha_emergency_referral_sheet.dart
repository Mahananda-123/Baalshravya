import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/asha_provider.dart';
import 'package:infant_hearing_app/core/theme/app_colors.dart';
import 'package:infant_hearing_app/core/theme/app_spacing.dart';
import 'package:infant_hearing_app/core/theme/app_text_styles.dart';
import 'package:infant_hearing_app/shared/widgets/app_button.dart';
import 'package:infant_hearing_app/shared/widgets/app_text_field.dart';
import 'package:infant_hearing_app/data/models/v2/child.dart';

/// Bottom sheet for creating an emergency referral.
/// Returns `true` if a referral was created successfully.
Future<bool?> showEmergencyReferralSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _EmergencyReferralSheet(),
  );
}

class _EmergencyReferralSheet extends StatefulWidget {
  const _EmergencyReferralSheet();

  @override
  State<_EmergencyReferralSheet> createState() => _EmergencyReferralSheetState();
}

class _EmergencyReferralSheetState extends State<_EmergencyReferralSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController(text: 'Emergency referral');
  final _hospitalController = TextEditingController();
  Child? _selectedInfant;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInfant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an infant')),
      );
      return;
    }

    setState(() => _submitting = true);

    final provider = context.read<AshaProvider>();
    try {
      await provider.createEmergencyReferral(
        infant: _selectedInfant!,
        reason: _reasonController.text.trim(),
        hospital: _hospitalController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create referral: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AshaProvider>();
    final infants = provider.children;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(AppSpacing.l),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                Row(
                  children: [
                    const Icon(Icons.emergency_rounded, color: AppColors.error),
                    const SizedBox(width: AppSpacing.s),
                    Text('Emergency Referral', style: AppTextStyles.h3),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),

                // Infant selector
                DropdownButtonFormField<Child>(
                  initialValue: _selectedInfant,
                  decoration: const InputDecoration(
                    labelText: 'Select Infant',
                    border: OutlineInputBorder(),
                  ),
                  items: infants.map((c) {
                    return DropdownMenuItem<Child>(
                      value: c,
                      child: Text('${c.name} (${c.childCode ?? c.childId})'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedInfant = value),
                  validator: (value) => value == null ? 'Select an infant' : null,
                ),
                const SizedBox(height: AppSpacing.m),

                AppTextField(
                  controller: _reasonController,
                  label: 'Reason',
                  hint: 'Reason for referral',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a reason';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.m),

                AppTextField(
                  controller: _hospitalController,
                  label: 'Hospital',
                  hint: 'Referral hospital / centre',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a hospital';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                AppPrimaryButton(
                  label: _submitting ? 'Creating referral…' : 'Create Referral',
                  isLoading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
                const SizedBox(height: AppSpacing.l),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
