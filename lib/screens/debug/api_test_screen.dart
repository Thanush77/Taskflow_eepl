import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';

class ApiTestScreen extends ConsumerStatefulWidget {
  const ApiTestScreen({super.key});

  @override
  ConsumerState<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends ConsumerState<ApiTestScreen> {
  final _testUsernameController = TextEditingController(text: 'testuser');
  final _testPasswordController = TextEditingController(text: 'TestPass123');
  String _testResult = '';

  @override
  void dispose() {
    _testUsernameController.dispose();
    _testPasswordController.dispose();
    super.dispose();
  }

  Future<void> _testLogin() async {
    setState(() {
      _testResult = 'Testing login...';
    });

    final username = _testUsernameController.text;
    final password = _testPasswordController.text;
    
    print('🔍 Debug - Username length: ${username.length}');
    print('🔍 Debug - Password length: ${password.length}');
    print('🔍 Debug - Username bytes: ${username.codeUnits}');
    print('🔍 Debug - Password bytes: ${password.codeUnits}');
    print('🔍 Debug - Username: "$username"');
    print('🔍 Debug - Password: "$password"');

    try {
      final success = await ref.read(authProvider.notifier).login(
        username,
        password,
      );
      
      setState(() {
        _testResult = success ? 'Login successful!' : 'Login failed';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Login error: $e';
      });
    }
  }

  Future<void> _testRegister() async {
    setState(() {
      _testResult = 'Testing registration...';
    });

    try {
      final success = await ref.read(authProvider.notifier).register(
        fullName: 'Test User 2',
        username: 'testuser2',
        email: 'test2@example.com',
        password: 'TestPass123',
      );
      
      setState(() {
        _testResult = success ? 'Registration successful!' : 'Registration failed';
      });
    } catch (e) {
      setState(() {
        _testResult = 'Registration error: $e';
      });
    }
  }

  Future<void> _testLoadTasks() async {
    setState(() {
      _testResult = 'Loading tasks...';
    });

    try {
      await ref.read(taskProvider.notifier).loadTasks();
      final taskState = ref.read(taskProvider);
      
      setState(() {
        _testResult = 'Tasks loaded: ${taskState.tasks.length} tasks found\n' +
                     (taskState.error ?? 'No errors');
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error loading tasks: $e';
      });
    }
  }

  Future<void> _testLoadUsers() async {
    setState(() {
      _testResult = 'Loading users...';
    });

    try {
      await ref.read(teamProvider.notifier).loadUsers();
      final teamState = ref.read(teamProvider);
      
      setState(() {
        _testResult = 'Users loaded: ${teamState.users.length} users found\n'
                     'Error: ${teamState.error ?? 'No errors'}\n'
                     'Loading: ${teamState.isLoading}';
        if (teamState.users.isNotEmpty) {
          _testResult += '\nFirst user: ${teamState.users.first.fullName}';
        }
      });
    } catch (e) {
      setState(() {
        _testResult = 'Error loading users: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('API Test'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Backend API Test',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            
            Text('Auth State: ${authState.isAuthenticated ? "Authenticated" : "Not Authenticated"}'),
            if (authState.user != null)
              Text('User: ${authState.user!.fullName}'),
            if (authState.error != null)
              Text('Error: ${authState.error}', style: const TextStyle(color: Colors.red)),
            
            const SizedBox(height: 32),
            
            TextField(
              controller: _testUsernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _testPasswordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _testLogin,
                    child: const Text('Test Login'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : _testRegister,
                    child: const Text('Test Register'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Test Result:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(_testResult),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test data endpoints
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: authState.isAuthenticated ? _testLoadTasks : null,
                    child: const Text('Test Load Tasks'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: authState.isAuthenticated ? _testLoadUsers : null,
                    child: const Text('Test Load Users'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to App'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
              child: const Text('Logout', style: TextStyle(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
  }
}