// cart_model.dart
import 'package:eaglesteelfurniture/models/product_model.dart';

class Cart {
  final List<CartItem> items;

  Cart({required this.items});

  double get totalPrice {
    return items.fold(
      0,
      (total, item) => total + (item.product.discountedPrice * item.quantity),
    );
  }

  int get totalItems {
    return items.fold(0, (total, item) => total + item.quantity);
  }

  Cart copyWith({List<CartItem>? items}) {
    return Cart(items: items ?? this.items);
  }
}

class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, required this.quantity});

  double get totalPrice {
    return product.discountedPrice * quantity;
  }

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}
