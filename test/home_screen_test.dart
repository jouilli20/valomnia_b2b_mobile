import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:valomnia_b2b_mobile/core/storage/secure_storage_service.dart';
import 'package:valomnia_b2b_mobile/features/catalog/data/catalog_api.dart';
import 'package:valomnia_b2b_mobile/features/catalog/presentation/home_screen.dart';
import 'package:valomnia_b2b_mobile/features/catalog/providers/catalog_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('product details uses API description before shortDescription', (
    tester,
  ) async {
    await _setSession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogApiProvider.overrideWithValue(_FakeCatalogApi())],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Produit test'));
    await tester.pumpAndSettle();

    expect(find.text('Description venant de POST /api/items'), findsOneWidget);
    expect(find.text('15/02/2024 12:30'), findsNothing);
  });

  testWidgets('adding product uses salesQty from items API', (tester) async {
    await _setSession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogApiProvider.overrideWithValue(_FakeCatalogApi())],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();

    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('product details add button uses salesQty from items API', (
    tester,
  ) async {
    await _setSession();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogApiProvider.overrideWithValue(_FakeCatalogApi())],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Produit test'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded).last);
    await tester.pumpAndSettle();

    expect(find.text('20'), findsWidgets);
  });
}

Future<void> _setSession() async {
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues({});

  await SecureStorageService.saveSession({
    'success': true,
    'token': 'token-1',
    'customerId': 11,
    'customer': {'id': 11, 'reference': 'CT-01'},
  });
}

class _FakeCatalogApi extends CatalogApi {
  @override
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
    return CatalogItemsPage(
      items: [
        {
          'id': 1,
          'name': 'Produit test',
          'reference': 'ref-001',
          'price': 18,
          'description': 'Description venant de POST /api/items',
          'shortDescription': '15/02/2024 12:30',
          'salesQty': 20,
          'category': 'SMPA',
          'unit': 'Piece',
          'barcode': '879786',
          'stock': 15266,
        },
      ],
      total: 1,
      offset: offset,
      max: max,
    );
  }
}
