import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // SAVE PROFILE
  Future<void> saveUserProfile({required UserModel userModel}) async {
    await _firestore
        .collection("users")
        .doc(userModel.uid)
        .set(userModel.toMap());
  }

  // GET USER PROFILE
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection("users").doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  //  GET ALL USERS (FOR CONTACTS)
  Stream<List<UserModel>> getAllUsers() {
    final currentUid = _auth.currentUser!.uid;

    return _firestore.collection("users").snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUid) //current-user means self remove
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    });
  }
}
