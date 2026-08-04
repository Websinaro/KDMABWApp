import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/safety_contact.dart';
import '../../providers/safety_provider.dart';
import '../../theme/app_colors.dart';
import 'safety_contact_form_screen.dart';

class SafetyContactsScreen extends StatefulWidget {
  const SafetyContactsScreen({super.key});

  @override
  State<SafetyContactsScreen> createState() => _SafetyContactsScreenState();
}

class _SafetyContactsScreenState extends State<SafetyContactsScreen> {
  @override
  void initState() {
    super.initState();
    // Always re-fetch on open - this screen is the source people expect to
    // trust, so it can't rely on whatever SafetyProvider last happened to
    // have cached at splash time.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SafetyProvider>().refresh();
    });
  }

  Future<void> _openForm({SafetyContact? existing}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SafetyContactFormScreen(existing: existing)),
    );
    if (saved == true && mounted) {
      await context.read<SafetyProvider>().refresh();
    }
  }

  Future<void> _confirmDelete(SafetyContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remove this contact?'),
        content: Text('${contact.name} will no longer be notified if you send an SOS.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove', style: TextStyle(color: AppColors.alertRed)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<SafetyProvider>().delete(contact.id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Safety Circle')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Consumer<SafetyProvider>(
        builder: (context, safety, _) {
          if (safety.loading && !safety.loaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (safety.errorMessage != null && safety.contacts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  safety.errorMessage!,
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final contacts = safety.contacts;

          if (contacts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_outlined, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    const Text(
                      'No safety contacts yet',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add up to 5 trusted people. They\'ll be notified with your live location if you press SOS.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => safety.refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: contacts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(contact.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                            if (contact.relationship != null && contact.relationship!.isNotEmpty)
                              Text(contact.relationship!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            Text(contact.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') _openForm(existing: contact);
                          if (value == 'delete') _confirmDelete(contact);
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Remove')),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
