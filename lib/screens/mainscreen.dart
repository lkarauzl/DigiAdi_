import 'package:flutter/material.dart';
import 'tablesscreen.dart';
import 'ordersscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'loginscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _userName = "";
  String _userRole = "";
  
  // Animasyon kontrolcüleri
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Personel bilgilerini getir
    _getUserInfo();
    
    // Animasyonları başlat
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuart,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    // Animasyonları başlat
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _getUserInfo() async {
    User? user = _auth.currentUser;
    
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && mounted) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userName = userData['name'] ?? "";
            _userRole = userData['role'] ?? "";
          });
        }
      } catch (e) {
        print("Kullanıcı bilgileri alınırken hata: $e");
      }
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekran boyutlarını al
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 380 || screenSize.height < 600;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepOrange.shade300,
              Colors.deepOrange.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 24, 
              vertical: isSmallScreen ? 16 : 24
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık ve profil alanı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SlideTransition(
                            position: _slideAnimation,
                            child: Text(
                              "Hoş Geldiniz",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 22 : 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(1, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SlideTransition(
                            position: _slideAnimation,
                            child: Text(
                              _userName,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _userRole,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 14,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      flex: 3,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: CircleAvatar(
                          radius: isSmallScreen ? 28 : 36,
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: Icon(
                              Icons.logout_rounded,
                              size: isSmallScreen ? 24 : 28,
                              color: Colors.deepOrange,
                            ),
                            onPressed: _signOut,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Ana içerik
                Expanded(
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 16 : 24
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Ana menü kartları
                                _buildMainCard(
                                  context: context,
                                  title: "Masalar",
                                  description: "Masaları görüntüle ve siparişleri yönet",
                                  icon: Icons.table_restaurant,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => TablesScreen()),
                                    );
                                  },
                                  color: Colors.deepOrange.shade400,
                                  isSmallScreen: isSmallScreen,
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 24),
                                _buildMainCard(
                                  context: context,
                                  title: "Siparişler",
                                  description: "Aktif ve tamamlanan siparişleri görüntüle",
                                  icon: Icons.receipt_long,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => OrdersScreen()),
                                    );
                                  },
                                  color: Colors.deepOrange.shade600,
                                  isSmallScreen: isSmallScreen,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Function() onTap,
    required Color color,
    required bool isSmallScreen,
  }) {
    final cardWidth = MediaQuery.of(context).size.width - (isSmallScreen ? 32 : 48);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: cardWidth,
          height: isSmallScreen ? 180 : 200,
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 22 : 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: isSmallScreen ? 24 : 30,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 40),
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16, 
                    vertical: isSmallScreen ? 6 : 8
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "Görüntüle",
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
