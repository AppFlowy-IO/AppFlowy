import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/home/home_screen.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time/time.dart';
import 'package:fluttertoast/fluttertoast.dart';

late FToast fToast;

// [[diagram: HomeStack's widget structure]]
//
//                                                               ┌──────────────────┐   ┌───────────────┐
//                                                            ┌──│BlankStackContext │──▶│BlankStackPage │
// ┌──────────┐  ┌───────────────────┐   ┌─────────────────┐  │  └──────────────────┘   └───────────────┘
// │HomeStack │─▶│ HomeStackManager  │──▶│HomeStackContext │◀─┤
// └──────────┘  └───────────────────┘   └─────────────────┘  │  ┌─────────────────┐    ┌────────────┐
//                                                            └──│ DocStackContext │───▶│DocStackPage│
//                                                               └─────────────────┘    └────────────┘
//
//
class HomeStack extends StatelessWidget {
  static GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  // final Size size;
  const HomeStack({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Log.info('HomePage build');
    final theme = context.watch<AppTheme>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        getIt<HomeStackManager>().stackTopBar(),
        Expanded(
          child: Container(
            color: theme.surface,
            child: FocusTraversalGroup(
              child: getIt<HomeStackManager>().stackWidget(),
            ),
          ),
        ),
      ],
    );
  }
}

class FadingIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadingIndexedStack({
    Key? key,
    required this.index,
    required this.children,
    this.duration = const Duration(
      milliseconds: 250,
    ),
  }) : super(key: key);

  @override
  _FadingIndexedStackState createState() => _FadingIndexedStackState();
}

class _FadingIndexedStackState extends State<FadingIndexedStack> {
  double _targetOpacity = 1;

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    fToast.init(HomeScreen.scaffoldKey.currentState!.context);
  }

  @override
  void didUpdateWidget(FadingIndexedStack oldWidget) {
    if (oldWidget.index == widget.index) return;
    setState(() => _targetOpacity = 0);
    Future.delayed(1.milliseconds, () => setState(() => _targetOpacity = 1));
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: _targetOpacity > 0 ? widget.duration : 0.milliseconds,
      tween: Tween(begin: 0, end: _targetOpacity),
      builder: (_, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: IndexedStack(index: widget.index, children: widget.children),
    );
  }
}
