import 'package:flutter/painting.dart';

extension ColorFade on Color {
  /// Multiplies the existing alpha by [factor]. Unlike [withOpacity], this
  /// keeps already-translucent glass roles translucent.
  Color fade(double factor) => withAlpha((alpha * factor).round().clamp(0, 255));
}
