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
  final formKey = GlobalKey<FormState>();
  final organizationController = TextEditingController(text: 'agro');
  final emailController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    organizationController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> sendResetLink() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await ref
          .read(authRepositoryProvider)
          .forgotPassword(
            email: emailController.text.trim(),
            organization: organizationController.text.trim(),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lien de réinitialisation envoyé par email'),
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
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: organizationController,
                decoration: const InputDecoration(labelText: 'Organisation'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Organisation obligatoire'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Email obligatoire' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : sendResetLink,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('ENVOYER'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
