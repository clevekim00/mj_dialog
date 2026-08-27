import 'dart:convert';

import 'package:cryptography/cryptography.dart';

abstract interface class ResourceSignatureVerifier {
  Future<bool> verify(Map<String, dynamic> document);
}

class Ed25519ResourceSignatureVerifier implements ResourceSignatureVerifier {
  Ed25519ResourceSignatureVerifier({
    this.publicKeyBase64 = const String.fromEnvironment(
      'RESOURCE_CATALOG_PUBLIC_KEY',
    ),
  });

  final String publicKeyBase64;

  @override
  Future<bool> verify(Map<String, dynamic> document) async {
    final signatureBase64 = document['signature'] as String? ?? '';
    if (publicKeyBase64.isEmpty || signatureBase64.isEmpty) return false;
    try {
      final publicKeyBytes = base64Decode(publicKeyBase64);
      final signatureBytes = base64Decode(signatureBase64);
      if (publicKeyBytes.length != 32 || signatureBytes.length != 64) {
        return false;
      }
      final unsigned = Map<String, dynamic>.from(document)..remove('signature');
      final publicKey = SimplePublicKey(
        publicKeyBytes,
        type: KeyPairType.ed25519,
      );
      return Ed25519().verify(
        utf8.encode(canonicalResourceJson(unsigned)),
        signature: Signature(signatureBytes, publicKey: publicKey),
      );
    } catch (_) {
      return false;
    }
  }
}

String canonicalResourceJson(Object? value) {
  Object? canonicalize(Object? item) {
    if (item is Map) {
      final keys = item.keys.map((key) => key.toString()).toList()..sort();
      return <String, dynamic>{
        for (final key in keys) key: canonicalize(item[key]),
      };
    }
    if (item is List) return item.map(canonicalize).toList(growable: false);
    return item;
  }

  return jsonEncode(canonicalize(value));
}
