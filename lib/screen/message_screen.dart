import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class MessageScreen extends StatelessWidget {
  const MessageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mesajlar'),
        ),
        body: const Center(
          child: Text(
            'Mesajları görüntülemek için giriş yapmalısınız.',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Henüz mesajlaşmalar yok.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // Chat dokümanlarını bir List'e çevirelim ki sıralayabilelim
          List<DocumentSnapshot> chatDocs = snapshot.data!.docs;

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: Stream.fromFuture(Future.wait(
              chatDocs.map((chat) async {
                final chatId = chat.id;
                final lastMessageQuery = await FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .limit(1)
                    .get();

                if (lastMessageQuery.docs.isEmpty) {
                  return {
                    'chat': chat,
                    'timestamp': Timestamp.fromDate(DateTime(2000)),
                  };
                }

                return {
                  'chat': chat,
                  'timestamp': lastMessageQuery.docs.first['timestamp'] ??
                      Timestamp.fromDate(DateTime(2000)),
                };
              }),
            )),
            builder: (context, asyncSnapshot) {
              if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!asyncSnapshot.hasData) return const SizedBox();

              // Chat'leri son mesaj zamanına göre sırala
              final sortedChats = asyncSnapshot.data!
                ..sort((a, b) {
                  final aTime = (a['timestamp'] as Timestamp).toDate();
                  final bTime = (b['timestamp'] as Timestamp).toDate();
                  return bTime.compareTo(aTime); // Descending order
                });

              return ListView.builder(
                itemCount: sortedChats.length,
                itemBuilder: (context, index) {
                  final chat = sortedChats[index]['chat'] as DocumentSnapshot;
                  final chatId = chat.id;

                  final otherUserId = currentUser.uid == chat['participants'][0]
                      ? chat['participants'][1]
                      : chat['participants'][0];

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(otherUserId)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return const SizedBox();
                      }

                      final userData = userSnapshot.data!;
                      final userName =
                          userData['name'] ?? 'Bilinmeyen Kullanıcı';

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('chats')
                            .doc(chatId)
                            .collection('messages')
                            .orderBy('timestamp', descending: true)
                            .limit(1)
                            .snapshots(),
                        builder: (context, messageSnapshot) {
                          if (messageSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox();
                          }

                          if (!messageSnapshot.hasData ||
                              messageSnapshot.data!.docs.isEmpty) {
                            return const SizedBox();
                          }

                          final lastMessageData =
                              messageSnapshot.data!.docs.first;
                          final lastMessage =
                              lastMessageData['text'] ?? 'Henüz mesaj yok';
                          final isRead = lastMessageData['isRead'] ?? true;
                          final isOwnMessage =
                              lastMessageData['user_id'] == currentUser.uid;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                userName[0],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                if (!isRead && !isOwnMessage)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: !isRead && !isOwnMessage
                                    ? Colors.black
                                    : Colors.grey,
                                fontWeight: !isRead && !isOwnMessage
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            onTap: () {
                              // Mesajları okundu olarak işaretle
                              FirebaseFirestore.instance
                                  .collection('chats')
                                  .doc(chatId)
                                  .collection('messages')
                                  .where('user_id',
                                      isNotEqualTo: currentUser.uid)
                                  .get()
                                  .then((snapshot) {
                                // WriteBatch kullanarak güncelle
                                final batch =
                                    FirebaseFirestore.instance.batch();
                                for (var doc in snapshot.docs) {
                                  if (doc['isRead'] == false) {
                                    batch.update(
                                        doc.reference, {'isRead': true});
                                  }
                                }
                                return batch.commit();
                              }).then((_) {
                                // Chat ekranına git
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      userId: currentUser.uid,
                                      chatId: chatId,
                                      user2Id: otherUserId,
                                    ),
                                  ),
                                );
                              });
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
