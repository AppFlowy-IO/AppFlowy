import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class ModalPage extends StatefulWidget {
  const ModalPage({super.key});

  @override
  State<ModalPage> createState() => _ModalPageState();
}

class _ModalPageState extends State<ModalPage> {
  double width = AFModalDimension.M;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 600),
        padding: EdgeInsets.symmetric(horizontal: theme.spacing.xl),
        child: Column(
          spacing: theme.spacing.l,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              spacing: theme.spacing.m,
              mainAxisSize: MainAxisSize.min,
              children: [
                AFGhostButton.normal(
                  onTap: () => setState(() => width = AFModalDimension.S),
                  builder: (context, isHovering, disabled) {
                    return Text(
                      'S',
                      style: TextStyle(
                        color: width == AFModalDimension.S
                            ? theme.textColorScheme.theme
                            : theme.textColorScheme.primary,
                      ),
                    );
                  },
                ),
                AFGhostButton.normal(
                  onTap: () => setState(() => width = AFModalDimension.M),
                  builder: (context, isHovering, disabled) {
                    return Text(
                      'M',
                      style: TextStyle(
                        color: width == AFModalDimension.M
                            ? theme.textColorScheme.theme
                            : theme.textColorScheme.primary,
                      ),
                    );
                  },
                ),
                AFGhostButton.normal(
                  onTap: () => setState(() => width = AFModalDimension.L),
                  builder: (context, isHovering, disabled) {
                    return Text(
                      'L',
                      style: TextStyle(
                        color: width == AFModalDimension.L
                            ? theme.textColorScheme.theme
                            : theme.textColorScheme.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
            AFFilledButton.primary(
              builder: (context, isHovering, disabled) {
                return Text(
                  'Show Modal',
                  style: TextStyle(
                    color: AppFlowyTheme.of(context).textColorScheme.onFill,
                  ),
                );
              },
              onTap: () {
                showDialog(
                  context: context,
                  barrierColor: theme.surfaceColorScheme.overlay,
                  builder: (context) {
                    final theme = AppFlowyTheme.of(context);

                    return Center(
                      child: AFModal(
                          constraints: BoxConstraints(
                            maxWidth: width,
                            maxHeight: AFModalDimension.dialogHeight,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AFModalHeader(
                                leading: Text(
                                  'Header',
                                  style: theme.textStyle.heading.h4(
                                    color: theme.textColorScheme.primary,
                                  ),
                                ),
                                trailing: [
                                  AFGhostButton.normal(
                                    onTap: () => Navigator.of(context).pop(),
                                    builder: (context, isHovering, disabled) {
                                      return const Icon(Icons.close);
                                    },
                                  )
                                ],
                              ),
                              Expanded(
                                child: AFModalBody(
                                  child: Text(
                                      'A dialog briefly presents information or requests confirmation, allowing users to continue their workflow after interaction.'),
                                ),
                              ),
                              AFModalFooter(
                                trailing: [
                                  AFOutlinedButton.normal(
                                    onTap: () => Navigator.of(context).pop(),
                                    builder: (context, isHovering, disabled) {
                                      return const Text('Cancel');
                                    },
                                  ),
                                  AFFilledButton.primary(
                                    onTap: () => Navigator.of(context).pop(),
                                    builder: (context, isHovering, disabled) {
                                      return Text(
                                        'Apply',
                                        style: TextStyle(
                                          color: AppFlowyTheme.of(context)
                                              .textColorScheme
                                              .onFill,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              )
                            ],
                          )),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
