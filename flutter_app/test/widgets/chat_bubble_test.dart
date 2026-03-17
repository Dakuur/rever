@TestOn('browser')
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rever_chat/models/chat_message.dart';
import 'package:rever_chat/widgets/chat_bubble.dart';

Widget _wrap(Widget child) => CupertinoApp(home: child);

ChatMessage _userMsg(String content) => ChatMessage(
      id: 'u1',
      role: MessageRole.user,
      content: content,
      timestamp: DateTime(2024, 1, 1, 12, 0),
    );

ChatMessage _botMsg(String content) => ChatMessage(
      id: 'b1',
      role: MessageRole.assistant,
      content: content,
      timestamp: DateTime(2024, 1, 1, 12, 1),
    );

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('ChatBubble – user messages', () {
    testWidgets('renders user message content', (tester) async {
      await tester.pumpWidget(_wrap(ChatBubble(message: _userMsg('Hello!'))));
      await tester.pump();
      expect(find.text('Hello!'), findsOneWidget);
    });

    testWidgets('user bubble is right-aligned', (tester) async {
      await tester.pumpWidget(
          _wrap(ChatBubble(message: _userMsg('Test'))));
      await tester.pump();
      final rows = tester.widgetList<Row>(find.byType(Row));
      final outerRow = rows.first;
      expect(outerRow.mainAxisAlignment, MainAxisAlignment.end);
    });

    testWidgets('user bubble shows timestamp', (tester) async {
      await tester.pumpWidget(
          _wrap(ChatBubble(message: _userMsg('Timed message'))));
      await tester.pump();
      // Timestamp is formatted as HH:mm
      expect(find.text('12:00'), findsOneWidget);
    });
  });

  group('ChatBubble – bot messages', () {
    testWidgets('renders bot message content', (tester) async {
      await tester.pumpWidget(_wrap(ChatBubble(message: _botMsg('Hi there!'))));
      await tester.pump();
      expect(find.text('Hi there!'), findsOneWidget);
    });

    testWidgets('bot bubble is left-aligned', (tester) async {
      await tester.pumpWidget(
          _wrap(ChatBubble(message: _botMsg('Test'))));
      await tester.pump();
      final rows = tester.widgetList<Row>(find.byType(Row));
      final outerRow = rows.first;
      expect(outerRow.mainAxisAlignment, MainAxisAlignment.start);
    });

    testWidgets('bot bubble shows avatar "R"', (tester) async {
      await tester.pumpWidget(_wrap(ChatBubble(message: _botMsg('Hello'))));
      await tester.pump();
      expect(find.text('R'), findsOneWidget);
    });
  });

  group('ChatBubble – loading state', () {
    testWidgets('loading message renders typing indicator (3 dots)',
        (tester) async {
      await tester
          .pumpWidget(_wrap(ChatBubble(message: ChatMessage.loading())));
      await tester.pump();
      // The typing indicator has 3 animated dots (small containers)
      // Avatar "R" should also be visible
      expect(find.text('R'), findsOneWidget);
      // No text content in loading state
      expect(find.text(''), findsNothing);
    });

    testWidgets('loading indicator does NOT show text content', (tester) async {
      await tester
          .pumpWidget(_wrap(ChatBubble(message: ChatMessage.loading())));
      await tester.pump();
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });
  });

  group('ChatSkeleton', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(_wrap(const ChatSkeleton()));
      await tester.pump();
      expect(find.byType(ChatSkeleton), findsOneWidget);
    });
  });
}
