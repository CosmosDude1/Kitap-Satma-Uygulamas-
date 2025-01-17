import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavouriteScreen extends StatelessWidget {
  const FavouriteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Kullanıcı oturum açmadı.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorilerim'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .collection('favourites')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'Favorileriniz boş',
                  style: TextStyle(fontSize: 18),
                ),
              );
            }

            final favouriteItems = snapshot.data!.docs;

            return ListView.builder(
              itemCount: favouriteItems.length,
              itemBuilder: (context, index) {
                final item = favouriteItems[index];
                final bookName = item['book_name'] ?? 'Bilinmeyen Kitap';
                final imageUrl = item['image_url'] ?? '';
                final price = _convertToDouble(item['price']);

                return _buildFavouriteItem(
                  context,
                  currentUserId,
                  item.id,
                  bookName,
                  imageUrl,
                  price,
                );
              },
            );
          },
        ),
      ),
    );
  }

  double _convertToDouble(dynamic price) {
    if (price is num) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  Widget _buildFavouriteItem(BuildContext context, String userId, String itemId,
      String bookName, String imageUrl, double price) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.book, size: 60, color: Colors.grey),
        title: Text(bookName, style: const TextStyle(fontSize: 18)),
        subtitle: Text('Fiyat: ${price.toStringAsFixed(2)} TL'),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: () => _removeFromFavourites(userId, itemId),
        ),
      ),
    );
  }

  Future<void> _removeFromFavourites(String userId, String itemId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('favourites')
        .doc(itemId)
        .delete();
  }
}
