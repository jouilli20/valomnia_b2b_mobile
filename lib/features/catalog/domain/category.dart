class Category {
  Category({
    required this.id,
    required this.name,
    this.parentId,
    this.description,
    this.imageUrl,
    List<Category>? children,
  }) : children = children ?? <Category>[];

  final String id;
  final String name;
  final String? parentId;
  final String? description;
  final String? imageUrl;
  final List<Category> children;

  factory Category.fromJson(Map<dynamic, dynamic> json) {
    return Category(
      id: _categoryId(json) ?? '',
      name: _categoryName(json),
      parentId: _parentId(json),
      description: _categoryDescription(json),
      imageUrl: _categoryImageUrl(json),
    );
  }

  bool matches(String query) {
    return name.toLowerCase().contains(query) ||
        (description?.toLowerCase().contains(query) ?? false);
  }

  int get descendantCount {
    var total = children.length;
    for (final child in children) {
      total += child.descendantCount;
    }
    return total;
  }
}

List<Category> buildCategoryTree(
  List<dynamic> rawCategories, {
  bool activeOnly = false,
}) {
  final byId = <String, Category>{};
  final orderedIds = <String>[];

  for (final rawCategory in rawCategories) {
    if (rawCategory is! Map) continue;
    if (activeOnly && !_isActive(rawCategory)) continue;

    final category = Category.fromJson(rawCategory);
    if (category.id.isEmpty) continue;

    _upsertCategory(category, byId, orderedIds);

    final parent = _parentCategory(rawCategory);
    if (parent == null) continue;

    final parentCategory = Category.fromJson(parent);
    if (parentCategory.id.isNotEmpty && (!activeOnly || _isActive(parent))) {
      _upsertCategory(parentCategory, byId, orderedIds);
    }
  }

  final roots = <Category>[];
  final attachedIds = <String>{};

  for (final id in orderedIds) {
    final category = byId[id];
    if (category == null) continue;

    final parentId = category.parentId;
    final parent = parentId == null || parentId == category.id
        ? null
        : byId[parentId];

    if (parent == null) {
      roots.add(category);
      continue;
    }

    if (attachedIds.add(category.id)) {
      parent.children.add(category);
    }
  }

  return List.unmodifiable(roots);
}

void _upsertCategory(
  Category category,
  Map<String, Category> byId,
  List<String> orderedIds,
) {
  final existing = byId[category.id];
  if (existing == null) {
    byId[category.id] = category;
    orderedIds.add(category.id);
    return;
  }

  byId[category.id] = Category(
    id: category.id,
    name: category.name,
    parentId: category.parentId,
    description: category.description,
    imageUrl: category.imageUrl,
    children: existing.children,
  );
}

List<Category> filterCategoryTree(List<Category> categories, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return categories;

  return categories
      .map((category) => _filterCategory(category, q))
      .whereType<Category>()
      .toList(growable: false);
}

Category? _filterCategory(Category category, String query) {
  final filteredChildren = category.children
      .map((child) => _filterCategory(child, query))
      .whereType<Category>()
      .toList(growable: false);

  if (!category.matches(query) && filteredChildren.isEmpty) {
    return null;
  }

  return Category(
    id: category.id,
    name: category.name,
    parentId: category.parentId,
    description: category.description,
    imageUrl: category.imageUrl,
    children: filteredChildren,
  );
}

String _categoryName(Map<dynamic, dynamic> category) {
  return _clean(category['name']) ?? 'Categorie';
}

String? _categoryDescription(Map<dynamic, dynamic> category) {
  for (final key in ['description', 'shortDescription', 'code', 'reference']) {
    final value = _clean(category[key]);
    if (value != null) return value;
  }

  return null;
}

String? _categoryImageUrl(Map<dynamic, dynamic> category) {
  for (final key in ['image', 'picture', 'thumbnail', 'imageUrl']) {
    final raw = _clean(category[key]);
    if (raw != null) return _absoluteTenantUrl(raw);
  }

  return null;
}

String? _categoryId(Map<dynamic, dynamic> category) {
  for (final key in ['id', 'href', 'reference', 'name']) {
    final value = _clean(category[key]);
    if (value != null) return value;
  }

  return null;
}

String? _parentId(Map<dynamic, dynamic> category) {
  final nestedParentId = _categoryIdFromDynamic(_parentCategory(category));
  if (nestedParentId != null) return nestedParentId;

  return _clean(category['parentId']);
}

String? _categoryIdFromDynamic(dynamic category) {
  if (category is! Map) return null;
  return _categoryId(category);
}

Map<dynamic, dynamic>? _parentCategory(Map<dynamic, dynamic> category) {
  final parent = category['parentCategory'];
  return parent is Map ? parent : null;
}

bool _isActive(Map<dynamic, dynamic> category) {
  final value = category['active'] ?? category['isActive'];
  if (value == null) return true;
  if (value is bool) return value;
  if (value is num) return value != 0;

  final text = value.toString().trim().toLowerCase();
  return text != 'false' && text != '0' && text != 'no';
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
