import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/page_transitions.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/district_picker_field.dart';
import '../../widgets/primary_button.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _accessCode = TextEditingController();

  String? _districtKey;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isPresident = false;
  bool _submitting = false;
  String? _districtError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _accessCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _districtError = Validators.district(_districtKey));
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk || _districtError != null) return;

    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    try {
      await auth.register(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
        district: _districtKey!,
        accessCode: _isPresident ? _accessCode.text : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account created for ${_email.text.trim()}. Please log in.')),
      );
      Navigator.of(context).pushReplacement(
        fadeScaleRoute(LoginScreen(prefilledEmail: _email.text.trim())),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              const Text(
                'Sign up to receive live weather and disaster alerts for your district.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 22),
              AppTextField(
                controller: _name,
                label: 'Full Name',
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: Validators.name,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _email,
                label: 'Email',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _phone,
                label: 'Phone Number',
                prefixIcon: Icons.call_outlined,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              const SizedBox(height: 14),
              DistrictPickerField(
                selectedKey: _districtKey,
                errorText: _districtError,
                onSelected: (key) => setState(() {
                  _districtKey = key;
                  _districtError = null;
                }),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _password,
                label: 'Password',
                prefixIcon: Icons.lock_outline_rounded,
                obscure: _obscurePass,
                validator: Validators.password,
                suffix: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _confirmPassword,
                label: 'Confirm Password',
                prefixIcon: Icons.lock_outline_rounded,
                obscure: _obscureConfirm,
                textInputAction: TextInputAction.done,
                validator: (v) => Validators.confirmPassword(v, _password.text),
                suffix: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: SwitchListTile(
                  value: _isPresident,
                  onChanged: (v) => setState(() => _isPresident = v),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  title: const Text('President / State Coordinator', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text(
                    'Enable this only if you hold an official access code for the state command dashboard.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ),
              ),
              if (_isPresident) ...[
                const SizedBox(height: 14),
                AppTextField(
                  controller: _accessCode,
                  label: 'Official Access Code',
                  prefixIcon: Icons.verified_user_outlined,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) => _isPresident ? Validators.required(v, message: 'Enter the access code') : null,
                ),
              ],
              const SizedBox(height: 26),
              PrimaryButton(label: 'Sign Up', onPressed: _submit, loading: _submitting),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account?', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      fadeScaleRoute(const LoginScreen()),
                    ),
                    child: const Text('Log In'),
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
