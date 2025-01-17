import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:your_project_name/screen/PaymentScreen.dart';
import 'package:your_project_name/screen/main_scaffold.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

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
        title: const Text('Sepetim'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .collection('cart')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'Sepetiniz boş',
                  style: TextStyle(fontSize: 18),
                ),
              );
            }

            final cartItems = snapshot.data!.docs;
            double totalAmount = cartItems.fold(0.0, (sum, item) {
              final price = _convertToDouble(item['price']);
              return sum + price;
            });

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sepetinizdeki Ürünler',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final bookName = item['book_name'] ?? 'Bilinmeyen Kitap';
                      final imageUrl = item['image_url'] ?? '';
                      final price = _convertToDouble(item['price']);

                      return _buildCartItem(
                        context,
                        currentUserId,
                        item.id,
                        bookName,
                        imageUrl,
                        price,
                      );
                    },
                  ),
                ),
                _buildTotalAndPaymentRow(context, totalAmount),
                _buildContinueShoppingButton(context),
              ],
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

  Future<void> _removeFromCart(String userId, String itemId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(itemId)
        .delete();
  }

  Widget _buildCartItem(BuildContext context, String userId, String itemId,
      String bookName, String imageUrl, double price) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.broken_image,
                        size: 60, color: Colors.grey),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookName,
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      'Fiyat: ${price.toStringAsFixed(2)} TL',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => _removeFromCart(userId, itemId),
              child: const Text('Çıkar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAndPaymentRow(BuildContext context, double totalAmount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Toplam: ${totalAmount.toStringAsFixed(2)} TL',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PaymentScreen(totalAmount: totalAmount)),
            );
          },
          child: const Text('Ödeme Yap'),
        ),
      ],
    );
  }

  Widget _buildContinueShoppingButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainScaffold(selectedIndex: 0),
          ),
        );
      },
      child: const Text('Alışverişe Devam Et'),
    );
  }
}
