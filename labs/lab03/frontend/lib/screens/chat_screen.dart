import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import 'dart:math';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  List<Message> _messages = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {  
    _usernameController.dispose();
    _messageController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _messages = await _apiService.getMessages();
    } catch (e){
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
    
  }

  Future<void> _sendMessage() async {
    final username = _usernameController.text.trim();
    final content = _messageController.text.trim();
    if(username.isEmpty || content.isEmpty) {
      setState(() {
        _error = 'Username and content are required';
      });
      return;
    }
    final request = CreateMessageRequest(username: username, content: content);
    try {
      final message = await _apiService.createMessage(request);
      setState(() {
        _messages.add(message);
        _messageController.clear();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
   }

  Future<void> _editMessage(Message message) async {
    final content = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: TextEditingController(text: message.content),
          decoration: const InputDecoration(labelText: 'New Content'),
        ),
      ),
    );
    if(content == null) return;
    final request = UpdateMessageRequest(content: content);
    try {
      final updatedMessage = await _apiService.updateMessage(message.id, request);
      setState(() {
        _messages.removeWhere((m) => m.id == message.id);
        _messages.add(updatedMessage);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _deleteMessage(Message message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if(confirmed != true) return;
    try {
      await _apiService.deleteMessage(message.id);
      setState(() {
        _messages.removeWhere((m) => m.id == message.id);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _showHTTPStatus(int statusCode) async {
    try {
      final status = await _apiService.getHTTPStatus(statusCode);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('HTTP Status $statusCode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(status.description),
              const SizedBox(height: 10),
              Image.network(
                status.imageUrl,
                height: 200,
                errorBuilder: (context, error, stackTrace) => 
                  const Text('Failed to load image'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Widget _buildMessageTile(Message message) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(message.username[0].toUpperCase()),
      ),
      title: Text('${message.username} - ${message.timestamp.toString()}'),
      subtitle: Text(message.content),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Text('Edit'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete'),
          ),
        ],
        onSelected: (value) {
          if (value == 'edit') {
            _editMessage(message);
          } else if (value == 'delete') {
            _deleteMessage(message);
          }
        },
      ),
      onTap: () => _showHTTPStatus(200),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Column(
        children: [
          TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username'),),
          const SizedBox(height: 16),
          TextField(controller: _messageController, decoration: const InputDecoration(labelText: 'Message'),),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: _sendMessage, child: const Text('Send'))),
              const SizedBox(width: 16),
              ElevatedButton(onPressed: () => _showHTTPStatus(200), child: const Text('200')),
              const SizedBox(width: 16),
              ElevatedButton(onPressed: () => _showHTTPStatus(404), child: const Text('404')),
              const SizedBox(width: 16),
              ElevatedButton(onPressed: () => _showHTTPStatus(500), child: const Text('500')),
            ],
          ),
        ],
      ),  
    ); 
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? 'An error occurred'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadMessages, child: const Text('Retry')),
        ],
      ),
    ); 
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(),
    ); 
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Implement build method
    // Return Scaffold with:
    // - AppBar with title "REST API Chat" and refresh action
    // - Body that shows loading, error, or message list based on state
    // - BottomSheet with message input
    // - FloatingActionButton for refresh
    // Handle different states: loading, error, success
    return Scaffold(
      appBar: AppBar(
        title: const Text('REST API CHAT'),
        actions: [
          IconButton(onPressed: _loadMessages, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading 
        ? _buildLoadingWidget() 
        : _error != null 
          ? _buildErrorWidget() 
          : ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageTile(_messages[index]),
            ),
      bottomSheet: _buildMessageInput(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadMessages,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// Helper class for HTTP status demonstrations
class HTTPStatusDemo {
  static void showRandomStatus(BuildContext context, ApiService apiService) {
    final random = Random();
    final statusCode = random.nextInt(5) + 200;
    // This would need to be called from a context that has _showHTTPStatus method
    // For now, it's just a placeholder
  }
    
  static void showStatusPicker(BuildContext context, ApiService apiService) {
    final statusCodes = [100, 200, 201, 400, 401, 403, 404, 418, 500, 503];
    final random = Random();
    final statusCode = statusCodes[random.nextInt(statusCodes.length)];
    // This would need to be called from a context that has _showHTTPStatus method
    // For now, it's just a placeholder
  }
}
