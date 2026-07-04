import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/catalog_api.dart';

final categoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  return CatalogApi().getCategories();
});
