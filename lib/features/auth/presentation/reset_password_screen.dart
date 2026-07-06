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
    final destination = _resetDestination(widget.email, widget.organization);

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
                          _BackButton(onPressed: _goBack),
                          const SizedBox(height: 18),
                          _ResetHeader(
                            icon: Icons.shield_outlined,
                            title: 'Nouveau mot de passe',
                            subtitle: destination.isEmpty
                                ? 'Collez le token ou le lien recu, puis choisissez un nouveau mot de passe.'
                                : 'Lien envoye a $destination. Collez le token puis choisissez votre nouveau mot de passe.',
                          ),
                          const SizedBox(height: 22),
                          _ResetPasswordPanel(
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

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        tooltip: 'Retour',
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
      ),
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

class _ResetPasswordPanel extends StatelessWidget {
  const _ResetPasswordPanel({
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
            controller: tokenController,
            labelText: 'Token ou lien',
            hintText: 'Coller le lien recu par email',
            icon: Icons.key_rounded,
            textInputAction: TextInputAction.next,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Token obligatoire'
                : null,
          ),
          const SizedBox(height: 14),
          _AuthField(
            controller: passwordController,
            labelText: 'Nouveau mot de passe',
            hintText: 'Minimum 6 caracteres',
            icon: Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.next,
            suffixIcon: _VisibilityButton(
              isObscured: obscurePassword,
              onPressed: onTogglePassword,
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
          _AuthField(
            controller: confirmPasswordController,
            labelText: 'Confirmation',
            hintText: 'Confirmer le mot de passe',
            icon: Icons.verified_user_outlined,
            obscureText: obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            suffixIcon: _VisibilityButton(
              isObscured: obscureConfirmPassword,
              onPressed: onToggleConfirmPassword,
            ),
            onFieldSubmitted: (_) => isLoading ? null : onSubmit(),
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
          _PrimaryButton(
            isLoading: isLoading,
            label: 'Modifier le mot de passe',
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
        color: _AuthColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(icon, color: _AuthColors.muted, size: 22),
        suffixIcon: suffixIcon,
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
      validator: validator,
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _VisibilityButton extends StatelessWidget {
  const _VisibilityButton({required this.isObscured, required this.onPressed});

  final bool isObscured;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: isObscured
          ? 'Afficher le mot de passe'
          : 'Masquer le mot de passe',
      onPressed: onPressed,
      icon: Icon(
        isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: _AuthColors.muted,
        size: 22,
      ),
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

String _resetDestination(String? email, String? organization) {
  return [
    if (email != null && email.isNotEmpty) email,
    if (organization != null && organization.isNotEmpty) organization,
  ].join(' - ');
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
