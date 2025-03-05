import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_map/pages/login.dart';
import 'package:memory_map/services/auth_services.dart'; // AuthService sınıfını içe aktar

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isValidPassword(String password) {
    // Şifre doğrulama için regex
    final passwordRegex = RegExp(
        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9]).{8,}$'); // En az bir büyük harf, bir küçük harf, bir rakam ve 8 karakter
    return passwordRegex.hasMatch(password);
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hata"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _registerWithEmail() async {
    setState(() => _isLoading = true);
    if (!_isValidEmail(_emailController.text.trim())) {
      setState(() => _isLoading = false);
      _showError("Lütfen geçerli bir e-posta adresi girin.");
      return;
    }
    if (!_isValidPassword(_passwordController.text.trim())) {
      setState(() => _isLoading = false);
      _showError(
          "Şifreniz en az 8 karakter uzunluğunda, bir büyük harf, bir küçük harf ve bir rakam içermelidir.");
      return;
    }
    try {
      await _authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hesabınız başarıyla silindi.")));
      Navigator.pop(context);
    } catch (e) {
      _showError("Kayıt işlemi sırasında bir hata oluştu. Lütfen tekrar deneyin.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async  => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 50),
                  Text(
                    "Yeni Hesap Oluştur",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Hesabınız yok mu? Kayıt olun.",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),
                  SingleChildScrollView(
                    child: TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "E-posta",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.email),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    child: TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: "Şifre",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _registerWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Kayıt Ol",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(context,MaterialPageRoute(builder: (context)=>LoginPage()));; // Zaten hesabınız varsa, login sayfasına yönlendirir
                    },
                    child: const Text(
                      "Zaten hesabınız var mı? Giriş yapın",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
