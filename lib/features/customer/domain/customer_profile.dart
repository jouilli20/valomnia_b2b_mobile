import '../../../core/constants/api_constants.dart';

class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.reference,
    required this.secondaryReference,
    required this.name,
    required this.categoryReference,
    required this.sector,
    required this.email,
    required this.phone,
    required this.mobile,
    required this.fax,
    required this.barcode,
    required this.logoUrl,
    required this.organization,
    required this.taxNumber,
    required this.companyRegistrationNumber,
    required this.currency,
    required this.website,
    required this.isActive,
    required this.billingAddress,
    required this.shippingAddress,
  });

  final String? id;
  final String? reference;
  final String? secondaryReference;
  final String? name;
  final String? categoryReference;
  final String? sector;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? fax;
  final String? barcode;
  final String? logoUrl;
  final String? organization;
  final String? taxNumber;
  final String? companyRegistrationNumber;
  final String? currency;
  final String? website;
  final bool isActive;
  final CustomerAddress billingAddress;
  final CustomerAddress shippingAddress;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: _clean(json['id']),
      reference: _clean(json['reference']),
      secondaryReference: _clean(json['reference2']),
      name: _clean(json['name']),
      categoryReference: _clean(json['categoryReference']),
      sector: _customerSector(json),
      email: _clean(json['email']),
      phone: _clean(json['phone']),
      mobile: _clean(json['mobile']),
      fax: _clean(json['fax']),
      barcode: _clean(json['barcode']),
      logoUrl: _absoluteTenantUrl(_clean(json['logo'])),
      organization: _clean(json['organization']),
      taxNumber: _clean(json['taxNumber']),
      companyRegistrationNumber: _clean(json['companyRegistrationNumber']),
      currency: _clean(json['currency']),
      website: _clean(json['website']),
      isActive: _boolValue(json['isActive'], fallback: true),
      billingAddress: CustomerAddress.fromJson(
        json,
        addressKeys: const ['billingAddress', 'billToAddress'],
        cityKeys: const ['billingCity', 'billToCity'],
        postalCodeKeys: const ['billingPostalCode', 'billToPostalCode'],
        countryKeys: const ['billingCountry', 'billToCountry'],
      ),
      shippingAddress: CustomerAddress.fromJson(
        json,
        addressKeys: const ['shippingAddress', 'deliveryAddress', 'address'],
        cityKeys: const ['shippingCity', 'deliveryCity', 'city'],
        postalCodeKeys: const [
          'shippingPostalCode',
          'deliveryPostalCode',
          'postalCode',
        ],
        countryKeys: const ['shippingCountry', 'deliveryCountry', 'country'],
      ),
    );
  }
}

class CustomerAddress {
  const CustomerAddress({
    required this.address,
    required this.city,
    required this.postalCode,
    required this.country,
  });

  final String? address;
  final String? city;
  final String? postalCode;
  final String? country;

  bool get hasAnyValue {
    return address != null ||
        city != null ||
        postalCode != null ||
        country != null;
  }

  factory CustomerAddress.fromJson(
    Map<String, dynamic> json, {
    required List<String> addressKeys,
    required List<String> cityKeys,
    required List<String> postalCodeKeys,
    required List<String> countryKeys,
  }) {
    return CustomerAddress(
      address: _firstClean(json, addressKeys),
      city: _firstClean(json, cityKeys),
      postalCode: _firstClean(json, postalCodeKeys),
      country: _firstNamed(json, countryKeys),
    );
  }
}

String? _customerSector(Map<String, dynamic> json) {
  for (final key in [
    'customerCategory',
    'category',
    'sector',
    'activitySector',
  ]) {
    final value = _namedValue(json[key]);
    if (value != null) return value;
  }

  return _clean(json['customerCategoryReference']);
}

String? _firstClean(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _clean(json[key]);
    if (value != null) return value;
  }

  return null;
}

String? _firstNamed(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = _namedValue(json[key]);
    if (value != null) return value;
  }

  return null;
}

String? _namedValue(dynamic value) {
  if (value is Map) {
    for (final key in ['name', 'label', 'reference', 'code', 'id']) {
      final text = _clean(value[key]);
      if (text != null) return text;
    }

    return null;
  }

  return _clean(value);
}

bool _boolValue(dynamic value, {required bool fallback}) {
  if (value is bool) return value;

  final text = _clean(value)?.toLowerCase();
  if (text == null) return fallback;

  return text == 'true' || text == '1' || text == 'yes';
}

String? _absoluteTenantUrl(String? value) {
  if (value == null) return null;

  final uri = Uri.tryParse(value);
  if (uri != null && uri.hasScheme) return value;

  return Uri.parse(ApiConstants.tenantBaseUrl).resolve(value).toString();
}

String? _clean(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}
