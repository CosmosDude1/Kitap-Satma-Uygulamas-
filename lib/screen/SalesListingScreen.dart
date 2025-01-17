import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SalesListingScreen extends StatelessWidget {
  const SalesListingScreen({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchUserBooks() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      throw Exception('Kullanıcı oturum açmamış!');
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('books') // Books koleksiyonu
          .get();

      // Kullanıcının user_id'sine eşit olan belgeleri filtrele
      final userBooks = snapshot.docs
          .where((doc) => doc['user_id'] == userId)
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return userBooks;
    } catch (e) {
      throw Exception('Kitap verileri alınamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Satış Listesi'),
        backgroundColor: Colors.deepOrange,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchUserBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Hata: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Satışta olan kitaplarınız bulunmamaktadır.'),
            );
          } else {
            final books = snapshot.data!;

            return ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                final bookName =
                    book['book_name'] as String? ?? 'Bilinmeyen Kitap';
                final bookPrice = _parsePrice(book['price']);
                final bookDescription =
                    book['description'] as String? ?? ''; // Açıklama örneği

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kitap Adı: $bookName',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fiyat: ₺${bookPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Açıklama: $bookDescription',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  /// Fiyatı doğru türe çevirir.
  double _parsePrice(dynamic price) {
    if (price is double) {
      return price;
    } else if (price is String) {
      return double.tryParse(price) ?? 0.0;
    } else {
      return 0.0;
    }
  }
}
