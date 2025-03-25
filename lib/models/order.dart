import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String categoryId;
  final String? waiterId;
  final String? waiterName;

  OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.categoryId,
    this.waiterId,
    this.waiterName,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'categoryId': categoryId,
      'waiterId': waiterId,
      'waiterName': waiterName,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      price: (map['price'] is int) 
          ? (map['price'] as int).toDouble() 
          : (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] as int? ?? 0,
      categoryId: map['categoryId']?.toString() ?? '',
      waiterId: map['waiterId']?.toString(),
      waiterName: map['waiterName']?.toString(),
    );
  }
}

class TableOrder {
  final int tableNumber;
  final List<OrderItem> items;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final bool isActive;
  final bool isReady;

  TableOrder({
    required this.tableNumber,
    List<OrderItem>? items,
    this.createdAt,
    this.completedAt,
    this.isActive = true,
    this.isReady = false,
  }) : items = items ?? [];

  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);

  Map<String, dynamic> toMap() {
    return {
      'tableNumber': tableNumber,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isActive': isActive,
      'isReady': isReady,
    };
  }

  factory TableOrder.fromMap(Map<String, dynamic> map) {
    try {
      final itemsList = (map['items'] as List?)?.map((item) {
        if (item is Map<String, dynamic>) {
          return OrderItem.fromMap(item);
        }
        return null;
      }).whereType<OrderItem>().toList() ?? [];

      Timestamp? createdAtTimestamp = map['createdAt'] as Timestamp?;
      Timestamp? completedAtTimestamp = map['completedAt'] as Timestamp?;

      return TableOrder(
        tableNumber: map['tableNumber'] as int? ?? 0,
        items: itemsList,
        createdAt: createdAtTimestamp?.toDate(),
        completedAt: completedAtTimestamp?.toDate(),
        isActive: map['isActive'] as bool? ?? false,
        isReady: map['isReady'] as bool? ?? false,
      );
    } catch (e) {
      print('Error parsing TableOrder: $e');
      print('Map data: $map');
      rethrow;
    }
  }
} 