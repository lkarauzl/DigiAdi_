import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mainscreen.dart';
import 'adminscreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adminCodeController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false;
  bool _isLoginMode = true; // true: login, false: signup
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    
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

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('email') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
      _rememberMe = prefs.getBool('rememberMe') ?? false;
    });
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('email', _emailController.text);
      await prefs.setString('password', _passwordController.text);
      await prefs.setBool('rememberMe', true);
    } else {
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.setBool('rememberMe', false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();

      // Login moduna geçerken önceden kaydedilmiş bilgileri yükle
      if (_isLoginMode) {
        _loadSavedCredentials();
      } else {
        // Signup moduna geçerken form alanlarını temizle
        _emailController.clear();
        _passwordController.clear();
        _nameController.clear();
        _confirmPasswordController.clear();
        _adminCodeController.clear();
      }
      
      // Geçiş animasyonu
      _animationController.reset();
      _animationController.forward();
    });
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _saveCredentials();

      if (userCredential.user != null && mounted) {
        await _checkUserRoleAndNavigate(userCredential.user!.uid);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Bir hata oluştu';
      if (e.code == 'user-not-found') {
        message = 'Bu e-posta adresi ile kayıtlı kullanıcı bulunamadı';
      } else if (e.code == 'wrong-password') {
        message = 'Yanlış şifre';
      } else if (e.code == 'invalid-email') {
        message = 'Geçersiz e-posta adresi';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giriş başarısız: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignup(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final name = _nameController.text.trim();
      final adminCode = _adminCodeController.text.trim();

      // Admin kodu kontrolü (Bu kod güvenlik için gerçek projede değiştirilmelidir)
      if (adminCode != 'admin123') {
        throw Exception('Geçersiz admin kodu');
      }

      // Kullanıcı kaydı
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı bilgilerini Firestore'a kaydet
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'role': 'admin', // Admin olarak kaydediliyor
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin kaydı başarıyla oluşturuldu. Giriş yapabilirsiniz.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        // Kayıt başarılı olduktan sonra giriş moduna geç
        setState(() {
          _isLoginMode = true;
        });
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Bir hata oluştu';
      if (e.code == 'weak-password') {
        message = 'Şifre çok zayıf';
      } else if (e.code == 'email-already-in-use') {
        message = 'Bu e-posta adresi zaten kullanılıyor';
      } else if (e.code == 'invalid-email') {
        message = 'Geçersiz e-posta adresi';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt başarısız: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkUserRoleAndNavigate(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('Kullanıcı bilgileri bulunamadı');
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userRole = userData['role'] as String;

      if (!mounted) return;

      if (userRole == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
        );
      } else if (userRole == 'garson') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      } else {
        throw Exception('Geçersiz kullanıcı rolü');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kullanıcı rolü kontrolünde hata: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    _adminCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepOrange.shade300,
              Colors.deepOrange.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo veya İkon
                      Hero(
                        tag: 'logo',
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.restaurant_menu,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Hoşgeldiniz Yazısı
                      const Text(
                        'DigiAdi',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.5,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black26,
                              offset: Offset(0, 5.0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Restoran Yönetim Sistemi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Giriş/Kayıt Formu
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _isLoginMode 
                                      ? Icons.login 
                                      : Icons.admin_panel_settings,
                                    color: Colors.deepOrange,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isLoginMode ? 'Giriş Yap' : 'Admin Kaydı',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Divider(color: Colors.black12),
                              const SizedBox(height: 24),
                              
                              // İsim alanı (sadece kayıt modunda)
                              if (!_isLoginMode)
                                Column(
                                  children: [
                                    TextFormField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        labelText: 'Ad Soyad',
                                        hintText: 'Ad ve soyadınızı girin',
                                        prefixIcon: const Icon(Icons.person_outline, color: Colors.deepOrange),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.deepOrange),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                      ),
                                      validator: (value) {
                                        if (!_isLoginMode && (value == null || value.isEmpty)) {
                                          return 'Lütfen adınızı ve soyadınızı girin';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              
                              // E-posta alanı
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'E-posta',
                                  hintText: 'E-posta adresinizi girin',
                                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.deepOrange),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.deepOrange),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Lütfen e-posta adresinizi girin';
                                  }
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Geçerli bir e-posta adresi girin';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              
                              // Şifre alanı
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Şifre',
                                  hintText: 'Şifrenizi girin',
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.deepOrange),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Colors.deepOrange),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                obscureText: _obscurePassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Lütfen şifrenizi girin';
                                  }
                                  if (!_isLoginMode && value.length < 6) {
                                    return 'Şifre en az 6 karakter olmalıdır';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              
                              // Şifre onayı alanı (sadece kayıt modunda)
                              if (!_isLoginMode)
                                Column(
                                  children: [
                                    TextFormField(
                                      controller: _confirmPasswordController,
                                      decoration: InputDecoration(
                                        labelText: 'Şifre Onayı',
                                        hintText: 'Şifrenizi tekrar girin',
                                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.deepOrange),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword = !_obscureConfirmPassword;
                                            });
                                          },
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.deepOrange),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                      ),
                                      obscureText: _obscureConfirmPassword,
                                      validator: (value) {
                                        if (!_isLoginMode) {
                                          if (value == null || value.isEmpty) {
                                            return 'Lütfen şifrenizi tekrar girin';
                                          }
                                          if (value != _passwordController.text) {
                                            return 'Şifreler eşleşmiyor';
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Admin kodu alanı
                                    TextFormField(
                                      controller: _adminCodeController,
                                      decoration: InputDecoration(
                                        labelText: 'Admin Kodu',
                                        hintText: 'Admin kodunu girin',
                                        prefixIcon: const Icon(Icons.admin_panel_settings, color: Colors.deepOrange),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: Colors.deepOrange),
                                        ),
                                        filled: true,
                                        fillColor: Colors.grey.shade50,
                                      ),
                                      validator: (value) {
                                        if (!_isLoginMode && (value == null || value.isEmpty)) {
                                          return 'Lütfen admin kodunu girin';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              
                              // Beni hatırla seçeneği (sadece giriş modunda)
                              if (_isLoginMode)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (value) {
                                            setState(() {
                                              _rememberMe = value ?? false;
                                            });
                                          },
                                          activeColor: Colors.deepOrange,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Beni Hatırla',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              const SizedBox(height: 32),
                              
                              // Giriş/Kayıt Butonu
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading 
                                      ? null 
                                      : () => _isLoginMode 
                                          ? _handleLogin(context) 
                                          : _handleSignup(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              _isLoginMode ? Icons.login : Icons.person_add,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              _isLoginMode ? 'Giriş Yap' : 'Kayıt Ol',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              
                              // Mod değiştirme butonu
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isLoginMode 
                                        ? 'Henüz bir hesabın yok mu?' 
                                        : 'Zaten bir hesabın var mı?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _toggleMode,
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.deepOrange,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    child: Text(
                                      _isLoginMode 
                                          ? 'Admin hesabı oluştur' 
                                          : 'Giriş yap',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
