import 'package:flutter_test/flutter_test.dart';
import 'package:valomnia_b2b_mobile/features/catalog/domain/category.dart';

void main() {
  test('buildCategoryTree creates an unlimited nested hierarchy by parentId', () {
    final tree = buildCategoryTree([
      {'id': 3, 'name': 'Pomme rouge', 'parentId': 2},
      {'id': 1, 'name': 'Fruits'},
      {'id': 2, 'name': 'Pommes', 'parentId': 1},
      {'id': 4, 'name': 'Boissons'},
    ]);

    expect(tree, hasLength(2));
    expect(tree.first.name, 'Fruits');
    expect(tree.first.children.single.name, 'Pommes');
    expect(tree.first.children.single.children.single.name, 'Pomme rouge');
    expect(tree.last.name, 'Boissons');
    expect(tree.last.children, isEmpty);
  });

  test('filterCategoryTree keeps parents when a nested child matches', () {
    final tree = buildCategoryTree([
      {'id': 1, 'name': 'Fruits'},
      {'id': 2, 'name': 'Pommes', 'parentId': 1},
      {'id': 3, 'name': 'Pomme rouge', 'parentId': 2},
      {'id': 4, 'name': 'Boissons'},
    ]);

    final filtered = filterCategoryTree(tree, 'rouge');

    expect(filtered, hasLength(1));
    expect(filtered.first.name, 'Fruits');
    expect(filtered.first.children.single.name, 'Pommes');
    expect(filtered.first.children.single.children.single.name, 'Pomme rouge');
  });

  test('buildCategoryTree ignores inactive categories when activeOnly is true', () {
    final tree = buildCategoryTree([
      {'id': 1, 'name': 'Fruits', 'active': true},
      {'id': 2, 'name': 'Pommes', 'parentId': 1, 'active': true},
      {'id': 3, 'name': 'Ancienne categorie', 'parentId': 1, 'active': false},
      {'id': 4, 'name': 'Archive', 'isActive': 'false'},
    ], activeOnly: true);

    expect(tree, hasLength(1));
    expect(tree.single.name, 'Fruits');
    expect(tree.single.children, hasLength(1));
    expect(tree.single.children.single.name, 'Pommes');
  });
}
