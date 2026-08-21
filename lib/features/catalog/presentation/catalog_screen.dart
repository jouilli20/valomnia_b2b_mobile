import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/presentation/language_selector.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../../cart/presentation/cart_screen.dart';
import '../../customer/presentation/customer_profile_screen.dart';
import '../../orders/presentation/order_history_screen.dart';
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
    final title = _tabs[_selectedTabIndex].label(context);

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
          const LanguageSelector(),
          IconButton(
            tooltip: context.l10n.text('logout'),
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
            onAllSelected: () => _selectContent(0),
            onCategorySelected: _showCategoryItems,
          ),
          1 => CartScreen(onContinueShopping: () => _selectContent(0)),
          2 => const OrderHistoryScreen(),
          3 => const CustomerProfileScreen(),
          _ => _TabPlaceholder(tab: _tabs[_selectedTabIndex]),
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: _selectTab,
        backgroundColor: _CatalogColors.surface,
        indicatorColor: _CatalogColors.primary,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon, color: Colors.white),
              label: tab.label(context),
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
    required this.onAllSelected,
    required this.onCategorySelected,
  });

  final int selectedIndex;
  final String? selectedCategoryId;
  final String? selectedCategoryName;
  final VoidCallback onAllSelected;
  final ValueChanged<Category> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTabletHome = constraints.maxWidth >= 840 && selectedIndex == 0;

        if (useTabletHome) {
          return Row(
            children: [
              _TabletCategoryRail(
                selectedCategoryId: selectedCategoryId,
                onAllSelected: onAllSelected,
                onCategorySelected: onCategorySelected,
              ),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: _CatalogColors.darkBorder,
              ),
              Expanded(
                child: HomeScreen(
                  key: ValueKey('home:${selectedCategoryId ?? 'all'}'),
                  categoryId: selectedCategoryId,
                  categoryName: selectedCategoryName,
                ),
              ),
            ],
          );
        }

        return _MobileCatalogContent(
          selectedIndex: selectedIndex,
          selectedCategoryId: selectedCategoryId,
          selectedCategoryName: selectedCategoryName,
          onCategorySelected: onCategorySelected,
        );
      },
    );
  }
}

class _MobileCatalogContent extends StatelessWidget {
  const _MobileCatalogContent({
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

class _TabletCategoryRail extends ConsumerWidget {
  const _TabletCategoryRail({
    required this.selectedCategoryId,
    required this.onAllSelected,
    required this.onCategorySelected,
  });

  final String? selectedCategoryId;
  final VoidCallback onAllSelected;
  final ValueChanged<Category> onCategorySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SizedBox(
      width: 116,
      child: ColoredBox(
        color: _CatalogColors.surface,
        child: SafeArea(
          top: false,
          bottom: false,
          child: ref
              .watch(categoriesProvider)
              .when(
                loading: () => const Center(
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: _CatalogColors.primary,
                    ),
                  ),
                ),
                error: (_, _) => IconButton(
                  tooltip: l10n.text('retry'),
                  onPressed: () => ref.invalidate(categoriesProvider),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: _CatalogColors.primary,
                  ),
                ),
                data: (rawCategories) {
                  final categories = _CatalogHierarchy.from(
                    rawCategories,
                  ).groups;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 18),
                    children: [
                      _TabletRailAction(
                        icon: Icons.arrow_back_rounded,
                        label: l10n.text('back'),
                        onTap: onAllSelected,
                      ),
                      const SizedBox(height: 8),
                      _TabletRailAction(
                        icon: Icons.list_rounded,
                        label: l10n.text('all'),
                        selected: selectedCategoryId == null,
                        onTap: onAllSelected,
                      ),
                      const SizedBox(height: 8),
                      for (final category in categories)
                        _TabletRailCategoryTile(
                          category: category,
                          selectedCategoryId: selectedCategoryId,
                          onSelected: onCategorySelected,
                        ),
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }
}

class _TabletRailAction extends StatelessWidget {
  const _TabletRailAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _CatalogColors.primary : _CatalogColors.muted;

    return Tooltip(
      message: label,
      child: Material(
        color: selected ? _CatalogColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 66,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
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

class _TabletRailCategoryTile extends StatelessWidget {
  const _TabletRailCategoryTile({
    required this.category,
    required this.selectedCategoryId,
    required this.onSelected,
    this.depth = 0,
  });

  final Category category;
  final String? selectedCategoryId;
  final ValueChanged<Category> onSelected;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final selected = selectedCategoryId == category.id;
    final children = category.children.take(3);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: depth * 6.0, bottom: 8),
          child: Tooltip(
            message: category.name,
            child: Material(
              color: selected ? _CatalogColors.primarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => onSelected(category),
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 76,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox.square(
                            dimension: 36,
                            child: _CategoryImage(
                              imageUrl: category.imageUrl,
                              icon: category.children.isEmpty
                                  ? Icons.inventory_2_outlined
                                  : Icons.category_outlined,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          category.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? _CatalogColors.primary
                                : _CatalogColors.ink,
                            fontSize: 10,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        for (final child in children)
          _TabletRailCategoryTile(
            category: child,
            selectedCategoryId: selectedCategoryId,
            onSelected: onSelected,
            depth: depth + 1,
          ),
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
    final l10n = context.l10n;
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
                l10n.text('catalog'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _CatalogColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _CatalogDrawerItem(
              label: l10n.text('items'),
              icon: Icons.inventory_2_outlined,
              selectedIcon: Icons.inventory_2_rounded,
              selected: selectedIndex == 0,
              onTap: () => _selectAndClose(context, 0),
            ),
            const SizedBox(height: 4),
            _CatalogDrawerItem(
              label: l10n.text('categories'),
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
    final l10n = context.l10n;
    return ref
        .watch(categoriesProvider)
        .when(
          loading: () => _StateView(
            icon: Icons.hourglass_top_rounded,
            title: l10n.text('loadingCatalog'),
            message: l10n.text('pleaseWait'),
            showProgress: true,
          ),
          error: (error, _) => _StateView(
            icon: Icons.wifi_off_rounded,
            title: l10n.text('catalogLoadFailed'),
            message: error.toString(),
            actionLabel: l10n.text('retry'),
            onAction: () => ref.invalidate(categoriesProvider),
          ),
          data: _buildCategoryList,
        );
  }

  Widget _buildCategoryList(List<dynamic> rawCategories) {
    final l10n = context.l10n;
    final hierarchy = _CatalogHierarchy.from(rawCategories);
    final categories = hierarchy.filter(_query);

    return RefreshIndicator(
      color: _CatalogColors.primary,
      onRefresh: _refreshCategories,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _CategorySearchHeaderDelegate(child: _buildSearchField()),
          ),
          if (hierarchy.groups.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _StateView(
                icon: Icons.inventory_2_outlined,
                title: l10n.text('noCategoryFound'),
                message: l10n.text('pullToRefreshCatalog'),
              ),
            )
          else if (categories.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _StateView(
                icon: Icons.search_off_rounded,
                title: l10n.text('noResult'),
                message: l10n.text('tryAnotherKeyword'),
                actionLabel: l10n.text('clear'),
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
    final l10n = context.l10n;
    return SizedBox(
      height: 54,
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: (value) => setState(() => _query = value),
        style: const TextStyle(
          color: _CatalogColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: l10n.text('searchCategory'),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: l10n.text('clear'),
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
      ),
    );
  }
}

class _CategorySearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _CategorySearchHeaderDelegate({required this.child});

  static const _extent = 72.0;

  final Widget child;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: _CatalogColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CategorySearchHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
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
                        tooltip: _expanded
                            ? context.l10n.text('collapse')
                            : context.l10n.text('expand'),
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
      title: tab.label(context),
      message: context.l10n.text('sectionComingSoon'),
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
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
  });

  final String labelKey;
  final IconData icon;
  final IconData selectedIcon;

  String label(BuildContext context) => context.l10n.text(labelKey);
}

class _CatalogColors {
  const _CatalogColors._();

  static const background = Color(0xFF031126);
  static const darkBorder = Color(0xFF17335D);
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
    labelKey: 'catalog',
    icon: Icons.layers_outlined,
    selectedIcon: Icons.layers_rounded,
  ),
  _CatalogTab(
    labelKey: 'cart',
    icon: Icons.shopping_cart_outlined,
    selectedIcon: Icons.shopping_cart_rounded,
  ),
  _CatalogTab(
    labelKey: 'orders',
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment_rounded,
  ),
  _CatalogTab(
    labelKey: 'profile',
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
