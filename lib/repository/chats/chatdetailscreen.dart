import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../../data/chat_service.dart';
import '../../domain/constants/appcolors.dart';
import '../screens/widgets/grammer_helper.dart';

class ChatDetailScreen extends StatefulWidget {
  final String currentUserId;
  final String receiverId;

  const ChatDetailScreen({
    super.key,
    required this.currentUserId,
    required this.receiverId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController messageController = TextEditingController();
  final ChatService chatService = ChatService();
  final FocusNode focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool showEmojiPicker = false;

  String formatMsgTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $amPm";
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _showEditDeleteOptions(
    Map<String, dynamic> msgData,
    bool isMe,
  ) async {
    if (!isMe) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Edit"),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(msgData);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Delete"),
                onTap: () async {
                  Navigator.pop(context);
                  final chatId = chatService.getChatId(
                    widget.currentUserId,
                    widget.receiverId,
                  );
                  await chatService.deleteMessage(
                    chatId: chatId,
                    messageId: msgData['id'],
                    deletedBy: widget.currentUserId,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> msgData) async {
    final TextEditingController editController = TextEditingController(
      text: msgData['text'] ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Message"),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(hintText: "Edit message"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final chatId = chatService.getChatId(
                widget.currentUserId,
                widget.receiverId,
              );
              await chatService.editMessage(
                chatId: chatId,
                messageId: msgData['id'],
                newText: editController.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.scaffolddark
            : AppColors.scaffoldlight,
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.receiverId)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Text("Loading...");
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: userData['profilePic'] != null
                      ? NetworkImage(userData['profilePic'])
                      : null,
                  child: userData['profilePic'] == null
                      ? Text(userData['firstName'][0])
                      : null,
                ),
                const SizedBox(width: 8),
                Text("${userData['firstName']} ${userData['lastName']}"),
              ],
            );
          },
        ),
      ),
      body: Column(
        children: [
          /// MESSAGES
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: chatService.getMessages(
                widget.currentUserId,
                widget.receiverId,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final msgData = msg.data() as Map<String, dynamic>;
                    final isMe = msgData['senderId'] == widget.currentUserId;
                    final isDeleted = msgData.containsKey('isDeleted')
                        ? msgData['isDeleted']
                        : false;
                    final text = msgData.containsKey('text')
                        ? msgData['text']
                        : '';

                    // Add msgId for edit/delete
                    msgData['id'] = msg.id;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => _showEditDeleteOptions(msgData, isMe),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(
                                text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black,
                                  fontSize: 15,
                                  fontStyle: isDeleted
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatMsgTime(msgData['timestamp']),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// INPUT BAR
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.scaffolddark
                    : Colors.white,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions, size: 26),
                    onPressed: () {
                      if (showEmojiPicker) {
                        focusNode.requestFocus();
                      } else {
                        focusNode.unfocus();
                      }
                      setState(() {
                        showEmojiPicker = !showEmojiPicker;
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      focusNode: focusNode,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.black,
                      ),
                      onTap: () {
                        setState(() {
                          showEmojiPicker = false;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Type a message",
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade200,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      /// GRAMMAR FIX BUTTON
                      /// GRAMMAR FIX BUTTON
                      GestureDetector(
                        onTap: () async {
                          if (messageController.text.trim().isEmpty) return;

                          // Unfocus keyboard (optional, looks cleaner)
                          focusNode.unfocus();

                          // Get current text
                          final text = messageController.text.trim();

                          // Call your intelligent grammar + spelling helper
                          String corrected = await GrammarHelper.fixText(text);

                          // Update TextField
                          setState(() {
                            messageController.text = corrected;
                            messageController.selection =
                                TextSelection.fromPosition(
                                  TextPosition(offset: corrected.length),
                                );
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10), // bigger tap area
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_fix_high,
                            color: Colors.white,
                            size: 23,
                          ),
                        ),
                      ),

                      /// SEND BUTTON
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () async {
                            if (messageController.text.trim().isEmpty) return;

                            await chatService.sendMessage(
                              senderId: widget.currentUserId,
                              receiverId: widget.receiverId,
                              message: messageController.text.trim(),
                            );

                            messageController.clear();
                            _scrollToBottom();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          /// EMOJI PICKER
          Offstage(
            offstage: !showEmojiPicker,
            child: SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  setState(() {
                    messageController.text += emoji.emoji;
                  });
                  _scrollToBottom();
                },
                config: Config(
                  emojiViewConfig: const EmojiViewConfig(
                    columns: 7,
                    emojiSizeMax: 32,
                  ),
                  categoryViewConfig: const CategoryViewConfig(
                    initCategory: Category.SMILEYS,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
