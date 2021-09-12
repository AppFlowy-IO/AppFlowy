import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/doc/doc_bloc.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/doc/doc_page.dart';
import 'package:flowy_infra/flowy_logger.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flowy_infra_ui/style_widget/progress_indicator.dart';

class DocStackPage extends HomeStackWidget {
  const DocStackPage({Key? key, required DocPageStackView stackView})
      : super(key: key, stackView: stackView);

  @override
  _DocStackPageState createState() => _DocStackPageState();
}

class _DocStackPageState extends State<DocStackPage> {
  @override
  Widget build(BuildContext context) {
    final stackView = widget.stackView as DocPageStackView;
    return MultiBlocProvider(
      providers: [
        BlocProvider<DocBloc>(
            create: (context) => getIt<DocBloc>(param1: stackView.view.id)
              ..add(const DocEvent.loadDoc())),
      ],
      child: BlocBuilder<DocBloc, DocState>(builder: (context, state) {
        assert(widget.stackView is DocPageStackView);
        return state.map(
          loading: (_) => const FlowyProgressIndicator(),
          loadDoc: (s) => DocPage(doc: s.doc),
          loadFail: (s) {
            Log.error("$s");
            return FlowyErrorPage(s.error.toString());
          },
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
  void didUpdateWidget(covariant DocStackPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }
}

class DocPageStackView extends HomeStackView {
  final View view;
  DocPageStackView(this.view)
      : super(
          type: view.viewType,
          title: view.name,
          identifier: view.id,
        );

  @override
  List<Object> get props => [view.id, type];
}
