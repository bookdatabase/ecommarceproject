// providers/wishlist_provider.dart
import 'package:eaglesteelfurniture/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final wishlistProvider = StreamProvider<List<Product>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('wishlists')
      .doc(user.uid)
      .collection('items')
      .snapshots()
      .handleError((error) {
        debugPrint('Wishlist stream error: $error');
        return [];
      })
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            // Ensure all fields have proper default values
            final data = doc.data();
            return Product.fromMap({
              'name': data['name'] ?? 'Unknown Product',
              'description': data['description'] ?? '',
              'price': data['price'] ?? 0.0,
              'discount': data['discount'],
              'stock': data['stock'] ?? 0,
              'rating': data['rating'] ?? 0.0,
              'imageUrl': data['imageUrl'] ?? '',
              'images': List<String>.from(data['images'] ?? []),
              'categories': List<String>.from(
                data['categories'] ?? [],
              ), // Ensure categories is never null
              'isFeatured': data['isFeatured'] ?? false,
            }, doc.id);
          } catch (e) {
            debugPrint('Error parsing wishlist item: $e');
            // Return a dummy product if parsing fails
            return Product(
              id: doc.id,
              name: 'Invalid Product',
              description: '',
              price: 0,
              stock: 0,
              rating: 0,
              imageUrl: '',
              images: [],
              categories: [],
            );
          }
        }).toList();
      });
});

final isProductInWishlistProvider = FutureProvider.family<bool, String>((
  ref,
  productId,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  try {
    final doc = await FirebaseFirestore.instance
        .collection('wishlists')
        .doc(user.uid)
        .collection('items')
        .doc(productId)
        .get();

    return doc.exists;
  } catch (e) {
    debugPrint('Error checking wishlist: $e');
    return false;
  }
});
