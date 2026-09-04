import 'dart:developer';

import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

class CatalogApi {
  CatalogApi({Dio? dio}) : _dio = dio ?? DioClient.dio;

  final Dio _dio;

  Future<List<dynamic>> getCategories() async {
    final response = await _dio.get(
      ApiConstants.itemCategories,
      queryParameters: {'baseUrl': ApiConstants.tenantBaseUrl, 'active': true},
    );

    log('CATEGORIES STATUS: ${response.statusCode}', name: 'CatalogApi');
    log('CATEGORIES RESPONSE: ${response.data}', name: 'CatalogApi');

    if (response.data is List) {
      return response.data;
    }

    if (response.data is Map && response.data['data'] is List) {
      return response.data['data'];
    }

    return [];
  }

  Future<List<dynamic>> getItems({
    String? customerId,
    int offset = 0,
    int max = 10,
    String? sort,
    String? order,
    String? category,
    String? searchTerm,
    String? minPrice,
    String? maxPrice,
    bool? isNew,
    String? withLabel,
    bool? isPromo,
  }) async {
    final page = await getItemsPage(
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

    return page.items;
  }

  Future<CatalogItemsPage> getItemsPage({
    String? customerId,
    int offset = 0,
    int max = 10,
    String? sort,
    String? order,
    String? category,
    String? searchTerm,
    String? minPrice,
    String? maxPrice,
    bool? isNew,
    String? withLabel,
    bool? isPromo,
  }) async {
    final queryParameters = <String, dynamic>{
      'baseUrl': ApiConstants.tenantBaseUrl,
      'offset': offset,
      'max': max,
      if (customerId != null && customerId.trim().isNotEmpty)
        'customerId': customerId.trim(),
      if (sort != null && sort.trim().isNotEmpty) 'sort': sort.trim(),
      if (order != null && order.trim().isNotEmpty) 'order': order.trim(),
      if (category != null && category.trim().isNotEmpty)
        'category': category.trim(),
      if (searchTerm != null && searchTerm.trim().isNotEmpty)
        'searchTerm': searchTerm.trim(),
      if (minPrice != null && minPrice.trim().isNotEmpty)
        'minPrice': minPrice.trim(),
      if (maxPrice != null && maxPrice.trim().isNotEmpty)
        'maxPrice': maxPrice.trim(),
      if (isNew != null) 'isNew': isNew.toString(),
      if (withLabel != null && withLabel.trim().isNotEmpty)
        'withLabel': withLabel.trim(),
      if (isPromo != null) 'isPromo': isPromo.toString(),
    };

    final response = await _dio.post(
      ApiConstants.items,
      queryParameters: queryParameters,
    );

    log('ITEMS STATUS: ${response.statusCode}', name: 'CatalogApi');
    log('ITEMS RESPONSE: ${response.data}', name: 'CatalogApi');

    final data = response.data;
    if (data is List) {
      final items = _withDefaultDeclination(data);
      return CatalogItemsPage(
        items: items,
        total: items.length,
        offset: offset,
        max: max,
      );
    }

    if (data is Map) {
      final paging = data['paging'];
      final total = paging is Map
          ? int.tryParse(paging['total']?.toString() ?? '')
          : null;
      final responseOffset = paging is Map
          ? int.tryParse(paging['offset']?.toString() ?? '')
          : null;
      final responseMax = paging is Map
          ? int.tryParse(paging['max']?.toString() ?? '')
          : null;

      for (final key in ['data', 'items', 'content', 'results']) {
        final value = data[key];
        if (value is List) {
          final items = _withDefaultDeclination(value);
          return CatalogItemsPage(
            items: items,
            total: total ?? items.length,
            offset: responseOffset ?? offset,
            max: responseMax ?? max,
          );
        }
      }
    }

    return CatalogItemsPage.empty(offset: offset, max: max);
  }

  Future<double> getCustomerMinOrderTotal({required String customerId}) async {
    final normalizedCustomerId = customerId.trim();
    if (normalizedCustomerId.isEmpty) {
      throw ArgumentError.value(customerId, 'customerId', 'Customer ID vide.');
    }

    final response = await _dio.get(
      ApiConstants.customerMinOrderTotal,
      queryParameters: {
        'baseUrl': ApiConstants.tenantBaseUrl,
        'customerId': normalizedCustomerId,
      },
      options: Options(responseType: ResponseType.plain),
    );

    log('MIN ORDER STATUS: ${response.statusCode}', name: 'CatalogApi');

    log('MIN ORDER RESPONSE: ${response.data}', name: 'CatalogApi');

    return _minimumOrderTotalInDt(_parseMinimumOrderTotal(response.data));
  }
}

double _parseMinimumOrderTotal(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is List && value.isNotEmpty) {
    return _parseMinimumOrderTotal(value.first);
  }

  if (value is Map) {
    for (final key in [
      'customerMinOrderTotal',
      'minimumOrderTotal',
      'minOrderTotal',
      'total',
      'amount',
      'value',
      'data',
    ]) {
      if (value.containsKey(key)) {
        return _parseMinimumOrderTotal(value[key]);
      }
    }
  }

  final text = value
      ?.toString()
      .replaceAll('"', '')
      .replaceAll('DT', '')
      .replaceAll('TND', '')
      .replaceAll(',', '.')
      .trim();

  if (text == null || text.isEmpty) {
    return 0;
  }

  final directValue = double.tryParse(text);
  if (directValue != null) return directValue;

  final match = RegExp(r'-?\d+(?:[\.,]\d+)?').firstMatch(text);
  if (match == null) return 0;

  return double.tryParse(match.group(0)!.replaceAll(',', '.')) ?? 0;
}

double _minimumOrderTotalInDt(double value) {
  if (value > 0 && value < 10) {
    return value * 1000;
  }

  return value;
}

List<dynamic> _withDefaultDeclination(List<dynamic> items) {
  return items
      .map((item) => item is Map ? {...item, 'hasDeclination': false} : item)
      .toList(growable: false);
}

class CatalogItemsPage {
  const CatalogItemsPage({
    required this.items,
    required this.total,
    required this.offset,
    required this.max,
  });

  factory CatalogItemsPage.empty({required int offset, required int max}) {
    return CatalogItemsPage(
      items: const [],
      total: 0,
      offset: offset,
      max: max,
    );
  }

  final List<dynamic> items;
  final int total;
  final int offset;
  final int max;
}
