import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_map/pages/login.dart';
import 'package:memory_map/services/auth_services.dart'; // AuthService sınıfını içe aktar

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

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

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    setState(() => _isLoading = true);
    if (!_isValidEmail(email)) {
      _showError("Lütfen geçerli bir e-posta adresi girin.");
      return;
    }
    final userExists = await _checkIfUserExists(email);

    if (!userExists) {
      _showError("Bu e-posta adresine ait bir kullanıcı bulunamadı.");
      setState(() => _isLoading = false);
      return;
    }
    try {
      await _authService.resetPassword(_emailController.text.trim());
      _showSuccess("Şifre sıfırlama bağlantısı e-posta adresinize gönderildi.");
    } catch (e) {
      _showError("Şifre sıfırlama işlemi sırasında bir hata oluştu. Lütfen tekrar deneyin.");
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Future<bool> _checkIfUserExists(String email) async {
    try {
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      print("Kullanıcı kontrolü sırasında hata: $e");
      return false; // Bir hata oluşursa kullanıcı yokmuş gibi davranın
    }
  }

  void _showSuccess(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Başarılı"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacement(context,MaterialPageRoute(builder: (context)=>LoginPage())),
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
                    "Şifremi Unuttum",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "E-posta adresinizi girin, şifrenizi sıfırlamanız için bir bağlantı gönderilecektir.",
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
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      "Şifreyi Sıfırla",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(context,MaterialPageRoute(builder: (context)=>LoginPage()));// Kullanıcıyı giriş ekranına yönlendirir
                    },
                    child: const Text(
                      "Şifreni Hatırladın mı,Giriş yap",
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
