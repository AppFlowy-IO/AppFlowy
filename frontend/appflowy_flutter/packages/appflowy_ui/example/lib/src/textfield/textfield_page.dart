import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class TextFieldPage extends StatelessWidget {
  const TextFieldPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'TextField with hint text',
            [
              AFTextField(
                hintText: 'Please enter your name',
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            'TextField with initial text',
            [
              AFTextField(
                initialText: 'https://appflowy.com',
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            'TextField with validator ',
            [
              AFTextField(
                validator: (controller) {
                  if (controller.text.isEmpty) {
                    return (true, 'This field is required');
                  }

                  final emailRegex =
                      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(controller.text)) {
                    return (true, 'Please enter a valid email address');
                  }

                  return (false, '');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
      ],
    );
  }
}
