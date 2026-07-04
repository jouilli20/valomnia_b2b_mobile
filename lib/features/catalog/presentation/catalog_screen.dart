import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../auth/presentation/login_screen.dart';
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
  // La doc API ne fige pas le schéma JSON exact renvoyé par
  // GET /api/itemCategories, donc on essaie plusieurs clés plausibles.

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

    for (final candidate in candidates) {
      final value = candidate?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') {
        return value;
      }
    }
    return null;
  }

  static String? _categoryImageUrl(dynamic image) {
    final rawImage = image?.toString().trim();
    if (rawImage == null || rawImage.isEmpty || rawImage == 'null') {
      return null;
    }

    final imageUri = Uri.tryParse(rawImage);
    if (imageUri != null && imageUri.hasScheme) {
      return rawImage;
    }

    // Chemin relatif renvoyé par le back -> on le résout sur le
    // baseUrl du tenant. NB: CatalogApi.getCategories() envoie
    // actuellement 'https://agro.valomnia.com' en dur comme baseUrl —
    // pensez à le remplacer par ApiConstants.tenantBaseUrl (ou par
    // l'organisation réelle du client connecté) pour rester cohérent
    // ici et là-bas.
    return Uri.parse(ApiConstants.tenantBaseUrl).resolve(rawImage).toString();
  }

  static String? _imageFromCategory(dynamic category) {
    if (category is! Map) return null;
    return _categoryImageUrl(
      category['image'] ??
          category['picture'] ??
          category['photo'] ??
          category['thumbnail'],
    );
  }

  Future<void> _refreshCategories() async {
    ref.invalidate(categoriesProvider);
    await ref.read(categoriesProvider.future);
  }

  void _reloadCategories() {
    ref.invalidate(categoriesProvider);
  }

  Future<void> _logout(BuildContext context) async {
    await SecureStorageService.logout();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  List<dynamic> _filterCategories(List<dynamic> categories) {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return categories;

    return categories.where((category) {
      final name = _categoryName(category).toLowerCase();
      final description = _categoryDescription(category)?.toLowerCase() ?? '';
      return name.contains(normalizedQuery) ||
          description.contains(normalizedQuery);
    }).toList();
  }

  void _updateQuery(String value) => setState(() => _query = value);

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
          loading: () => _CatalogShell(
            totalCount: 0,
            searchController: _searchController,
            query: _query,
            searchEnabled: false,
            onQueryChanged: _updateQuery,
            onClearQuery: _clearQuery,
            onRefresh: _refreshCategories,
            onLogout: () => _logout(context),
            slivers: const [_LoadingSliver()],
          ),
          error: (error, _) => _CatalogShell(
            totalCount: 0,
            searchController: _searchController,
            query: _query,
            searchEnabled: false,
            onQueryChanged: _updateQuery,
            onClearQuery: _clearQuery,
            onRefresh: _refreshCategories,
            onLogout: () => _logout(context),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: _StateMessage(
                  icon: Icons.wifi_off_rounded,
                  title: 'Impossible de charger le catalogue',
                  message: error.toString(),
                  actionLabel: 'Réessayer',
                  onAction: _reloadCategories,
                ),
              ),
            ],
          ),
          data: (categories) {
            final filteredCategories = _filterCategories(categories);

            return _CatalogShell(
              totalCount: categories.length,
              searchController: _searchController,
              query: _query,
              onQueryChanged: _updateQuery,
              onClearQuery: _clearQuery,
              onRefresh: _refreshCategories,
              onLogout: () => _logout(context),
              slivers: [
                if (categories.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _StateMessage(
                      icon: Icons.inventory_2_outlined,
                      title: 'Aucune catégorie trouvée',
                      message: 'Tirez vers le bas pour actualiser le catalogue.',
                    ),
                  )
                else if (filteredCategories.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _StateMessage(
                      icon: Icons.search_off_rounded,
                      title: 'Aucun résultat',
                      message:
                      'Essayez un autre mot-clé pour retrouver une catégorie.',
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
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final category = filteredCategories[index];
                            return _CategoryCard(
                              name: _categoryName(category),
                              description: _categoryDescription(category),
                              imageUrl: _imageFromCategory(category),
                              // TODO: naviguer vers l'écran produits de
                              // cette catégorie une fois l'endpoint
                              // POST /api/items branché.
                              onTap: () {},
                            );
                          }, childCount: filteredCategories.length),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CatalogShell extends StatelessWidget {
  const _CatalogShell({
    required this.totalCount,
    required this.searchController,
    required this.query,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onRefresh,
    required this.onLogout,
    required this.slivers,
    this.searchEnabled = true,
  });

  final int totalCount;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final RefreshCallback onRefresh;
  final VoidCallback onLogout;
  final List<Widget> slivers;
  final bool searchEnabled;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _CatalogScreenState._primaryColor,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _CatalogHeader(
              totalCount: totalCount,
              searchController: searchController,
              query: query,
              searchEnabled: searchEnabled,
              onQueryChanged: onQueryChanged,
              onClearQuery: onClearQuery,
              onRefresh: onRefresh,
              onLogout: onLogout,
            ),
          ),
          ...slivers,
        ],
      ),
    );
  }
}

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({
    required this.totalCount,
    required this.searchController,
    required this.query,
    required this.searchEnabled,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onRefresh,
    required this.onLogout,
  });

  final int totalCount;
  final TextEditingController searchController;
  final String query;
  final bool searchEnabled;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final RefreshCallback onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5EAF1)),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: _CatalogScreenState._primaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valomnia B2B',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _CatalogScreenState._mutedColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Catalogue',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _CatalogScreenState._inkColor,
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                tooltip: 'Actualiser',
                icon: Icons.sync_rounded,
                onPressed: onRefresh,
              ),
              const SizedBox(width: 8),
              _HeaderIconButton(
                tooltip: 'Déconnexion',
                icon: Icons.logout_rounded,
                onPressed: onLogout,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF155E75),
                  Color(0xFF2563EB),
                  Color(0xFFE85D4F),
                ],
                stops: [0, 0.68, 1],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x242563EB),
                  blurRadius: 26,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricPill(
                        icon: Icons.category_outlined,
                        value: totalCount.toString(),
                        label: totalCount > 1 ? 'catégories' : 'catégorie',
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: _MetricPill(
                        icon: Icons.storefront_outlined,
                        value: 'B2B',
                        label: 'mode vente',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Parcourez vos familles de produits',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Retrouvez rapidement les catégories disponibles pour préparer vos commandes.',
                  style: TextStyle(
                    color: Color(0xE6FFFFFF),
                    fontSize: 14.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SearchField(
            controller: searchController,
            query: query,
            enabled: searchEnabled,
            onChanged: onQueryChanged,
            onClear: onClearQuery,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
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

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x24FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x30FFFFFF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.query,
    required this.enabled,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: _CatalogScreenState._inkColor,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'Rechercher une catégorie',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _CatalogScreenState._mutedColor,
        ),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
          tooltip: 'Effacer',
          onPressed: onClear,
          icon: const Icon(
            Icons.close_rounded,
            color: _CatalogScreenState._mutedColor,
          ),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFEFF4FA),
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        border: _border(const Color(0xFFE2E8F0)),
        enabledBorder: _border(const Color(0xFFE2E8F0)),
        focusedBorder: _border(_CatalogScreenState._primaryColor, width: 1.6),
        disabledBorder: _border(const Color(0xFFE2E8F0)),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.onTap,
  });

  final String name;
  final String? description;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5EAF1)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F0F172A),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(22)),
                  child: _CategoryImage(imageUrl: imageUrl),
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
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: _CatalogScreenState._primaryColor,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            description ?? 'Voir les produits',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _CatalogScreenState._mutedColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return const _ImageFallback();
    }

    return Image.network(
      imageUrl!,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _ImageFallback(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const _ImageLoading();
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF6FF),
      child: const Center(
        child: Icon(
          Icons.category_outlined,
          color: _CatalogScreenState._primaryColor,
          size: 42,
        ),
      ),
    );
  }
}

class _ImageLoading extends StatelessWidget {
  const _ImageLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF4FA),
      child: const Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}

class _LoadingSliver extends StatelessWidget {
  const _LoadingSliver();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.76,
        ),
        delegate: SliverChildBuilderDelegate(
              (context, index) => const _LoadingCard(),
          childCount: 6,
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEFF4FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 86,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: _CatalogScreenState._primaryColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _CatalogScreenState._inkColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _CatalogScreenState._mutedColor,
                fontSize: 14.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _CatalogScreenState._primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}