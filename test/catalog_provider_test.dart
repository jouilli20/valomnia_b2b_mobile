import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valomnia_b2b_mobile/core/storage/secure_storage_service.dart';
import 'package:valomnia_b2b_mobile/features/catalog/data/catalog_api.dart';
import 'package:valomnia_b2b_mobile/features/catalog/providers/catalog_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('minimum order total uses order customer reference', () async {
    FlutterSecureStorage.setMockInitialValues({});

    await SecureStorageService.saveSession({
      'success': true,
      'token': 'token-1',
      'customerId': 11,
      'customer': {'id': 11, 'reference': 'CT-01'},
    });

    final catalogApi = _FakeCatalogApi();
    final container = ProviderContainer(
      overrides: [catalogApiProvider.overrideWithValue(catalogApi)],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(customerMinOrderTotalProvider.future),
      completion(200),
    );
    expect(catalogApi.requestedCustomerId, 'CT-01');
  });
}

class _FakeCatalogApi extends CatalogApi {
  String? requestedCustomerId;

  @override
  Future<double> getCustomerMinOrderTotal({required String customerId}) async {
    requestedCustomerId = customerId;
    return 200;
  }
}
