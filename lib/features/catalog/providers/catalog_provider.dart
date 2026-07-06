import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  log('Loading categories...', name: 'CatalogProvider');

  return await catalogApi.getCategories();
});

final catalogProvider = FutureProvider<List<dynamic>>((ref) async {
  return _fetchCatalogItemsPage(ref);
});

final catalogItemsPageProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  offset,
) async {
  return _fetchCatalogItemsPage(ref, offset: offset);
});

final catalogItemsQueryProvider =
    FutureProvider.family<List<dynamic>, CatalogItemsQuery>((ref, query) async {
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

Future<List<dynamic>> _fetchCatalogItemsPage(
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

  final customerId = (await SecureStorageService.getCustomerId())?.trim();

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

  return await catalogApi.getItems(
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
}
