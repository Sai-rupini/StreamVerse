import 'package:flutter/material.dart';
import 'package:movie/services/auth_service.dart';

// The TickerProviderStateMixin is required to use AnimationController.
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

// Add TickerProviderStateMixin to enable animations.
class _SignUpPageState extends State<SignUpPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';

  // AnimationController manages the overall animation sequence.
  late final AnimationController _controller;
  // This animation will control the widget's position, creating a slide-in effect.
  late final Animation<Offset> _slideAnimation;
  // This animation will control the widget's opacity, creating a fade-in effect.
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize the AnimationController with a duration.
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Create a Tween to define the start and end values for the slide.
    // Here, we slide the content up from 50% below its final position.
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Define the fade-in animation, going from invisible to fully opaque.
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    // Start the animation.
    _controller.forward();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed to prevent memory leaks.
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    try {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        throw Exception('Email and Password cannot be empty.');
      }
      await AuthService.signUp(_emailController.text, _passwordController.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful! Please login.')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold provides the fundamental visual structure.
    return Scaffold(
      // AppBar is the top bar of the screen.
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // The Padding widget is wrapped in a FadeTransition and SlideTransition.
      // This applies the combined slide and fade animation to the entire form.
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            // Column arranges its children vertically.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Create a New Account',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                // TextField for the email input.
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                // TextField for the password input.
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                // This conditional Text widget displays an error message if one exists.
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 30),
                // Sizedbox ensures the button takes up the full width.
                SizedBox(
                  width: double.infinity,
                  // ElevatedButton is a button with a solid background color.
                  child: ElevatedButton(
                    onPressed: _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}