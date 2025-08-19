import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cart_model.dart';
import '../../models/product_model.dart';

final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<Cart> {
  CartNotifier() : super(Cart(items: []));

  void addToCart(Product product, {int quantity = 1}) {
    final existingItemIndex = state.items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingItemIndex != -1) {
      // Update quantity if product already exists
      final updatedItems = List<CartItem>.from(state.items);
      final existingItem = updatedItems[existingItemIndex];
      updatedItems[existingItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      // Add new item to cart
      final newItem = CartItem(product: product, quantity: quantity);
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void removeFromCart(String productId) {
    final updatedItems = state.items
        .where((item) => item.product.id != productId)
        .toList();
    state = state.copyWith(items: updatedItems);
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final updatedItems = List<CartItem>.from(state.items);
    final itemIndex = updatedItems.indexWhere(
      (item) => item.product.id == productId,
    );

    if (itemIndex != -1) {
      updatedItems[itemIndex] = updatedItems[itemIndex].copyWith(
        quantity: newQuantity,
      );
      state = state.copyWith(items: updatedItems);
    }
  }

  void incrementQuantity(String productId) {
    final itemIndex = state.items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (itemIndex != -1) {
      final item = state.items[itemIndex];
      updateQuantity(productId, item.quantity + 1);
    }
  }

  void decrementQuantity(String productId) {
    final itemIndex = state.items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (itemIndex != -1) {
      final item = state.items[itemIndex];
      updateQuantity(productId, item.quantity - 1);
    }
  }

  void clearCart() {
    state = state.copyWith(items: []);
  }

  bool isInCart(String productId) {
    return state.items.any((item) => item.product.id == productId);
  }

  int getItemQuantity(String productId) {
    final itemIndex = state.items.indexWhere(
      (item) => item.product.id == productId,
    );
    if (itemIndex != -1) {
      return state.items[itemIndex].quantity;
    }
    return 0;
  }

  // Helper method to create a dummy product for error handling
  Product _createDummyProduct() {
    return Product(
      id: '',
      name: '',
      description: '',
      price: 0,
      stock: 0,
      rating: 0,
      imageUrl: '',
      images: [],
      categories: [], // Use categories instead of categoryId
    );
  }
}
