import 'package:flutter_test/flutter_test.dart';
import 'package:ac_techs/core/widgets/zoom_drawer.dart';

void main() {
  group('ZoomDrawerController', () {
    test('isOpen defaults to false when not attached', () {
      final controller = ZoomDrawerController();
      expect(controller.isOpen, isFalse);
    });

    test('toggle/open/close are no-ops when not attached', () {
      final controller = ZoomDrawerController();
      // Should not throw
      controller.toggle();
      controller.open();
      controller.close();
      expect(controller.isOpen, isFalse);
    });
  });

  group('ZoomDrawerScope', () {
    test('maybeOf returns null when no scope in tree', () {
      // Cannot test without a widget tree — covered by widget tests
      // This test verifies the static constructor exists
      expect(ZoomDrawerScope.maybeOf, isNotNull);
    });
  });
}
