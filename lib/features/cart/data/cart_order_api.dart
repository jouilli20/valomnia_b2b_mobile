import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/cart_item.dart';

class CartOrderApi {
  CartOrderApi({Dio? dio}) : _dio = dio ?? DioClient.dio;

  static final Options _formOptions = Options(
    contentType: Headers.multipartFormDataContentType,
  );
  static const _referenceSequenceKey = 'order_reference_sequence';

  final Dio _dio;

  Future<String> addOrder({
    required CustomerCart cart,
    required DateTime deliveryDate,
    String deliveryComment = '',
  }) async {
    final now = DateTime.now();
    final payload = CartOrderPayload(
      cart: cart,
      deliveryDate: deliveryDate,
      reference: await _nextReference(now),
      deliveryComment: deliveryComment,
    );

    Response<dynamic> response;
    try {
      response = await _dio.post(
        ApiConstants.addOrder,
        queryParameters: {'baseUrl': ApiConstants.tenantBaseUrl},
        data: FormData.fromMap(payload.toFormData()),
        options: await _options(),
      );
    } on DioException catch (error) {
      log(
        'ADD ORDER ERROR STATUS: ${error.response?.statusCode}',
        name: 'CartOrderApi',
      );
      log(
        'ADD ORDER ERROR DATA: ${error.response?.data}',
        name: 'CartOrderApi',
      );
      throw CartOrderException.fromDio(error);
    }

    log('ADD ORDER STATUS: ${response.statusCode}', name: 'CartOrderApi');
    log('ADD ORDER RESPONSE: ${response.data}', name: 'CartOrderApi');

    return payload.reference;
  }

  Future<Options> _options() async {
    final token = await SecureStorageService.getToken();
    final authorization = token == null
        ? null
        : token.toLowerCase().startsWith('bearer ')
        ? token
        : 'Bearer $token';

    final headers = <String, dynamic>{};
    if (authorization != null) {
      headers['Authorization'] = authorization;
    }

    return _formOptions.copyWith(headers: headers);
  }

  Future<String> _nextReference(DateTime date) async {
    final preferences = await SharedPreferences.getInstance();
    final nextSequence = preferences.getInt(_referenceSequenceKey) ?? 0;
    final referenceSequence = nextSequence + 1;

    await preferences.setInt(_referenceSequenceKey, referenceSequence);

    return 'ORDER${_compactDate(date)}'
        '${referenceSequence.toString().padLeft(4, '0')}';
  }
}

class CartOrderException implements Exception {
  const CartOrderException(this.message);

  factory CartOrderException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data?.toString().trim();

    if (statusCode == 404) {
      return CartOrderException(
        data == null || data.isEmpty
            ? 'Commande rejetee par le serveur (404). Verifiez les articles et la session.'
            : 'Commande rejetee par le serveur (404): $data',
      );
    }

    if (statusCode == null) {
      return const CartOrderException(
        'Impossible de joindre le serveur. Verifiez votre connexion.',
      );
    }

    return CartOrderException(
      data == null || data.isEmpty
          ? 'Commande rejetee par le serveur ($statusCode).'
          : 'Commande rejetee par le serveur ($statusCode): $data',
    );
  }

  final String message;

  @override
  String toString() => message;
}

class CartOrderPayload {
  const CartOrderPayload({
    required this.cart,
    required this.deliveryDate,
    required this.reference,
    required this.deliveryComment,
  });

  final CustomerCart cart;
  final DateTime deliveryDate;
  final String reference;
  final String deliveryComment;

  Map<String, dynamic> toFormData() {
    if (cart.isEmpty) {
      throw StateError('Panier vide.');
    }

    final total = _moneyText(cart.total);

    return {
      'useExternalId': 'true',
      'reference': reference,
      'customerId': cart.customerId,
      'status': 'NOT_PAID',
      'total': total,
      'totalExclTax': total,
      'operationType': 'ORDER',
      'orderLines': jsonEncode(_orderLines()),
      'deliveryComment': deliveryComment.trim(),
      'deliveryDate': _dateTimeUtcDay(deliveryDate),
    };
  }

  List<Map<String, dynamic>> _orderLines() {
    return cart.items
        .map((item) {
          final itemId = item.orderItemId ?? _idFromProductKey(item.productKey);
          final itemUnitId = item.orderItemUnitId;

          if (itemId == null || itemId.trim().isEmpty) {
            throw StateError('ID article manquant pour ${item.name}.');
          }

          if (itemUnitId == null || itemUnitId.trim().isEmpty) {
            throw StateError('ID unite manquant pour ${item.name}.');
          }

          final unitPrice = _money(item.unitPrice ?? 0);
          final lineTotal = _money(item.lineTotal);

          return {
            'id': _numericOrText(itemId),
            'itemUnitId': _numericOrText(itemUnitId),
            'finalPrice': lineTotal,
            'unitPrice': unitPrice,
            'tax': '',
            'productName': item.name,
            'productReference': item.reference ?? '',
            'imageUrl': item.imageUrl ?? '',
            'quantity': item.quantity,
            'salesQty': item.quantity,
          };
        })
        .toList(growable: false);
  }
}

String _moneyText(double value) {
  return _money(value).toString();
}

num _money(double value) {
  return value % 1 == 0
      ? value.toInt()
      : double.parse(value.toStringAsFixed(3));
}

Object _numericOrText(String? value) {
  if (value == null || value.trim().isEmpty) return '';
  return int.tryParse(value) ?? value;
}

String _dateTimeUtcDay(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}T00:00:00Z';
}

String _compactDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}'
      '${value.month.toString().padLeft(2, '0')}'
      '${(value.year % 100).toString().padLeft(2, '0')}';
}

String? _idFromProductKey(String value) {
  final match = RegExp(r'^(?:id|item|product):(.+)$').firstMatch(value);
  return match?.group(1);
}
