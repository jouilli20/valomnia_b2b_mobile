import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valomnia_b2b_mobile/core/storage/secure_storage_service.dart';
import 'package:valomnia_b2b_mobile/features/orders/data/orders_api.dart';
import 'package:valomnia_b2b_mobile/features/orders/domain/order_history.dart';
import 'package:valomnia_b2b_mobile/features/orders/providers/orders_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CustomerOrder maps historical order fields', () {
    final order = CustomerOrder.fromJson({
      'reference': 'ORDER2107260145',
      'dateCreated': '2026-07-21T08:30:00Z',
      'deliveryDate': '21/07/2026',
      'total': '1800.000 DT',
      'status': 'En attente',
      'orderLines': [
        {'productName': 'Article A', 'quantity': 2},
      ],
    });

    expect(order.reference, 'ORDER2107260145');
    expect(order.createdAt, DateTime.utc(2026, 7, 21, 8, 30));
    expect(order.deliveryDate, DateTime(2026, 7, 21));
    expect(order.total, 1800);
    expect(order.totalLabel, '1800.000 DT');
    expect(order.status, 'En attente');
    expect(order.orderLines, hasLength(1));
  });

  test('CustomerOrder maps technical order status to readable label', () {
    final order = CustomerOrder.fromJson({
      'reference': 'ORDER2107260146',
      'status': 'NOT_PAID',
    });

    expect(order.status, 'Non payé');
    expect(order.raw['status'], 'NOT_PAID');
  });

  test('order history uses order customer reference', () async {
    FlutterSecureStorage.setMockInitialValues({});

    await SecureStorageService.saveSession({
      'success': true,
      'token': 'token-1',
      'customerId': 11,
      'customer': {'id': 11, 'reference': 'CT-01'},
    });

    final ordersApi = _FakeOrdersApi();
    final container = ProviderContainer(
      overrides: [ordersApiProvider.overrideWithValue(ordersApi)],
    );
    addTearDown(container.dispose);

    await expectLater(
      container.read(orderHistoryProvider.future),
      completion(hasLength(1)),
    );
    expect(ordersApi.requestedCustomerId, 'CT-01');
  });
}

class _FakeOrdersApi extends OrdersApi {
  String? requestedCustomerId;

  @override
  Future<List<CustomerOrder>> getOrders({required String customerId}) async {
    requestedCustomerId = customerId;
    return [
      CustomerOrder.fromJson({
        'reference': 'ORDER1',
        'status': 'En attente',
        'total': 12,
      }),
    ];
  }
}
