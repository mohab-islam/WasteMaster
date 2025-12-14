import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'main_layout.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    final isLogin = _tabController.index == 0;
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    try {
      Map<String, dynamic> response;
      if (isLogin) {
        if (email.isEmpty || password.isEmpty) throw Exception("Please fill all fields");
        response = await ApiService.loginUser(email, password);
      } else {
        if (name.isEmpty || email.isEmpty || password.isEmpty) throw Exception("Please fill all fields");
        response = await ApiService.registerUser(name, email, password);
      }

      await AuthService.saveUser(response['_id'], response['name']);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainLayout()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Title
              const Icon(Icons.recycling, size: 80, color: AppTheme.primaryGold),
              const SizedBox(height: 16),
              const Text(
                'WasteMaster',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textLight,
                ),
              ),
              const SizedBox(height: 40),

              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryGold,
                labelColor: AppTheme.primaryGold,
                unselectedLabelColor: AppTheme.textDim,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                tabs: const [
                  Tab(text: 'Log In'),
                  Tab(text: 'Sign Up'),
                ],
              ),
              const SizedBox(height: 24),

              // Form
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Login Form
                    _buildForm(isLogin: true),
                    // Sign Up Form
                    _buildForm(isLogin: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm({required bool isLogin}) {
    return SingleChildScrollView(
      child: Column(
        children: [
          if (!isLogin) ...[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline, color: AppTheme.textDim),
              ),
              style: const TextStyle(color: AppTheme.textLight),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textDim),
            ),
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppTheme.textLight),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textDim),
            ),
            obscureText: true,
            style: const TextStyle(color: AppTheme.textLight),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppTheme.background))
                : Text(isLogin ? 'Log In' : 'Sign Up'),
            ),
          ),
        ],
      ),
    );
  }
}
