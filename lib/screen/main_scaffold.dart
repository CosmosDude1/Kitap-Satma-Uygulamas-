import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // Bu import'u ekleyin
import 'main_screen.dart';
import 'favourite_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'message_screen.dart';

class MainScaffold extends StatefulWidget {
  final int selectedIndex;

  const MainScaffold({Key? key, required this.selectedIndex}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  List<String> favourites = [];
  int unreadMessages = 0;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _listenToUnreadMessages();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _listenToUnreadMessages() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _subscription = FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .snapshots()
          .listen((chatSnapshot) {
        _checkUnreadMessages(currentUser.uid);
      });
    }
  }

  Future<void> _checkUnreadMessages(String userId) async {
    try {
      print("CheckUnreadMessages başladı - userId: $userId");

      final chats = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();

      print("Bulunan chat sayısı: ${chats.docs.length}");

      int total = 0;

      for (var chat in chats.docs) {
        print("Chat ID: ${chat.id}");

        // Sadece user_id ile filtrele, isRead kontrolünü kod içinde yapalım
        final messages = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chat.id)
            .collection('messages')
            .where('user_id', isNotEqualTo: userId)
            .get();

        // Mesajları döngüde kontrol et
        for (var message in messages.docs) {
          print("Mesaj detayları:");
          print("user_id: ${message['user_id']}");
          print("isRead: ${message['isRead']}");

          // isRead false olan mesajları say
          if (message['isRead'] == false) {
            total++;
          }
        }

        print("Bu chat'teki okunmamış mesaj: $total");
      }

      print("Toplam okunmamış mesaj: $total");

      setState(() {
        unreadMessages = total;
        print("setState sonrası unreadMessages: $unreadMessages");
      });
    } catch (e) {
      print("Hata: $e");
      print("Hata stack trace: ${StackTrace.current}");
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Mesajlar sekmesine geçildiğinde sayacı güncelle
    if (index == 3) {
      // 3 mesajlar sekmesinin indexi
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _checkUnreadMessages(currentUser.uid);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      MainScreen(
        favourites: favourites,
        onToggleFavourite: (product) {
          setState(() {
            if (favourites.contains(product)) {
              favourites.remove(product);
            } else {
              favourites.add(product);
            }
          });
        },
      ),
      const FavouriteScreen(),
      const CartScreen(),
      const MessageScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text([
          "Ana Sayfa",
          "Favoriler",
          "Sepet",
          "Mesajlar",
          "Profil",
        ][_currentIndex]),
        backgroundColor: Colors.deepOrange,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Ana Sayfa",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favoriler",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Sepet",
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.message),
                if (unreadMessages > 0)
                  Positioned(
                    right: -8,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadMessages.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: "Mesajlar",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepOrange,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
