import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class CryptoService {
  CryptoService._internal();
  static final CryptoService instance = CryptoService._internal();

  // Must be the EXACT same base64 key as the backend's AES_SECRET_KEY
  static const String _base64Key = 'KQ7eZ9waT3sSW69aNLqXkGW1yoTdhueVnX+W3dP5coE=';

  final _algorithm = AesGcm.with256bits();

  Future<SecretKey> _getKey() async {
    return SecretKey(base64Decode(_base64Key));
  }

  Future<String> encryptPayload(Map<String, dynamic> data) async {
    final key = await _getKey();
    final nonce = _algorithm.newNonce();
    final plaintext = utf8.encode(jsonEncode(data));

    final secretBox = await _algorithm.encrypt(plaintext, secretKey: key, nonce: nonce);

    final combined = Uint8List.fromList(
      secretBox.nonce + secretBox.cipherText + secretBox.mac.bytes,
    );
    return base64Encode(combined);
  }

  Future<Map<String, dynamic>> decryptPayload(String token) async {
    final key = await _getKey();
    final raw = base64Decode(token);

    final nonce = raw.sublist(0, 12);
    final mac = raw.sublist(raw.length - 16);
    final cipherText = raw.sublist(12, raw.length - 16);

    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
    final decrypted = await _algorithm.decrypt(secretBox, secretKey: key);
    return jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
  }
}