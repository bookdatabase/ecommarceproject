import 'package:flutter_riverpod/flutter_riverpod.dart';

class WishlistStateNotifier extends StateNotifier<Map<String, bool>> {
  WishlistStateNotifier() : super({});

  bool isInWishlist(String productId) => state[productId] ?? false;

  void toggle(String productId) {
    state = {...state, productId: !(state[productId] ?? false)};
  }

  void set(String productId, bool value) {
    state = {...state, productId: value};
  }
}

final wishlistStateProvider =
    StateNotifierProvider<WishlistStateNotifier, Map<String, bool>>(
      (ref) => WishlistStateNotifier(),
    );
