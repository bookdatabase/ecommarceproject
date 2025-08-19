import 'package:eaglesteelfurniture/models/category_model.dart';
import 'package:eaglesteelfurniture/models/product_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

final productsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).getProducts();
});

final productsByCategoryProvider = StreamProvider.family<List<Product>, String>(
  (ref, categoryId) {
    return ref
        .watch(productRepositoryProvider)
        .getProductsByCategory(categoryId);
  },
);

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(productRepositoryProvider).getCategories();
});

final productByIdProvider = FutureProvider.family<Product?, String>((
  ref,
  productId,
) {
  return ref.watch(productRepositoryProvider).getProductById(productId);
});
