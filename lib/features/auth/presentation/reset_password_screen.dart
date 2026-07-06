import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_repository_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.organization, this.email});

  final String? organization;
  final String? email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            token: _tokenFromInput(_tokenController.text),
            password: _passwordController.text.trim(),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe modifie avec succes.')),
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de modifier le mot de passe : $e')),
      );
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
        title: const Text('Nouveau mot de passe'),
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
                          _PageIntro(
                            organization: widget.organization,
                            email: widget.email,
                          ),
                          const SizedBox(height: 28),
                          _ResetPasswordForm(
                            isLoading: _isLoading,
                            tokenController: _tokenController,
                            passwordController: _passwordController,
                            confirmPasswordController:
                                _confirmPasswordController,
                            obscurePassword: _obscurePassword,
                            obscureConfirmPassword: _obscureConfirmPassword,
                            onTogglePassword: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            onToggleConfirmPassword: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            onSubmit: _resetPassword,
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
  const _PageIntro({required this.organization, required this.email});

  final String? organization;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final destination = [
      if (email != null && email!.isNotEmpty) email,
      if (organization != null && organization!.isNotEmpty) organization,
    ].whereType<String>().join(' - ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _BrandMark(),
        const SizedBox(height: 24),
        const Text(
          'Finaliser la reinitialisation',
          style: TextStyle(
            color: _ResetColors.ink,
            fontSize: 28,
            height: 1.12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          destination.isEmpty
              ? 'Saisissez le token recu par email puis choisissez un nouveau mot de passe.'
              : 'Token envoye a $destination. Saisissez-le ici puis choisissez un nouveau mot de passe.',
          style: const TextStyle(
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

class _ResetPasswordForm extends StatelessWidget {
  const _ResetPasswordForm({
    required this.isLoading,
    required this.tokenController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onSubmit,
  });

  final bool isLoading;
  final TextEditingController tokenController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
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
            controller: tokenController,
            labelText: 'Token ou lien',
            hintText: 'Token ou lien recu par email',
            icon: Icons.key_rounded,
            textInputAction: TextInputAction.next,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Token obligatoire'
                : null,
          ),
          const SizedBox(height: 14),
          _ResetField(
            controller: passwordController,
            labelText: 'Nouveau mot de passe',
            hintText: 'Minimum 6 caracteres',
            icon: Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              tooltip: obscurePassword
                  ? 'Afficher le mot de passe'
                  : 'Masquer le mot de passe',
              onPressed: onTogglePassword,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _ResetColors.muted,
                size: 22,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Mot de passe obligatoire';
              }
              if (value.trim().length < 6) {
                return 'Minimum 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _ResetField(
            controller: confirmPasswordController,
            labelText: 'Confirmer le mot de passe',
            hintText: 'Ressaisir le mot de passe',
            icon: Icons.lock_reset_rounded,
            obscureText: obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => isLoading ? null : onSubmit(),
            suffixIcon: IconButton(
              tooltip: obscureConfirmPassword
                  ? 'Afficher le mot de passe'
                  : 'Masquer le mot de passe',
              onPressed: onToggleConfirmPassword,
              icon: Icon(
                obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _ResetColors.muted,
                size: 22,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Confirmation obligatoire';
              }
              if (value.trim() != passwordController.text.trim()) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
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
                  : const Text('Modifier le mot de passe'),
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
    required this.validator,
    required this.icon,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final FormFieldValidator<String> validator;
  final IconData icon;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      obscureText: obscureText,
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
        suffixIcon: suffixIcon,
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
      validator: validator,
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

String _tokenFromInput(String input) {
  final value = input.trim();
  final uri = Uri.tryParse(value);
  var token = uri?.queryParameters['token'];

  if ((token == null || token.isEmpty) && uri?.fragment.isNotEmpty == true) {
    token = Uri.tryParse(uri!.fragment)?.queryParameters['token'];
  }

  if (token != null && token.isNotEmpty) {
    return token;
  }

  return value;
}
