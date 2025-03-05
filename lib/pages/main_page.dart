import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memory_map/pages/memory_options_dialog.dart';
import 'package:memory_map/pages/profile.dart';
import 'package:memory_map/pages/settings_page.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/memory.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'memoryPage.dart';

class MainPage extends StatefulWidget {
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Memory> memories = [];
  double? locationX;
  User? currentUser;
  late LatLng _currentLatLng;
  double? locationY;
  List<Marker> _markers = [];
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      bool locationPermission = await _requestPermission(Permission.location);
      bool storagePermission=await _requestPermission(Permission.storage);
      if (locationPermission&&storagePermission) {
        getCurrentLoc();
        _getCurrentUser();
        _loadMemories().then((_) {
          _getprevmemories();
        });

    }
    });
  }
  void _getCurrentUser() {
    currentUser = FirebaseAuth.instance.currentUser;
    setState(() {});
  }
  Future<void> getCurrentLoc() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        locationX = position.latitude;
        locationY = position.longitude;
        _currentLatLng = LatLng(locationX!, locationY!);
      });
      _mapController.animateCamera(
        CameraUpdate.newLatLng(_currentLatLng),
      );
    } catch (e) {
      print("Konum alınamadı: $e");
    }
  }
  Future<void> _loadMemories() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String userId = currentUser!.uid;
      var snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('memories')
          .get();
      setState(() {
        memories = snapshot.docs.map((doc) {
          return Memory.fromJson(doc.data());
        }).toList();
      });
    } catch (e) {
      print("Error loading memories: $e");
    }
  }
  void _getprevmemories(){
    for(int i=0;i<memories.length;i++){
      if (!_markers.any((marker) => marker.markerId.value == memories[i].id)) {
        _addMemory(memories[i]);
      }
    }
  }
  void _deleteMemoryFromMainPage(Memory memory) {
    setState(() {
      memories.removeWhere((item) => item.id == memory.id);
      _markers.removeWhere((marker) => marker.markerId.value == memory.id);
    });
  }
  void _showMemoryDetails(Memory memory) {
    String date = formatEpochToDateString(memory.id);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(memory.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tarih: $date"),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: memory.photoUrl.map((photoPath) {
                    return Image.file(
                      File(photoPath),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Close"),
            ),
            TextButton(
              onPressed: () {

        showDialog(
        context: context,
        builder: (BuildContext context) {
        return AlertDialog(
        title: Text("Emin Misin?"),
        content: Text("Anını silmek istiyor musun?Bu işlem geri alınamaz"),
        actions: [
        TextButton(
        onPressed: () {
        Navigator.pop(context); // Onay diyaloğundan çık
        },
        child: Text("İptal"),
        ),
        TextButton(
        onPressed: () {
        // Kullanıcı onayladı, silme işlemini başlat
        _deleteMemory(memory);
        Navigator.pop(context); // Onay diyaloğundan çık
        Navigator.pop(context); // Detay diyaloğundan çık
        },
        child: Text("Sil", style: TextStyle(color: Colors.red)),
        ),
        ],
        );
        },
        );
        },
              child: Text("Anıyı Sil"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMemory(Memory memory) async {
    try {
      // Firestore'dan anıyı sil
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String userId = currentUser!.uid; // Şu an giriş yapan kullanıcının UID'sini al
      await firestore
          .collection('users')
          .doc(userId)
          .collection('memories')
          .doc(memory.id) // Silinecek belgenin ID'si
          .delete();

      // Listeden ve marker'dan sil
      setState(() {
        memories.removeWhere((item) => item.id == memory.id); // Listeden sil
        _markers.removeWhere((marker) => marker.markerId.value == memory.id); // Marker'ı kaldır
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Anı başarıyla silindi.")),
      );
    } catch (e) {
      print("Error deleting memory: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bir hata oluştu: $e")),
      );
    }
  }
  String formatEpochToDateString(String epochTimeString) {
    // String olan epoch zamanı int'e dönüştür
    int epochTime = int.parse(epochTimeString);

    // Epoch zamanı DateTime objesine dönüştür
    DateTime date = DateTime.fromMillisecondsSinceEpoch(epochTime);
    String formattedDate = "${date.day.toString().padLeft(2, '0')}:${date.month.toString().padLeft(2, '0')}:${date.year.toString().padLeft(2,'0')}-${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";

    return formattedDate;
  }

  void _addMemory(Memory memory) {
    setState(() {
      if (!memories.any((mem) => memory.id ==mem.id)) {
        memories.add(memory);
      }
      _markers.add(Marker(
        markerId: MarkerId(memory.id),
        position: LatLng(memory.latitude, memory.longitude),
        infoWindow: InfoWindow(
          title: "${memory.name}",
          snippet: "Anıyı görmek için tıklayınız",
        ),
        onTap: () {
          _showMemoryDetails(memory);
        },
      ));
    });
    print("Added marker: ${memory.id}");
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hafıza Haritası"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: getCurrentLoc,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: currentUser?.photoURL != null
                        ? NetworkImage(currentUser!.photoURL!)
                        : const AssetImage('assets/person.png')
                    as ImageProvider,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentUser?.displayName ?? 'Kullanıcı',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                   Text(
                     currentUser?.email ?? 'user@example.com',
                     style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Anılar'),
              onTap: () async{
                Navigator.push(context,MaterialPageRoute(builder: (context)=>MemoriesPage(memories: memories,onMemoryDeleted: _deleteMemoryFromMainPage,))); // Menüyü kapatır
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profil'),
              onTap: () {
                Navigator.push(context,MaterialPageRoute(builder: (context)=>ProfilePage(memoryLength: memories.length,)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Ayarlar'),
              onTap: () {
                Navigator.push(context,MaterialPageRoute(builder: (context)=>SettingsPage()));
              },
            ),
          ],
        ),
      ),
      body: locationX != null && locationY != null
          ? GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: LatLng(locationX!, locationY!),
          zoom: 10,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        markers: Set<Marker>.of(_markers),
      )
          : const Center(
        child: CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: ()async {
              MaterialPageRoute route=MaterialPageRoute(builder: (context)=>MemoryOptionsPage(onMemoryAdded: _addMemory,position: _currentLatLng,));
              Navigator.push(context,route);

        }
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
  Future<bool>_requestPermission(Permission permission) async {
    AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;
    if (build.version.sdkInt >= 30) {
      if (permission == Permission.location) {
        var result = await Permission.location.request();
        return result.isGranted;
      } else if (permission == Permission.storage) {
        var result = await Permission.manageExternalStorage.request();
        return result.isGranted;
      } else {
        return false;
      }
    } else {
      if (await permission.isGranted) {
        return true;
      } else {
        var result = await permission.request();
        return result.isGranted;
      }
    }
  }
}
