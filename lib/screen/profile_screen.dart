import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase için gerekli
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore için gerekli
import 'package:your_project_name/screen/login_screen.dart'; // Login ekranını import edin
import 'package:your_project_name/screen/AccountSettingsScreen.dart';
import 'package:your_project_name/screen/ShoppingHistoryScreen.dart';
import 'package:your_project_name/screen/help_screen.dart';
import 'package:your_project_name/screen/message_screen.dart';
import 'SalesListingScreen.dart'; // Satış listesini gösteren ekranı import ediyoruz

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId) // currentUserId kullanarak veriye ulaşalım
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text("Bir hata oluştu"));
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text("Kullanıcı verisi bulunamadı"));
            }

            final userData = snapshot.data!;
            final username =
                userData['name'] ?? 'Kullanıcı Adı'; // 'name' alanını çekiyoruz

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profil Bilgileri

                Text(
                  username, // Burada kullanıcı adı yazdırılıyor
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Onaylı Satıcı',
                  style: TextStyle(fontSize: 16, color: Colors.orangeAccent),
                ),
                const SizedBox(height: 20),

                // Menü Seçenekleri
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildMenuItem(
                        icon: Icons.shopping_bag,
                        label: 'Satış İlanlarım',
                        onTap: () =>
                            _navigateTo(context, const SalesListingScreen()),
                      ),
                      _buildMenuItem(
                        icon: Icons.history,
                        label: 'Alışveriş Geçmişim',
                        onTap: () =>
                            _navigateTo(context, const ShoppingHistoryScreen()),
                      ),
                      _buildMenuItem(
                        icon: Icons.message,
                        label: 'Mesajlar',
                        onTap: () =>
                            _navigateTo(context, const MessageScreen()),
                      ),
                      _buildMenuItem(
                        icon: Icons.settings,
                        label: 'Hesap Ayarları',
                        onTap: () =>
                            _navigateTo(context, const AccountSettingsScreen()),
                      ),
                      _buildMenuItem(
                        icon: Icons.support_agent,
                        label: 'Destek',
                        onTap: () =>
                            _navigateTo(context, const SupportScreen()),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Oturumu Kapat Butonu
                ElevatedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    "Oturumu Kapat",
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Menü Seçenekleri için Yardımcı Widget
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.deepOrange),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // Ekranlar Arası Geçiş Yardımcı Fonksiyonu
  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  // Oturumu Kapat Yardımcı Fonksiyonu
  void _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // Önceki tüm rotaları temizle
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Oturumu kapatma başarısız: $e")),
      );
    }
  }
}
