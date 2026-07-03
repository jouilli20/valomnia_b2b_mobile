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
const _page = Color(0xFFF4F7FB);

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  int _selectedCategory = 0;
  int _selectedSubCategory = 0;

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

  static const List<String> _subCategories = [
    'Tous',
    'Promos',
    'Packs',
    'Gratuites',
  ];

  static const List<_Product> _products = [
    _Product(
      name: 'Thon entier',
      category: 'Alimentaire',
      price: '5 dt',
      badge: '-20%',
      imageColors: [Color(0xFFFFF1E6), Color(0xFFD97706)],
      icon: Icons.set_meal_outlined,
    ),
    _Product(
      name: 'Eau minerale 1.5L',
      category: 'Boissons',
      price: '8 dt',
      badge: 'Stock',
      imageColors: [Color(0xFFE0F2FE), Color(0xFF2563EB)],
      icon: Icons.water_drop_outlined,
    ),
    _Product(
      name: 'Pate spaghetti',
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
      name: 'Huile d olive 1L',
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

  @override
  Widget build(BuildContext context) {
    final activeCategory = _categories[_selectedCategory];
    final filteredProducts = _filterProducts(activeCategory.value);

    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  children: [
                    _Header(onLogout: () => _logout(context)),
                    const SizedBox(height: 16),
                    const _SearchBar(),
                    const SizedBox(height: 16),
                    _CategorySelector(
                      categories: _categories,
                      subCategories: _subCategories,
                      selectedIndex: _selectedCategory,
                      selectedSubIndex: _selectedSubCategory,
                      onSelected: (index) {
                        setState(() {
                          _selectedCategory = index;
                          _selectedSubCategory = 0;
                        });
                      },
                      onSubSelected: (index) {
                        setState(() => _selectedSubCategory = index);
                      },
                    ),
                    const SizedBox(height: 14),
                    _SectionHeader(count: filteredProducts.length),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 112),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final crossAxisCount = width >= 560 ? 3 : 2;

                  return SliverGrid.builder(
                    itemCount: filteredProducts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.71,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                    ),
                    itemBuilder: (context, index) {
                      return _ProductCard(product: filteredProducts[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _CatalogNavigationBar(),
    );
  }

  List<_Product> _filterProducts(String category) {
    final productsByCategory = category == 'Promo'
        ? _products.where((product) => product.badge != null)
        : _products.where((product) => product.category == category);

    if (_selectedSubCategory == 1) {
      return productsByCategory
          .where((product) => product.badge != null)
          .toList();
    }

    return productsByCategory.toList();
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_deepTeal, _primary],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x242563EB),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 25),
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
                  color: _ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Catalogue commercial',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        _RoundIconButton(
          tooltip: 'Notifications',
          icon: Icons.notifications_none_rounded,
          onPressed: () {},
        ),
        const SizedBox(width: 8),
        _RoundIconButton(
          tooltip: 'Deconnexion',
          icon: Icons.logout_rounded,
          onPressed: onLogout,
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            textInputAction: TextInputAction.search,
            style: const TextStyle(
              color: _ink,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Rechercher produits, SKU...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 21,
                color: _muted,
              ),
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              filled: true,
              fillColor: _surface,
              border: _inputBorder(_line),
              enabledBorder: _inputBorder(_line),
              focusedBorder: _inputBorder(_primary, width: 1.6),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _RoundIconButton(
          tooltip: 'Filtres',
          icon: Icons.tune_rounded,
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
    required this.onSelected,
    required this.onSubSelected,
  });

  final List<_Category> categories;
  final List<String> subCategories;
  final int selectedIndex;
  final int selectedSubIndex;
  final ValueChanged<int> onSelected;
  final ValueChanged<int> onSubSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                for (var index = 0; index < categories.length; index++)
                  Expanded(
                    child: _CategoryBlock(
                      category: categories[index],
                      selected: selectedIndex == index,
                      onPressed: () => onSelected(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: _surface,
            border: Border.all(color: _line),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x080F172A),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              for (var index = 0; index < subCategories.length; index++)
                Expanded(
                  child: _SubCategoryBlock(
                    label: subCategories[index],
                    selected: selectedSubIndex == index,
                    onPressed: () => onSubSelected(index),
                  ),
                ),
            ],
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
      color: category.color,
      child: InkWell(
        onTap: onPressed,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.icon, color: Colors.white, size: 17),
                const SizedBox(height: 4),
                Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (selected)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(height: 4, color: Colors.white),
              ),
          ],
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
      color: selected ? _primary : _surface,
      child: InkWell(
        onTap: onPressed,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF475569),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Articles disponibles',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _ink,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            '$count produits',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final _Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _ProductVisual(product: product),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    height: 1.18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.price,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    SizedBox.square(
                      dimension: 34,
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.add_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
        Positioned(
          right: -18,
          top: -18,
          child: _BannerCircle(size: 74, opacity: 0.24),
        ),
        Positioned(
          left: -22,
          bottom: -24,
          child: _BannerCircle(size: 88, opacity: 0.18),
        ),
        Center(
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xD9FFFFFF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(product.icon, color: const Color(0xFF111827), size: 34),
          ),
        ),
        if (product.badge != null)
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF2F2F),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9.5,
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
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  final String tooltip;
  final IconData icon;
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

OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: width),
  );
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
