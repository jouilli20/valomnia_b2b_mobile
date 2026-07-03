import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../providers/catalog_provider.dart';
import '../../../core/constants/api_constants.dart';

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

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
    final catalogState = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('VALOMNIA'),
        actions: [
          IconButton(
            onPressed: () => ref.refresh(catalogProvider),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: catalogState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Erreur : $error'),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Aucun produit trouvé'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.78,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final product = items[index];

              return _ProductCard(product: product);
            },
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final name = product['name']?.toString() ?? 'Produit';
    final price = product['prices']?.toString() ?? '0 DT';
    final imageUrl = _buildImageUrl(product);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imageUrl != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                )
                    : const Center(
                  child: Icon(Icons.image, size: 40),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              price, // ici pas "$price DT"
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.add_circle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _buildImageUrl(dynamic product) {
    final itemImages = product['itemImages'];

    if (itemImages is! List || itemImages.isEmpty) {
      return null;
    }

    final firstImage = itemImages.first;
    if (firstImage is! Map || firstImage['smallImage'] == null) {
      return null;
    }

    final smallImage = firstImage['smallImage'].toString().trim();
    if (smallImage.isEmpty) {
      return null;
    }

    final imageUri = Uri.tryParse(smallImage);
    if (imageUri != null && imageUri.hasScheme) {
      return smallImage;
    }

    return Uri.parse(ApiConstants.tenantBaseUrl).resolve(smallImage).toString();
  }
}
