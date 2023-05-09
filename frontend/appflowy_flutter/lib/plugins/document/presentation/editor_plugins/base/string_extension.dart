extension Capitalize on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
