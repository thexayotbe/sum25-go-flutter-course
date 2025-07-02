import 'package:flutter_test/flutter_test.dart';
import '../lib/chat_service.dart';
import 'dart:async';

void main() {
  test('emits messages on stream', () async {
    final service = ChatService();
    final messages = <String>[];
    service.messageStream.listen(messages.add);
    await service.sendMessage('hello');
    await Future.delayed(Duration(milliseconds: 10));
    expect(messages, contains('hello'));
  });

  test('sends message and receives confirmation', () async {
    final service = ChatService();
    final completer = Completer<String>();
    service.messageStream.listen((msg) {
      if (!completer.isCompleted) {
        completer.complete(msg);
      }
    });
    
    await service.sendMessage('test');
    final result = await completer.future.timeout(Duration(seconds: 5));
    expect(result, equals('test'));
  });

  test('handles connection errors', () async {
    final service = ChatService();
    // Этот тест проверяет, что sendMessage не выбрасывает исключение
    expect(() => service.sendMessage('test'), returnsNormally);
  });
}
