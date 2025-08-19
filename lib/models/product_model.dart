class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discount;
  final int stock;
  final double rating;
  final String imageUrl;
  final List<String> images;
  final List<String> categories;
  final bool isFeatured;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discount,
    required this.stock,
    required this.rating,
    required this.imageUrl,
    required this.images,
    required this.categories,
    this.isFeatured = false,
  });

  double get discountedPrice {
    return discount != null ? price * (1 - discount! / 100) : price;
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    int parseStock(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Product(
      id: id,
      name: map['name']?.toString() ?? 'Unknown Product',
      description: map['description']?.toString() ?? '',
      price: parseDouble(map['price']),
      discount: map['discount'] != null ? parseDouble(map['discount']) : null,
      stock: parseStock(map['stock']),
      rating: parseDouble(map['rating']),
      imageUrl: map['imageUrl']?.toString() ?? '',
      images: map['images'] != null
          ? List<String>.from(map['images'])
          : <String>[],
      categories: map['categories'] != null
          ? List<String>.from(map['categories'])
          : <String>[],
      isFeatured: map['isFeatured'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'discount': discount,
      'stock': stock,
      'rating': rating,
      'imageUrl': imageUrl,
      'images': images,
      'categories': categories,
      'isFeatured': isFeatured,
    };
  }
}
