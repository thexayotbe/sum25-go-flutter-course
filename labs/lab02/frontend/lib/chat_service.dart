import 'dart:async';

// ChatService handles chat logic and backend communication
class ChatService {
  final StreamController<String> _controller = StreamController<String>.broadcast();

  ChatService();

  Future<void> connect() async {}

  Future<void> sendMessage(String msg) async {
    _controller.add(msg);
  }

  Stream<String> get messageStream => _controller.stream;

  void dispose() {
    _controller.close();
  }
}
