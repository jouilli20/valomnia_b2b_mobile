import 'dart:convert';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/connectivity_service.dart';
import '../../../core/storage/local_cache_repository.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/catalog_api.dart';

final catalogApiProvider = Provider<CatalogApi>((ref) {
  return CatalogApi();
});

const catalogItemsPageSize = 10;

class CatalogItemsQuery {
  const CatalogItemsQuery({
    this.offset = 0,
    this.max = catalogItemsPageSize,
    this.sort = 'name',
    this.order = 'ASC',
    this.category,
    this.searchTerm,
    this.minPrice,
    this.maxPrice,
    this.isNew,
    this.withLabel,
    this.isPromo,
  });

  final int offset;
  final int max;
  final String? sort;
  final String? order;
  final String? category;
  final String? searchTerm;
  final String? minPrice;
  final String? maxPrice;
  final bool? isNew;
  final String? withLabel;
  final bool? isPromo;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CatalogItemsQuery &&
            other.offset == offset &&
            other.max == max &&
            other.sort == sort &&
            other.order == order &&
            other.category == category &&
            other.searchTerm == searchTerm &&
            other.minPrice == minPrice &&
            other.maxPrice == maxPrice &&
            other.isNew == isNew &&
            other.withLabel == withLabel &&
            other.isPromo == isPromo;
  }

  @override
  int get hashCode {
    return Object.hash(
      offset,
      max,
      sort,
      order,
      category,
      searchTerm,
      minPrice,
      maxPrice,
      isNew,
      withLabel,
      isPromo,
    );
  }
}

final categoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  final catalogApi = ref.watch(catalogApiProvider);
  final onlineStatus = ref.watch(isOnlineProvider);
  final connectivityService = ref.read(connectivityServiceProvider);
  final cache = ref.read(localCacheRepositoryProvider);
  const cacheKey = 'catalog:categories';

  log('Loading categories...', name: 'CatalogProvider');

  if (!await _isOnline(connectivityService, onlineStatus)) {
    final cachedCategories = await _cachedList(cache, cacheKey);
    if (cachedCategories != null) return cachedCategories;
    throw StateError('Aucune categorie disponible hors ligne.');
  }

  try {
    final categories = await catalogApi.getCategories();
    await cache.saveJson(cacheKey, categories);
    return categories;
  } catch (error) {
    final cachedCategories = await _cachedList(cache, cacheKey);
    if (cachedCategories != null) return cachedCategories;
    rethrow;
  }
});

final catalogProvider = FutureProvider<List<dynamic>>((ref) async {
  final page = await _fetchCatalogItemsPage(ref);
  return page.items;
});

final customerMinOrderTotalProvider = FutureProvider.autoDispose<double>((
  ref,
) async {
  final catalogApi = ref.read(catalogApiProvider);
  final onlineStatus = ref.watch(isOnlineProvider);
  final connectivityService = ref.read(connectivityServiceProvider);
  final cache = ref.read(localCacheRepositoryProvider);
  final customerId = (await SecureStorageService.getCustomerOrderId())?.trim();

  if (customerId == null || customerId.isEmpty) {
    log(
      'Customer order ID not found, cannot load minimum order total',
      name: 'CatalogProvider',
    );
    throw StateError('Customer ID introuvable.');
  }

  log(
    'Loading minimum order total for customer order ID = $customerId',
    name: 'CatalogProvider',
  );

  final cacheKey = 'catalog:min-order-total:$customerId';

  if (!await _isOnline(connectivityService, onlineStatus)) {
    final cachedMinimum = await cache.readJson(cacheKey);
    if (cachedMinimum is num) return cachedMinimum.toDouble();
    return 0;
  }

  try {
    final minimum = await catalogApi.getCustomerMinOrderTotal(
      customerId: customerId,
    );
    await cache.saveJson(cacheKey, minimum);
    return minimum;
  } catch (_) {
    final cachedMinimum = await cache.readJson(cacheKey);
    if (cachedMinimum is num) return cachedMinimum.toDouble();
    return 0;
  }
});

final catalogItemsPageProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  offset,
) async {
  final page = await _fetchCatalogItemsPage(ref, offset: offset);
  return page.items;
});

final catalogItemsQueryProvider =
    FutureProvider.family<CatalogItemsPage, CatalogItemsQuery>((
      ref,
      query,
    ) async {
      return _fetchCatalogItemsPage(
        ref,
        offset: query.offset,
        max: query.max,
        sort: query.sort,
        order: query.order,
        category: query.category,
        searchTerm: query.searchTerm,
        minPrice: query.minPrice,
        maxPrice: query.maxPrice,
        isNew: query.isNew,
        withLabel: query.withLabel,
        isPromo: query.isPromo,
      );
    });

Future<CatalogItemsPage> _fetchCatalogItemsPage(
  Ref ref, {
  int offset = 0,
  int max = catalogItemsPageSize,
  String? sort = 'name',
  String? order = 'ASC',
  String? category,
  String? searchTerm,
  String? minPrice,
  String? maxPrice,
  bool? isNew,
  String? withLabel,
  bool? isPromo,
}) async {
  final catalogApi = ref.watch(catalogApiProvider);
  final onlineStatus = ref.watch(isOnlineProvider);
  final connectivityService = ref.read(connectivityServiceProvider);
  final cache = ref.read(localCacheRepositoryProvider);

  final customerId = (await SecureStorageService.getCustomerId())?.trim();
  final cacheKey = _catalogItemsCacheKey(
    customerId: customerId,
    offset: offset,
    max: max,
    sort: sort,
    order: order,
    category: category,
    searchTerm: searchTerm,
    minPrice: minPrice,
    maxPrice: maxPrice,
    isNew: isNew,
    withLabel: withLabel,
    isPromo: isPromo,
  );

  log(
    'CUSTOMER ID = $customerId, offset = $offset, max = $max',
    name: 'CatalogProvider',
  );

  if (customerId == null || customerId.isEmpty) {
    log(
      'Customer ID not found, loading catalog without customer pricing',
      name: 'CatalogProvider',
    );
  }

  if (!await _isOnline(connectivityService, onlineStatus)) {
    final cachedPage = await _cachedItemsPage(cache, cacheKey);
    if (cachedPage != null) return cachedPage;
    return CatalogItemsPage.empty(offset: offset, max: max);
  }

  try {
    final page = await catalogApi.getItemsPage(
      customerId: customerId,
      offset: offset,
      max: max,
      sort: sort,
      order: order,
      category: category,
      searchTerm: searchTerm,
      minPrice: minPrice,
      maxPrice: maxPrice,
      isNew: isNew,
      withLabel: withLabel,
      isPromo: isPromo,
    );
    await cache.saveJson(cacheKey, _itemsPageJson(page));
    return page;
  } catch (_) {
    final cachedPage = await _cachedItemsPage(cache, cacheKey);
    if (cachedPage != null) return cachedPage;
    rethrow;
  }
}

Future<bool> _isOnline(
  ConnectivityService connectivityService,
  AsyncValue<bool> onlineStatus,
) async {
  if (onlineStatus is AsyncData<bool>) return onlineStatus.value;
  return connectivityService.hasConnection();
}

Future<List<dynamic>?> _cachedList(
  LocalCacheRepository cache,
  String key,
) async {
  final cachedValue = await cache.readJson(key);
  return cachedValue is List ? cachedValue : null;
}

Future<CatalogItemsPage?> _cachedItemsPage(
  LocalCacheRepository cache,
  String key,
) async {
  final cachedValue = await cache.readJson(key);
  if (cachedValue is! Map) return null;

  final items = cachedValue['items'];
  if (items is! List) return null;

  return CatalogItemsPage(
    items: items,
    total: int.tryParse(cachedValue['total']?.toString() ?? '') ?? items.length,
    offset: int.tryParse(cachedValue['offset']?.toString() ?? '') ?? 0,
    max: int.tryParse(cachedValue['max']?.toString() ?? '') ?? items.length,
  );
}

Map<String, dynamic> _itemsPageJson(CatalogItemsPage page) {
  return {
    'items': page.items,
    'total': page.total,
    'offset': page.offset,
    'max': page.max,
  };
}

String _catalogItemsCacheKey({
  required String? customerId,
  required int offset,
  required int max,
  required String? sort,
  required String? order,
  required String? category,
  required String? searchTerm,
  required String? minPrice,
  required String? maxPrice,
  required bool? isNew,
  required String? withLabel,
  required bool? isPromo,
}) {
  return 'catalog:items:${customerId ?? 'anonymous'}:${jsonEncode({'offset': offset, 'max': max, 'sort': sort, 'order': order, 'category': category, 'searchTerm': searchTerm, 'minPrice': minPrice, 'maxPrice': maxPrice, 'isNew': isNew, 'withLabel': withLabel, 'isPromo': isPromo})}';
}
