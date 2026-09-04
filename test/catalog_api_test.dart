import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:valomnia_b2b_mobile/features/catalog/data/catalog_api.dart';

void main() {
  test('items response includes hasDeclination false', () async {
    late RequestOptions requestOptions;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.valomnia.com/api/'))
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requestOptions = options;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'paging': {'total': 1, 'offset': 0, 'max': 10},
                  'data': [
                    {'id': 1, 'name': 'Produit test'},
                  ],
                },
              ),
            );
          },
        ),
      );

    final page = await CatalogApi(dio: dio).getItemsPage();

    expect(requestOptions.path, 'items');
    expect(page.items, [
      {'id': 1, 'name': 'Produit test', 'hasDeclination': false},
    ]);
  });
}
