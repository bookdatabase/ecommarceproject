import 'package:eaglesteelfurniture/models/product_model.dart';

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  double get totalPrice => product.discountedPrice * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class Cart {
  final List<CartItem> items;

  Cart({required this.items});

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      items.fold(0.0, (sum, item) => sum + item.totalPrice);

  Cart copyWith({List<CartItem>? items}) {
    return Cart(items: items ?? this.items);
  }
}
