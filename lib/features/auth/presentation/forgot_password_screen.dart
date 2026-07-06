import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_repository_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _organizationController = TextEditingController(text: 'agro');
  final _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _organizationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(
            email: _emailController.text.trim(),
            organization: _organizationController.text.trim(),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lien de réinitialisation envoyé par email.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goBack() {
    if (_isLoading) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ResetColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Mot de passe oublié'),
        centerTitle: false,
        backgroundColor: _ResetColors.background,
        foregroundColor: _ResetColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: _ResetColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 56,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _PageIntro(),
                          const SizedBox(height: 28),
                          _ResetForm(
                            isLoading: _isLoading,
                            organizationController: _organizationController,
                            emailController: _emailController,
                            onSubmit: _sendResetLink,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BrandMark(),
        SizedBox(height: 24),
        Text(
          'Réinitialiser votre mot de passe',
          style: TextStyle(
            color: _ResetColors.ink,
            fontSize: 28,
            height: 1.12,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Saisissez votre organisation et votre adresse e-mail. Vous recevrez un lien de réinitialisation.',
          style: TextStyle(
            color: _ResetColors.muted,
            fontSize: 15.5,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _ResetColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            color: _ResetColors.primary,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Valomnia B2B',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _ResetColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResetForm extends StatelessWidget {
  const _ResetForm({
    required this.isLoading,
    required this.organizationController,
    required this.emailController,
    required this.onSubmit,
  });

  final bool isLoading;
  final TextEditingController organizationController;
  final TextEditingController emailController;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _ResetColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResetField(
            controller: organizationController,
            labelText: 'Organisation',
            hintText: 'Nom de votre organisation',
            icon: Icons.business_outlined,
            textInputAction: TextInputAction.next,
            validatorMessage: 'Organisation obligatoire',
          ),
          const SizedBox(height: 14),
          _ResetField(
            controller: emailController,
            labelText: 'Adresse e-mail',
            hintText: 'exemple@entreprise.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validatorMessage: 'Adresse e-mail obligatoire',
            onFieldSubmitted: (_) => isLoading ? null : onSubmit(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ResetColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF9DB7EF),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: isLoading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Envoyer '),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResetField extends StatelessWidget {
  const _ResetField({
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.validatorMessage,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final String validatorMessage;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        color: _ResetColors.ink,
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: _ResetColors.muted, size: 21),
        labelStyle: const TextStyle(
          color: _ResetColors.muted,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: _ResetColors.primary,
          fontSize: 14.5,
          fontWeight: FontWeight.w800,
        ),
        hintStyle: const TextStyle(
          color: _ResetColors.faint,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: const TextStyle(fontWeight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        filled: true,
        fillColor: _ResetColors.field,
        border: _fieldBorder(_ResetColors.inputBorder),
        enabledBorder: _fieldBorder(_ResetColors.inputBorder),
        focusedBorder: _fieldBorder(_ResetColors.primary, width: 1.5),
        errorBorder: _fieldBorder(_ResetColors.error, width: 1.4),
        focusedErrorBorder: _fieldBorder(_ResetColors.error, width: 1.5),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? validatorMessage : null,
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _ResetColors {
  const _ResetColors._();

  static const background = Color(0xFFF7F9FC);
  static const field = Color(0xFFF8FAFC);
  static const border = Color(0xFFE5EAF1);
  static const inputBorder = Color(0xFFE2E8F0);
  static const primary = Color(0xFF2563EB);
  static const primarySoft = Color(0xFFEAF2FF);
  static const error = Color(0xFFE85D4F);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);
}
