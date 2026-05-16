import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ConditionalListenableBuilder<T> extends StatefulWidget {
  const ConditionalListenableBuilder({
    super.key,
    required this.valueListenable,
    required this.buildWhen,
    required this.builder,
    this.child,
  });

  /// The [ValueListenable] whose value you depend on in order to build.
  ///
  /// This widget does not ensure that the [ValueListenable]'s value is not
  /// null, therefore your [builder] may need to handle null values.
  final ValueListenable<T> valueListenable;

  /// The [buildWhen] function will be called on each value change of the
  /// [valueListenable]. If the [buildWhen] function returns true, the [builder]
  /// will be called with the new value of the [valueListenable].
  ///
  final bool Function(T previous, T current) buildWhen;

  /// A [ValueWidgetBuilder] which builds a widget depending on the
  /// [valueListenable]'s value.
  ///
  /// Can incorporate a [valueListenable] value-independent widget subtree
  /// from the [child] parameter into the returned widget tree.
  final ValueWidgetBuilder<T> builder;

  /// A [valueListenable]-independent widget which is passed back to the [builder].
  ///
  /// This argument is optional and can be null if the entire widget subtree the
  /// [builder] builds depends on the value of the [valueListenable]. For
  /// example, in the case where the [valueListenable] is a [String] and the
  /// [builder] returns a [Text] widget with the current [String] value, there
  /// would be no useful [child].
  final Widget? child;

  @override
  State<ConditionalListenableBuilder> createState() =>
      _ConditionalListenableBuilderState<T>();
}

class _ConditionalListenableBuilderState<T>
    extends State<ConditionalListenableBuilder<T>> {
  late T value;

  @override
  void initState() {
    super.initState();
    value = widget.valueListenable.value;
    widget.valueListenable.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(ConditionalListenableBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.valueListenable != widget.valueListenable) {
      oldWidget.valueListenable.removeListener(_valueChanged);
      value = widget.valueListenable.value;
      widget.valueListenable.addListener(_valueChanged);
    }
  }

  @override
  void dispose() {
    widget.valueListenable.removeListener(_valueChanged);
    super.dispose();
  }

  void _valueChanged() {
    if (widget.buildWhen(value, widget.valueListenable.value)) {
      setState(() {
        value = widget.valueListenable.value;
      });
    } else {
      value = widget.valueListenable.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value, widget.child);
  }
}
