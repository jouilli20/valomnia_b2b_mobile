class CartItem {
  const CartItem({
    required this.productKey,
    required this.name,
    required this.quantity,
    this.reference,
    this.imageUrl,
    this.unitPrice,
    this.priceLabel,
    this.orderItemId,
    this.orderItemUnitId,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productKey: json['productKey']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Article',
      reference: _clean(json['reference']),
      imageUrl: _clean(json['imageUrl']),
      quantity: _positiveInt(json['quantity']),
      unitPrice: _optionalDouble(json['unitPrice']),
      priceLabel: _clean(json['priceLabel']),
      orderItemId: _clean(json['orderItemId']),
      orderItemUnitId: _clean(json['orderItemUnitId']),
    );
  }

  final String productKey;
  final String name;
  final String? reference;
  final String? imageUrl;
  final int quantity;
  final double? unitPrice;
  final String? priceLabel;
  final String? orderItemId;
  final String? orderItemUnitId;

  double get lineTotal => (unitPrice ?? 0) * quantity;

  CartItem copyWith({
    String? productKey,
    String? name,
    String? reference,
    String? imageUrl,
    int? quantity,
    double? unitPrice,
    String? priceLabel,
    String? orderItemId,
    String? orderItemUnitId,
  }) {
    return CartItem(
      productKey: productKey ?? this.productKey,
      name: name ?? this.name,
      reference: reference ?? this.reference,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      priceLabel: priceLabel ?? this.priceLabel,
      orderItemId: orderItemId ?? this.orderItemId,
      orderItemUnitId: orderItemUnitId ?? this.orderItemUnitId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productKey': productKey,
      'name': name,
      'reference': reference,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'priceLabel': priceLabel,
      'orderItemId': orderItemId,
      'orderItemUnitId': orderItemUnitId,
    };
  }
}

class CustomerCart {
  const CustomerCart({required this.customerId, required this.items});

  factory CustomerCart.empty(String customerId) {
    return CustomerCart(customerId: customerId, items: const []);
  }

  factory CustomerCart.fromJson(String customerId, Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item)))
              .where((item) => item.productKey.isNotEmpty && item.quantity > 0)
              .toList(growable: false)
        : const <CartItem>[];

    return CustomerCart(customerId: customerId, items: items);
  }

  final String customerId;
  final List<CartItem> items;

  bool get isEmpty => items.isEmpty;
  int get itemCount => items.fold(0, (total, item) => total + item.quantity);
  double get total => items.fold(0, (total, item) => total + item.lineTotal);

  int quantityFor(String productKey) {
    for (final item in items) {
      if (item.productKey == productKey) return item.quantity;
    }

    return 0;
  }

  CustomerCart upsert(CartItem item) {
    if (item.productKey.isEmpty || item.quantity <= 0) {
      return remove(item.productKey);
    }

    final updatedItems = [...items];
    final index = updatedItems.indexWhere(
      (entry) => entry.productKey == item.productKey,
    );

    if (index == -1) {
      updatedItems.add(item);
    } else {
      updatedItems[index] = item;
    }

    return copyWith(items: List.unmodifiable(updatedItems));
  }

  CustomerCart increment(CartItem item) {
    final currentQuantity = quantityFor(item.productKey);
    return upsert(item.copyWith(quantity: currentQuantity + 1));
  }

  CustomerCart decrement(String productKey) {
    final currentQuantity = quantityFor(productKey);
    if (currentQuantity <= 1) return remove(productKey);

    final updatedItems = items
        .map(
          (item) => item.productKey == productKey
              ? item.copyWith(quantity: item.quantity - 1)
              : item,
        )
        .toList(growable: false);

    return copyWith(items: updatedItems);
  }

  CustomerCart remove(String productKey) {
    return copyWith(
      items: items
          .where((item) => item.productKey != productKey)
          .toList(growable: false),
    );
  }

  CustomerCart copyWith({String? customerId, List<CartItem>? items}) {
    return CustomerCart(
      customerId: customerId ?? this.customerId,
      items: List.unmodifiable(items ?? this.items),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}

String? _clean(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty || text == 'null' ? null : text;
}

int _positiveInt(dynamic value) {
  final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed < 0) return 0;
  return parsed;
}

double? _optionalDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}
