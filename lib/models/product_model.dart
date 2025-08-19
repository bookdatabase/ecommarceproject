class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discount;
  final double rating;
  final String imageUrl;
  final List<String> images;
  final String categoryId;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discount,
    required this.rating,
    required this.imageUrl,
    required this.images,
    required this.categoryId,
    required this.stock,
  });

  double get discountedPrice {
    if (discount != null) {
      return price - (price * discount! / 100);
    }
    return price;
  }

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: _parseDouble(map['price']),
      discount: _parseNullableDouble(map['discount']),
      rating: _parseDouble(map['rating']),
      imageUrl: map['imageUrl']?.toString() ?? '',
      images: _parseStringList(map['images']),
      categoryId: map['categoryId']?.toString() ?? '',
      stock: _parseInt(map['stock']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'discount': discount,
      'rating': rating,
      'imageUrl': imageUrl,
      'images': images,
      'categoryId': categoryId,
      'stock': stock,
    };
  }

  // Helper methods for type conversion
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? _parseNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List<String>) return value;
    if (value is List<dynamic>) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}
