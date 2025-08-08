import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegistering = false;
  bool _isLoading = false;

  void _toggleMode() {
    setState(() {
      _isRegistering = !_isRegistering;
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isRegistering) {
      
      setState(() => _isLoading = true);
    }

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    try {
      if (_isRegistering) {
        final credential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await firestore.collection('users').doc(credential.user!.uid).set({
          'full_name': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
        });

        if (mounted) {
          FocusScope.of(context).unfocus();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Successfully registered"),
              backgroundColor: Colors.green,
            ),
          );

          
          _fullNameController.clear();
          _emailController.clear();
          _passwordController.clear();

          
          await Future.delayed(const Duration(seconds: 1));

          
          setState(() {
            _isRegistering = false;
            _isLoading = false;
          });
        }
      } else {
        final credential = await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final doc = await firestore.collection('users').doc(credential.user!.uid).get();
        final fullName = doc.data()?['full_name'] ?? 'User';

        if (mounted) {
          setState(() => _isLoading = false);
          _navigateToHome(fullName);
        }
      }
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.message ?? 'Authentication error');
      }
    } on FirebaseException catch (e) {
      print('FirebaseException: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.message ?? 'Database error');
      }
    } catch (e) {
      print('Unexpected error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('An unexpected error occurred: $e');
      }
    }
  }

  void _navigateToHome(String fullName) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(fullName: fullName)),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    if (_isRegistering && (value == null || value.trim().isEmpty)) {
      return 'Please enter your full name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isButtonDisabled = _isRegistering && _isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegistering ? 'Register' : 'Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_isRegistering)
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(labelText: 'Full Name'),
                  validator: _validateFullName,
                ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: _validatePassword,
              ),
              SizedBox(height: 20),
              _isRegistering
                  ? ElevatedButton(
                      onPressed: isButtonDisabled ? null : _submit,
                      child: Text('Register'),
                    )
                  : (_isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submit,
                          child: Text('Login'),
                        )),
              TextButton(
                onPressed: _toggleMode,
                child: Text(_isRegistering
                    ? 'Already have an account? Login'
                    : 'Don\'t have an account? Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
