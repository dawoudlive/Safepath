import 'package:flutter_test/flutter_test.dart';
import 'package:safepath/i18n.dart';

void main() {
  test('tr picks the right language', () {
    isArabic.value = false;
    expect(tr('Hello', 'مرحبا'), 'Hello');
    isArabic.value = true;
    expect(tr('Hello', 'مرحبا'), 'مرحبا');
  });
}
