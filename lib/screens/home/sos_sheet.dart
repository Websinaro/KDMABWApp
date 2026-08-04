import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/safety_provider.dart';
import '../../providers/sos_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/page_transitions.dart';
import '../profile/safety_contacts_screen.dart';

Future<void> showSosFlow(BuildContext context) async {
  final safety = context.read<SafetyProvider>();
  final sos = context.read<SosProvider>();

  if (sos.status == SosStatus.active) {
    await _showActiveSheet(context);
    return;
  }

  // Always refresh right before deciding - cheap, and guarantees this
  // check can never be stale no matter which screen last touched contacts.
  await safety.refresh();

  if (!safety.hasContacts) {
    await _showNoContactsSheet(context);
    return;
  }

  await _showConfirmSheet(context);
}

Future<void> _showNoContactsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.textMuted, size: 44),
          const SizedBox(height: 16),
          const Text(
            'Add a Safety Contact First',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'SOS needs at least one trusted contact to alert with your location.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(fadeScaleRoute(const SafetyContactsScreen()));
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Add Safety Contact'),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showConfirmSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isDismissible: true,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Consumer<SosProvider>(
        builder: (context, sos, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.alertDarkRed, size: 44),
              const SizedBox(height: 16),
              const Text(
                'Send Emergency SOS?',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your safety contacts will be alerted immediately with your live location.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              if (sos.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(sos.errorMessage!, style: const TextStyle(color: AppColors.alertRed, fontSize: 12.5), textAlign: TextAlign.center),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: sos.status == SosStatus.sending
                      ? null
                      : () async {
                          final ok = await sos.sendSos();
                          if (ok && ctx.mounted) Navigator.of(ctx).pop();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.alertDarkRed,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: sos.status == SosStatus.sending
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('SEND SOS', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          );
        },
      ),
    ),
  );
}

Future<void> _showActiveSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceElevated,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Consumer<SosProvider>(
        builder: (context, sos, _) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sensors_rounded, color: AppColors.alertDarkRed, size: 44),
              const SizedBox(height: 16),
              const Text(
                'SOS Is Active',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your safety contacts can see your live location. Only mark yourself safe once the emergency has passed.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await sos.markSafe();
                    if (ok && ctx.mounted) Navigator.of(ctx).pop();
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.alertGreen),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("I'm Safe Now", style: TextStyle(color: AppColors.alertGreen, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          );
        },
      ),
    ),
  );
}
