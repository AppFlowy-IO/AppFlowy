import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/view/doc_watch_bloc.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/doc/editor_widget.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowy_infra_ui/style_widget/styled_progress_indicator.dart';

class DocPage extends HomeStackWidget {
  const DocPage({Key? key, required DocPageStackView stackView})
      : super(key: key, stackView: stackView);

  @override
  _DocPageState createState() => _DocPageState();
}

class _DocPageState extends State<DocPage> {
  @override
  Widget build(BuildContext context) {
    final stackView = widget.stackView as DocPageStackView;
    return MultiBlocProvider(
      providers: [
        BlocProvider<DocWatchBloc>(
            create: (context) => getIt<DocWatchBloc>(param1: stackView.view.id)
              ..add(const DocWatchEvent.started())),
      ],
      child:
          BlocBuilder<DocWatchBloc, DocWatchState>(builder: (context, state) {
        assert(widget.stackView is DocPageStackView);
        return state.map(
          loading: (_) => const StyledProgressIndicator(),
          loadDoc: (s) => EditorWdiget(doc: s.doc),
          loadFail: (s) => FlowyErrorPage(s.error.toString()),
        );
      }),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void didUpdateWidget(covariant DocPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }
}

class DocPageStackView extends HomeStackView {
  final View view;
  DocPageStackView(this.view)
      : super(
          type: view.viewType,
          title: view.name,
        );

  @override
  List<Object> get props => [view.id, type];
}
