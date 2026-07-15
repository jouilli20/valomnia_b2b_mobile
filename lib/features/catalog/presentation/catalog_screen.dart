import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../../cart/presentation/cart_screen.dart';
import '../domain/category.dart';
import '../providers/catalog_provider.dart';
import 'home_screen.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  int _selectedTabIndex = _homeTabIndex;
  int _selectedContentIndex = 0;
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  static const _homeTabIndex = 0;

  Future<void> _logout() async {
    await SecureStorageService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _selectTab(int index) {
    if (_selectedTabIndex == index) return;
    setState(() => _selectedTabIndex = index);
  }

  void _selectContent(int index) {
    final alreadySelected =
        _selectedTabIndex == _homeTabIndex && _selectedContentIndex == index;
    final keepsSameArticleFilter = index != 0 || _selectedCategoryId == null;
    if (alreadySelected && keepsSameArticleFilter) {
      return;
    }
    setState(() {
      _selectedTabIndex = _homeTabIndex;
      _selectedContentIndex = index;
      if (index == 0) {
        _selectedCategoryId = null;
        _selectedCategoryName = null;
      }
    });
  }

  void _showCategoryItems(Category category) {
    setState(() {
      _selectedTabIndex = _homeTabIndex;
      _selectedContentIndex = 0;
      _selectedCategoryId = category.id;
      _selectedCategoryName = category.name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _tabs[_selectedTabIndex].label;

    return Scaffold(
      backgroundColor: _CatalogColors.background,
      drawer: _CatalogDrawer(
        selectedIndex: _selectedContentIndex,
        onSelected: _selectContent,
      ),
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: _CatalogColors.background,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w900,
        ),
        actions: [
          IconButton(
            tooltip: 'Deconnexion',
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: switch (_selectedTabIndex) {
          _homeTabIndex => _CatalogContent(
            selectedIndex: _selectedContentIndex,
            selectedCategoryId: _selectedCategoryId,
            selectedCategoryName: _selectedCategoryName,
            onCategorySelected: _showCategoryItems,
          ),
          1 => CartScreen(onContinueShopping: () => _selectContent(0)),
          _ => _TabPlaceholder(tab: _tabs[_selectedTabIndex]),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: _selectTab,
        backgroundColor: _CatalogColors.surface,
        indicatorColor: _CatalogColors.primarySoft,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _CatalogContent extends StatelessWidget {
  const _CatalogContent({
    required this.selectedIndex,
    required this.selectedCategoryId,
    required this.selectedCategoryName,
    required this.onCategorySelected,
  });

  final int selectedIndex;
  final String? selectedCategoryId;
  final String? selectedCategoryName;
  final ValueChanged<Category> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: selectedIndex,
      children: [
        HomeScreen(
          key: ValueKey('home:${selectedCategoryId ?? 'all'}'),
          categoryId: selectedCategoryId,
          categoryName: selectedCategoryName,
        ),
        _CatalogCategoriesView(onCategorySelected: onCategorySelected),
      ],
    );
  }
}

class _CatalogDrawer extends StatelessWidget {
  const _CatalogDrawer({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _CatalogColors.surface,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
              child: Text(
                'Catalogue',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _CatalogColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _CatalogDrawerItem(
              label: 'Articles',
              icon: Icons.inventory_2_outlined,
              selectedIcon: Icons.inventory_2_rounded,
              selected: selectedIndex == 0,
              onTap: () => _selectAndClose(context, 0),
            ),
            const SizedBox(height: 4),
            _CatalogDrawerItem(
              label: 'Categories',
              icon: Icons.category_outlined,
              selectedIcon: Icons.category_rounded,
              selected: selectedIndex == 1,
              onTap: () => _selectAndClose(context, 1),
            ),
          ],
        ),
      ),
    );
  }

  void _selectAndClose(BuildContext context, int index) {
    Navigator.pop(context);
    onSelected(index);
  }
}

class _CatalogDrawerItem extends StatelessWidget {
  const _CatalogDrawerItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? _CatalogColors.primary : _CatalogColors.muted;
    return Tooltip(
      message: label,
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: Material(
          color: selected ? _CatalogColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(selected ? selectedIcon : icon, color: foreground),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogCategoriesView extends ConsumerStatefulWidget {
  const _CatalogCategoriesView({required this.onCategorySelected});

  final ValueChanged<Category> onCategorySelected;

  @override
  ConsumerState<_CatalogCategoriesView> createState() =>
      _CatalogCategoriesViewState();
}

class _CatalogCategoriesViewState
    extends ConsumerState<_CatalogCategoriesView> {
  final _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshCategories() async {
    ref.invalidate(categoriesProvider);
    await ref.read(categoriesProvider.future);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(categoriesProvider)
        .when(
          loading: () => const _StateView(
            icon: Icons.hourglass_top_rounded,
            title: 'Chargement du catalogue',
            message: 'Veuillez patienter.',
            showProgress: true,
          ),
          error: (error, _) => _StateView(
            icon: Icons.wifi_off_rounded,
            title: 'Impossible de charger le catalogue',
            message: error.toString(),
            actionLabel: 'Reessayer',
            onAction: () => ref.invalidate(categoriesProvider),
          ),
          data: _buildCategoryList,
        );
  }

  Widget _buildCategoryList(List<dynamic> rawCategories) {
    final hierarchy = _CatalogHierarchy.from(rawCategories);
    final categories = hierarchy.filter(_query);

    return RefreshIndicator(
      color: _CatalogColors.primary,
      onRefresh: _refreshCategories,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            sliver: SliverToBoxAdapter(child: _buildSearchField()),
          ),
          if (hierarchy.groups.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _StateView(
                icon: Icons.inventory_2_outlined,
                title: 'Aucune categorie trouvee',
                message: 'Tirez vers le bas pour actualiser le catalogue.',
              ),
            )
          else if (categories.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _StateView(
                icon: Icons.search_off_rounded,
                title: 'Aucun resultat',
                message: 'Essayez un autre mot-cle.',
                actionLabel: 'Effacer',
                onAction: _clearSearch,
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.separated(
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _CategoryTreeTile(
                    category: categories[index],
                    onSelected: widget.onCategorySelected,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged: (value) => setState(() => _query = value),
      style: const TextStyle(
        color: _CatalogColors.ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'Rechercher une categorie',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Effacer',
                onPressed: _clearSearch,
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: _CatalogColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: _inputBorder(_CatalogColors.border),
        enabledBorder: _inputBorder(_CatalogColors.border),
        focusedBorder: _inputBorder(_CatalogColors.primary, width: 1.5),
      ),
    );
  }
}

class _CategoryTreeTile extends StatefulWidget {
  const _CategoryTreeTile({
    required this.category,
    required this.onSelected,
    this.depth = 0,
  });

  final Category category;
  final ValueChanged<Category> onSelected;
  final int depth;

  @override
  State<_CategoryTreeTile> createState() => _CategoryTreeTileState();
}

class _CategoryTreeTileState extends State<_CategoryTreeTile> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category;
    final hasChildren = category.children.isNotEmpty;
    final horizontalIndent = widget.depth * 14.0;

    return Material(
      color: _CatalogColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _CatalogColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => widget.onSelected(category),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.fromLTRB(10 + horizontalIndent, 10, 10, 10),
                child: Row(
                  children: [
                    _CategoryAvatar(category: category),
                    const SizedBox(width: 12),
                    Expanded(child: _CategoryTitle(category: category)),
                    if (hasChildren) ...[
                      const SizedBox(width: 8),
                      _CountBadge(count: category.children.length),
                      IconButton(
                        tooltip: _expanded ? 'Reduire' : 'Developper',
                        visualDensity: VisualDensity.compact,
                        onPressed: _toggleExpanded,
                        icon: AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 180),
                          child: const Icon(Icons.expand_more_rounded),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (hasChildren && _expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  children: [
                    for (final child in category.children) ...[
                      _CategoryTreeTile(
                        category: child,
                        depth: widget.depth + 1,
                        onSelected: widget.onSelected,
                      ),
                      if (child != category.children.last)
                        const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryAvatar extends StatelessWidget {
  const _CategoryAvatar({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 54,
        height: 54,
        child: _CategoryImage(
          imageUrl: category.imageUrl,
          icon: category.children.isEmpty
              ? Icons.inventory_2_outlined
              : Icons.category_outlined,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _CategoryTitle extends StatelessWidget {
  const _CategoryTitle({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _CatalogColors.ink,
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (category.description != null) ...[
          const SizedBox(height: 4),
          Text(
            category.description!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _CatalogColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({
    required this.imageUrl,
    required this.icon,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final IconData icon;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) return _CategoryPlaceholder(icon: icon);

    return ColoredBox(
      color: _CatalogColors.softSurface,
      child: Padding(
        padding: fit == BoxFit.contain
            ? const EdgeInsets.all(6)
            : EdgeInsets.zero,
        child: Image.network(
          imageUrl!,
          fit: fit,
          errorBuilder: (_, _, _) => _CategoryPlaceholder(icon: icon),
          loadingBuilder: (context, child, progress) {
            return progress == null ? child : _CategoryPlaceholder(icon: icon);
          },
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 28),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: _CatalogColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count.toString(),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _CatalogColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CategoryPlaceholder extends StatelessWidget {
  const _CategoryPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _CatalogColors.softSurface,
      child: Center(child: Icon(icon, color: _CatalogColors.muted, size: 28)),
    );
  }
}

class _StateView extends StatelessWidget {
  const _StateView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showProgress)
              const CircularProgressIndicator(color: _CatalogColors.primary)
            else
              Icon(icon, color: _CatalogColors.primary, size: 38),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _CatalogColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _CatalogColors.muted,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({required this.tab});

  final _CatalogTab tab;

  @override
  Widget build(BuildContext context) {
    return _StateView(
      icon: tab.selectedIcon,
      title: tab.label,
      message: 'Cette section sera branchee prochainement.',
    );
  }
}

class _CatalogHierarchy {
  const _CatalogHierarchy(this.categories);

  final List<Category> categories;

  List<Category> get groups => categories;

  int get subcategoryCount {
    return categories.fold(
      0,
      (total, category) => total + category.descendantCount,
    );
  }

  factory _CatalogHierarchy.from(List<dynamic> categories) {
    return _CatalogHierarchy(
      _withoutHomeRoot(buildCategoryTree(categories, activeOnly: true)),
    );
  }

  List<Category> filter(String query) {
    return filterCategoryTree(categories, query);
  }
}

List<Category> _withoutHomeRoot(List<Category> categories) {
  final visibleCategories = <Category>[];

  for (final category in categories) {
    final isHomeRoot = category.name.trim().toLowerCase() == 'home';
    if (isHomeRoot) {
      visibleCategories.addAll(category.children);
    } else {
      visibleCategories.add(category);
    }
  }

  return List.unmodifiable(visibleCategories);
}

class _CatalogTab {
  const _CatalogTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _CatalogColors {
  const _CatalogColors._();

  static const background = Color(0xFF031126);
  static const surface = Colors.white;
  static const softSurface = Color(0xFFF1F5F9);
  static const border = Color(0xFFE5EAF1);
  static const primary = Color(0xFF2563EB);
  static const primarySoft = Color(0xFFEAF2FF);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
}

const _tabs = [
  _CatalogTab(
    label: 'Catalogue',
    icon: Icons.layers_outlined,
    selectedIcon: Icons.layers_rounded,
  ),
  _CatalogTab(
    label: 'Panier',
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart_rounded,
  ),
  _CatalogTab(
    label: 'Commandes',
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment_rounded,
  ),
  _CatalogTab(
    label: 'Profil',
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  ),
];

OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: width),
  );
}
