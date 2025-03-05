import 'dart:convert';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/memory.dart';

class MemoriesPage extends StatefulWidget {
  List<Memory> memories = [];
  final Function(Memory) onMemoryDeleted;
  MemoriesPage({required this.memories,required this.onMemoryDeleted});
  @override
  _MemoriesPageState createState() => _MemoriesPageState();
}
class _MemoriesPageState extends State<MemoriesPage> {
  late Map<String,List<Memory>> groupedMemories={};
  User? currentUser = FirebaseAuth.instance.currentUser;
  Map<String, String> cityCache = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      _groupMemoriesByCity();
    });
    _groupMemoriesByCity();
  }
  @override
  Future<String> getCityName(double latitude, double longitude) async {
    String locationKey = '$latitude,$longitude';
    if (cityCache.containsKey(locationKey)) {
      return cityCache[locationKey]!;
    }
    String apiKey = 'AIzaSyAGc7OiihLXFBHfcDB3vV_u0g-E00uay2E';
    String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        print(response.body);
        // API başarılı bir şekilde yanıt verdi
        var data = json.decode(response.body);

        // Geocode API yanıtından şehir bilgisi alın
        if (data['results'] != null && data['results'].isNotEmpty) {
          for (var result in data['results']) {
            for (var component in result['address_components']) {
              // "locality" tipini kontrol ediyoruz, ancak diğer bileşenleri de kontrol ediyoruz
              if (component['types'].contains('locality')) {
                // Şehir adı bulunursa, onu döndür
                cityCache[locationKey] = component['long_name'];
                return component['long_name'];
              }
              // Eğer locality bulunamazsa, başka bir bileşeni kontrol et
              else if (component['types'].contains('administrative_area_level_1')) {
                // Eyalet veya il ismini döndürebiliriz
                cityCache[locationKey] = component['long_name'];
                return component['long_name'];
              }
              // Eğer hala şehir bulunamazsa, ülke bilgisini al
              else if (component['types'].contains('country')) {
                cityCache[locationKey] = component['long_name'];
                return component['long_name'];
              }
            }
          }
          return 'Şehir bulunamadı';
        } else {
          return 'Geçerli bir sonuç bulunamadı';
        }
      } else {
        return 'API hatası: ${response.statusCode}';
      }
    } catch (e) {
      print('Hata: $e');
      return 'Hata oluştu';
    }
  }
  String formatEpochToDateString(String epochTimeString) {
    // String olan epoch zamanı int'e dönüştür
    int epochTime = int.parse(epochTimeString);

    // Epoch zamanı DateTime objesine dönüştür
    DateTime date = DateTime.fromMillisecondsSinceEpoch(epochTime);
    String formattedDate = "${date.day.toString().padLeft(2, '0')}:${date.month.toString().padLeft(2, '0')}:${date.year.toString()}";

    return formattedDate;
  }
  void _showMemoryDetails(Memory memory) {
    String date = formatEpochToDateString(memory.id); // ID'den tarih formatını al
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
                // Silmeden önce onay diyaloğu aç
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
        widget.memories.removeWhere((item) => item.id == memory.id); // Listeden sil
        _groupMemoriesByCity();

      });
      widget.onMemoryDeleted(memory);
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
  Future<void> _groupMemoriesByCity() async {
    Map<String, List<Memory>> cityMap = {};
    for (var memory in widget.memories) {
      final cityName = await getCityName(memory.latitude, memory.longitude);
      if (!cityMap.containsKey(cityName)) {
        cityMap[cityName] = [];
      }
      cityMap[cityName]!.add(memory);
    }
    setState(() {
      groupedMemories = cityMap;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Anılarım"),
      ),
      body: groupedMemories.isEmpty
          ? const Center(
        child: Text(
          "Hiç anın yok, hadi anı biriktirelim!",
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView(
        children: groupedMemories.entries.map((entry) {
          final city = entry.key;
          final cityMemories = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ExpansionTile(
              title: Text(
                city,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              children: cityMemories.map((memory) {
                return ListTile(
                  leading: Image.file(
                    File(memory.photoUrl[0]),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(
                    "${memory.name}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => _showMemoryDetails(memory),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
