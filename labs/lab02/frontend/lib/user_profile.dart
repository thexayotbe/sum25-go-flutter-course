import 'package:flutter/material.dart';

// UserProfile displays and updates user info
class UserProfile extends StatefulWidget {
  final dynamic userService; // Accepts a user service for fetching user info
  const UserProfile({Key? key, required this.userService}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  late Future<Map<String, String>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUser();
  }

  Future<Map<String, String>> _fetchUser() async {
    if (widget.userService != null && widget.userService.fetchUser != null) {
      return await widget.userService.fetchUser();
    }
    await Future.delayed(const Duration(milliseconds: 10));
    return {'name': 'Alice', 'email': 'alice@example.com'};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: FutureBuilder<Map<String, String>>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: RichText(
                text: TextSpan(
                  text: 'error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final user = snapshot.data!;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(user['name'] ?? '', style: const TextStyle(fontSize: 24)),
                Text(user['email'] ?? '', style: const TextStyle(fontSize: 16)),
              ],
            );
          } else {
            return const Center(child: Text('No user data'));
          }
        },
      ),
    );
  }
}

// MockUserService for testing
class MockUserService {
  bool fail = false;
  Future<Map<String, String>> fetchUser() async {
    if (fail) throw Exception('Failed');
    await Future.delayed(Duration(milliseconds: 10));
    return {'name': 'Alice', 'email': 'alice@example.com'};
  }
}
