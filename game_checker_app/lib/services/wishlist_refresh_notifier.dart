import 'package:flutter/foundation.dart';

class WishlistRefreshNotifier {
  WishlistRefreshNotifier._();

  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  static void notifyChanged() {
    version.value += 1;
  }
}
