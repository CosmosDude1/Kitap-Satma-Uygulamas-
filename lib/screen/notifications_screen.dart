import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> _getNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return []; // Kullanıcı oturum açmamışsa boş liste döndür

    // Kullanıcıya ait notifications alt koleksiyonunu getir
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .get();

    // Bildirimleri liste olarak dön
    return querySnapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Henüz bir bildiriminiz yok.'));
          }

          final notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                title: Text(notification['title'] ?? 'Başlık Yok'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification['message'] ?? 'Mesaj Yok'),
                    Text(notification['timestamp']?.toDate().toString() ?? ''),
                  ],
                ),
                leading: const Icon(Icons.notifications),
                onTap: () {
                  // İsteğe bağlı: Bildirime tıklanınca işlem yap
                },
              );
            },
          );
        },
      ),
    );
  }
}
