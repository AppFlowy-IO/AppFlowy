import 'package:flutter/material.dart';

import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';

class FontSizeStepper extends StatefulWidget {
  const FontSizeStepper({
    super.key,
    required this.minimumValue,
    required this.maximumValue,
    required this.value,
    required this.divisions,
    required this.onChanged,
  });

  final double minimumValue;
  final double maximumValue;
  final double value;
  final ValueChanged<double> onChanged;
  final int divisions;

  @override
  State<FontSizeStepper> createState() => _FontSizeStepperState();
}

class _FontSizeStepperState extends State<FontSizeStepper> {
  late double _value = widget.value.clamp(
    widget.minimumValue,
    widget.maximumValue,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const FlowyText('A', fontSize: 14),
          const HSpace(6),
          Expanded(
            child: SliderTheme(
              data: Theme.of(context).sliderTheme.copyWith(
                    showValueIndicator: ShowValueIndicator.never,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
                    ),
                  ),
              child: Slider(
                value: _value,
                min: widget.minimumValue,
                max: widget.maximumValue,
                divisions: widget.divisions,
                onChanged: (value) {
                  setState(() => _value = value);
                  widget.onChanged(value);
                },
              ),
            ),
          ),
          const HSpace(6),
          const FlowyText('A', fontSize: 20),
        ],
      ),
    );
  }
}
