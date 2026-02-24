class CustomException implements Exception {
  /**
   * A message describing the format error.
   */
  String message;

  /**
   * Creates a new FormatException with an optional error [message].
   */
  CustomException({
    required this.message,
  });
  @override
  String toString() => "$message";
}
