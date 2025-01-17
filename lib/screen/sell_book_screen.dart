import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellBookScreen extends StatefulWidget {
  const SellBookScreen({Key? key}) : super(key: key);

  @override
  State<SellBookScreen> createState() => _SellBookScreenState();
}

final currentUserId = FirebaseAuth.instance.currentUser?.uid;

class _SellBookScreenState extends State<SellBookScreen> {
  final TextEditingController _bookNameController = TextEditingController();
  final TextEditingController _authorNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController(); // Yeni eklenen controller
  File? _image;
  String? _imageUrl;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_image == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('book_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(_image!);

      final imageUrl = await storageRef.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Resim yükleme hatası: $e');
      return null;
    }
  }

  void _sellBook() async {
    final bookName = _bookNameController.text;
    final authorName = _authorNameController.text;
    final price = _priceController.text;
    final description =
        _descriptionController.text; // Yeni eklenen description değişkeni

    if (bookName.isEmpty ||
        authorName.isEmpty ||
        price.isEmpty ||
        description.isEmpty || // Description kontrolü eklendi
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm alanları doldurun ve bir resim seçin!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final imageUrl = await _uploadImage();

      if (imageUrl == null) {
        throw Exception('Resim yüklenemedi.');
      }

      await FirebaseFirestore.instance.collection('books').add({
        'book_name': bookName,
        'author_name': authorName,
        'price': price,
        'description': description, // Description field'ı eklendi
        'image_url': imageUrl,
        'user_id': currentUserId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$bookName başarıyla kaydedildi!'),
          backgroundColor: Colors.green,
        ),
      );

      _bookNameController.clear();
      _authorNameController.clear();
      _priceController.clear();
      _descriptionController.clear(); // Description controller'ı temizlendi
      setState(() {
        _image = null;
        _imageUrl = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kitap kaydedilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitap Sat'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kitap Bilgilerini Girin',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _bookNameController,
                decoration: const InputDecoration(
                  labelText: 'Kitap Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _authorNameController,
                decoration: const InputDecoration(
                  labelText: 'Yazar Adı',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fiyat (₺)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                // Yeni eklenen description TextField'ı
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Kitap Açıklaması',
                  hintText: 'Kitabın durumu, özellikleri vs...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Resim Seç'),
              ),
              const SizedBox(height: 16),
              if (_image != null) Image.file(_image!),
              if (_imageUrl != null) Image.network(_imageUrl!),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _sellBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                  ),
                  child: const Text('Satış Yap'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
