import 'package:flutter/material.dart';

import '../../services/backup_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _working = false;
  String? _lastMessage;
  bool? _lastSuccess;

  Future<void> _backup() async {
    setState(() {
      _working = true;
      _lastMessage = null;
    });
    final result = await BackupService.instance.backupNow();
    setState(() {
      _working = false;
      _lastMessage = result.message;
      _lastSuccess = result.success;
    });
  }

  Future<void> _restore() async {
    setState(() {
      _working = true;
      _lastMessage = null;
    });
    final result = await BackupService.instance.restoreNow();
    setState(() {
      _working = false;
      _lastMessage = result.message;
      _lastSuccess = result.success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Backup & Restore')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const Text(
            'WeBAlert automatically keeps your profile and latest weather saved on this device so you can view them offline.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.folder_shared_outlined, color: AppColors.primary, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can also save a portable copy to Documents/WeBAlert on your device storage - it survives even if the app is uninstalled, and can be shared or moved to a computer.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          PrimaryButton(label: 'Backup Now', icon: Icons.save_alt_rounded, onPressed: _backup, loading: _working),
          const SizedBox(height: 12),
          SecondaryButton(label: 'Restore from Backup', icon: Icons.restore_rounded, onPressed: _working ? null : _restore),
          if (_lastMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (_lastSuccess == true ? AppColors.alertGreen : AppColors.alertRed).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (_lastSuccess == true ? AppColors.alertGreen : AppColors.alertRed).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _lastSuccess == true ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                    color: _lastSuccess == true ? AppColors.alertGreen : AppColors.alertRed,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _lastMessage!,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
