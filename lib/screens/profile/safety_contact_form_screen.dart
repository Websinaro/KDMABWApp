import 'package:flutter/material.dart';

import '../../models/safety_contact.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';

class SafetyContactFormScreen extends StatefulWidget {
  final SafetyContact? existing;

  const SafetyContactFormScreen({super.key, this.existing});

  @override
  State<SafetyContactFormScreen> createState() => _SafetyContactFormScreenState();
}

class _SafetyContactFormScreenState extends State<SafetyContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _relationship;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _relationship = TextEditingController(text: e?.relationship ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _address = TextEditingController(text: e?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _relationship.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (widget.existing == null) {
        await ApiService.instance.addSafetyContact(
          name: _name.text,
          relationship: _relationship.text.isEmpty ? null : _relationship.text,
          phone: _phone.text,
          email: _email.text.isEmpty ? null : _email.text,
          address: _address.text.isEmpty ? null : _address.text,
        );
      } else {
        await ApiService.instance.updateSafetyContact(
          id: widget.existing!.id,
          name: _name.text,
          relationship: _relationship.text.isEmpty ? null : _relationship.text,
          phone: _phone.text,
          email: _email.text.isEmpty ? null : _email.text,
          address: _address.text.isEmpty ? null : _address.text,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isEdit ? 'Edit Contact' : 'Add Safety Contact')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_error!, style: const TextStyle(color: AppColors.alertRed, fontSize: 13)),
              ),
            AppTextField(
              controller: _name,
              label: 'Full Name',
              prefixIcon: Icons.person_outline_rounded,
              textCapitalization: TextCapitalization.words,
              validator: Validators.name,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _relationship,
              label: 'Relationship (optional)',
              prefixIcon: Icons.family_restroom_rounded,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _phone,
              label: 'Phone Number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: Validators.phone,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _email,
              label: 'Email (optional)',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _address,
              label: 'Address (optional)',
              prefixIcon: Icons.location_on_outlined,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isEdit ? 'Save Changes' : 'Add Contact'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
