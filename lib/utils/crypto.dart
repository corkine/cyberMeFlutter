import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cyberme_flutter/pocket/day.dart';
import 'package:sprintf/sprintf.dart';

String encryptPassword(String password, int validSeconds, [int? nowMill]) {
  var willExpired = (nowMill ?? DateTime.now().millisecondsSinceEpoch) + validSeconds * 1000;
  var digest = sha1.convert(utf8.encode("$password::$willExpired"));
  var passInSha1Base64 = base64Encode(digest.bytes);
  var res = base64Encode(utf8.encode("$passInSha1Base64::$willExpired"));
  DayInfo.encryptInfo = sprintf("The last encrypt validSec: %s, nowMill: %s, pass: %s, willExpired: %s,"
      "encrypt %s", [validSeconds, nowMill ?? -1, password.isNotEmpty, willExpired, res]);
  return res;
}

String encodeSha1Base64(String plain) {
  var digest = sha1.convert(utf8.encode(plain));
  return base64Encode(digest.bytes);
}