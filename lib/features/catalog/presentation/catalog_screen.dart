import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  String? _selectedParentKey;
  int _selectedTabIndex = _catalogTabIndex;

  static const _catalogTabIndex = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _updateQuery(String value) => setState(() => _query = value);

  void _clearQuery() {
    _searchController.clear();
    _updateQuery('');
  }

  void _selectParent(String key) {
    if (_selectedParentKey == key) return;
    setState(() => _selectedParentKey = key);
  }

  void _selectTab(int index) {
    if (_selectedTabIndex == index) return;
    setState(() => _selectedTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: _CatalogTheme.background,
      bottomNavigationBar: _CatalogBottomNavigation(
        selectedIndex: _selectedTabIndex,
        onSelected: _selectTab,
      ),
      body: SafeArea(
        bottom: false,
        child: _selectedTabIndex == _catalogTabIndex
            ? categoriesState.when(
                loading: () => const _LoadingView(),
                error: (error, _) => _CatalogErrorView(
                  message: error.toString(),
                  onRetry: _reloadCategories,
                  onLogout: () => _logout(context),
                ),
                data: _buildCatalogContent,
              )
            : _TabPlaceholder(index: _selectedTabIndex),
      ),
    );
  }

  Widget _buildCatalogContent(List<dynamic> categories) {
    final hierarchy = _CatalogHierarchy.from(categories);
    final visibleGroups = hierarchy.filter(_query);
    final selectedGroup = _resolveSelectedGroup(visibleGroups);

    return _CatalogContent(
      searchController: _searchController,
      query: _query,
      groups: visibleGroups,
      selectedGroup: selectedGroup,
      hasAnyCategory: hierarchy.groups.isNotEmpty,
      onQueryChanged: _updateQuery,
      onClearQuery: _clearQuery,
      onRefresh: _refreshCategories,
      onLogout: () => _logout(context),
      onParentSelected: _selectParent,
    );
  }

  _CategoryGroup? _resolveSelectedGroup(List<_CategoryGroup> groups) {
    if (groups.isEmpty) return null;

    final selectedKey = _selectedParentKey;
    if (selectedKey != null) {
      for (final group in groups) {
        if (group.parent.key == selectedKey) return group;
      }
    }

    return groups.first;
  }
}

class _CatalogTheme {
  const _CatalogTheme._();

  static const background = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const fieldFill = Color(0xFFF8FAFC);
  static const softSurface = Color(0xFFF1F5F9);
  static const border = Color(0xFFE5EAF1);
  static const inputBorder = Color(0xFFE2E8F0);
  static const primary = Color(0xFF2563EB);
  static const primarySoft = Color(0xFFEAF2FF);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);

  static const panelShadow = [
    BoxShadow(color: Color(0x120F172A), blurRadius: 24, offset: Offset(0, 14)),
  ];

  static OutlineInputBorder inputBorderFor(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _CatalogContent extends StatelessWidget {
  const _CatalogContent({
    required this.searchController,
    required this.query,
    required this.groups,
    required this.selectedGroup,
    required this.hasAnyCategory,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onRefresh,
    required this.onLogout,
    required this.onParentSelected,
  });

  final TextEditingController searchController;
  final String query;
  final List<_CategoryGroup> groups;
  final _CategoryGroup? selectedGroup;
  final bool hasAnyCategory;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final Future<void> Function() onRefresh;
  final VoidCallback onLogout;
  final ValueChanged<String> onParentSelected;

  @override
  Widget build(BuildContext context) {
    final state = _emptyState;

    return RefreshIndicator(
      color: _CatalogTheme.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _CatalogHeader(
              controller: searchController,
              query: query,
              onChanged: onQueryChanged,
              onClear: onClearQuery,
              onRefresh: onRefresh,
              onLogout: onLogout,
            ),
          ),
          if (groups.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Categories',
                subtitle: '${groups.length} familles disponibles',
              ),
            ),
            SliverToBoxAdapter(
              child: _ParentCategoryStrip(
                groups: groups,
                selectedKey: selectedGroup!.parent.key,
                onSelected: onParentSelected,
              ),
            ),
          ],
          if (state != null)
            SliverFillRemaining(hasScrollBody: false, child: state)
          else ...[
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: selectedGroup!.parent.name,
                subtitle: '${selectedGroup!.children.length} sous-categories',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              sliver: SliverList.separated(
                itemCount: selectedGroup!.children.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _SubcategoryRow(
                    category: selectedGroup!.children[index],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget? get _emptyState {
    if (!hasAnyCategory) {
      return const _StatePanel(
        icon: Icons.inventory_2_outlined,
        title: 'Aucune categorie trouvee',
        message: 'Tirez vers le bas pour actualiser le catalogue.',
      );
    }

    if (groups.isEmpty) {
      return _StatePanel(
        icon: Icons.search_off_rounded,
        title: 'Aucun resultat',
        message: 'Essayez un autre mot-cle.',
        actionLabel: 'Effacer',
        onAction: onClearQuery,
      );
    }

    if (selectedGroup?.children.isEmpty ?? true) {
      return _StatePanel(
        icon: Icons.category_outlined,
        title: selectedGroup?.parent.name ?? 'Categorie',
        message: 'Aucune sous-categorie disponible.',
      );
    }

    return null;
  }
}

class _CatalogHeader extends StatelessWidget {
  const _CatalogHeader({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.onRefresh,
    required this.onLogout,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final Future<void> Function() onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SimpleCatalogTopBar(onRefresh: onRefresh, onLogout: onLogout),
          const SizedBox(height: 12),
          _SearchPanel(
            controller: controller,
            query: query,
            onChanged: onChanged,
            onClear: onClear,
          ),
        ],
      ),
    );
  }
}

class _SimpleCatalogTopBar extends StatelessWidget {
  const _SimpleCatalogTopBar({required this.onRefresh, required this.onLogout});

  final Future<void> Function() onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _CatalogTheme.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: _CatalogTheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Catalogue',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _CatalogTheme.ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _HeaderIconButton(
          icon: Icons.sync_rounded,
          tooltip: 'Actualiser',
          onPressed: () {
            onRefresh();
          },
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: Icons.logout_rounded,
          tooltip: 'Deconnexion',
          onPressed: onLogout,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: _CatalogTheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _CatalogTheme.border),
            ),
            child: Icon(icon, color: _CatalogTheme.muted, size: 21),
          ),
        ),
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: _CatalogTheme.ink,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Rechercher une categorie',
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: _CatalogTheme.muted,
          size: 23,
        ),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Effacer',
                onPressed: onClear,
                icon: const Icon(
                  Icons.close_rounded,
                  color: _CatalogTheme.muted,
                  size: 22,
                ),
              ),
        hintStyle: const TextStyle(
          color: _CatalogTheme.faint,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        filled: true,
        fillColor: _CatalogTheme.fieldFill,
        border: _CatalogTheme.inputBorderFor(_CatalogTheme.inputBorder),
        enabledBorder: _CatalogTheme.inputBorderFor(_CatalogTheme.inputBorder),
        focusedBorder: _CatalogTheme.inputBorderFor(
          _CatalogTheme.primary,
          width: 1.6,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _CatalogTheme.ink,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _CatalogTheme.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

class _ParentCategoryStrip extends StatelessWidget {
  const _ParentCategoryStrip({
    required this.groups,
    required this.selectedKey,
    required this.onSelected,
  });

  final List<_CategoryGroup> groups;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 174,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        itemCount: groups.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final group = groups[index];
          return _ParentCategoryTile(
            category: group.parent,
            childCount: group.children.length,
            isSelected: group.parent.key == selectedKey,
            onTap: () => onSelected(group.parent.key),
          );
        },
      ),
    );
  }
}

class _ParentCategoryTile extends StatelessWidget {
  const _ParentCategoryTile({
    required this.category,
    required this.childCount,
    required this.isSelected,
    required this.onTap,
  });

  final _CategoryItem category;
  final int childCount;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _CatalogTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSelected
                    ? _CatalogTheme.primary
                    : _CatalogTheme.border,
                width: isSelected ? 1.6 : 1,
              ),
              boxShadow: isSelected ? _CatalogTheme.panelShadow : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 86,
                    child: _CategoryImage(
                      imageUrl: category.imageUrl,
                      icon: Icons.category_outlined,
                      iconSize: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? _CatalogTheme.primary
                        : _CatalogTheme.ink,
                    fontSize: 13,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '$childCount sous-categories',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _CatalogTheme.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubcategoryRow extends StatelessWidget {
  const _SubcategoryRow({required this.category});

  final _CategoryItem category;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _CatalogTheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          // TODO: open products for this category when the products screen exists.
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 72,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _CatalogTheme.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: _CategoryImage(
                    imageUrl: category.imageUrl,
                    icon: Icons.inventory_2_outlined,
                    iconSize: 25,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _CatalogTheme.ink,
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
                          color: _CatalogTheme.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: _CatalogTheme.faint,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({
    required this.imageUrl,
    required this.icon,
    required this.iconSize,
  });

  final String? imageUrl;
  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return _CategoryImagePlaceholder(icon: icon, iconSize: iconSize);
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) {
        return _CategoryImagePlaceholder(icon: icon, iconSize: iconSize);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _CategoryImagePlaceholder(icon: icon, iconSize: iconSize);
      },
    );
  }
}

class _CategoryImagePlaceholder extends StatelessWidget {
  const _CategoryImagePlaceholder({required this.icon, required this.iconSize});

  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: _CatalogTheme.softSurface),
      child: Center(
        child: Icon(icon, color: _CatalogTheme.muted, size: iconSize),
      ),
    );
  }
}

class _CatalogBottomNavigation extends StatelessWidget {
  const _CatalogBottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _items = [
    _BottomNavItem(icon: Icons.home_rounded, label: 'HOME'),
    _BottomNavItem(icon: Icons.layers_rounded, label: 'CATALOG'),
    _BottomNavItem(icon: Icons.shopping_cart_rounded, label: 'CART'),
    _BottomNavItem(icon: Icons.assignment_rounded, label: 'ORDERS'),
    _BottomNavItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 68,
        decoration: const BoxDecoration(
          color: _CatalogTheme.surface,
          border: Border(top: BorderSide(color: _CatalogTheme.border)),
          boxShadow: [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 18,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var index = 0; index < _items.length; index++)
              Expanded(
                child: _BottomNavButton(
                  item: _items[index],
                  isSelected: selectedIndex == index,
                  onTap: () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _BottomNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? _CatalogTheme.primary : _CatalogTheme.muted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: isSelected ? 34 : 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected
                      ? _CatalogTheme.primarySoft
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  item.icon,
                  color: color,
                  size: isSelected ? 20 : 18,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 8.5,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: 34,
        child: CircularProgressIndicator(
          color: _CatalogTheme.primary,
          strokeWidth: 3,
        ),
      ),
    );
  }
}

class _CatalogErrorView extends StatelessWidget {
  const _CatalogErrorView({
    required this.message,
    required this.onRetry,
    required this.onLogout,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: _SimpleCatalogTopBar(
              onRefresh: () async => onRetry(),
              onLogout: onLogout,
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: _StatePanel(
            icon: Icons.wifi_off_rounded,
            title: 'Impossible de charger le catalogue',
            message: message,
            actionLabel: 'Reessayer',
            onAction: onRetry,
          ),
        ),
      ],
    );
  }
}

class _TabPlaceholder extends StatelessWidget {
  const _TabPlaceholder({required this.index});

  final int index;

  static const _titles = ['Home', 'Catalog', 'Cart', 'Orders', 'Profile'];
  static const _icons = [
    Icons.home_rounded,
    Icons.layers_rounded,
    Icons.shopping_cart_rounded,
    Icons.assignment_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final safeIndex = index.clamp(0, _titles.length - 1);

    return _StatePanel(
      icon: _icons[safeIndex],
      title: _titles[safeIndex],
      message: 'Cette section sera branchee prochainement.',
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
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
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _CatalogTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _CatalogTheme.border),
            boxShadow: _CatalogTheme.panelShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _CatalogTheme.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: _CatalogTheme.primary, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _CatalogTheme.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _CatalogTheme.muted,
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _CatalogTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text(actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogHierarchy {
  const _CatalogHierarchy(this.groups);

  final List<_CategoryGroup> groups;

  factory _CatalogHierarchy.from(List<dynamic> categories) {
    final byKey = <String, dynamic>{};
    for (final category in categories) {
      final key = _categoryKey(category);
      if (key != null) byKey[key] = category;
    }

    final groupsByKey = <String, _MutableCategoryGroup>{};

    _MutableCategoryGroup ensureGroup(String key, dynamic parentSource) {
      final existing = groupsByKey[key];
      if (existing != null) {
        existing.parent = _CategoryItem.from(parentSource, fallbackKey: key);
        return existing;
      }

      final group = _MutableCategoryGroup(
        parent: _CategoryItem.from(parentSource, fallbackKey: key),
      );
      groupsByKey[key] = group;
      return group;
    }

    for (final category in categories) {
      final categoryKey = _categoryKey(category);
      if (categoryKey == null) continue;

      final parentSource = _parentCategory(category);
      final parentKey = _parentKey(category);

      if (parentKey == null || parentKey == categoryKey) {
        ensureGroup(categoryKey, category);
        continue;
      }

      ensureGroup(
        parentKey,
        parentSource ?? byKey[parentKey] ?? _fallbackParent(parentKey),
      ).addChild(_CategoryItem.from(category, fallbackKey: categoryKey));
    }

    final groups = groupsByKey.values
        .map((group) => group.freeze())
        .where((group) => group.parent.name.trim().isNotEmpty)
        .toList(growable: false);

    return _CatalogHierarchy(groups);
  }

  List<_CategoryGroup> filter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return groups;

    return groups
        .map((group) {
          final parentMatches = group.parent.matches(q);
          final children = parentMatches
              ? group.children
              : group.children.where((child) => child.matches(q)).toList();

          if (!parentMatches && children.isEmpty) return null;
          return _CategoryGroup(parent: group.parent, children: children);
        })
        .whereType<_CategoryGroup>()
        .toList(growable: false);
  }

  static dynamic _fallbackParent(String key) {
    final id = key.startsWith('id:') ? key.substring(3) : key;
    return {'id': id, 'name': 'Categorie $id'};
  }
}

class _MutableCategoryGroup {
  _MutableCategoryGroup({required this.parent});

  _CategoryItem parent;
  final List<_CategoryItem> children = [];
  final Set<String> _childKeys = {};

  void addChild(_CategoryItem child) {
    if (_childKeys.add(child.key)) children.add(child);
  }

  _CategoryGroup freeze() {
    return _CategoryGroup(
      parent: parent,
      children: List.unmodifiable(children),
    );
  }
}

class _CategoryGroup {
  const _CategoryGroup({required this.parent, required this.children});

  final _CategoryItem parent;
  final List<_CategoryItem> children;
}

class _CategoryItem {
  const _CategoryItem({
    required this.key,
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  final String key;
  final String name;
  final String? description;
  final String? imageUrl;

  factory _CategoryItem.from(dynamic category, {required String fallbackKey}) {
    return _CategoryItem(
      key: _categoryKey(category) ?? fallbackKey,
      name: _categoryName(category),
      description: _categoryDescription(category),
      imageUrl: _categoryImageUrl(category),
    );
  }

  bool matches(String query) {
    return name.toLowerCase().contains(query) ||
        (description?.toLowerCase().contains(query) ?? false);
  }
}

String _categoryName(dynamic category) {
  if (category is! Map) return 'Categorie';
  return _clean(category['name']) ?? 'Categorie';
}

String? _categoryDescription(dynamic category) {
  if (category is! Map) return null;

  for (final key in ['description', 'shortDescription', 'code', 'reference']) {
    final value = _clean(category[key]);
    if (value != null) return value;
  }

  return null;
}

String? _categoryImageUrl(dynamic category) {
  if (category is! Map) return null;

  for (final key in ['image', 'picture', 'thumbnail', 'imageUrl']) {
    final raw = _clean(category[key]);
    if (raw == null) continue;

    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme) return raw;

    return Uri.parse('https://agro.valomnia.com').resolve(raw).toString();
  }

  return null;
}

String? _categoryKey(dynamic category) {
  if (category is! Map) return null;

  for (final entry in const [
    MapEntry('id', 'id'),
    MapEntry('href', 'href'),
    MapEntry('reference', 'ref'),
    MapEntry('name', 'name'),
  ]) {
    final value = _clean(category[entry.key]);
    if (value != null) return '${entry.value}:$value';
  }

  return null;
}

String? _parentKey(dynamic category) {
  if (category is! Map) return null;

  final nestedParentKey = _categoryKey(_parentCategory(category));
  if (nestedParentKey != null) return nestedParentKey;

  final parentId = _clean(category['parentId']);
  return parentId == null ? null : 'id:$parentId';
}

Map<dynamic, dynamic>? _parentCategory(dynamic category) {
  if (category is! Map) return null;
  final parent = category['parentCategory'];
  return parent is Map ? parent : null;
}

String? _clean(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}
