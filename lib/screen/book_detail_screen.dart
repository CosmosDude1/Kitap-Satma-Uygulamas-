// book_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class BookDetailScreen extends StatelessWidget {
  final String bookId;

  const BookDetailScreen({Key? key, required this.bookId}) : super(key: key);

  Future<double> _getSellerRating(String sellerId) async {
    try {
      final ratingsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .collection('ratings')
          .get();

      if (ratingsSnapshot.docs.isEmpty) return 0.0;

      double totalRating = 0;
      for (var doc in ratingsSnapshot.docs) {
        totalRating += (doc.data()['rating'] ?? 0).toDouble();
      }
      return totalRating / ratingsSnapshot.docs.length;
    } catch (e) {
      print('Rating hesaplanırken hata: $e');
      return 0.0;
    }
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating) {
          return const Icon(Icons.star, color: Colors.amber, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 20);
        }
      }),
    );
  }

  Future<void> addToCart(String bookName, String price, String imageUrl,
      String seller_id, String currentUserId) async {
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
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitap Detayları'),
        backgroundColor: Colors.deepOrange,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future:
            FirebaseFirestore.instance.collection('books').doc(bookId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Kitap bulunamadı',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final bookData = snapshot.data!;
          final bookName = bookData['book_name'] ?? 'Bilinmeyen Kitap';
          final imageUrl = bookData['image_url'] ?? '';
          final description = bookData['description'] ?? 'Açıklama bulunamadı';
          final authorName = bookData['author_name'] ?? 'Yazar bilinmiyor';
          final price = bookData['price']?.toString() ?? 'Fiyat belirtilmemiş';
          final sellerUserId = bookData['user_id'] ?? '';

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(sellerUserId)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const Center(
                  child: Text(
                    'Satıcı bilgisi bulunamadı.',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              final sellerName =
                  userSnapshot.data!['name'] ?? 'Bilinmeyen Satıcı';

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 200, // 300'den 200'e düşürdüm
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.deepOrange.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain, // cover yerine contain kullandım
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image,
                                  size: 100, color: Colors.grey),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepOrange.withOpacity(0.1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bookName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Yazar: $authorName',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$price ₺',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.deepOrange.withOpacity(0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Açıklama',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepOrange,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  description,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (currentUser != null &&
                              currentUser.uid != sellerUserId)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.shopping_cart),
                                label: const Text('Sepete Ekle'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  addToCart(
                                    bookName,
                                    price,
                                    imageUrl,
                                    sellerUserId,
                                    currentUser.uid,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Ürün sepete eklendi'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 20),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepOrange.withOpacity(0.1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<double>(
                                  future: _getSellerRating(sellerUserId),
                                  builder: (context, ratingSnapshot) {
                                    final rating = ratingSnapshot.data ?? 0.0;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor:
                                                  Colors.deepOrange,
                                              child: Text(
                                                sellerName[0].toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Satıcı: $sellerName',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            _buildRatingStars(rating),
                                            const SizedBox(width: 5),
                                            Text(
                                              '(${rating.toStringAsFixed(1)})',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                if (currentUser != null &&
                                    currentUser.uid != sellerUserId) ...[
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.message),
                                      label: const Text('Mesaj Gönder'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepOrange,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () => navigateToChat(
                                        context,
                                        currentUser.uid,
                                        sellerUserId,
                                        bookId,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Satıcı Yorumları',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const SizedBox(height: 10),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(sellerUserId)
                                .collection('comments')
                                .orderBy('timestamp', descending: true)
                                .snapshots(),
                            builder: (context, commentsSnapshot) {
                              if (!commentsSnapshot.hasData) {
                                return const Text('Henüz yorum yapılmamış');
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: commentsSnapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  final comment =
                                      commentsSnapshot.data!.docs[index];
                                  final timestamp =
                                      comment['timestamp'] as Timestamp?;
                                  final date = timestamp?.toDate();

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            Colors.deepOrange.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: Colors.deepOrange
                                                  .withOpacity(0.1),
                                              radius: 16,
                                              child: Text(
                                                (comment['user_name'] ?? 'A')[0]
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.deepOrange,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              comment['user_name'] ??
                                                  'Bilinmeyen Kullanıcı',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(comment['comment'] ?? ''),
                                        if (date != null)
                                          Text(
                                            '${date.day}/${date.month}/${date.year}',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Sohbet ekranına yönlendirme ve Firestore'da kontrol fonksiyonu
void navigateToChat(BuildContext context, String currentUserId,
    String sellerUserId, String bookId) async {
  String chatId;
  final sortedIds = [currentUserId, sellerUserId]..sort();
  chatId = sortedIds.join('_');

  final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

  final chatDoc = await chatRef.get();
  if (!chatDoc.exists) {
    final participants = [currentUserId, sellerUserId]..sort();

    await chatRef.set({
      'user1_id': currentUserId,
      'user2_id': sellerUserId,
      'participants': participants,
      'book_id': bookId,
      'last_message': '',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatScreen(
        userId: currentUserId,
        chatId: chatId,
        user2Id: sellerUserId,
      ),
    ),
  );
}
