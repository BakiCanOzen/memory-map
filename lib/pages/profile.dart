import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:memory_map/pages/login.dart';

class ProfilePage extends StatelessWidget {
  final int memoryLength;

  ProfilePage({required this.memoryLength});

  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profil"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profil resmi
              CircleAvatar(
                radius: 50,
                backgroundImage: currentUser?.photoURL != null
                    ? NetworkImage(currentUser!.photoURL!)
                    : AssetImage('assets/default_profile.png') as ImageProvider,
                backgroundColor: Colors.grey[200],
              ),
              SizedBox(height: 16),
              // Kullanıcı adı
              Text(
                currentUser?.displayName ?? "Kullanıcı Adı Yok",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              // Kullanıcı email
              Text(
                currentUser?.email ?? "Email Yok",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              // Toplam anı sayısı
              Text(
                "Toplam Anılar: $memoryLength",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.blueAccent,
                ),
              ),
              Spacer(),
              ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context)=>LoginPage()));
                },
                icon: Icon(Icons.logout,color: Colors.white,),
                label: Text("Çıkış Yap",style:
                  TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
