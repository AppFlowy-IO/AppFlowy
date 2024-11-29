import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_arrow_down_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_arrow_left_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_arrow_right_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_arrow_up_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_backspace_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_tab_command.dart';

final simpleTableCommands = [
  arrowUpInTableCell,
  arrowDownInTableCell,
  arrowLeftInTableCell,
  arrowRightInTableCell,
  tabInTableCell,
  shiftTabInTableCell,
  backspaceInTableCell,
];
