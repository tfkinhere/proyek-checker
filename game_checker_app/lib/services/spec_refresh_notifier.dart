import 'package:flutter/foundation.dart';

/// Sinyal global untuk memberi tahu bahwa spesifikasi hardware user berubah.
///
/// Dipakai agar dashboard (dimiliki oleh MainNavigationPage) bisa auto-refresh
/// segera setelah user menyimpan/mengubah spek dari halaman mana pun, tanpa
/// perlu menekan tombol refresh manual.
class SpecRefreshNotifier {
  SpecRefreshNotifier._();

  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  static void notifyChanged() {
    version.value += 1;
  }
}
