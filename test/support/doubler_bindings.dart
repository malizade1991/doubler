import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The app key store lives behind a MethodChannel (`MainActivity.kt` /
/// `AppDelegate.swift`). In `flutter test` an unmocked channel never replies —
/// the awaited read would hang the splash forever — so any test that pumps the
/// whole app must install this handler first.
///
/// Returning `null` means "no key stored", which is what a fresh device does.
void mockDoublerStoreChannel({String? storedKey}) {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('com.doubler.doubler/store'),
    (MethodCall call) async {
      switch (call.method) {
        case 'read':
          return storedKey;
        case 'write':
        case 'remove':
          return true;
        default:
          return null;
      }
    },
  );
}
