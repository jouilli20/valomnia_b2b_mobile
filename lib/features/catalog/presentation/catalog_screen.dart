import 'package:flutter/material.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../../auth/presentation/login_screen.dart';

const _primary = Color(0xFF2563EB);
const _deepTeal = Color(0xFF155E75);
const _danger = Color(0xFFE85D4F);
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFE5EAF1);
const _surface = Colors.white;
const _page = Color(0xFFF8FAFC);

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  int _selectedCategory = 0;
  int _selectedSubCategory = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<_Category> _categories = [
    _Category(
      label: 'Alim.',
      value: 'Alimentaire',
      icon: Icons.local_dining_outlined,
      color: _primary,
    ),
    _Category(
      label: 'Cosm.',
      value: 'Cosmetique',
      icon: Icons.spa_outlined,
      color: Color(0xFF8E44AD),
    ),
    _Category(
      label: 'Eau',
      value: 'Boissons',
      icon: Icons.water_drop_outlined,
      color: Color(0xFF1FA06F),
    ),
    _Category(
      label: 'Promo',
      value: 'Promo',
      icon: Icons.local_offer_outlined,
      color: _danger,
    ),
  ];

  static const List<String> _subCategories = ['Tous', 'Promos', 'Packs', 'Gratuites'];

  final List<_Product> _products = [
    _Product(
      name: 'Thon entier',
      category: 'Alimentaire',
      price: '5 dt',
      badge: '-20%',
      imageColors: [Color(0xFFFFF1E6), Color(0xFFD97706)],
      icon: Icons.set_meal_outlined,
    ),
    _Product(
      name: 'Eau minérale 1.5L',
      category: 'Boissons',
      price: '8 dt',
      badge: 'Stock',
      imageColors: [Color(0xFFE0F2FE), Color(0xFF2563EB)],
      icon: Icons.water_drop_outlined,
    ),
    _Product(
      name: 'Pâte spaghetti',
      category: 'Alimentaire',
      price: '1 dt',
      badge: null,
      imageColors: [Color(0xFFFFF7ED), Color(0xFFF59E0B)],
      icon: Icons.ramen_dining_outlined,
    ),
    _Product(
      name: 'Harissa traditionnelle',
      category: 'Alimentaire',
      price: '7 dt',
      badge: 'Nouveau',
      imageColors: [Color(0xFFFFE4E6), Color(0xFFDC2626)],
      icon: Icons.local_fire_department_outlined,
    ),
    _Product(
      name: 'Huile d\'olive 1L',
      category: 'Alimentaire',
      price: '18 dt',
      badge: 'Top',
      imageColors: [Color(0xFFECFCCB), Color(0xFF65A30D)],
      icon: Icons.opacity_outlined,
    ),
    _Product(
      name: 'Couscous fin',
      category: 'Alimentaire',
      price: '3 dt',
      badge: null,
      imageColors: [Color(0xFFFEF3C7), Color(0xFFCA8A04)],
      icon: Icons.grain_outlined,
    ),
  ];

  Future<void> _logout(BuildContext context) async {
    await SecureStorageService.logout();
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  List<_Product> get _filteredProducts {
    final activeCategory = _categories[_selectedCategory];

    var result = _products.where((product) {
      final matchesCategory = activeCategory.value == 'Promo'
          ? product.badge != null
          : product.category == activeCategory.value;

      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();

    if (_selectedSubCategory == 1) {
      result = result.where((p) => p.badge != null).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _filteredProducts;

    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    children: [
                      _Header(onLogout: () => _logout(context)),
                      const SizedBox(height: 20),
                      _SearchBar(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                      const SizedBox(height: 20),
                      _CategorySelector(
                        categories: _categories,
                        subCategories: _subCategories,
                        selectedIndex: _selectedCategory,
                        selectedSubIndex: _selectedSubCategory,
                        onCategorySelected: (index) {
                          setState(() {
                            _selectedCategory = index;
                            _selectedSubCategory = 0;
                          });
                        },
                        onSubSelected: (index) =>
                            setState(() => _selectedSubCategory = index),
                      ),
                      const SizedBox(height: 16),
                      _SectionHeader(count: filteredProducts.length),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: filteredProducts.isEmpty
                    ? const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48, color: _muted),
                        SizedBox(height: 12),
                        Text('Aucun produit trouvé',
                            style: TextStyle(fontSize: 16, color: _muted)),
                      ],
                    ),
                  ),
                )
                    : SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final crossAxisCount = width >= 560 ? 3 : 2;

                    return SliverGrid.builder(
                      itemCount: filteredProducts.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 16,
                      ),
                      itemBuilder: (context, index) {
                        return _ProductCard(
                            product: filteredProducts[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const _CatalogNavigationBar(),
    );
  }
}

// ====================== Widgets ======================

class _Header extends StatelessWidget {
  const _Header({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [_deepTeal, _primary],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x402563EB),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Valomnia B2B',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              Text(
                'Catalogue commercial',
                style: TextStyle(
                  fontSize: 13,
                  color: _muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _RoundIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        _RoundIconButton(
          icon: Icons.logout_rounded,
          tooltip: 'Déconnexion',
          onPressed: onLogout,
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Rechercher produits, SKU...',
              prefixIcon: const Icon(Icons.search_rounded, color: _muted),
              filled: true,
              fillColor: _surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _primary, width: 1.8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _RoundIconButton(
          icon: Icons.tune_rounded,
          tooltip: 'Filtres',
          onPressed: () {},
          filled: true,
        ),
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.categories,
    required this.subCategories,
    required this.selectedIndex,
    required this.selectedSubIndex,
    required this.onCategorySelected,
    required this.onSubSelected,
  });

  final List<_Category> categories;
  final List<String> subCategories;
  final int selectedIndex;
  final int selectedSubIndex;
  final ValueChanged<int> onCategorySelected;
  final ValueChanged<int> onSubSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // === Catégories Principales ===
        Container(
          height: 62,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: List.generate(categories.length, (index) {
              final cat = categories[index];
              final isSelected = selectedIndex == index;
              return Expanded(
                child: _CategoryBlock(
                  category: cat,
                  selected: isSelected,
                  onPressed: () => onCategorySelected(index),
                ),
              );
            }),
          ),
        ),

        // === Sous-catégories ===
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: _surface,
            border: Border(
              top: BorderSide.none,
              bottom: BorderSide(color: _line),
              left: BorderSide(color: _line),
              right: BorderSide(color: _line),
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Row(
            children: List.generate(subCategories.length, (index) {
              return Expanded(
                child: _SubCategoryBlock(
                  label: subCategories[index],
                  selected: selectedSubIndex == index,
                  onPressed: () => onSubSelected(index),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _CategoryBlock extends StatelessWidget {
  const _CategoryBlock({
    required this.category,
    required this.selected,
    required this.onPressed,
  });

  final _Category category;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: selected ? category.color : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category.icon,
                    color: selected ? Colors.white : category.color,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.label,
                    style: TextStyle(
                      color: selected ? Colors.white : category.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: 24,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubCategoryBlock extends StatelessWidget {
  const _SubCategoryBlock({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF475569),
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Articles disponibles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
        Text(
          '$count produits',
          style: const TextStyle(
            fontSize: 13.5,
            color: _muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final _Product product;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigation vers détail produit (à implémenter)
      },
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ProductVisual(product: product),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        product.price,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: _primary,
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(36, 36),
                        ),
                        child: const Icon(Icons.add_rounded, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({required this.product});

  final _Product product;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: product.imageColors,
            ),
          ),
        ),
        const Positioned(
          right: -20,
          top: -20,
          child: _BannerCircle(size: 78, opacity: 0.25),
        ),
        const Positioned(
          left: -25,
          bottom: -25,
          child: _BannerCircle(size: 92, opacity: 0.18),
        ),
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(product.icon, size: 36, color: const Color(0xFF111827)),
          ),
        ),
        if (product.badge != null)
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _danger,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CatalogNavigationBar extends StatelessWidget {
  const _CatalogNavigationBar();

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      height: 72,
      elevation: 0,
      backgroundColor: _surface,
      indicatorColor: const Color(0x1A2563EB),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded, color: _primary),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Badge(
            label: Text('3'),
            child: Icon(Icons.shopping_cart_outlined),
          ),
          selectedIcon: Badge(
            label: Text('3'),
            child: Icon(Icons.shopping_cart_rounded, color: _primary),
          ),
          label: 'Panier',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded, color: _primary),
          label: 'Commandes',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded, color: _primary),
          label: 'Profil',
        ),
      ],
      onDestinationSelected: (_) {},
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 42,
        child: IconButton(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: filled ? _ink : _surface,
            foregroundColor: filled ? Colors.white : const Color(0xFF334155),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: filled ? _ink : _line),
            ),
          ),
          icon: Icon(icon, size: 21),
        ),
      ),
    );
  }
}

class _BannerCircle extends StatelessWidget {
  const _BannerCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Category {
  const _Category({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _Product {
  const _Product({
    required this.name,
    required this.category,
    required this.price,
    required this.badge,
    required this.imageColors,
    required this.icon,
  });

  final String name;
  final String category;
  final String price;
  final String? badge;
  final List<Color> imageColors;
  final IconData icon;
}