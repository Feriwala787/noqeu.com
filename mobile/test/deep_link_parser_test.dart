import 'package:flutter_test/flutter_test.dart';
import 'package:noqeu_mobile/utils/deep_link_parser.dart';

void main() {
  test('parses custom scheme deep links', () {
    expect(parseShopIdFromLink('noqeu://shop/abc123'), 'abc123');
  });

  test('parses web deep links', () {
    expect(parseShopIdFromLink('https://noqeu.com/shop/abc123'), 'abc123');
  });

  test('returns null for invalid links', () {
    expect(parseShopIdFromLink('https://noqeu.com/other/abc123'), isNull);
  });
}
