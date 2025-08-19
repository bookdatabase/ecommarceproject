import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartScreen extends StatelessWidget {
  final String userId;

  const CartScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('carts')
            .doc(userId)
            .collection('items')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final cartItems = snapshot.data!.docs;
          if (cartItems.isEmpty) {
            return const Center(child: Text('Cart is empty'));
          }

          return ListView.builder(
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return ListTile(
                leading: Image.network(
                  item['imageUrl'],
                  width: 50,
                  fit: BoxFit.cover,
                ),
                title: Text(item['name']),
                subtitle: Text('\$${item['price']} x ${item['quantity']}'),
                trailing: Text(
                  '\$${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
