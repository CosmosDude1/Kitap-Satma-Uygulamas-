// main_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_detail_screen.dart';
import 'sell_book_screen.dart';
import 'notifications_screen.dart';

class MainScreen extends StatefulWidget {
  final List<String> favourites;
  final Function(String) onToggleFavourite;

  const MainScreen({
    Key? key,
    required this.favourites,
    required this.onToggleFavourite,
  }) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String? currentUserId;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
    }
  }

  Future<void> toggleFavourite(String bookId, String bookName, String price,
      String imageUrl, String seller_id) async {
    if (currentUserId == null) return;

    if (widget.favourites.contains(bookId)) {
      widget.onToggleFavourite(bookId);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('favourites')
          .doc(bookId)
          .delete();
    } else {
      widget.onToggleFavourite(bookId);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('favourites')
          .doc(bookId)
          .set({
        'book_name': bookName,
        'price': price,
        'image_url': imageUrl,
      });
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(seller_id)
        .collection('notifications')
        .add({
      'title': 'Ürün Favorilere Eklendi',
      'message': 'Bir kullanıcı "$bookName" adlı ürününüzü favorilere ekledi.',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addToCart(
      String bookName, String price, String imageUrl, String seller_id) async {
    if (currentUserId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('cart')
        .add({
      'book_name': bookName,
      'price': price,
      'image_url': imageUrl,
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(seller_id)
        .collection('notifications')
        .add({
      'title': 'Ürün Sepete Eklendi',
      'message': 'Bir kullanıcı "$bookName" adlı ürününüzü sepete ekledi.',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim();
                });
              },
              decoration: InputDecoration(
                labelText: 'Kitap Ara',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Öne Çıkan Ürünler',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('books').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Henüz kitap yok.'));
                  }

                  final books = snapshot.data!.docs.where((book) {
                    final seller_id = book['user_id'] as String;
                    final bookName = book['book_name']?.toLowerCase() ?? '';
                    final matchesSearch = searchQuery.isEmpty ||
                        bookName.contains(searchQuery.toLowerCase());
                    return seller_id != currentUserId && matchesSearch;
                  }).toList();

                  if (books.isEmpty) {
                    return const Center(
                        child: Text(
                            'Aradığınız kriterlere uygun kitap bulunmuyor.'));
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      final bookId = book.id;
                      final bookName = book['book_name'] ?? 'Bilinmeyen Kitap';
                      final imageUrl = book['image_url'] ?? '';
                      final price = book['price']?.toString() ?? 'Fiyat Yok';
                      final seller_id = book['user_id'] as String;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BookDetailScreen(bookId: bookId),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 4,
                          child: Column(
                            children: [
                              Expanded(
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image, size: 80),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                bookName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                '$price TL',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () => toggleFavourite(bookId,
                                        bookName, price, imageUrl, seller_id),
                                    icon: Icon(
                                      widget.favourites.contains(bookId)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: widget.favourites.contains(bookId)
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => addToCart(
                                        bookName, price, imageUrl, seller_id),
                                    icon: const Icon(
                                      Icons.shopping_cart,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SellBookScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.sell,
                    size: 30,
                    color: Colors.white,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Kitap Sat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
