import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'rate_seller_screen.dart';

class ShoppingHistoryScreen extends StatelessWidget {
  const ShoppingHistoryScreen({Key? key}) : super(key: key);

  // Kitabın satıcısını books collection'dan getir
  Future<Map<String, dynamic>?> _fetchBookSeller(String bookName) async {
    try {
      final bookQuery = await FirebaseFirestore.instance
          .collection('books')
          .where('book_name', isEqualTo: bookName)
          .get();

      if (bookQuery.docs.isNotEmpty) {
        final bookData = bookQuery.docs.first.data();
        return {
          'book_name': bookName,
          'seller_id': bookData['user_id'] ?? '',
        };
      }
      return null;
    } catch (e) {
      print('Kitap satıcısı bulunamadı: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchShoppingHistory() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      throw Exception('Kullanıcı oturum açmamış!');
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('purchaseHistory')
          .orderBy('date', descending: true)
          .get();

      List<Map<String, dynamic>> history = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final booksList = (data['books'] as List?)?.cast<String>() ?? [];

        // Her kitap için satıcı bilgisini al
        List<Map<String, dynamic>> booksWithSellers = [];
        for (String bookName in booksList) {
          final bookData = await _fetchBookSeller(bookName);
          if (bookData != null) {
            booksWithSellers.add(bookData);
          }
        }

        data['id'] = doc.id;
        data['booksWithSellers'] = booksWithSellers;
        history.add(data);
      }

      return history;
    } catch (e) {
      throw Exception('Veriler alınamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışveriş Geçmişi'),
        backgroundColor: Colors.deepOrange,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchShoppingHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Hata: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Henüz alışveriş geçmişiniz bulunmamaktadır.'),
            );
          }

          final history = snapshot.data!;
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final purchase = history[index];
              final books = purchase['books'] as List? ?? [];
              final booksWithSellers =
                  purchase['booksWithSellers'] as List<Map<String, dynamic>>? ??
                      [];
              final amount = purchase['amount'] as num? ?? 0.0;
              final date = (purchase['date'] as Timestamp?)?.toDate();

              // Benzersiz satıcı ID'lerini al
              final sellers = booksWithSellers
                  .map((book) => book['seller_id'] as String)
                  .where((id) => id.isNotEmpty)
                  .toSet()
                  .toList();

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alışveriş Tarihi: ${date != null ? '${date.day}/${date.month}/${date.year}' : 'Bilinmiyor'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Alınan Kitaplar:',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...books.map((book) => Text('- $book')),
                      const SizedBox(height: 8),
                      Text(
                        'Toplam Tutar: ₺${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (sellers.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RateSellerScreen(
                                  purchaseId: purchase['id'],
                                  sellers: sellers,
                                  books: booksWithSellers,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                          ),
                          child: const Text('Değerlendir'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
