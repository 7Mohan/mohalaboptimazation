/// String utility extensions.
extension StringExtensions on String {
  /// Capitalises only the first character of this string.
  String get capitalised {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Returns true if this string contains only whitespace or is empty.
  bool get isBlank => trim().isEmpty;

  /// Returns true if this string is non-empty and not blank.
  bool get isNotBlank => !isBlank;

  /// Truncates to [maxLength] characters, appending [ellipsis] if truncated.
  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }
}

/// Nullable string extensions.
extension NullableStringExtensions on String? {
  /// Returns [fallback] if null or blank, otherwise returns the trimmed string.
  String orFallback(String fallback) {
    final v = this?.trim();
    if (v == null || v.isEmpty) return fallback;
    return v;
  }
}
