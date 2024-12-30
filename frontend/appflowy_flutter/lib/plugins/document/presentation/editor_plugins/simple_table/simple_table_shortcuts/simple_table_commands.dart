import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_arrow_down_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_arrow_left_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_arrow_right_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_arrow_up_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_backspace_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_enter_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_navigation_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_select_all_command.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_shortcuts/simple_table_tab_command.dart';

final simpleTableCommands = [
  tableNavigationArrowDownCommand,
  arrowUpInTableCell,
  arrowDownInTableCell,
  arrowLeftInTableCell,
  arrowRightInTableCell,
  tabInTableCell,
  shiftTabInTableCell,
  backspaceInTableCell,
  selectAllInTableCellCommand,
  enterInTableCell,
];
