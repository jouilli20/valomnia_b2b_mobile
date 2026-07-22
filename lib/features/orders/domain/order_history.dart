class CustomerOrder {
  const CustomerOrder({
    required this.reference,
    required this.createdAt,
    required this.deliveryDate,
    required this.total,
    required this.totalLabel,
    required this.status,
    required this.orderLines,
    required this.raw,
  });

  final String reference;
  final DateTime? createdAt;
  final DateTime? deliveryDate;
  final double? total;
  final String? totalLabel;
  final String status;
  final List<Map<String, dynamic>> orderLines;
  final Map<String, dynamic> raw;

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    final totalValue = _firstValue(json, const [
      'total',
      'totalTTC',
      'totalPrice',
      'totalInclTax',
      'amount',
      'grandTotal',
      'finalPrice',
    ]);

    return CustomerOrder(
      reference:
          _firstText(json, const [
            'reference',
            'orderReference',
            'ref',
            'code',
            'externalId',
            'id',
          ]) ??
          'Commande',
      createdAt: _firstDate(json, const [
        'dateCreated',
        'createdAt',
        'creationDate',
        'createdDate',
        'orderDate',
        'date',
      ]),
      deliveryDate: _firstDate(json, const [
        'deliveryDate',
        'expectedDeliveryDate',
        'shippingDate',
        'dateLivraison',
        'deliveredAt',
      ]),
      total: _parseMoney(totalValue),
      totalLabel: _moneyLabel(totalValue),
      status:
          _statusLabel(
            _firstText(json, const [
              'status',
              'orderStatus',
              'state',
              'statut',
            ]),
          ) ??
          'Non defini',
      orderLines: _firstMapList(json, const [
        'orderLines',
        'orderLine',
        'orderline',
        'lines',
        'items',
        'details',
      ]),
      raw: Map<String, dynamic>.unmodifiable(json),
    );
  }

  String get searchableText {
    return [
      reference,
      status,
      totalLabel,
      if (createdAt != null) _compactDate(createdAt!),
      if (deliveryDate != null) _compactDate(deliveryDate!),
      ...orderLines.expand(
        (line) => [
          _firstText(line, const ['productName', 'name', 'label', 'reference']),
          _firstText(line, const ['productReference', 'itemReference', 'ref']),
        ],
      ),
    ].whereType<String>().join(' ').toLowerCase();
  }
}

Object? _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      final value = json[key];
      if (_clean(value) != null || value is num || value is DateTime) {
        return value;
      }
    }
  }

  return null;
}

String? _firstText(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);
  if (value is Map) {
    for (final key in ['name', 'label', 'reference', 'id']) {
      final nestedValue = _clean(value[key]);
      if (nestedValue != null) return nestedValue;
    }
  }

  return _clean(value);
}

DateTime? _firstDate(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final date = _parseDate(value);
    if (date != null) return date;
  }

  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) return value;

  final text = _clean(value);
  if (text == null) return null;

  final isoDate = DateTime.tryParse(text);
  if (isoDate != null) return isoDate;

  final slashDate = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(text);
  if (slashDate != null) {
    final day = int.tryParse(slashDate.group(1)!);
    final month = int.tryParse(slashDate.group(2)!);
    final year = int.tryParse(slashDate.group(3)!);
    if (day != null && month != null && year != null) {
      return DateTime(year, month, day);
    }
  }

  return null;
}

double? _parseMoney(dynamic value) {
  if (value is num) return value.toDouble();

  if (value is Map) {
    for (final key in ['value', 'amount', 'total', 'price']) {
      final money = _parseMoney(value[key]);
      if (money != null) return money;
    }
  }

  final text = _clean(value)
      ?.replaceAll(RegExp(r'\s+'), '')
      .replaceAll('DT', '')
      .replaceAll('TND', '')
      .replaceAll(',', '.');
  if (text == null || text.isEmpty) return null;

  final directValue = double.tryParse(text);
  if (directValue != null) return directValue;

  final match = RegExp(r'-?\d+(?:[\.,]\d+)?').firstMatch(text);
  if (match == null) return null;

  return double.tryParse(match.group(0)!.replaceAll(',', '.'));
}

String? _moneyLabel(dynamic value) {
  final money = _parseMoney(value);
  if (money != null) {
    return '${money.toStringAsFixed(3)} DT';
  }

  return _clean(value);
}

String? _statusLabel(String? value) {
  final status = _clean(value);
  if (status == null) return null;

  final normalized = status.toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');

  return switch (normalized) {
    'NOT_PAID' || 'UNPAID' => 'Non payé',
    'PAID' => 'Payee',
    'PENDING' || 'WAITING' => 'En attente',
    'CANCELLED' || 'CANCELED' => 'Annulee',
    'REJECTED' => 'Rejetee',
    'CONFIRMED' || 'VALIDATED' => 'Validee',
    'DELIVERED' => 'Livree',
    _ => status,
  };
}

List<Map<String, dynamic>> _firstMapList(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
    }
  }

  return const [];
}

String _compactDate(DateTime value) {
  return '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year.toString().padLeft(4, '0')}';
}

String? _clean(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty || text == 'null' ? null : text;
}
