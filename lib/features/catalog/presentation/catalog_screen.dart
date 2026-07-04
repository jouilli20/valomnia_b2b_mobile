import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../providers/catalog_provider.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  static String? _categoryImageUrl(dynamic image) {
    final rawImage = image?.toString().trim();

    if (rawImage == null || rawImage.isEmpty || rawImage == 'null') {
      return null;
    }

    final imageUri = Uri.tryParse(rawImage);

    if (imageUri != null && imageUri.hasScheme) {
      return rawImage;
    }

    return Uri.parse(ApiConstants.tenantBaseUrl).resolve(rawImage).toString();
  }

  static Widget _categoryLeading(String? imageUrl) {
    const fallback = Icon(Icons.category);

    if (imageUrl == null) {
      return fallback;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        imageUrl,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return const SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    await SecureStorageService.logout();

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VALOMNIA'),
        actions: [
          IconButton(
            onPressed: () => ref.refresh(categoriesProvider),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: categoriesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('Aucune categorie trouvee'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final name = category['name']?.toString() ?? 'Categorie';
              final imageUrl = _categoryImageUrl(category['image']);

              return Card(
                child: ListTile(
                  leading: _categoryLeading(imageUrl),
                  title: Text(name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
