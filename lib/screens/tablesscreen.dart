import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'menuscreen.dart';

class TablesScreen extends StatefulWidget {
  @override
  _TablesScreenState createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  final int totalTables = 15;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animasyon kontrolcüsü
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
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

  void _showTableDetails(BuildContext context, int tableNumber) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          height: screenHeight * 0.75,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepOrange.shade300,
                      Colors.deepOrange.shade100,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Masa $tableNumber',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          color: Colors.white,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _orderService.createTableOrder(tableNumber);
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MenuScreen(
                                  tableNumber: tableNumber,
                                  orderService: _orderService,
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_shopping_cart, size: 20),
                        label: const Text('Sipariş Başlat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_restaurant,
                          size: 72,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Bu masa şu anda boş',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Yeni bir sipariş başlatabilirsiniz',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutlarını al
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 350 || screenHeight < 600;
    
    // Küçük ekranlar için grid düzenini ayarla
    final crossAxisCount = isSmallScreen ? 2 : 3;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Masalar', 
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
      ),
      body: StreamBuilder<List<TableOrder>>(
        stream: _orderService.getAllActiveOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.deepOrange.shade50,
                    Colors.white,
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                ),
              ),
            );
          }

          final activeOrders = snapshot.data ?? [];
          final activeTableNumbers = activeOrders.map((order) => order.tableNumber).toSet();

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.deepOrange.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: GridView.builder(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 1,
                  crossAxisSpacing: isSmallScreen ? 8 : 12,
                  mainAxisSpacing: isSmallScreen ? 8 : 12,
                ),
                itemCount: 15,
                itemBuilder: (context, index) {
                  final tableNumber = index + 1;
                  final isOccupied = activeTableNumbers.contains(tableNumber);

                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 2 : 4,
                      vertical: isSmallScreen ? 2 : 4
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                    ),
                    child: InkWell(
                      onTap: isOccupied ? null : () => _showTableDetails(context, tableNumber),
                      borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                      splashColor: isOccupied ? Colors.transparent : Colors.deepOrange.withOpacity(0.2),
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 4 : 8),
                        decoration: BoxDecoration(
                          color: isOccupied ? Colors.grey.shade200 : Colors.white,
                          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 6 : 10),
                              decoration: BoxDecoration(
                                color: isOccupied 
                                    ? Colors.grey.shade300 
                                    : Colors.deepOrange.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.table_bar,
                                size: isSmallScreen ? 20 : 28,
                                color: isOccupied 
                                    ? Colors.grey.shade600 
                                    : Colors.deepOrange.shade700,
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 8),
                            Text(
                              'Masa $tableNumber',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
                                fontWeight: FontWeight.bold,
                                color: isOccupied 
                                    ? Colors.grey.shade600 
                                    : Colors.deepOrange,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: isSmallScreen ? 2 : 4),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 6 : 8, 
                                vertical: isSmallScreen ? 2 : 4
                              ),
                              decoration: BoxDecoration(
                                color: isOccupied 
                                    ? Colors.grey.shade300 
                                    : Colors.green.shade100,
                                borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                              ),
                              child: Text(
                                isOccupied ? 'Dolu' : 'Boş',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 9 : 11,
                                  fontWeight: FontWeight.bold,
                                  color: isOccupied 
                                      ? Colors.grey.shade700 
                                      : Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
