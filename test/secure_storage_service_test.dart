import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valomnia_b2b_mobile/core/storage/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'stores internal customer id separately from order customer reference',
    () async {
      FlutterSecureStorage.setMockInitialValues({});

      await SecureStorageService.saveSession({
        'success': true,
        'token': 'token-1',
        'customerId': 11,
        'customer': {'id': 11, 'reference': 'CT-01'},
      });

      expect(await SecureStorageService.getCustomerId(), '11');
      expect(await SecureStorageService.getCustomerOrderId(), 'CT-01');
    },
  );

  test(
    'falls back to internal customer id when no order reference exists',
    () async {
      FlutterSecureStorage.setMockInitialValues({});

      await SecureStorageService.saveSession({
        'success': true,
        'token': 'token-1',
        'customerId': 11,
      });

      expect(await SecureStorageService.getCustomerId(), '11');
      expect(await SecureStorageService.getCustomerOrderId(), '11');
    },
  );
}
