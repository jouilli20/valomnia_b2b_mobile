import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../providers/catalog_provider.dart';
import 'home_screen.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchController = TextEditingController();

  String _query = '';
  String? _selectedParentKey;
  int _selectedTabIndex = _homeTabIndex;

  static const _homeTabIndex = 0;
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

  Future<void> _logout() async {
    await SecureStorageService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  void _selectTab(int index) {
    if (_selectedTabIndex == index) return;
    setState(() => _selectedTabIndex = index);
  }

  void _selectParent(String key) {
    if (_selectedParentKey == key) return;
    setState(() => _selectedParentKey = key);
  }

  @override
  Widget build(BuildContext context) {
    final title = _tabs[_selectedTabIndex].label;

    return Scaffold(
      backgroundColor: _CatalogColors.background,
      appBar: AppBar(
        title: Text(title),
        centerTitle: false,
        backgroundColor: _CatalogColors.background,
        foregroundColor: _CatalogColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          color: _CatalogColors.ink,
          fontSize: 24,
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
          _homeTabIndex => const HomeScreen(),
          _catalogTabIndex => _buildCatalog(),
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

  Widget _buildCatalog() {
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
    final groups = hierarchy.filter(_query);
    final selectedGroup = _selectedGroup(groups);

    return RefreshIndicator(
      color: _CatalogColors.primary,
      onRefresh: _refreshCategories,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
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
          else if (groups.isEmpty)
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
            _SectionTitle(
              title: 'Categories',
              subtitle: '${groups.length} familles',
            ),
            SliverToBoxAdapter(
              child: _ParentCategoryList(
                groups: groups,
                selectedKey: selectedGroup!.parent.key,
                onSelected: _selectParent,
              ),
            ),
            _SectionTitle(
              title: selectedGroup.parent.name,
              subtitle: '${selectedGroup.children.length} sous-categories',
            ),
            if (selectedGroup.children.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _StateView(
                  icon: Icons.category_outlined,
                  title: 'Aucune sous-categorie',
                  message:
                      'Cette categorie ne contient pas encore de niveau enfant.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList.separated(
                  itemCount: selectedGroup.children.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    return _SubcategoryTile(
                      category: selectedGroup.children[index],
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
        fontSize: 16,
        fontWeight: FontWeight.w600,
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
        fillColor: _CatalogColors.field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _inputBorder(_CatalogColors.border),
        enabledBorder: _inputBorder(_CatalogColors.border),
        focusedBorder: _inputBorder(_CatalogColors.primary, width: 1.5),
      ),
    );
  }

  _CategoryGroup? _selectedGroup(List<_CategoryGroup> groups) {
    if (groups.isEmpty) return null;

    for (final group in groups) {
      if (group.parent.key == _selectedParentKey) return group;
    }

    return groups.first;
  }
}

class _ParentCategoryList extends StatelessWidget {
  const _ParentCategoryList({
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
      height: 146,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        itemCount: groups.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final group = groups[index];
          return _ParentCategoryTile(
            group: group,
            selected: group.parent.key == selectedKey,
            onTap: () => onSelected(group.parent.key),
          );
        },
      ),
    );
  }
}

class _ParentCategoryTile extends StatelessWidget {
  const _ParentCategoryTile({
    required this.group,
    required this.selected,
    required this.onTap,
  });

  final _CategoryGroup group;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      child: Material(
        color: selected ? _CatalogColors.primarySoft : _CatalogColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? _CatalogColors.primary
                    : _CatalogColors.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 70,
                    width: double.infinity,
                    child: _CategoryImage(
                      imageUrl: group.parent.imageUrl,
                      icon: Icons.category_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  group.parent.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? _CatalogColors.primary
                        : _CatalogColors.ink,
                    fontSize: 12.5,
                    height: 1.08,
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

class _SubcategoryTile extends StatelessWidget {
  const _SubcategoryTile({required this.category});

  final _CategoryItem category;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _CatalogColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 70,
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _CatalogColors.border),
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
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _CatalogColors.faint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({required this.imageUrl, required this.icon});

  final String? imageUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) return _CategoryPlaceholder(icon: icon);

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _CategoryPlaceholder(icon: icon),
      loadingBuilder: (context, child, progress) {
        return progress == null ? child : _CategoryPlaceholder(icon: icon);
      },
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _CatalogColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _CatalogColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
  const _CatalogHierarchy(this.groups);

  final List<_CategoryGroup> groups;

  factory _CatalogHierarchy.from(List<dynamic> categories) {
    final byKey = <String, dynamic>{};
    for (final category in categories) {
      final key = _categoryKey(category);
      if (key != null) byKey[key] = category;
    }

    final mutableGroups = <String, _MutableCategoryGroup>{};

    _MutableCategoryGroup ensureGroup(String key, dynamic source) {
      return mutableGroups.putIfAbsent(
        key,
        () => _MutableCategoryGroup(
          parent: _CategoryItem.from(source, fallbackKey: key),
        ),
      );
    }

    for (final category in categories) {
      final categoryKey = _categoryKey(category);
      if (categoryKey == null) continue;

      final parentKey = _parentKey(category);
      if (parentKey == null || parentKey == categoryKey) {
        ensureGroup(categoryKey, category);
        continue;
      }

      final parentSource =
          _parentCategory(category) ??
          byKey[parentKey] ??
          _fallbackParent(parentKey);
      ensureGroup(
        parentKey,
        parentSource,
      ).addChild(_CategoryItem.from(category, fallbackKey: categoryKey));
    }

    final groups = mutableGroups.values
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

          return parentMatches || children.isNotEmpty
              ? _CategoryGroup(parent: group.parent, children: children)
              : null;
        })
        .whereType<_CategoryGroup>()
        .toList(growable: false);
  }

  static Map<String, String> _fallbackParent(String key) {
    final id = key.startsWith('id:') ? key.substring(3) : key;
    return {'id': id, 'name': 'Categorie $id'};
  }
}

class _MutableCategoryGroup {
  _MutableCategoryGroup({required this.parent});

  _CategoryItem parent;
  final children = <_CategoryItem>[];
  final _childKeys = <String>{};

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

  static const background = Color(0xFFF4F7FB);
  static const surface = Colors.white;
  static const field = Color(0xFFF8FAFC);
  static const softSurface = Color(0xFFF1F5F9);
  static const border = Color(0xFFE5EAF1);
  static const primary = Color(0xFF2563EB);
  static const primarySoft = Color(0xFFEAF2FF);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);
}

const _tabs = [
  _CatalogTab(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
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
    if (raw != null) return _absoluteTenantUrl(raw);
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
  return text == null || text.isEmpty || text == 'null' ? null : text;
}

String _absoluteTenantUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && uri.hasScheme
      ? value
      : Uri.parse('https://agro.valomnia.com').resolve(value).toString();
}
