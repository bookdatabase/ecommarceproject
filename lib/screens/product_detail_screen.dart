import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eaglesteelfurniture/screens/cartscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../core/providers/wishlistprovider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int quantity = 1;

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

    final isInWishlist = await wishlistRef.get().then((doc) => doc.exists);

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _addToCart() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add to cart')),
      );
      return;
    }

    try {
      final cartRef = FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .doc(widget.product.id);

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.product.name} added to cart')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding to cart: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null || user.isAnonymous;

    final isInWishlistAsync = isGuest
        ? AsyncValue.data(false)
        : ref.watch(isProductInWishlistProvider(widget.product.id));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            actions: [
              // Wishlist button - only for logged in users
              if (!isGuest)
                isInWishlistAsync.when(
                  data: (isInWishlist) => IconButton(
                    icon: Icon(
                      isInWishlist ? Icons.favorite : Icons.favorite_border,
                      color: isInWishlist ? Colors.red : Colors.white,
                    ),
                    onPressed: _toggleWishlist,
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (error, stack) => IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: _toggleWishlist,
                  ),
                ),
              // Cart button
              IconButton(
                icon: const Icon(Icons.shopping_cart),
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
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.product.imageUrl,
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 24),
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
                  Row(
                    children: [
                      // Wishlist button
                      if (!isGuest)
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: isInWishlistAsync.when(
                              data: (isInWishlist) => Icon(
                                isInWishlist
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: isInWishlist ? Colors.red : null,
                              ),
                              loading: () => const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, stack) =>
                                  const Icon(Icons.favorite_border),
                            ),
                            label: isInWishlistAsync.when(
                              data: (isInWishlist) => Text(
                                isInWishlist
                                    ? 'In Wishlist'
                                    : 'Add to Wishlist',
                              ),
                              loading: () => const Text('Loading...'),
                              error: (error, stack) =>
                                  const Text('Add to Wishlist'),
                            ),
                            onPressed: _toggleWishlist,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      if (!isGuest) const SizedBox(width: 16),
                      // Add to Cart button
                      Expanded(
                        flex: isGuest ? 1 : 2,
                        child: ElevatedButton(
                          onPressed: widget.product.stock > 0
                              ? _addToCart
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          child: Text(
                            widget.product.stock > 0
                                ? 'Add to Cart - \$${(widget.product.discountedPrice * quantity).toStringAsFixed(2)}'
                                : 'Out of Stock',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
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
