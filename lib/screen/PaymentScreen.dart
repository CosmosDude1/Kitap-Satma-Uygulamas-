import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;

  const PaymentScreen({Key? key, required this.totalAmount}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isPaymentProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
    _amountController.text =
        widget.totalAmount.toStringAsFixed(2); // Ödenecek tutar.
  }

  Future<void> _fetchBooks() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('books').get();

      if (snapshot.docs.isEmpty) {
        throw Exception("Kitap listesi boş.");
      }

      final books = snapshot.docs
          .map((doc) => doc.data()['name']?.toString() ?? 'Bilinmeyen Kitap')
          .toList();
    } catch (e) {
      print("Hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kitap listesi alınamadı: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePurchaseToHistory() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı oturum açmamış!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      if (cartSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sepetinizde kitap bulunmamaktadır!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      List<String> bookNames = [];
      List<String> sellerIds = []; // Satıcı ID'lerini tutacağız

      for (var doc in cartSnapshot.docs) {
        bookNames.add(doc['book_name'] ?? 'Bilinmeyen Kitap');

        // books koleksiyonundan satıcı bilgisi alınacak
        final bookName = doc['book_name'];
        if (bookName != null) {
          final bookSnapshot = await FirebaseFirestore.instance
              .collection('books')
              .where('book_name', isEqualTo: bookName)
              .limit(1)
              .get();

          if (bookSnapshot.docs.isNotEmpty) {
            final book = bookSnapshot.docs.first;
            final sellerId = book['user_id']; // Satıcı ID'sini alıyoruz
            sellerIds.add(sellerId);
          }
        }
      }

      final purchase = {
        'amount': widget.totalAmount,
        'date': Timestamp.now(),
        'cardNumber': _cardNumberController.text
            .substring(_cardNumberController.text.length - 4),
        'books': bookNames,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('purchaseHistory')
          .add(purchase);

      // Satıcıya bildirim gönderiyoruz
      for (var sellerId in sellerIds) {
        final sellerNotification = {
          'message':
              'Kullanıcı ${FirebaseAuth.instance.currentUser?.displayName ?? "Bilinmeyen"} bir kitap satın aldı.',
          'date': Timestamp.now(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(sellerId)
            .collection('notifications')
            .add(sellerNotification);
      }

      // Sepetteki kitapları siliyoruz
      for (var doc in cartSnapshot.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alışveriş başarıyla tamamlandı!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Hata: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bir hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processPayment() async {
    setState(() {
      _isPaymentProcessing = true;
    });

    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isPaymentProcessing = false;
    });

    await _savePurchaseToHistory();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ödeme Başarılı!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Yap'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ödeme Bilgilerini Girin',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 16),
            TextField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kart Numarası',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryDateController,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Son Kullanma Tarihi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isPaymentProcessing ? null : _processPayment,
              child: _isPaymentProcessing
                  ? const CircularProgressIndicator()
                  : const Text('Ödemeyi Tamamla'),
            ),
          ],
        ),
      ),
    );
  }
}
