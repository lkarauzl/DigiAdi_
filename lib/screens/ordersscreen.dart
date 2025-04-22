import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/order.dart';
import '../services/order_service.dart';
import 'menuscreen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with TickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutlarını al
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 380 || screenSize.height < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Siparişler', style: TextStyle(fontSize: isSmallScreen ? 18 : 20)),
        backgroundColor: Colors.deepOrange,
      ),
      body: _buildOrdersList(isSmallScreen),
    );
  }

  Widget _buildOrdersList(bool isSmallScreen) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Hata oluştu: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: isSmallScreen ? 48 : 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aktif sipariş bulunmamaktadır',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(
              vertical: isSmallScreen ? 8 : 12, 
              horizontal: isSmallScreen ? 8 : 16
            ),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final orderDoc = snapshot.data!.docs[index];
              final orderData = orderDoc.data() as Map<String, dynamic>;
              
              // Masa adını belirle
              String masaText = _getMasaAdi(orderDoc);
              
              // Tarih
              final timestamp = orderData['createdAt'] as Timestamp?;
              final dateTime = timestamp?.toDate() ?? DateTime.now();
              final formattedDate = DateFormat('dd.MM.yyyy - HH:mm').format(dateTime);
              
              // Garson bilgisini kontrol et
              String waiterInfo = "";
              if (orderData.containsKey('waiterName') && orderData['waiterName'] != null) {
                waiterInfo = "Garson: ${orderData['waiterName']}";
              } else if (orderData.containsKey('waiterId') && orderData['waiterId'] != null) {
                waiterInfo = "Garson ID: ${orderData['waiterId']}";
              }
              
              // Toplam tutarı hesapla - items dizisindeki price * quantity değerlerini topla
              double totalAmount = 0.0;
              final items = orderData['items'] as List<dynamic>? ?? [];
              
              for (var item in items) {
                final itemData = item as Map<String, dynamic>;
                final price = itemData['price'] as double? ?? 0.0;
                final quantity = itemData['quantity'] as int? ?? 0;
                totalAmount += (price * quantity);
              }
              
              return Card(
                elevation: 2,
                margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              masaText,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepOrange,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Hazırlık durumunu göster
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 10, 
                              vertical: isSmallScreen ? 4 : 6
                            ),
                            decoration: BoxDecoration(
                              color: orderData['isReady'] == true 
                                  ? Colors.green.shade100 
                                  : Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  orderData['isReady'] == true 
                                      ? Icons.check_circle
                                      : Icons.hourglass_empty,
                                  size: isSmallScreen ? 14 : 16,
                                  color: orderData['isReady'] == true
                                      ? Colors.green.shade700
                                      : Colors.amber.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  orderData['isReady'] == true ? 'Hazır' : 'Hazırlanıyor',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 13,
                                    fontWeight: FontWeight.bold,
                                    color: orderData['isReady'] == true
                                        ? Colors.green.shade700
                                        : Colors.amber.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (waiterInfo.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 6 : 8,
                                vertical: isSmallScreen ? 2 : 4
                              ),
                              decoration: BoxDecoration(
                                color: Colors.deepOrange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                waiterInfo,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 11 : 12,
                                  color: Colors.deepOrange.shade800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        'Sipariş Detayları',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, idx) {
                          final item = items[idx] as Map<String, dynamic>;
                          final name = item['name'] ?? 'Bilinmeyen ürün';
                          final quantity = item['quantity'] ?? 0;
                          final price = item['price'] ?? 0.0;
                          final itemTotal = price * quantity;
                          
                          // Ürün için garson bilgisi kontrol et
                          String itemWaiterName = "";
                          if (item.containsKey('waiterName') && item['waiterName'] != null) {
                            itemWaiterName = item['waiterName'];
                          } else if (item.containsKey('waiterId') && item['waiterId'] != null) {
                            itemWaiterName = "ID: ${item['waiterId']}";
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        name,
                                        style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '${quantity}x',
                                        style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        '₺${price.toStringAsFixed(2)}',
                                        style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                                if (itemWaiterName.isNotEmpty) 
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2, left: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          itemWaiterName,
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 10 : 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Toplam',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₺${totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (orderData['isReady'] == true) {
                              _completeOrder(orderDoc.id);
                            } else {
                              _markOrderAsReady(orderDoc.id);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orderData['isReady'] == true 
                                ? Colors.green 
                                : Colors.amber.shade700,
                            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10 : 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                orderData['isReady'] == true
                                    ? Icons.check_circle
                                    : Icons.restaurant,
                                size: isSmallScreen ? 18 : 20,
                              ),
                              SizedBox(width: isSmallScreen ? 6 : 8),
                              Text(
                                orderData['isReady'] == true
                                    ? 'Siparişi Tamamla'
                                    : 'Siparişi Hazırla',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _completeOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'isActive': false,
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş başarıyla tamamlandı!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata oluştu: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Siparişi hazır olarak işaretle
  Future<void> _markOrderAsReady(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'isReady': true,
        'readyAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş hazır olarak işaretlendi!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.amber,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata oluştu: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Masa adını belirlemek için özel fonksiyon
  String _getMasaAdi(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return 'Masa Bilinmiyor';
    
    // 1. Doğrudan tableNumber alanını kontrol et
    if (data.containsKey('tableNumber')) {
      final tableNumber = data['tableNumber'];
      if (tableNumber != null) {
        return 'Masa $tableNumber';
      }
    }
    
    // 2. Belge ID kontrolü - Firebase ekran görüntüsünde belge ID'lerinin 1, 2, 3.. olarak göründüğünü gördük
    try {
      final docId = doc.id;
      final idNumber = int.tryParse(docId);
      if (idNumber != null) {
        return 'Masa $idNumber';
      }
    } catch (_) {}
    
    // 3. Diğer olası alanları kontrol et
    for (final field in ['masa', 'masaNo', 'table', 'tableId']) {
      if (data.containsKey(field)) {
        final value = data[field];
        if (value != null) {
          return 'Masa $value';
        }
      }
    }
    
    return 'Masa Bilinmiyor';
  }
}