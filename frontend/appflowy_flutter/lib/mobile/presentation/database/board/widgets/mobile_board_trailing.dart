import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/board/application/board_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add new group
class MobileBoardTrailing extends StatefulWidget {
  const MobileBoardTrailing({super.key});

  @override
  State<MobileBoardTrailing> createState() => _MobileBoardTrailingState();
}

class _MobileBoardTrailingState extends State<MobileBoardTrailing> {
  final TextEditingController _textController = TextEditingController();

  bool isEditing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final style = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: screenSize.width * 0.7,
        child: isEditing
            ? DecoratedBox(
                decoration: BoxDecoration(
                  color: style.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _textController,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          suffixIcon: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: _textController.text.isNotEmpty ? 1 : 0,
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: style.colorScheme.onSurface,
                                ),
                                onPressed: () =>
                                    setState(() => _textController.clear()),
                              ),
                            ),
                          ),
                          isDense: true,
                        ),
                        onEditingComplete: () {
                          context.read<BoardBloc>().add(
                                BoardEvent.createGroup(
                                  _textController.text,
                                ),
                              );
                          _textController.clear();
                          setState(() => isEditing = false);
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            child: Text(
                              LocaleKeys.button_cancel.tr(),
                              style: style.textTheme.titleSmall?.copyWith(
                                color: style.colorScheme.onSurface,
                              ),
                            ),
                            onPressed: () => setState(() => isEditing = false),
                          ),
                          TextButton(
                            child: Text(
                              LocaleKeys.button_add.tr(),
                              style: style.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: style.colorScheme.onSurface,
                              ),
                            ),
                            onPressed: () {
                              context.read<BoardBloc>().add(
                                    BoardEvent.createGroup(
                                      _textController.text,
                                    ),
                                  );
                              _textController.clear();
                              setState(() => isEditing = false);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  foregroundColor: style.colorScheme.onSurface,
                  backgroundColor: style.colorScheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ).copyWith(
                  overlayColor:
                      WidgetStateProperty.all(Theme.of(context).hoverColor),
                ),
                icon: const Icon(Icons.add),
                label: Text(
                  LocaleKeys.board_column_newGroup.tr(),
                  style: style.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => setState(() => isEditing = true),
              ),
      ),
    );
  }
}
