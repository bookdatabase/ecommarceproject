import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eaglesteelfurniture/screens/cartscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

/// Wishlist StateNotifier
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

/// Global Wishlist provider
final wishlistStateProvider =
    StateNotifierProvider<WishlistStateNotifier, Map<String, bool>>(
      (ref) => WishlistStateNotifier(),
    );

/// Cart StateNotifier to track cart count
class CartStateNotifier extends StateNotifier<int> {
  CartStateNotifier() : super(0);

  void setCount(int count) => state = count;

  void increment(int value) => state += value;

  void decrement(int value) => state -= value;
}

/// Global Cart provider
final cartProvider = StateNotifierProvider<CartStateNotifier, int>(
  (ref) => CartStateNotifier(),
);

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int quantity = 1;
  int _selectedImageIndex = 0;
  bool isLoadingCartCount = true;

  @override
  void initState() {
    super.initState();
    _loadCartCount();
  }

  /// Load initial cart count from Firestore
  Future<void> _loadCartCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .get();

      int totalQuantity = 0;
      for (var doc in cartSnapshot.docs) {
        totalQuantity += (doc.data()['quantity'] ?? 0) as int;
      }
      ref.read(cartProvider.notifier).setCount(totalQuantity);
    }
    setState(() => isLoadingCartCount = false);
  }

  /// Toggle wishlist with instant UI update
  Future<void> _toggleWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to use wishlist')),
      );
      return;
    }

    final wishlistRef = FirebaseFirestore.instance
        .collection('wishlists')
        .doc(user.uid)
        .collection('items')
        .doc(widget.product.id);

    final wishlistNotifier = ref.read(wishlistStateProvider.notifier);
    final isInWishlist = wishlistNotifier.isInWishlist(widget.product.id);

    // Optimistic UI update
    wishlistNotifier.toggle(widget.product.id);

    try {
      if (isInWishlist) {
        await wishlistRef.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.name} removed from wishlist'),
          ),
        );
      } else {
        await wishlistRef.set(widget.product.toMap());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.product.name} added to wishlist')),
        );
      }
    } catch (e) {
      // Revert on error
      wishlistNotifier.set(widget.product.id, isInWishlist);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  /// Add to cart with instant feedback and increment badge
  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add to cart')),
      );
      return;
    }

    // Increment cart badge instantly
    ref.read(cartProvider.notifier).increment(quantity);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.product.name} added to cart')),
    );

    final cartRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(widget.product.id);

    try {
      final cartItem = await cartRef.get();

      if (cartItem.exists) {
        final currentQuantity = (cartItem.data()?['quantity'] ?? 0) as int;
        await cartRef.update({
          'quantity': currentQuantity + quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await cartRef.set({
          'productId': widget.product.id,
          'name': widget.product.name,
          'price': widget.product.discountedPrice,
          'quantity': quantity,
          'imageUrl': widget.product.imageUrl,
          'addedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding to cart: $e')));
    }
  }

  void _openImageGallery(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            PageView.builder(
              itemCount: widget.product.images.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 3,
                  child: CachedNetworkImage(
                    imageUrl: widget.product.images[index],
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.error),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null || user.isAnonymous;

    final isInWishlist =
        ref.watch(wishlistStateProvider)[widget.product.id] ?? false;
    final cartCount = ref.watch(cartProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            actions: [
              if (!isGuest)
                IconButton(
                  icon: Icon(
                    isInWishlist ? Icons.favorite : Icons.favorite_border,
                    color: isInWishlist ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleWishlist,
                ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: () {
                      if (isGuest) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please log in to view cart'),
                          ),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartScreen(userId: user!.uid),
                        ),
                      );
                    },
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: GestureDetector(
                onTap: () => _openImageGallery(context, _selectedImageIndex),
                child: CachedNetworkImage(
                  imageUrl: widget.product.images.isNotEmpty
                      ? widget.product.images[_selectedImageIndex]
                      : widget.product.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rating & Price
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber[600], size: 20),
                          const SizedBox(width: 4),
                          Text(widget.product.rating.toStringAsFixed(1)),
                        ],
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (widget.product.discount != null &&
                              widget.product.discount! > 0)
                            Text(
                              '\$${widget.product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            '\$${widget.product.discountedPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Discount badge
                  if (widget.product.discount != null &&
                      widget.product.discount! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.product.discount!.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  // Images List
                  if (widget.product.images.length > 1) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Product Images',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.product.images.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImageIndex = index;
                              });
                            },
                            child: Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _selectedImageIndex == index
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[300]!,
                                  width: _selectedImageIndex == index ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: CachedNetworkImage(
                                  imageUrl: widget.product.images[index],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error),
                                      ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Quantity selector
                  if (widget.product.stock > 0) ...[
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: quantity > 1
                              ? () => setState(() => quantity--)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            quantity.toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: quantity < widget.product.stock
                              ? () => setState(() => quantity++)
                              : null,
                        ),
                        const Spacer(),
                        Text(
                          '${widget.product.stock} available',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 32),

                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.product.stock > 0 && !isGuest
                          ? _addToCart
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      child: Text(
                        isGuest
                            ? 'Login to Add to Cart'
                            : widget.product.stock > 0
                            ? 'Add to Cart - \$${(widget.product.discountedPrice * quantity).toStringAsFixed(2)}'
                            : 'Out of Stock',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  if (isGuest) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Please log in to use wishlist and cart features',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
