import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class ButtonsPage extends StatelessWidget {
  const ButtonsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Filled Text Buttons',
            [
              AFFilledTextButton.primary(
                text: 'Primary Button',
                onTap: () {},
              ),
              const SizedBox(width: 16),
              AFFilledTextButton.destructive(
                text: 'Destructive Button',
                onTap: () {},
              ),
              const SizedBox(width: 16),
              AFFilledTextButton.disabled(
                text: 'Disabled Button',
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            'Filled Icon Text Buttons',
            [
              AFFilledButton.primary(
                onTap: () {},
                builder: (context, isHovering, disabled) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 20,
                      color: AppFlowyTheme.of(context).textColorScheme.onFill,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Primary Button',
                      style: TextStyle(
                        color: AppFlowyTheme.of(context).textColorScheme.onFill,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              AFFilledButton.destructive(
                onTap: () {},
                builder: (context, isHovering, disabled) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete,
                      size: 20,
                      color: AppFlowyTheme.of(context).textColorScheme.onFill,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Destructive Button',
                      style: TextStyle(
                        color: AppFlowyTheme.of(context).textColorScheme.onFill,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              AFFilledButton.disabled(
                builder: (context, isHovering, disabled) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.block,
                      size: 20,
                      color: AppFlowyTheme.of(context).textColorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Disabled Button',
                      style: TextStyle(
                        color:
                            AppFlowyTheme.of(context).textColorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            'Outlined Text Buttons',
            [
              AFOutlinedTextButton.normal(
                text: 'Normal Button',
                onTap: () {},
              ),
              const SizedBox(width: 16),
              AFOutlinedTextButton.destructive(
                text: 'Destructive Button',
                onTap: () {},
              ),
              const SizedBox(width: 16),
              AFOutlinedTextButton.disabled(
                text: 'Disabled Button',
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            'Outlined Icon Text Buttons',
            [
              AFOutlinedButton.normal(
                onTap: () {},
                builder: (context, isHovering, disabled) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add,
                      size: 20,
                      color: AppFlowyTheme.of(context).textColorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Normal Button',
                      style: TextStyle(
                        color:
                            AppFlowyTheme.of(context).textColorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              AFOutlinedButton.destructive(
                onTap: () {},
                builder: (context, isHovering, disabled) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete,
                      size: 20,
                      color: AppFlowyTheme.of(context).textColorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Destructive Button',
                      style: TextStyle(
                        color: AppFlowyTheme.of(context).textColorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              AFOutlinedButton.disabled(
                builder: (context, isHovering, disabled) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.block,
                      size: 20,
                      color: AppFlowyTheme.of(context).textColorScheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Disabled Button',
                      style: TextStyle(
                        color:
                            AppFlowyTheme.of(context).textColorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            'Ghost Buttons',
            [
              AFGhostTextButton.normal(
                text: 'Primary Button',
                onTap: () {},
              ),
              const SizedBox(width: 16),
              AFGhostTextButton.disabled(
                text: 'Disabled Button',
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSection(
            'Button Sizes',
            [
              AFFilledTextButton.primary(
                text: 'Small Button',
                onTap: () {},
                size: AFButtonSize.s,
              ),
              const SizedBox(width: 16),
              AFFilledTextButton.primary(
                text: 'Medium Button',
                onTap: () {},
              ),
              const SizedBox(width: 16),
              AFFilledTextButton.primary(
                text: 'Large Button',
                onTap: () {},
                size: AFButtonSize.l,
              ),
              const SizedBox(width: 16),
              AFFilledTextButton.primary(
                text: 'Extra Large Button',
                onTap: () {},
                size: AFButtonSize.xl,
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
