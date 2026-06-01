import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CustomTextField(label: 'Full Name', controller: nameController),
            const SizedBox(height: 16),
            CustomTextField(label: 'Email', controller: emailController),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Password',
              controller: passwordController,
              isPassword: true,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Create Account',
              onPressed: () {
                // Implement signup logic
                context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
