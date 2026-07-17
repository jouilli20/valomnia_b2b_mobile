import 'package:flutter_test/flutter_test.dart';
import 'package:valomnia_b2b_mobile/features/customer/domain/customer_profile.dart';
import 'package:valomnia_b2b_mobile/features/customer/domain/user_profile.dart';

void main() {
  test('CustomerProfile maps API customer fields used by profile screen', () {
    final profile = CustomerProfile.fromJson({
      'id': 11,
      'reference': 'CT-01',
      'reference2': 'reference 2',
      'name': 'MAGAZIN SHOP',
      'categoryReference': 'Ref-01',
      'customerCategory': {'id': 4, 'reference': 'Ref-01', 'name': 'MAGASIN'},
      'email': 'shop@example.com',
      'phone': '71111111',
      'mobile': '22111111',
      'fax': '71111112',
      'barcode': 'CT-01',
      'logo': '/uploads/agro/logo.png',
      'billingCountry': 'TN',
      'billingCity': 'Kalaa Kebira',
      'billingAddress': 'VG8V+RXF, Kalaa Kebira, Tunisia',
      'billingPostalCode': null,
      'country': 'TN',
      'city': 'Sousse',
      'address': 'Rue principale',
      'postalCode': '4000',
      'taxNumber': 'DE344077967',
      'companyRegistrationNumber': 'FEXX344077967X',
      'currency': 'TND',
      'organization': 'STE JLASSI MOLKA',
      'website': 'https://example.com',
      'isActive': true,
    });

    expect(profile.id, '11');
    expect(profile.reference, 'CT-01');
    expect(profile.secondaryReference, 'reference 2');
    expect(profile.name, 'MAGAZIN SHOP');
    expect(profile.categoryReference, 'Ref-01');
    expect(profile.sector, 'MAGASIN');
    expect(profile.email, 'shop@example.com');
    expect(profile.phone, '71111111');
    expect(profile.mobile, '22111111');
    expect(profile.fax, '71111112');
    expect(profile.barcode, 'CT-01');
    expect(profile.logoUrl, 'https://agro.valomnia.com/uploads/agro/logo.png');
    expect(profile.billingAddress.address, 'VG8V+RXF, Kalaa Kebira, Tunisia');
    expect(profile.billingAddress.city, 'Kalaa Kebira');
    expect(profile.billingAddress.country, 'TN');
    expect(profile.shippingAddress.address, 'Rue principale');
    expect(profile.shippingAddress.city, 'Sousse');
    expect(profile.shippingAddress.postalCode, '4000');
    expect(profile.shippingAddress.country, 'TN');
    expect(profile.taxNumber, 'DE344077967');
    expect(profile.companyRegistrationNumber, 'FEXX344077967X');
    expect(profile.currency, 'TND');
    expect(profile.organization, 'STE JLASSI MOLKA');
    expect(profile.website, 'https://example.com');
    expect(profile.isActive, isTrue);
  });

  test('UserProfile maps connected profile API fields', () {
    final profile = UserProfile.fromJson({
      'data': {
        'firstName': 'Demo',
        'lastName': '2',
        'email': 'demo2_b2b@yopmail.com',
      },
    });

    expect(profile.name, 'Demo 2');
    expect(profile.email, 'demo2_b2b@yopmail.com');
  });

  test('UserProfile maps loginB2B user fields', () {
    final profile = UserProfile.fromJson({
      'user_email': 'demo2_b2b@yopmail.com',
      'user_name': 'Demo 2',
    });

    expect(profile.name, 'Demo 2');
    expect(profile.email, 'demo2_b2b@yopmail.com');
  });
}
