import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/chat_service.dart';
import '../../domain/constants/appcolors.dart';
import 'chatdetailscreen.dart';

class ChatsScreen extends StatelessWidget {
  final String currentUserId;
  const ChatsScreen({super.key, required this.currentUserId});

  String formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();

    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';

    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return "$hour:$minute $amPm";
    }
    if (dt.year == now.year) {
      return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}";
    }
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Chats"),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.scaffolddark
            : AppColors.scaffoldlight,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatService.getUserChats(currentUserId),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          // No data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No chats yet"));
          }

          // UI level filter (WhatsApp style)
          final chats = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final hidden = Map<String, dynamic>.from(data['hiddenFor'] ?? {});
            return hidden[currentUserId] != true;
          }).toList();

          if (chats.isEmpty) {
            return const Center(child: Text("No chats yet"));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final chatId = chat.id;
              final data = chat.data() as Map<String, dynamic>;

              final participants = List<String>.from(data['participants']);
              final otherUserId = participants.firstWhere(
                (e) => e != currentUserId,
              );

              final unread = data['unreadCount']?[currentUserId] ?? 0;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox();

                  final userData =
                      userSnap.data!.data() as Map<String, dynamic>;

                  return GestureDetector(
                    onLongPress: () async {
                      final result = await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Delete chat?"),
                          content: const Text(
                            "This will remove chat from your list and delete previous messages for you only.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (result == true) {
                        // Delete chat for current user only
                        await chatService.deleteChatForMe(
                          chatId: chatId,
                          userId: currentUserId,
                        );
                      }
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundImage: userData['profilePic'] != null
                            ? NetworkImage(userData['profilePic'])
                            : null,
                        child: userData['profilePic'] == null
                            ? Text(userData['firstName'][0])
                            : null,
                      ),
                      title: Text(
                        "${userData['firstName']} ${userData['lastName']}",
                      ),
                      subtitle: FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('chats')
                            .doc(chatId)
                            .collection('messages')
                            .orderBy('timestamp', descending: true)
                            .limit(1)
                            .get(),
                        builder: (context, lastMsgSnap) {
                          if (!lastMsgSnap.hasData ||
                              lastMsgSnap.data!.docs.isEmpty) {
                            return const SizedBox();
                          }

                          final lastMsgData =
                              lastMsgSnap.data!.docs.first.data()
                                  as Map<String, dynamic>;
                          final text = lastMsgData['text'] ?? '';
                          final isDeleted = lastMsgData['isDeleted'] ?? false;

                          return Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontStyle: isDeleted
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              color: isDeleted
                                  ? Colors.grey
                                  : Theme.of(context).brightness ==
                                        Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          );
                        },
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            formatTime(data['lastMessageTime']),
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (unread > 0)
                            CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.green,
                              child: Text(
                                unread.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        chatService.resetUnread(currentUserId, otherUserId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              currentUserId: currentUserId,
                              receiverId: otherUserId,
                            ),
                          ),
                        );
                      },
                    ),
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
