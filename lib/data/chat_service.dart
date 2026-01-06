import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? "${uid1}_$uid2" : "${uid2}_$uid1";
  }

  /// CREATE CHAT IF NOT EXISTS
  Future<void> ensureChatExists(String uid1, String uid2) async {
    final chatId = getChatId(uid1, uid2);
    final chatRef = _firestore.collection('chats').doc(chatId);

    final snap = await chatRef.get();
    if (!snap.exists) {
      await chatRef.set({
        'participants': [uid1, uid2],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': '',
        'unreadCount': {uid1: 0, uid2: 0},
        'chatClearedAt': {},
      });
    }
  }

  /// SEND MESSAGE (REVIVES CHAT)
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
  }) async {
    final chatId = getChatId(senderId, receiverId);
    final chatRef = _firestore.collection('chats').doc(chatId);

    await ensureChatExists(senderId, receiverId);

    await chatRef.collection('messages').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'text': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await chatRef.set({
      'participants': [senderId, receiverId],
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': senderId,
      'unreadCount.$receiverId': FieldValue.increment(1),
      'chatClearedAt.$senderId': FieldValue.delete(), // 🔥 revive
      'chatClearedAt.$receiverId': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  /// CLEAR CHAT FOR ME (WHATSAPP STYLE)
  Future<void> clearChatForMe({
    required String chatId,
    required String userId,
  }) async {
    await _firestore.collection('chats').doc(chatId).set({
      'chatClearedAt.$userId': FieldValue.serverTimestamp(),
      'unreadCount.$userId': 0,
    }, SetOptions(merge: true));
  }

  /// GET CHAT LIST
  Stream<QuerySnapshot> getUserChats(String uid) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// GET MESSAGES (FILTERED AFTER CLEAR)
  Stream<QuerySnapshot> getMessages(String me, String other) async* {
    final chatId = getChatId(me, other);
    final chatRef = _firestore.collection('chats').doc(chatId);

    final snap = await chatRef.get();
    final clearedAt = snap.data()?['chatClearedAt']?[me];

    Query q = chatRef.collection('messages').orderBy('timestamp');
    if (clearedAt != null) {
      q = q.where('timestamp', isGreaterThan: clearedAt);
    }
    yield* q.snapshots();
  }

  /// EDIT SINGLE MESSage
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc(messageId);

    final msgSnap = await msgRef.get();
    if (!msgSnap.exists) return;

    final oldText = msgSnap['text'];

    // Update message
    await msgRef.update({'text': newText, 'edited': true});

    // Update chat list if LAST message
    final chatSnap = await chatRef.get();
    if (chatSnap['lastMessage'] == oldText) {
      await chatRef.update({'lastMessage': newText});
    }
  }

  /// DELETE SINGLE MESSAGE
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    required String deletedBy,
  }) async {
    final chatRef = _firestore.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc(messageId);

    final msgSnap = await msgRef.get();
    if (!msgSnap.exists) return;

    final msgData = msgSnap.data()!;
    if (msgData['senderId'] != deletedBy) return;

    // Update message
    await msgRef.update({
      'text': 'This message was deleted',
      'isDeleted': true,
    });

    // Check if this was LAST message
    final chatSnap = await chatRef.get();
    final chatData = chatSnap.data()!;

    if (chatData['lastMessage'] == msgData['text']) {
      await chatRef.update({'lastMessage': 'This message was deleted'});
    }
  }

  /// RESET UNREAD
  Future<void> resetUnread(String me, String other) async {
    final chatId = getChatId(me, other);
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount.$me': 0,
    });
  }
}
