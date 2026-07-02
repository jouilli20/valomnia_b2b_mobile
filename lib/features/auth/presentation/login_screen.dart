import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _organisationController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _organisationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(authProvider.notifier)
        .login(
          organisation: _organisationController.text.trim(),
          username: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    ref.listen(authProvider, (previous, next) {
      next.whenOrNull(
        data: (data) {
          if (data != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Connexion réussie')));
          }
        },
        error: (error, _) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
        },
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _BrandHeader(),
                          const SizedBox(height: 28),
                          const Text(
                            'Veuillez saisir vos coordonnées pour\naccéder à votre compte de vente en gros',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF74747F),
                              fontSize: 17,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 32),
                          _LoginField(
                            controller: _organisationController,
                            hintText: 'Votre Organisation',
                            textInputAction: TextInputAction.next,
                            validatorMessage: 'Organisation obligatoire',
                          ),
                          const SizedBox(height: 16),
                          _LoginField(
                            controller: _emailController,
                            hintText: 'Adresse e-mail',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validatorMessage: 'Adresse e-mail obligatoire',
                          ),
                          const SizedBox(height: 16),
                          _LoginField(
                            controller: _passwordController,
                            hintText: 'Mot de passe',
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            validatorMessage: 'Mot de passe obligatoire',
                            onFieldSubmitted: (_) =>
                                isLoading ? null : _submitLogin(),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Afficher le mot de passe'
                                  : 'Masquer le mot de passe',
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF74747F),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF4E8FCE),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              child: const Text('Mot de passe oublié ?'),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 60,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submitLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A96E2),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: const Color(
                                  0xFF9CC5ED,
                                ),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              child: isLoading
                                  ? const SizedBox.square(
                                      dimension: 26,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Se connecter'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const _SupportPhone(),
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF4C91D9),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: Colors.white,
            size: 31,
          ),
        ),
        const SizedBox(width: 14),
        const Flexible(
          child: Text(
            'Valomnia B2B',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF11111F),
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.hintText,
    required this.validatorMessage,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final String validatorMessage;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(color: Color(0xFF11111F), fontSize: 18),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Color(0xFF7B7B85),
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 18,
        ),
        filled: true,
        fillColor: Colors.white,
        border: _fieldBorder(const Color(0xFFE3E5EA)),
        enabledBorder: _fieldBorder(const Color(0xFFE3E5EA)),
        focusedBorder: _fieldBorder(const Color(0xFF4A96E2)),
        errorBorder: _fieldBorder(const Color(0xFFE35656)),
        focusedErrorBorder: _fieldBorder(const Color(0xFFE35656)),
      ),
      validator: (value) =>
          value == null || value.trim().isEmpty ? validatorMessage : null,
    );
  }

  OutlineInputBorder _fieldBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: 1.4),
    );
  }
}

class _SupportPhone extends StatelessWidget {
  const _SupportPhone();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(
          Icons.phone_in_talk,
          color: Color(0xFFD82727),
          size: 30,
        ),
        label: const Text('71 204 542'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF11111F),
          side: const BorderSide(color: Color(0xFFE6E8ED), width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
