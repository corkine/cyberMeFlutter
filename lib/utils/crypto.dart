import 'dart:convert';

import 'package:crypto/crypto.dart';

String encryptPassword(String password, int validSeconds, [int? nowMill]) {
  var willExpired = (nowMill == null ? DateTime.now().millisecondsSinceEpoch : nowMill) + validSeconds * 1000;
  var digest = sha1.convert(utf8.encode("$password::$willExpired"));
  var passInSha1Base64 = base64Encode(digest.bytes);
  return base64Encode(utf8.encode("$passInSha1Base64::$willExpired"));
}

String encodeSha1Base64(String plain) {
  var digest = sha1.convert(utf8.encode(plain));
  return base64Encode(digest.bytes);
}