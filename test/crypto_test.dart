
import 'package:cyberme_flutter/pocket/config.dart';
import 'package:flutter_test/flutter_test.dart';

main() {
  test("sha-b64 right", () {
    expect(encodeSha1Base64("hello"), 'qvTGHdzF6KLavt4PO0gs2a6pQ00=');
    expect(encodeSha1Base64("world"), 'fCEUM/AgcVl3Qeb/Wo6jR4mrv0M=');
    expect(encodeSha1Base64("this is something important"), 'AfGW2Ea1vsAjYSxPHLzBUAE2QsI=');
  });

  test("encryptPassword right", () {
    expect(encryptPassword("hello", 1000, 1678671400640), "NDhvRmFRSmI5cVpEWmw3VS8xUXhWMm1ybGhzPTo6MTY3ODY3MjQwMDY0MA==");
    expect(encryptPassword("world", 1000, 1678671400640), "WlJiQUdubFlLc0E5ZkxIOThvak5pRUVna3pZPTo6MTY3ODY3MjQwMDY0MA==");
  });
}