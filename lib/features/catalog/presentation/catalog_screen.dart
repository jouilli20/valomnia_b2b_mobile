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
  static const _backgroundColor = Color(0xFFFFFFFF);
  static const _surfaceColor = Color(0xFFF1F4F7);
  static const _primaryColor = Color(0xFF2563EB);
  static const _inkColor = Color(0xFF202938);
  static const _mutedColor = Color(0xFF6B7280);
  static const _borderColor = Color(0xFFDDE3EA);

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
      backgroundColor: _backgroundColor,
      bottomNavigationBar: _CatalogBottomNavigation(
        selectedIndex: _selectedTabIndex,
        onSelected: _selectTab,
      ),
      body: SafeArea(
        bottom: false,
        child: _selectedTabIndex == _catalogTabIndex
            ? categoriesState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _StateMessage(
                  icon: Icons.wifi_off_rounded,
                  title: 'Impossible de charger le catalogue',
                  message: error.toString(),
                  actionLabel: 'Reessayer',
                  onAction: _reloadCategories,
                ),
                data: (categories) {
                  final hierarchy = _CatalogHierarchy.from(categories);
                  final visibleGroups = hierarchy.filter(_query);

                  if (categories.isEmpty || hierarchy.groups.isEmpty) {
                    return RefreshIndicator(
                      color: _primaryColor,
                      onRefresh: _refreshCategories,
                      child: const CustomScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _StateMessage(
                              icon: Icons.inventory_2_outlined,
                              title: 'Aucune categorie trouvee',
                              message:
                                  'Tirez vers le bas pour actualiser le catalogue.',
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (visibleGroups.isEmpty) {
                    return RefreshIndicator(
                      color: _primaryColor,
                      onRefresh: _refreshCategories,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: _CatalogHeader(
                              controller: _searchController,
                              query: _query,
                              onChanged: _updateQuery,
                              onClear: _clearQuery,
                              onRefresh: _refreshCategories,
                              onLogout: () => _logout(context),
                            ),
                          ),
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _StateMessage(
                              icon: Icons.search_off_rounded,
                              title: 'Aucun resultat',
                              message: 'Essayez un autre mot-cle.',
                              actionLabel: 'Effacer',
                              onAction: _clearQuery,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final selectedKey =
                      visibleGroups.any(
                        (group) => group.parent.key == _selectedParentKey,
                      )
                      ? _selectedParentKey!
                      : visibleGroups.first.parent.key;
                  final selectedGroup = visibleGroups.firstWhere(
                    (group) => group.parent.key == selectedKey,
                  );

                  return RefreshIndicator(
                    color: _primaryColor,
                    onRefresh: _refreshCategories,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _CatalogHeader(
                            controller: _searchController,
                            query: _query,
                            onChanged: _updateQuery,
                            onClear: _clearQuery,
                            onRefresh: _refreshCategories,
                            onLogout: () => _logout(context),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _ParentCategoryStrip(
                            groups: visibleGroups,
                            selectedKey: selectedKey,
                            onSelected: _selectParent,
                          ),
                        ),
                        if (selectedGroup.children.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _StateMessage(
                              icon: Icons.category_outlined,
                              title: selectedGroup.parent.name,
                              message: 'Aucune sous-categorie disponible.',
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                            sliver: SliverList.separated(
                              itemCount: selectedGroup.children.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final category = selectedGroup.children[index];
                                return _SubcategoryRow(category: category);
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              )
            : _TabPlaceholder(index: _selectedTabIndex),
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
        height: 66,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: _CatalogScreenState._borderColor),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 14,
              offset: Offset(0, -3),
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
    final color = isSelected
        ? _CatalogScreenState._primaryColor
        : _CatalogScreenState._mutedColor;

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
                width: isSelected ? 32 : 28,
                height: isSelected ? 32 : 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEAF2FF)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  color: color,
                  size: isSelected ? 20 : 18,
                ),
              ),
              const SizedBox(height: 2),
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

    return _StateMessage(
      icon: _icons[safeIndex],
      title: _titles[safeIndex],
      message: 'Cette section sera branchee prochainement.',
    );
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
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'What are you looking for?',
                hintStyle: const TextStyle(
                  color: _CatalogScreenState._inkColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _CatalogScreenState._inkColor,
                  size: 25,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 1,
                      height: 28,
                      color: _CatalogScreenState._borderColor,
                    ),
                    IconButton(
                      tooltip: query.isEmpty ? 'Actualiser' : 'Effacer',
                      icon: Icon(
                        query.isEmpty
                            ? Icons.sync_rounded
                            : Icons.close_rounded,
                        color: _CatalogScreenState._inkColor,
                      ),
                      onPressed: query.isEmpty ? onRefresh : onClear,
                    ),
                  ],
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: _CatalogScreenState._borderColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: _CatalogScreenState._primaryColor,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _HeaderActionButton(
            icon: Icons.logout_rounded,
            tooltip: 'Deconnexion',
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _CatalogScreenState._borderColor),
          ),
          child: Tooltip(
            message: tooltip,
            child: Icon(icon, color: _CatalogScreenState._inkColor, size: 23),
          ),
        ),
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
      height: 182,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        itemCount: groups.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final group = groups[index];
          return _ParentCategoryTile(
            category: group.parent,
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
    required this.isSelected,
    required this.onTap,
  });

  final _CategoryItem category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 116,
                width: 116,
                decoration: BoxDecoration(
                  color: _CatalogScreenState._surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? _CatalogScreenState._primaryColor
                        : _CatalogScreenState._borderColor,
                    width: isSelected ? 1.8 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x140F172A),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _CategoryImage(
                  imageUrl: category.imageUrl,
                  icon: Icons.category_outlined,
                  iconSize: 42,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? _CatalogScreenState._primaryColor
                      : _CatalogScreenState._inkColor,
                  fontSize: 13.5,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
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
      color: _CatalogScreenState._surfaceColor,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: () {
          // TODO: open products for this category when the products screen exists.
        },
        borderRadius: BorderRadius.circular(5),
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: _CategoryImage(
                      imageUrl: category.imageUrl,
                      icon: Icons.inventory_2_outlined,
                      iconSize: 25,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _CatalogScreenState._inkColor,
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
      errorBuilder: (_, _, _) =>
          _CategoryImagePlaceholder(icon: icon, iconSize: iconSize),
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
    return Container(
      color: const Color(0xFFE8EDF2),
      child: Center(
        child: Icon(
          icon,
          color: _CatalogScreenState._mutedColor,
          size: iconSize,
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
              style: const TextStyle(
                color: _CatalogScreenState._mutedColor,
                fontSize: 13.5,
              ),
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

      final group = ensureGroup(
        parentKey,
        parentSource ?? byKey[parentKey] ?? _fallbackParent(parentKey),
      );
      group.addChild(_CategoryItem.from(category, fallbackKey: categoryKey));
    }

    return _CatalogHierarchy(
      groupsByKey.values
          .map((group) => group.freeze())
          .where((group) => group.parent.name.trim().isNotEmpty)
          .toList(),
    );
  }

  List<_CategoryGroup> filter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return groups;

    final filtered = <_CategoryGroup>[];
    for (final group in groups) {
      final parentMatches = group.parent.matches(q);
      final children = parentMatches
          ? group.children
          : group.children.where((child) => child.matches(q)).toList();

      if (parentMatches || children.isNotEmpty) {
        filtered.add(_CategoryGroup(parent: group.parent, children: children));
      }
    }

    return filtered;
  }

  static dynamic _fallbackParent(String key) {
    if (key.startsWith('id:')) {
      return {'id': key.substring(3), 'name': 'Categorie ${key.substring(3)}'};
    }
    return {'name': key};
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
  if (category is Map) {
    final name = category['name']?.toString().trim();
    if (name != null && name.isNotEmpty && name != 'null') return name;
  }
  return 'Categorie';
}

String? _categoryDescription(dynamic category) {
  if (category is! Map) return null;
  final candidates = [
    category['description'],
    category['shortDescription'],
    category['code'],
    category['reference'],
  ];

  for (final candidate in candidates) {
    final value = candidate?.toString().trim();
    if (value != null && value.isNotEmpty && value != 'null') return value;
  }

  return null;
}

String? _categoryImageUrl(dynamic category) {
  if (category is! Map) return null;
  final raw =
      (category['image'] ??
              category['picture'] ??
              category['thumbnail'] ??
              category['imageUrl'])
          ?.toString()
          .trim();
  if (raw == null || raw.isEmpty || raw == 'null') return null;

  final uri = Uri.tryParse(raw);
  if (uri != null && uri.hasScheme) return raw;

  return Uri.parse('https://agro.valomnia.com').resolve(raw).toString();
}

String? _categoryKey(dynamic category) {
  if (category is! Map) return null;

  final id = category['id']?.toString().trim();
  if (id != null && id.isNotEmpty && id != 'null') return 'id:$id';

  final href = category['href']?.toString().trim();
  if (href != null && href.isNotEmpty && href != 'null') return 'href:$href';

  final reference = category['reference']?.toString().trim();
  if (reference != null && reference.isNotEmpty && reference != 'null') {
    return 'ref:$reference';
  }

  final name = category['name']?.toString().trim();
  if (name != null && name.isNotEmpty && name != 'null') return 'name:$name';

  return null;
}

String? _parentKey(dynamic category) {
  if (category is! Map) return null;

  final parent = _parentCategory(category);
  final nestedParentKey = _categoryKey(parent);
  if (nestedParentKey != null) return nestedParentKey;

  final parentId = category['parentId']?.toString().trim();
  if (parentId != null && parentId.isNotEmpty && parentId != 'null') {
    return 'id:$parentId';
  }

  return null;
}

Map<dynamic, dynamic>? _parentCategory(dynamic category) {
  if (category is! Map) return null;
  final parent = category['parentCategory'];
  return parent is Map ? parent : null;
}
