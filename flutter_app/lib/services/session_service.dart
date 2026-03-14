import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/chat_message.dart';

const _kSessionKey = 'rever_session_id';
const _kHistoryLimit = 20;

class SessionService {
  static final SessionService _instance = SessionService._();
  factory SessionService() => _instance;
  SessionService._();

  final _uuid = const Uuid();
  String? _cachedSessionId;

  CollectionReference<Map<String, dynamic>> _messages(String sessionId) =>
      FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .collection('messages');

  // ── Session ID ────────────────────────────────────────────────────────────

  Future<String> getOrCreateSessionId() async {
    if (_cachedSessionId != null) return _cachedSessionId!;
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString(_kSessionKey);
      if (id == null || id.isEmpty) {
        id = _uuid.v4();
        await prefs.setString(_kSessionKey, id);
      }
      _cachedSessionId = id;
      return id;
    } catch (e) {
      // shared_preferences unavailable (e.g. in some iframe contexts) — use
      // an in-memory ID so the session still works for this page load.
      _cachedSessionId ??= _uuid.v4();
      return _cachedSessionId!;
    }
  }

  // ── Persist a message ─────────────────────────────────────────────────────

  Future<void> saveMessage(String sessionId, ChatMessage msg) async {
    try {
      await _messages(sessionId).doc(msg.id).set({
        'role': msg.role.name,
        'content': msg.content,
        'timestamp': Timestamp.fromDate(msg.timestamp),
      });
    } catch (e) {
      // Firebase unavailable — silently skip persistence.
      print('[SessionService] saveMessage failed (non-fatal): $e');
    }
  }

  // ── Load recent history ───────────────────────────────────────────────────

  Future<List<ChatMessage>> loadRecentMessages(String sessionId) async {
    try {
      final snap = await _messages(sessionId)
          .orderBy('timestamp', descending: true)
          .limit(_kHistoryLimit)
          .get();

      // Reverse so oldest message is first in the list.
      return snap.docs.reversed
          .map((d) => ChatMessage.fromMap(d.id, d.data()))
          .toList();
    } catch (e) {
      print('[SessionService] loadRecentMessages failed (non-fatal): $e');
      return [];
    }
  }
}
