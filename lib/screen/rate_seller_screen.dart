import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RateSellerScreen extends StatefulWidget {
  final String purchaseId;
  final List<String> sellers;
  final List<Map<String, dynamic>> books;

  const RateSellerScreen({
    Key? key,
    required this.purchaseId,
    required this.sellers,
    required this.books,
  }) : super(key: key);

  @override
  State<RateSellerScreen> createState() => _RateSellerScreenState();
}

class _RateSellerScreenState extends State<RateSellerScreen> {
  final Map<String, double> _ratings = {};
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, String> _sellerNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchSellerNames();
  }

  void _initializeControllers() {
    for (var sellerId in widget.sellers) {
      _ratings[sellerId] = 0;
      _commentControllers[sellerId] = TextEditingController();
    }
  }

  Future<void> _fetchSellerNames() async {
    setState(() => _isLoading = true);
    try {
      for (var sellerId in widget.sellers) {
        final sellerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(sellerId)
            .get();
        if (sellerDoc.exists) {
          _sellerNames[sellerId] =
              sellerDoc.data()?['name'] ?? 'Bilinmeyen Satıcı';
        }
      }
    } catch (e) {
      print('Satıcı isimleri alınamadı: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRating(String sellerId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      // Önce kullanıcı adını al
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userName = userDoc.data()?['name'] ?? 'Bilinmeyen Kullanıcı';

      final batch = FirebaseFirestore.instance.batch();

      // Rating ekle
      final ratingRef = FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .collection('ratings')
          .doc();

      batch.set(ratingRef, {
        'rating': _ratings[sellerId],
        'user_id': currentUser.uid,
        'user_name': userName, // Users collection'dan alınan isim
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Yorum varsa ekle
      if (_commentControllers[sellerId]?.text.isNotEmpty ?? false) {
        final commentRef = FirebaseFirestore.instance
            .collection('users')
            .doc(sellerId)
            .collection('comments')
            .doc();

        batch.set(commentRef, {
          'comment': _commentControllers[sellerId]?.text,
          'user_id': currentUser.uid,
          'user_name': userName, // Users collection'dan alınan isim
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Değerlendirmeniz kaydedildi!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata oluştu: $e')),
      );
    }
  }

  @override
  void dispose() {
    _commentControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Satıcıları Değerlendir'),
        backgroundColor: Colors.deepOrange,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.sellers.length,
        itemBuilder: (context, index) {
          final sellerId = widget.sellers[index];
          final sellerName = _sellerNames[sellerId] ?? 'Bilinmeyen Satıcı';
          final sellerBooks = widget.books
              .where((book) => book['seller_id'] == sellerId)
              .map((book) => book['book_name'] as String)
              .toList();

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sellerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Satın Alınan Kitaplar: ${sellerBooks.join(", ")}'),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                          i < (_ratings[sellerId] ?? 0).floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          setState(() {
                            _ratings[sellerId] = (i + 1).toDouble();
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentControllers[sellerId],
                    decoration: const InputDecoration(
                      labelText: 'Yorumunuz (İsteğe bağlı)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _submitRating(sellerId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                    ),
                    child: const Text('Değerlendirmeyi Gönder'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
