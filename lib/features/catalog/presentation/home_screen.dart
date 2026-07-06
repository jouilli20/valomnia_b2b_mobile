import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../cart/providers/cart_provider.dart';
import '../data/catalog_api.dart';
import '../providers/catalog_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ProductItem> _loadedMoreItems = [];
  CatalogItemsPage? _lastPage;
  Timer? _searchDebounce;
  String _query = '';
  String _remoteQuery = '';
  int _nextOffset = catalogItemsPageSize;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  Object? _loadMoreError;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  CatalogItemsQuery _itemsQuery({int offset = 0}) {
    return CatalogItemsQuery(
      offset: offset,
      searchTerm: _remoteQuery.trim().isEmpty ? null : _remoteQuery.trim(),
    );
  }

  Future<void> _refreshItems() async {
    _resetPagination();
    ref.invalidate(catalogItemsQueryProvider(_itemsQuery()));
    await ref.read(catalogItemsQueryProvider(_itemsQuery()).future);
  }

  void _handleSearchChanged(String value) {
    setState(() {
      _query = value;
      _loadMoreError = null;
    });

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 420), () {
      if (!mounted) return;
      setState(() {
        _remoteQuery = _query.trim();
        _loadedMoreItems.clear();
        _nextOffset = catalogItemsPageSize;
        _hasMore = true;
        _isLoadingMore = false;
        _loadMoreError = null;
      });
    });
  }

  void _applyImmediateSearch(String value) {
    _searchDebounce?.cancel();
    setState(() {
      _query = value;
      _remoteQuery = value.trim();
      _loadedMoreItems.clear();
      _nextOffset = catalogItemsPageSize;
      _hasMore = true;
      _isLoadingMore = false;
      _loadMoreError = null;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _applyImmediateSearch('');
  }

  void _resetPagination() {
    if (!mounted) return;
    setState(() {
      _loadedMoreItems.clear();
      _nextOffset = catalogItemsPageSize;
      _hasMore = true;
      _isLoadingMore = false;
      _loadMoreError = null;
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    if (_query.trim() != _remoteQuery.trim()) return;
    if (_scrollController.position.extentAfter < 520) {
      unawaited(_loadMoreItems());
    }
  }

  Future<void> _loadMoreItems() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreError = null;
    });

    try {
      final page = await ref.read(
        catalogItemsQueryProvider(_itemsQuery(offset: _nextOffset)).future,
      );
      final items = _mapProducts(page.items);

      if (!mounted) return;
      setState(() {
        _loadedMoreItems.addAll(items);
        _nextOffset = page.offset + page.items.length;
        _hasMore = _nextOffset < page.total;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadMoreError = error);
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncPage = ref.watch(catalogItemsQueryProvider(_itemsQuery()));

    return asyncPage.when(
      loading: () {
        final page = _lastPage;
        return page == null
            ? const _StateView(
                icon: Icons.hourglass_top_rounded,
                title: 'Chargement des articles',
                message: 'Veuillez patienter.',
                showProgress: true,
              )
            : _buildContent(page, isRefreshing: true);
      },
      error: (error, _) => _StateView(
        icon: Icons.wifi_off_rounded,
        title: 'Impossible de charger les articles',
        message: error.toString(),
        actionLabel: 'Reessayer',
        onAction: () =>
            ref.invalidate(catalogItemsQueryProvider(_itemsQuery())),
      ),
      data: (page) {
        _lastPage = page;
        return _buildContent(page);
      },
    );
  }

  Widget _buildContent(CatalogItemsPage page, {bool isRefreshing = false}) {
    final initialItems = _mapProducts(page.items);
    final items = _mergeProducts(initialItems, _loadedMoreItems);
    final visibleItems = _filterProducts(items, _query);
    final displayTotal = _query.trim().isEmpty
        ? page.total
        : visibleItems.length;
    final canLoadMore =
        _query.trim() == _remoteQuery.trim() &&
        _nextOffset < page.total &&
        visibleItems.isNotEmpty;

    return RefreshIndicator(
      color: _HomeColors.primary,
      onRefresh: _refreshItems,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            sliver: SliverToBoxAdapter(
              child: _HomeHeader(
                controller: _searchController,
                query: _query,
                itemCount: displayTotal,
                isRefreshing:
                    isRefreshing || _query.trim() != _remoteQuery.trim(),
                onChanged: _handleSearchChanged,
                onClear: _clearSearch,
              ),
            ),
          ),
          if (visibleItems.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _StateView(
                icon: Icons.inventory_2_outlined,
                title: _query.trim().isEmpty
                    ? 'Aucun article trouve'
                    : 'Aucun resultat',
                message: _query.trim().isEmpty
                    ? 'Tirez vers le bas pour actualiser les articles.'
                    : 'Essayez un autre mot-cle.',
                actionLabel: _query.trim().isEmpty ? null : 'Effacer',
                onAction: _query.trim().isEmpty ? null : _clearSearch,
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              sliver: SliverGrid.builder(
                itemCount: visibleItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, index) {
                  final item = visibleItems[index];
                  return _ProductCard(
                    item: item,
                    onAddToCart: () => _addToCart(item),
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
              sliver: SliverToBoxAdapter(
                child: _LoadMoreFooter(
                  hasMore: _hasMore && canLoadMore,
                  isLoading: _isLoadingMore,
                  error: _loadMoreError,
                  onRetry: _loadMoreItems,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _addToCart(_ProductItem item) {
    ref
        .read(cartProvider.notifier)
        .add(
          CartProduct(
            key: item.key,
            name: item.name,
            reference: item.reference,
            imageUrl: item.imageUrl,
            price: item.price,
          ),
        );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${item.name} ajoute au panier'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.controller,
    required this.query,
    required this.itemCount,
    required this.isRefreshing,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final int itemCount;
  final bool isRefreshing;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _HomeColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: _HomeColors.primary,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catalogue produits',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _HomeColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    itemCount == 1
                        ? '1 article disponible'
                        : '$itemCount articles disponibles',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _HomeColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (isRefreshing) ...[
          const SizedBox(height: 10),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(99)),
            child: LinearProgressIndicator(
              minHeight: 3,
              color: _HomeColors.primary,
              backgroundColor: _HomeColors.primarySoft,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Material(
          color: _HomeColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            style: const TextStyle(
              color: _HomeColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Rechercher un article',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Effacer',
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: _HomeColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              border: _inputBorder(_HomeColors.border),
              enabledBorder: _inputBorder(_HomeColors.border),
              focusedBorder: _inputBorder(_HomeColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.item, required this.onAddToCart});

  final _ProductItem item;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _HomeColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _HomeColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.05,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: _ProductImage(imageUrl: item.imageUrl),
                    ),
                  ),
                  if (item.isPromo || item.isNew || item.labelName != null)
                    Positioned(
                      left: 7,
                      top: 7,
                      child: _ProductBadge(item: item),
                    ),
                  Positioned(
                    right: 7,
                    top: 7,
                    child: _AddToCartButton(onPressed: onAddToCart),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _HomeColors.ink,
                fontSize: 13.5,
                height: 1.14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              item.reference ?? item.category ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _HomeColors.muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    item.price ?? 'Prix non defini',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _HomeColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (item.stock != null)
                  Flexible(
                    child: Text(
                      item.stock!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: _HomeColors.muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _HomeColors.primary,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox.square(
          dimension: 34,
          child: Icon(Icons.add_rounded, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _ProductBadge extends StatelessWidget {
  const _ProductBadge({required this.item});

  final _ProductItem item;

  @override
  Widget build(BuildContext context) {
    final label = item.isPromo
        ? 'Promo'
        : item.isNew
        ? 'New'
        : item.labelName!;
    final color = item.labelColor ?? _HomeColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) return const _ImagePlaceholder();

    return ColoredBox(
      color: _HomeColors.softSurface,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Image.network(
          imageUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const _ImagePlaceholder(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const _ImagePlaceholder(showProgress: true);
          },
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.showProgress = false});

  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _HomeColors.softSurface,
      child: Center(
        child: showProgress
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: _HomeColors.primary,
                ),
              )
            : const Icon(
                Icons.inventory_2_outlined,
                color: _HomeColors.faint,
                size: 34,
              ),
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.hasMore,
    required this.isLoading,
    required this.error,
    required this.onRetry,
  });

  final bool hasMore;
  final bool isLoading;
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: _HomeColors.primary,
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Reessayer'),
      );
    }

    if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Tous les articles sont charges',
            style: TextStyle(
              color: _HomeColors.muted,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return TextButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.expand_more_rounded),
      label: const Text('Charger plus'),
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
              const CircularProgressIndicator(color: _HomeColors.primary)
            else
              Icon(icon, color: _HomeColors.primary, size: 38),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _HomeColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _HomeColors.muted,
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

class _ProductItem {
  const _ProductItem({
    required this.key,
    required this.name,
    required this.reference,
    required this.imageUrl,
    required this.price,
    required this.description,
    required this.category,
    required this.unit,
    required this.barcode,
    required this.stock,
    required this.isNew,
    required this.isPromo,
    required this.labelName,
    required this.labelColor,
  });

  final String key;
  final String name;
  final String? reference;
  final String? imageUrl;
  final String? price;
  final String? description;
  final String? category;
  final String? unit;
  final String? barcode;
  final String? stock;
  final bool isNew;
  final bool isPromo;
  final String? labelName;
  final Color? labelColor;

  factory _ProductItem.from(dynamic item) {
    return _ProductItem(
      key: _itemKey(item),
      name: _itemName(item),
      reference: _itemReference(item),
      imageUrl: _itemImageUrl(item),
      price: _itemPrice(item),
      description: _itemDescription(item),
      category: _itemCategory(item),
      unit: _itemUnit(item),
      barcode: _itemBarcode(item),
      stock: _itemStock(item),
      isNew: _boolValue(item, 'isNew'),
      isPromo: _boolValue(item, 'isPromo'),
      labelName: _stringValue(item, 'labelName'),
      labelColor: _labelColor(item),
    );
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    return [
      name,
      reference,
      description,
      category,
      unit,
      barcode,
      price,
    ].whereType<String>().any((value) => value.toLowerCase().contains(q));
  }
}

class _HomeColors {
  const _HomeColors._();

  static const surface = Colors.white;
  static const softSurface = Color(0xFFF1F5F9);
  static const border = Color(0xFFE5EAF1);
  static const primary = Color(0xFF2563EB);
  static const primarySoft = Color(0xFFEAF2FF);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);
}

OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: color, width: width),
  );
}

List<_ProductItem> _mapProducts(List<dynamic> rawItems) {
  return rawItems
      .map((item) => _ProductItem.from(item))
      .where((item) => item.name.trim().isNotEmpty)
      .toList(growable: false);
}

List<_ProductItem> _mergeProducts(
  List<_ProductItem> initialItems,
  List<_ProductItem> loadedMoreItems,
) {
  final keys = <String>{};
  final items = <_ProductItem>[];

  for (final item in [...initialItems, ...loadedMoreItems]) {
    if (keys.add(item.key)) items.add(item);
  }

  return items;
}

List<_ProductItem> _filterProducts(List<_ProductItem> items, String query) {
  final q = query.trim();
  if (q.isEmpty) return items;
  return items.where((item) => item.matches(q)).toList(growable: false);
}

String _itemKey(dynamic item) {
  if (item is! Map) return 'item:${identityHashCode(item)}';

  for (final entry in const [
    MapEntry('id', 'id'),
    MapEntry('href', 'href'),
    MapEntry('reference', 'ref'),
    MapEntry('code', 'code'),
    MapEntry('sku', 'sku'),
    MapEntry('name', 'name'),
  ]) {
    final value = _clean(item[entry.key]);
    if (value != null) return '${entry.value}:$value';
  }

  return 'item:${identityHashCode(item)}';
}

String _itemName(dynamic item) {
  if (item is! Map) return 'Article';

  for (final key in ['name', 'label', 'title', 'designation']) {
    final value = _clean(item[key]);
    if (value != null) return value;
  }

  return 'Article';
}

String? _itemReference(dynamic item) {
  if (item is! Map) return null;

  for (final key in ['reference', 'ref', 'code', 'sku']) {
    final value = _clean(item[key]);
    if (value != null) return value;
  }

  return null;
}

String? _itemImageUrl(dynamic item) {
  if (item is! Map) return null;

  final itemImages = item['itemImages'];
  if (itemImages is List) {
    for (final image in itemImages) {
      final url = _imageFromMap(image);
      if (url != null) return url;
    }
  }

  return _imageFromMap(item);
}

String? _imageFromMap(dynamic value) {
  if (value is! Map) return null;

  for (final key in [
    'smallImage',
    'thumbnailImage',
    'originalImage',
    'mediumImage',
    'image',
    'picture',
    'thumbnail',
    'imageUrl',
    'photo',
  ]) {
    final raw = _clean(value[key]);
    if (raw != null) return _absoluteTenantUrl(raw);
  }

  return null;
}

String? _itemPrice(dynamic item) {
  if (item is! Map) return null;

  final formattedPrice = _clean(item['prices']);
  if (formattedPrice != null) return formattedPrice;

  for (final key in [
    'valuePrice',
    'price',
    'salePrice',
    'unitPrice',
    'amount',
  ]) {
    final price = _formatPrice(item[key]);
    if (price != null) return price;
  }

  return null;
}

String? _itemDescription(dynamic item) {
  if (item is! Map) return null;

  for (final key in ['shortDescription', 'description', 'details', 'note']) {
    final value = _clean(item[key]);
    if (value != null && value != _itemName(item)) return value;
  }

  return null;
}

String? _itemCategory(dynamic item) {
  if (item is! Map) return null;

  for (final key in [
    'itemCategory',
    'category',
    'categoryName',
    'itemCategoryName',
    'family',
  ]) {
    final value = _namedValue(item[key]);
    if (value != null) return value;
  }

  return null;
}

String? _itemUnit(dynamic item) {
  if (item is! Map) return null;

  for (final key in [
    'unit',
    'itemUnit',
    'unitName',
    'salesUnit',
    'defaultUnit',
    'packing',
  ]) {
    final value = _namedValue(item[key]);
    if (value != null) return value;
  }

  return null;
}

String? _itemBarcode(dynamic item) {
  if (item is! Map) return null;

  for (final key in ['barcode', 'barCode', 'ean', 'upc']) {
    final value = _clean(item[key]);
    if (value != null) return value;
  }

  final itemUnit = item['itemUnit'];
  if (itemUnit is Map) return _clean(itemUnit['barcode']);

  return null;
}

String? _itemStock(dynamic item) {
  if (item is! Map) return null;

  for (final key in [
    'availableQuantity',
    'stock',
    'quantity',
    'qty',
    'availableQty',
  ]) {
    final value = _formatQuantity(item[key]);
    if (value != null) return value;
  }

  return null;
}

bool _boolValue(dynamic item, String key) {
  if (item is! Map) return false;
  final value = item[key];
  if (value is bool) return value;
  final text = _clean(value)?.toLowerCase();
  return text == 'true' || text == '1';
}

String? _stringValue(dynamic item, String key) {
  if (item is! Map) return null;
  return _clean(item[key]);
}

Color? _labelColor(dynamic item) {
  final raw = _stringValue(item, 'labelColor');
  if (raw == null) return null;

  final normalized = raw.replaceFirst('#', '');
  if (normalized.length != 6) return null;

  final value = int.tryParse('FF$normalized', radix: 16);
  return value == null ? null : Color(value);
}

String? _clean(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty || text == 'null' ? null : text;
}

String? _namedValue(dynamic value) {
  if (value is Map) {
    for (final key in ['name', 'label', 'title', 'reference', 'code', 'id']) {
      final text = _clean(value[key]);
      if (text != null) return text;
    }
    return null;
  }

  return _clean(value);
}

String _absoluteTenantUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && uri.hasScheme
      ? value
      : Uri.parse(ApiConstants.tenantBaseUrl).resolve(value).toString();
}

String? _formatPrice(dynamic value) {
  if (value == null) return null;

  if (value is Map) {
    for (final key in ['value', 'amount', 'price', 'valuePrice']) {
      final price = _formatPrice(value[key]);
      if (price != null) return price;
    }
    return null;
  }

  if (value is num) {
    final text = value % 1 == 0 ? value.toInt().toString() : value.toString();
    return '$text DT';
  }

  return _clean(value);
}

String? _formatQuantity(dynamic value) {
  if (value == null) return null;

  if (value is Map) {
    for (final key in ['value', 'quantity', 'qty', 'availableQuantity']) {
      final quantity = _formatQuantity(value[key]);
      if (quantity != null) return quantity;
    }
    return null;
  }

  if (value is num) {
    final text = value % 1 == 0 ? value.toInt().toString() : value.toString();
    return 'Stock $text';
  }

  final text = _clean(value);
  return text == null ? null : 'Stock $text';
}
