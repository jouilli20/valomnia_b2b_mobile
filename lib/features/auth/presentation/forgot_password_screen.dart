import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/presentation/language_selector.dart';
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

    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(
            email: _emailController.text.trim(),
            organization: _organizationController.text.trim(),
          );

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(content: Text(l10n.text('resetLinkSent'))),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(SnackBar(content: Text(l10n.genericError(e))));
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
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: _AuthColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 38,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              _BackButton(onPressed: _goBack),
                              const Spacer(),
                              const LanguageSelector(compact: true),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _ResetHeader(
                            icon: Icons.lock_reset_rounded,
                            title: l10n.text('forgotPasswordTitle'),
                            subtitle: l10n.text('forgotPasswordSubtitle'),
                          ),
                          const SizedBox(height: 22),
                          _ForgotPasswordPanel(
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.text('back'),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _AuthColors.ink,
        fixedSize: const Size.square(44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _AuthColors.border),
        ),
      ),
      icon: const Icon(Icons.arrow_back_rounded, size: 22),
    );
  }
}

class _ResetHeader extends StatelessWidget {
  const _ResetHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF155E75), Color(0xFF2563EB)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2563EB),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: _AuthColors.primary, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Valomnia B2B',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.08,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xE6FFFFFF),
              fontSize: 15,
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForgotPasswordPanel extends StatelessWidget {
  const _ForgotPasswordPanel({
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
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _AuthColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthField(
            controller: organizationController,
            labelText: l10n.text('organization'),
            hintText: l10n.text('organizationHint'),
            icon: Icons.business_outlined,
            textInputAction: TextInputAction.next,
            validatorMessage: l10n.requiredField(l10n.text('organization')),
          ),
          const SizedBox(height: 14),
          _AuthField(
            controller: emailController,
            labelText: l10n.text('email'),
            hintText: l10n.text('emailHint'),
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validatorMessage: l10n.requiredField(l10n.text('email')),
            onFieldSubmitted: (_) => isLoading ? null : onSubmit(),
          ),
          const SizedBox(height: 18),
          _PrimaryButton(
            isLoading: isLoading,
            label: l10n.text('sendResetLink'),
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
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
        color: _AuthColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: _AuthColors.muted, size: 22),
        labelStyle: const TextStyle(
          color: _AuthColors.muted,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: _AuthColors.primary,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
        hintStyle: const TextStyle(
          color: _AuthColors.faint,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: const TextStyle(fontWeight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        filled: true,
        fillColor: _AuthColors.field,
        border: _fieldBorder(_AuthColors.inputBorder),
        enabledBorder: _fieldBorder(_AuthColors.inputBorder),
        focusedBorder: _fieldBorder(_AuthColors.primary, width: 1.6),
        errorBorder: _fieldBorder(_AuthColors.error, width: 1.5),
        focusedErrorBorder: _fieldBorder(_AuthColors.error, width: 1.6),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? validatorMessage : null,
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  final bool isLoading;
  final String label;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _AuthColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9DB7EF),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

class _AuthColors {
  const _AuthColors._();

  static const background = Color(0xFFF4F7FB);
  static const field = Color(0xFFF8FAFC);
  static const border = Color(0xFFE5EAF1);
  static const inputBorder = Color(0xFFE2E8F0);
  static const primary = Color(0xFF2563EB);
  static const error = Color(0xFFE85D4F);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);
}
