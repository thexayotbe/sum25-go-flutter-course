import 'dart:convert';

import '../models/message.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  static const Duration timeout = Duration(seconds: 30);
  late final http.Client _client;

  ApiService() {
    _client = http.Client();
  }

  // TODO: Add dispose() method that calls _client.close();
  void dispose() {
    _client.close();
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<T> _handleResponse<T>(http.Response response, T Function(Map<String, dynamic>) fromJson) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return fromJson(json.decode(response.body));
    }
    else if(response.statusCode >=400 && response.statusCode < 500) {
      throw ValidationException(response.body);
    }
    else if(response.statusCode >=500 && response.statusCode < 600) {
      throw ServerException(response.body);
    }
    else {
      throw ApiException(response.body);
    }
  }
  

  // Get all messages
  Future<List<Message>> getMessages() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/messages'), headers: _getHeaders());
    return _handleResponse(response, (data) => (data as List).map((json) => Message.fromJson(json)).toList());
  }

  // Create a new message
  Future<Message> createMessage(CreateMessageRequest request) async {
    final response = await _client.post(Uri.parse('$baseUrl/api/v1/messages'), headers: _getHeaders(), body: json.encode(request.toJson()));
    return _handleResponse(response, (data) => Message.fromJson(data));  
  }

  // Update an existing message
  Future<Message> updateMessage(int id, UpdateMessageRequest request) async {
    final response = await _client.put(Uri.parse('$baseUrl/api/v1/messages/$id'), headers: _getHeaders(), body: json.encode(request.toJson()));
    return _handleResponse(response, (data) => Message.fromJson(data));
  }

  // Delete a message
  Future<void> deleteMessage(int id) async {
    final response = await _client.delete(Uri.parse('$baseUrl/api/v1/messages/$id'), headers: _getHeaders());
    if (response.statusCode != 204) {
      throw ApiException('Failed to delete message');
    }
  }

  // Get HTTP status information
  Future<HTTPStatusResponse> getHTTPStatus(int statusCode) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/status/$statusCode'), headers: _getHeaders());
    return _handleResponse(response, (data) => HTTPStatusResponse.fromJson(data));
  }

  // Health check
  Future<Map<String, dynamic>> healthCheck() async {
    final response = await _client.get(Uri.parse('$baseUrl/api/v1/health'), headers: _getHeaders());
    return json.decode(response.body);
  }
}

// Custom exceptions
class ApiException implements Exception {
  final String message;
  
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message);
}

class ValidationException extends ApiException {
  ValidationException(String message) : super(message);
}
