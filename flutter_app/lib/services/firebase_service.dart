import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/chat_message.dart';
import '../models/return_request.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._();
  factory FirebaseService() => _instance;
  FirebaseService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  // ── Auth ────────────────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  // ── Conversations ────────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('conversations');

  Future<String> createConversation(String mode) async {
    final uid = _auth.currentUser?.uid ?? 'anonymous';
    final ref = await _conversations.add({
      'userId': uid,
      'mode': mode,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> addMessage(String conversationId, ChatMessage msg) =>
      _conversations
          .doc(conversationId)
          .collection('messages')
          .doc(msg.id)
          .set(msg.toMap());

  Stream<List<ChatMessage>> messagesStream(String conversationId) =>
      _conversations
          .doc(conversationId)
          .collection('messages')
          .orderBy('timestamp')
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => ChatMessage.fromMap(d.id, d.data()))
              .toList());

  Future<List<Map<String, dynamic>>> getConversationHistory(
      String conversationId) async {
    final snap = await _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp')
        .get();
    return snap.docs
        .map((d) => {'role': d['role'], 'content': d['content']})
        .toList();
  }

  // ── Return Requests ──────────────────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _returnRequests =>
      _db.collection('return_requests');

  Future<void> saveReturnRequest(ReturnRequest req) async {
    await _returnRequests.doc(req.id).set(req.toMap());
  }

  Future<List<ReturnRequest>> getReturnRequests({String? email}) async {
    Query<Map<String, dynamic>> query =
        _returnRequests.orderBy('createdAt', descending: true);
    if (email != null) {
      query = query.where('customerEmail', isEqualTo: email);
    }
    final snap = await query.limit(50).get();
    return snap.docs
        .map((d) => ReturnRequest.fromMap(d.id, d.data()))
        .toList();
  }
}
