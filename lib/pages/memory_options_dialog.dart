import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:memory_map/models/memory.dart';
import 'package:geolocator/geolocator.dart';

class MemoryOptionsPage extends StatefulWidget {
  final Function(Memory) onMemoryAdded;
  bool iscansee = true;
  final LatLng position; // Marker konumu

  MemoryOptionsPage({
    required this.onMemoryAdded,
    required this.position,
  });

  @override
  MemoryOptionsPageState createState() => MemoryOptionsPageState();
}
class MemoryOptionsPageState extends State<MemoryOptionsPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  bool isNameEntered = false;
  List<File> _selectedPhotos = [];
  User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _pickMultipleImages(BuildContext context, ImageSource source) async {
    if (source == ImageSource.camera) {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final result = await ImageGallerySaverPlus.saveFile(pickedFile.path);
        setState(() {
          _selectedPhotos.add(File(pickedFile.path)); // Kamera ile seçilen fotoğrafı ekle
        });
      }
    }
    else {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles != null && pickedFiles.isNotEmpty) {
        setState(() {
          _selectedPhotos.addAll(pickedFiles.map((file) => File(file.path)).toList()); // Galeriden seçilen fotoğrafları ekle
        });
      }
    }
    Navigator.pop(context); // Alt menüyü kapat
  }

  Future<void> saveMemory(Memory memory) async {
    try {
      if (currentUser != null) {
        String userId = currentUser!.uid; // Kullanıcının UID'sini al
        FirebaseFirestore firestore = FirebaseFirestore.instance;
        await firestore
            .collection('users')
            .doc(userId)
            .collection('memories')
            .doc(memory.id)
            .set(memory.toJson());
        print('Memory added to Firestore!');
      }
    } catch (e) {
      print('Error adding memory: $e');
    }
  }

  Future<void> _onConfirm() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lütfen anı adi giriniz!")),
      );
      return;
    }

    if (_selectedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lütfen en az bir fotoğraf seçiniz!")),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String memoryId = DateTime.now().millisecondsSinceEpoch.toString();
    List<String> photoPaths=[];
    for (var photo in _selectedPhotos) {
      photoPaths.add(photo.path);

      Memory memory = Memory(
        id: memoryId,
        photoUrl: photoPaths,
        latitude: position.latitude,
        longitude: position.longitude,
        name: _nameController.text,
      );

      widget.onMemoryAdded(memory);
      await saveMemory(memory);
    }

    print("Memory saved successfully!");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Memory"),
        backgroundColor: Colors.blue,
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // Klavyeyi kapatır
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Memory Name',
                            hintText: 'Enter the name of your memory',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              isNameEntered = value.isNotEmpty;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        // Fotoğraf Listesi Görüntüleme
                        _selectedPhotos.isNotEmpty
                            ? Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: _selectedPhotos.map((photo) {
                            return Stack(
                              children: [
                                Image.file(
                                  photo,
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: Icon(Icons.cancel, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _selectedPhotos.remove(photo); // Fotoğrafı listeden kaldır
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        )
                            : Text(
                          "No photos selected",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.camera),
                                      title: const Text('Take Photo from Camera'),
                                      onTap: () => _pickMultipleImages(context, ImageSource.camera),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.photo),
                                      title: const Text('Choose Photos from Gallery'),
                                      onTap: () => _pickMultipleImages(context, ImageSource.gallery),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Text('Add Photos'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                        Spacer(),
                        ElevatedButton(
                          onPressed: _onConfirm,
                          child: Text('Confirm'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
