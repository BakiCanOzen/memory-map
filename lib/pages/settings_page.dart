import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:memory_map/pages/login.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context,listen: true);
    Future<void> _deleteAccount(BuildContext context) async {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kullanıcı bulunamadı.")),
        );
        return;
      }

      try {
        // Firestore'daki kullanıcı verilerini sil
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

        // Firebase Authentication'dan kullanıcıyı sil
        await user.delete();

        // Kullanıcıyı başarıyla sildikten sonra giriş sayfasına yönlendir
        Navigator.pushReplacement(context,MaterialPageRoute(builder: (context)=>LoginPage()));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Hesabınız başarıyla silindi.")),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Hesabınızı silmek için yeniden oturum açmanız gerekiyor.",
              ),
            ),
          );

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Hata: ${e.message}")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bir hata oluştu: $e")),
        );
      }
    }
    Future<void> _saveThemeToPreferences(ThemeMode themeMode) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme', themeMode.toString());
    }
    Future<void> _loadThemeFromPreferences() async {
      final prefs = await SharedPreferences.getInstance();
      String? themeString = prefs.getString('theme');
      if (themeString != null) {
        if (themeString == ThemeMode.dark.toString()) {
          themeProvider.setTheme(ThemeMode.dark);
        } else {
          themeProvider.setTheme(ThemeMode.light);
        }
      }
    }
    _loadThemeFromPreferences();
    Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Hesabı Sil"),
            content: const Text("Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Diyalogdan çık
                },
                child: const Text("Vazgeç"),
              ),
              TextButton(
                onPressed: () {// Diyalogdan çık ve silme işlemini başlat
                  _deleteAccount(context); // Hesap silme işlemi
                },
                child: const Text("Evet, Sil"),
              ),
            ],
          );
        },
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Tema Ayarları"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Tema Seçimi",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            RadioListTile<ThemeMode>(
              selected: true,
              title: Text("Açık Tema"),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setTheme(value!);
                _saveThemeToPreferences(value);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text("Karanlık Tema"),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                themeProvider.setTheme(value!);
                _saveThemeToPreferences(value);
              },
            ),
        Expanded(child: Container()),
        Center(
          child: ElevatedButton(
            onPressed: () => _showDeleteConfirmationDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              "Hesabı Sil",
              style: TextStyle(color: Colors.white),
            )),
        ),
          ],
        ),
      ),
    );
  }
}
