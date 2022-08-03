import 'dart:collection';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../flowy_board.dart';

import 'column_container.dart';
import 'flex/reorder_flex.dart';
import 'phantom/phantom_controller.dart';

class Board extends StatelessWidget {
  /// The direction to use as the main axis.
  final Axis direction = Axis.vertical;

  /// How much space to place between children in a run in the main axis.
  /// Defaults to 10.0.
  final double spacing;

  /// How much space to place between the runs themselves in the cross axis.
  /// Defaults to 0.0.
  final double runSpacing;

  final Widget? background;

  final BoardColumnItemWidgetBuilder builder;

  ///
  final BoardDataController dataController;

  ///
  final BoardPhantomController passthroughPhantomContorller;

  Board({
    required this.dataController,
    required this.builder,
    this.spacing = 10.0,
    this.runSpacing = 0.0,
    this.background,
    Key? key,
  })  : passthroughPhantomContorller =
            BoardPhantomController(delegate: dataController),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: dataController,
      child: Consumer(
        builder: (context, notifier, child) {
          List<Widget> children = [];
          List<String> acceptColumns =
              dataController.columnControllers.keys.toList();

          dataController.columnControllers.forEach((columnId, dataController) {
            Widget child =
                buildBoardColumn(columnId, acceptColumns, dataController);
            if (children.isEmpty) {
              // children.add(SizedBox(width: spacing));
            }
            // if (background != null) {
            //   child = Stack(children: [
            //     background!,
            //     child,
            //   ]);
            // }
            // children.add(Expanded(key: ValueKey(columnId), child: child));
            children.add(child);
            // children.add(SizedBox(width: spacing));
          });

          return BoardColumnContainer(
            onReorder: (fromIndex, toIndex) {},
            boardDataController: dataController,
            children: children,
          );

          // return Row(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //   children: children,
          // );
        },
      ),
    );
  }

  ///
  Widget buildBoardColumn(
    String columnId,
    List<String> acceptColumns,
    BoardColumnDataController dataController,
  ) {
    return ChangeNotifierProvider.value(
      key: ValueKey(columnId),
      value: dataController,
      child: Consumer<BoardColumnDataController>(
        builder: (context, value, child) {
          return SizedBox(
            width: 200,
            child: BoardColumnWidget(
              header: Container(color: Colors.yellow, height: 30),
              builder: builder,
              acceptColumns: acceptColumns,
              dataController: dataController,
              scrollController: ScrollController(),
              onReorder: (_, int fromIndex, int toIndex) {
                dataController.move(fromIndex, toIndex);
              },
              phantomController: passthroughPhantomContorller,
            ),
          );
        },
      ),
    );
  }
}

class BoardDataController extends ChangeNotifier
    with EquatableMixin, BoardPhantomControllerDelegate, ReoderFlextDataSource {
  final LinkedHashMap<String, BoardColumnData> columnDatas = LinkedHashMap();
  final LinkedHashMap<String, BoardColumnDataController> columnControllers =
      LinkedHashMap();

  BoardDataController();

  void setColumnData(BoardColumnData columnData) {
    final controller = BoardColumnDataController(columnData: columnData);
    columnDatas[columnData.id] = columnData;
    columnControllers[columnData.id] = controller;
  }

  @override
  List<Object?> get props {
    return [columnDatas.values];
  }

  @override
  BoardColumnDataController? controller(String columnId) {
    return columnControllers[columnId];
  }

  @override
  String get identifier => '$BoardDataController';

  @override
  List<ReoderFlextItem> get items => columnDatas.values.toList();
}

class BoardDataIdentifier {}
