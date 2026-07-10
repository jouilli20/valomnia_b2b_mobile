import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../data/catalog_api.dart';
import '../providers/catalog_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.categoryId, this.categoryName});

  final String? categoryId;
  final String? categoryName;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ProductItem> _loadedMoreItems = [];
  final Map<String, int> _cartQuantities = {};
  CatalogItemsPage? _lastPage;
  _ProductFilter _lastPageFilter = _ProductFilter.all;
  _ProductFilter _selectedFilter = _ProductFilter.all;
  String _searchQuery = '';
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
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  CatalogItemsQuery _itemsQuery({int offset = 0}) {
    return CatalogItemsQuery(
      offset: offset,
      category: _categoryRequestParam,
      isNew: _selectedFilter.isNew ? true : null,
    );
  }

  String? get _categoryRequestParam {
    final id = widget.categoryId?.trim();
    if (id == null || id.isEmpty) return null;
    return '[$id]';
  }

  Future<void> _refreshItems() async {
    _resetPagination();
    ref.invalidate(catalogItemsQueryProvider(_itemsQuery()));
    await ref.read(catalogItemsQueryProvider(_itemsQuery()).future);
  }

  void _selectFilter(_ProductFilter filter) {
    if (_selectedFilter == filter) return;
    final shouldResetPage = _selectedFilter.apiKey != filter.apiKey;
    setState(() {
      _selectedFilter = filter;
      if (shouldResetPage) {
        _loadedMoreItems.clear();
        _nextOffset = catalogItemsPageSize;
        _hasMore = true;
        _isLoadingMore = false;
      }
      _loadMoreError = null;
    });
  }

  void _handleSearchChanged(String value) {
    setState(() => _searchQuery = value);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
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
        if (page == null) {
          return const _StateView(
            icon: Icons.hourglass_top_rounded,
            title: 'Chargement des articles',
            message: 'Veuillez patienter.',
            showProgress: true,
          );
        }

        return _buildContent(
          page,
          isRefreshing: true,
          showLoadingState: _lastPageFilter.apiKey != _selectedFilter.apiKey,
        );
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
        _lastPageFilter = _selectedFilter;
        return _buildContent(page);
      },
    );
  }

  Widget _buildContent(
    CatalogItemsPage page, {
    bool isRefreshing = false,
    bool showLoadingState = false,
  }) {
    final initialItems = _mapProducts(page.items);
    final items = _mergeProducts(initialItems, _loadedMoreItems);
    final filters = _buildProductFilters();
    final visibleItems = _filterProducts(
      items,
      _selectedFilter,
      searchQuery: _searchQuery,
    );
    final canLoadMore = _nextOffset < page.total && visibleItems.isNotEmpty;

    return ColoredBox(
      color: _HomeColors.background,
      child: RefreshIndicator(
        color: _HomeColors.primary,
        onRefresh: _refreshItems,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              sliver: SliverToBoxAdapter(
                child: _HomeHeader(
                  searchController: _searchController,
                  searchQuery: _searchQuery,
                  selectedCategoryName: widget.categoryName,
                  filters: filters,
                  selectedFilter: _selectedFilter,
                  isRefreshing: isRefreshing,
                  onSearchChanged: _handleSearchChanged,
                  onClearSearch: _clearSearch,
                  onFilterSelected: _selectFilter,
                ),
              ),
            ),
            if (showLoadingState)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _StateView(
                  icon: Icons.hourglass_top_rounded,
                  title: 'Chargement des articles',
                  message: 'Veuillez patienter.',
                  showProgress: true,
                ),
              )
            else if (visibleItems.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _StateView(
                  icon: Icons.inventory_2_outlined,
                  title: widget.categoryName == null
                      ? 'Aucun article trouve'
                      : 'Aucun article dans cette categorie',
                  message: 'Tirez vers le bas pour actualiser les articles.',
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final columnCount = _responsiveGridColumnCount(
                      constraints.crossAxisExtent,
                    );

                    return SliverGrid.builder(
                      itemCount: visibleItems.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columnCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.66,
                      ),
                      itemBuilder: (context, index) {
                        final item = visibleItems[index];
                        return _ProductCard(
                          item: item,
                          onTap: () => _showProductDetails(item),
                          quantity: _cartQuantities[item.key] ?? 0,
                          onAddToCart: () => _incrementCartQuantity(item),
                          onIncrement: () => _incrementCartQuantity(item),
                          onDecrement: () => _decrementCartQuantity(item),
                        );
                      },
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
      ),
    );
  }

  void _incrementCartQuantity(_ProductItem item) {
    setState(() {
      _cartQuantities.update(
        item.key,
        (quantity) => quantity + 1,
        ifAbsent: () => 1,
      );
    });
  }

  void _decrementCartQuantity(_ProductItem item) {
    setState(() {
      final currentQuantity = _cartQuantities[item.key] ?? 0;
      if (currentQuantity <= 1) {
        _cartQuantities.remove(item.key);
      } else {
        _cartQuantities[item.key] = currentQuantity - 1;
      }
    });
  }

  void _showProductDetails(_ProductItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _HomeColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _ProductDetailsSheet(item: item),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.searchController,
    required this.searchQuery,
    required this.selectedCategoryName,
    required this.filters,
    required this.selectedFilter,
    required this.isRefreshing,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onFilterSelected,
  });

  final TextEditingController searchController;
  final String searchQuery;
  final String? selectedCategoryName;
  final List<_ProductFilter> filters;
  final _ProductFilter selectedFilter;
  final bool isRefreshing;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<_ProductFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = filters.indexOf(selectedFilter);
    final categoryName = selectedCategoryName?.trim();
    final hasSelectedCategory = categoryName != null && categoryName.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _HomeColors.darkPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _HomeColors.darkBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000A18),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 78,
                height: 78,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _HomeColors.success, width: 2),
                ),
                child: Image.asset(
                  'assets/images/organization_mark.png',
                  fit: BoxFit.contain,
                  semanticLabel: 'Organisation',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasSelectedCategory ? categoryName : 'Bienvenue',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomeColors.success,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hasSelectedCategory
                          ? 'Articles de cette categorie'
                          : 'Decouvrez nos produits et profitez des meilleures offres',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomeColors.lightText,
                        fontSize: 13.5,
                        height: 1.28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isRefreshing) ...[
          const SizedBox(height: 8),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(99)),
            child: LinearProgressIndicator(
              minHeight: 3,
              color: _HomeColors.primary,
              backgroundColor: _HomeColors.primarySoft,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          height: 54,
          decoration: BoxDecoration(
            color: _HomeColors.darkField,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _HomeColors.darkBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000614),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onChanged: onSearchChanged,
            style: const TextStyle(
              color: _HomeColors.lightText,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: 'Rechercher un produit, une categorie...',
              hintStyle: const TextStyle(
                color: _HomeColors.lightMuted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: _HomeColors.lightMuted,
                size: 25,
              ),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Effacer',
                      onPressed: onClearSearch,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: _HomeColors.lightText,
                      ),
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        DefaultTabController(
          key: ValueKey(
            '${filters.length}:${selectedIndex < 0 ? 0 : selectedIndex}',
          ),
          length: filters.length,
          initialIndex: selectedIndex < 0 ? 0 : selectedIndex,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: _HomeColors.darkField,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _HomeColors.darkBorder),
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 7,
              ),
              indicator: BoxDecoration(
                color: _HomeColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: _HomeColors.lightMuted,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              onTap: (index) => onFilterSelected(filters[index]),
              tabs: [
                for (final filter in filters)
                  Tab(
                    height: 48,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(filter.icon, size: 18),
                          const SizedBox(width: 7),
                          Text(filter.title),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.onTap,
    required this.quantity,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
  });

  final _ProductItem item;
  final VoidCallback onTap;
  final int quantity;
  final VoidCallback onAddToCart;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _HomeColors.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: 8,
      shadowColor: const Color(0x66000614),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _HomeColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                        child: _ProductImage(imageUrl: item.imageUrl),
                      ),
                    ),
                    if (item.isPromo || item.isNew || item.labelName != null)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: _ProductBadge(item: item),
                      ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: _AddToCartButton(onPressed: onAddToCart),
                    ),
                    if (quantity > 0)
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: _QuantityPopup(
                          quantity: quantity,
                          onIncrement: onIncrement,
                          onDecrement: onDecrement,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _HomeColors.ink,
                        fontSize: 13.5,
                        height: 1.15,
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
                    const SizedBox(height: 8),
                    Row(
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
                          Text(
                            item.stock!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _HomeColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
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

class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _HomeColors.primary,
      shape: const CircleBorder(),
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

class _QuantityPopup extends StatelessWidget {
  const _QuantityPopup({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _HomeColors.primary,
      borderRadius: BorderRadius.circular(12),
      elevation: 8,
      shadowColor: const Color(0x332563EB),
      child: Container(
        height: 38,
        constraints: const BoxConstraints(minWidth: 112),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4F8DF7), _HomeColors.primary],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QuantityButton(
              icon: Icons.remove_rounded,
              tooltip: 'Retirer',
              onPressed: onDecrement,
            ),
            SizedBox(
              width: 32,
              child: Text(
                quantity.toString(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _QuantityButton(
              icon: Icons.add_rounded,
              tooltip: 'Ajouter',
              onPressed: onIncrement,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 38, height: 38),
      padding: EdgeInsets.zero,
      icon: Icon(icon, color: Colors.white, size: 22),
      visualDensity: VisualDensity.compact,
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
    final color = _productBadgeColor(item);
    final textColor = _productBadgeTextColor(color);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 10.5,
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

    return Image.network(
      imageUrl!,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const _ImagePlaceholder(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const _ImagePlaceholder(showProgress: true);
      },
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
              color: _HomeColors.lightMuted,
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

class _ProductDetailsSheet extends StatelessWidget {
  const _ProductDetailsSheet({required this.item});

  final _ProductItem item;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: _HomeColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 1.6,
                child: _ProductImage(imageUrl: item.imageUrl),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.name,
              style: const TextStyle(
                color: _HomeColors.ink,
                fontSize: 20,
                height: 1.16,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (item.reference != null) ...[
              const SizedBox(height: 6),
              Text(
                item.reference!,
                style: const TextStyle(
                  color: _HomeColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            if (item.price != null) ...[
              const SizedBox(height: 12),
              Text(
                item.price!,
                style: const TextStyle(
                  color: _HomeColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
            if (item.description != null) ...[
              const SizedBox(height: 16),
              Text(
                item.description!,
                style: const TextStyle(
                  color: _HomeColors.muted,
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            _DetailRow(
              icon: Icons.category_outlined,
              label: 'Categorie',
              value: item.category,
            ),
            _DetailRow(
              icon: Icons.straighten_rounded,
              label: 'Unite',
              value: item.unit,
            ),
            _DetailRow(
              icon: Icons.qr_code_rounded,
              label: 'Code barre',
              value: item.barcode,
            ),
            _DetailRow(
              icon: Icons.inventory_rounded,
              label: 'Stock',
              value: item.stock,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _HomeColors.faint, size: 20),
          const SizedBox(width: 10),
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                color: _HomeColors.muted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value!,
              style: const TextStyle(
                color: _HomeColors.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
              const CircularProgressIndicator(color: _HomeColors.primary)
            else
              Icon(icon, color: _HomeColors.primary, size: 38),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _HomeColors.lightText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _HomeColors.lightMuted,
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

class _ProductFilter {
  const _ProductFilter._({
    required this.key,
    required this.title,
    required this.icon,
    this.isNew = false,
    this.isPromo = false,
    this.labelName,
  });

  static const all = _ProductFilter._(
    key: 'all',
    title: 'Tous',
    icon: Icons.apps_rounded,
  );

  static const newItems = _ProductFilter._(
    key: 'new',
    title: 'New',
    icon: Icons.fiber_new_rounded,
    isNew: true,
  );

  static const promo = _ProductFilter._(
    key: 'promo',
    title: 'Promo',
    icon: Icons.local_offer_rounded,
    isPromo: true,
  );

  static const labelNameGroup = _ProductFilter._(
    key: 'labelName',
    title: 'LabelName',
    icon: Icons.label_rounded,
    labelName: 'FOCUS,RETOUR',
  );

  final String key;
  final String title;
  final IconData icon;
  final bool isNew;
  final bool isPromo;
  final String? labelName;

  String get apiKey {
    if (isNew) return 'new';
    return 'all';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _ProductFilter && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;
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

  bool matchesFilter(_ProductFilter filter) {
    if (filter == _ProductFilter.all) return true;
    if (filter.isNew) return isNew;
    if (filter == _ProductFilter.promo) return _isPromoProduct(this);
    if (filter == _ProductFilter.labelNameGroup) {
      return _isGroupedLabelName(labelName);
    }
    return false;
  }

  bool matchesSearch(String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) return true;

    return [
      name,
      reference,
      description,
      category,
      unit,
      barcode,
      price,
      labelName,
    ].whereType<String>().any((text) => text.toLowerCase().contains(value));
  }
}

class _HomeColors {
  const _HomeColors._();

  static const background = Color(0xFF031126);
  static const darkPanel = Color(0xFF061B3B);
  static const darkField = Color(0xFF0B1A2E);
  static const darkBorder = Color(0xFF17335D);
  static const lightText = Color(0xFFF8FAFC);
  static const lightMuted = Color(0xFF9FB1CC);
  static const surface = Colors.white;
  static const softSurface = Color(0xFFF1F5F9);
  static const border = Color(0xFFE5EAF1);
  static const primary = Color(0xFF2563EB);
  static const primarySoft = Color(0xFFEAF2FF);
  static const success = Color(0xFF22C55E);
  static const promo = Color(0xFFE11D48);
  static const newItem = Color(0xFF16A34A);
  static const focus = Color(0xFFFDE047);
  static const retour = Color(0xFFF97316);
  static const ink = Color(0xFF0F172A);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);
}

Color _productBadgeColor(_ProductItem item) {
  if (item.isPromo) return _HomeColors.promo;
  if (item.isNew) return _HomeColors.newItem;

  final labelName = item.labelName?.trim().toLowerCase();
  if (labelName == 'promo') return _HomeColors.promo;
  if (labelName == 'focus') return _HomeColors.focus;
  if (labelName == 'retour') return _HomeColors.retour;

  return item.labelColor ?? _HomeColors.primary;
}

Color _productBadgeTextColor(Color backgroundColor) {
  return backgroundColor == _HomeColors.focus ? _HomeColors.ink : Colors.white;
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

List<_ProductFilter> _buildProductFilters() {
  return const [
    _ProductFilter.all,
    _ProductFilter.newItems,
    _ProductFilter.labelNameGroup,
    _ProductFilter.promo,
  ];
}

List<_ProductItem> _filterProducts(
  List<_ProductItem> items,
  _ProductFilter filter, {
  required String searchQuery,
}) {
  return items
      .where((item) => item.matchesFilter(filter))
      .where((item) => item.matchesSearch(searchQuery))
      .toList(growable: false);
}

int _responsiveGridColumnCount(double width) {
  if (width >= 960) return 5;
  if (width >= 720) return 4;
  if (width >= 520) return 3;
  return 2;
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

bool _isGroupedLabelName(String? labelName) {
  final value = labelName?.trim().toLowerCase();
  return value == 'focus' || value == 'retour';
}

bool _isPromoProduct(_ProductItem item) {
  return item.isPromo || item.labelName?.trim().toLowerCase() == 'promo';
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
