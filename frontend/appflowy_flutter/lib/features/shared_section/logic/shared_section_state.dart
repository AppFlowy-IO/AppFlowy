import 'package:appflowy/features/shared_section/models/shared_page.dart';

class SharedSectionState {
  factory SharedSectionState.initial() => const SharedSectionState();

  const SharedSectionState({
    this.sharedPages = const [],
    this.isLoading = false,
    this.errorMessage = '',
    this.isExpanded = true,
  });

  final SharedPages sharedPages;
  final bool isLoading;
  final String errorMessage;
  final bool isExpanded;

  SharedSectionState copyWith({
    SharedPages? sharedPages,
    bool? isLoading,
    String? errorMessage,
    bool? isExpanded,
  }) {
    return SharedSectionState(
      sharedPages: sharedPages ?? this.sharedPages,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SharedSectionState &&
        other.sharedPages == sharedPages &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage &&
        other.isExpanded == isExpanded;
  }

  @override
  int get hashCode {
    return Object.hash(
      sharedPages,
      isLoading,
      errorMessage,
      isExpanded,
    );
  }

  @override
  String toString() {
    return 'SharedSectionState(sharedPages: $sharedPages, isLoading: $isLoading, errorMessage: $errorMessage, isExpanded: $isExpanded)';
  }
}
