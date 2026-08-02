import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/local_cache.dart';
import '../../theme/app_colors.dart';
import '../../utils/page_transitions.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../home/home_shell.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? prefilledEmail;
  const LoginScreen({super.key, this.prefilledEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _remember = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledEmail != null) {
      _email.text = widget.prefilledEmail!;
    } else {
      LocalCache.instance.getRememberedEmail().then((email) {
        if (email != null && mounted) setState(() => _email.text = email);
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) return;

    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    try {
      await auth.login(email: _email.text, password: _password.text);
      await LocalCache.instance.setRememberedEmail(_remember ? _email.text.trim() : null);

      if (!mounted) return;

      final isPresident = auth.currentUser?.isPresident ?? false;
      if (isPresident) {
        await _showPresidentWelcome();
      }
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        fadeScaleRoute(const HomeShell()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showPresidentWelcome() async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.presidentGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.presidentGold.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: AppColors.presidentGold, size: 30),
              ),
              const SizedBox(height: 16),
              const Text('President Access Granted', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                'You now have the State Command view: live alert status across all 14 districts of Kerala.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.presidentGold,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Enter Command Center'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Log In')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const Text('Welcome back', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text(
                'Log in to view live weather and disaster alerts.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
              ),
              const SizedBox(height: 26),
              AppTextField(
                controller: _email,
                label: 'Email',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _password,
                label: 'Password',
                prefixIcon: Icons.lock_outline_rounded,
                obscure: _obscure,
                textInputAction: TextInputAction.done,
                validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                onFieldSubmitted: (_) => _submit(),
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              CheckboxListTile(
                value: _remember,
                onChanged: (v) => setState(() => _remember = v ?? true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text('Remember my email', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: 'Log In', onPressed: _submit, loading: _submitting),
              const SizedBox(height: 10),
              const Text(
                'President / State Coordinator accounts sign in with the same form above — access is granted through your registered role.',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.35),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      fadeScaleRoute(const SignupScreen()),
                    ),
                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
