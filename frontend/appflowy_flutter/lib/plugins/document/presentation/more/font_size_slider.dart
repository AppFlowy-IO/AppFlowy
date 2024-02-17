import 'package:flutter/material.dart';

import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FontSizeStepper extends StatelessWidget {
  const FontSizeStepper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentAppearanceCubit, DocumentAppearance>(
      builder: (context, state) {
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
                    value: state.fontSize,
                    min: 10,
                    max: 24,
                    divisions: 8,
                    onChanged: (fontSize) => context
                        .read<DocumentAppearanceCubit>()
                        .syncFontSize(fontSize),
                  ),
                ),
              ),
              const HSpace(6),
              const FlowyText('A', fontSize: 20),
            ],
          ),
        );
      },
    );
  }
}
