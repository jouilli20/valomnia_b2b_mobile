import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/secure_storage_service.dart';
import '../data/catalog_api.dart';

final catalogProvider = FutureProvider<List<dynamic>>((ref) async {
  final customerId = await SecureStorageService.getCustomerId();

  print('CUSTOMER ID = $customerId');

  if (customerId == null) {
    print('CUSTOMER ID NULL');
    return [];
  }

  return CatalogApi().getItems(customerId: customerId);
});