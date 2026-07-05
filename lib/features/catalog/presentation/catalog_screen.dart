import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/login_screen.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../providers/catalog_provider.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _backgroundColor = Color(0xFFF4F7FB);
  static const _primaryColor = Color(0xFF2563EB);
  static const _inkColor = Color(0xFF0F172A);
  static const _mutedColor = Color(0xFF64748B);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---- Lecture défensive des champs catégorie ----
  // GET /api/itemCategories ne fige pas le schéma JSON exact des
  // catégories -> on tente plusieurs clés plausibles.

  static String _categoryName(dynamic category) {
    if (category is Map) {
      final n = category['name']?.toString().trim();
      if (n != null && n.isNotEmpty) return n;
    }
    return 'Catégorie';
  }

  static String? _categoryDescription(dynamic category) {
    if (category is! Map) return null;
    final candidates = [
      category['description'],
      category['shortDescription'],
      category['code'],
      category['reference'],
    ];
    for (final c in candidates) {
      final v = c?.toString().trim();
      if (v != null && v.isNotEmpty && v != 'null') return v;
    }
    return null;
  }

  static String? _categoryImageUrl(dynamic category) {
    if (category is! Map) return null;
    final raw =
    (category['image'] ?? category['picture'] ?? category['thumbnail'])
        ?.toString()
        .trim();
    if (raw == null || raw.isEmpty || raw == 'null') return null;

    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) return raw;

    // Chemin relatif -> résolu sur le tenant utilisé par getCategories().
    // NB: CatalogApi envoie actuellement 'https://agro.valomnia.com' en
    // dur -> à remplacer par le tenant réel du client connecté.
    return Uri.parse('https://agro.valomnia.com').resolve(raw).toString();
  }

  Future<void> _refreshCategories() async {
    ref.invalidate(categoriesProvider);
    await ref.read(categoriesProvider.future);
  }

  void _reloadCategories() => ref.invalidate(categoriesProvider);

  Future<void> _logout(BuildContext context) async {
    await SecureStorageService.logout();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  List<dynamic> _filterCategories(List<dynamic> categories) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return categories;
    return categories.where((c) {
      final name = _categoryName(c).toLowerCase();
      final desc = _categoryDescription(c)?.toLowerCase() ?? '';
      return name.contains(q) || desc.contains(q);
    }).toList();
  }

  void _updateQuery(String v) => setState(() => _query = v);

  void _clearQuery() {
    _searchController.clear();
    _updateQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        bottom: false,
        child: categoriesState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _StateMessage(
            icon: Icons.wifi_off_rounded,
            title: 'Impossible de charger le catalogue',
            message: error.toString(),
            actionLabel: 'Réessayer',
            onAction: _reloadCategories,
          ),
          data: (categories) {
            final filtered = _filterCategories(categories);

            return RefreshIndicator(
              color: _primaryColor,
              onRefresh: _refreshCategories,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ---- En-tête + recherche ----
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Catalogue',
                                  style: TextStyle(
                                    color: _inkColor,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              _IconButton(
                                icon: Icons.sync_rounded,
                                tooltip: 'Actualiser',
                                onPressed: _refreshCategories,
                              ),
                              const SizedBox(width: 8),
                              _IconButton(
                                icon: Icons.logout_rounded,
                                tooltip: 'Déconnexion',
                                onPressed: () => _logout(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _searchController,
                            onChanged: _updateQuery,
                            decoration: InputDecoration(
                              hintText: 'Rechercher une catégorie',
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: _mutedColor),
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: _mutedColor),
                                onPressed: _clearQuery,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide:
                                const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ---- Grille des catégories ----
                  if (categories.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _StateMessage(
                        icon: Icons.inventory_2_outlined,
                        title: 'Aucune catégorie trouvée',
                        message:
                        'Tirez vers le bas pour actualiser le catalogue.',
                      ),
                    )
                  else if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _StateMessage(
                        icon: Icons.search_off_rounded,
                        title: 'Aucun résultat',
                        message: 'Essayez un autre mot-clé.',
                        actionLabel: 'Effacer',
                        onAction: _clearQuery,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          final crossAxisCount = width >= 720 ? 3 : 2;

                          return SliverGrid(
                            gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: width >= 720 ? 0.92 : 0.76,
                            ),
                            delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                final category = filtered[index];
                                return _CategoryCard(
                                  name: _categoryName(category),
                                  description: _categoryDescription(category),
                                  imageUrl: _categoryImageUrl(category),
                                );
                              },
                              childCount: filtered.length,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton(
      {required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5EAF1)),
          ),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: _CatalogScreenState._inkColor, size: 22),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  final String name;
  final String? description;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () {
          // TODO: naviguer vers les produits de cette catégorie
          // (POST /api/items?category=...) une fois cet écran branché.
        },
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5EAF1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
                  child: imageUrl == null
                      ? Container(
                    color: const Color(0xFFEFF6FF),
                    child: const Center(
                      child: Icon(Icons.category_outlined,
                          color: _CatalogScreenState._primaryColor,
                          size: 42),
                    ),
                  )
                      : Image.network(
                    imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(color: const Color(0xFFEFF6FF)),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _CatalogScreenState._inkColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description ?? 'Voir les produits',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _CatalogScreenState._mutedColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _CatalogScreenState._primaryColor, size: 40),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _CatalogScreenState._inkColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
              const TextStyle(color: _CatalogScreenState._mutedColor, fontSize: 13.5),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}