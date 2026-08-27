import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_rehab/services/resources/resource_signature_verifier.dart';

void main() {
  test('Ed25519로 서명한 catalog만 허용한다', () async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final document = <String, dynamic>{
      'schemaVersion': 1,
      'catalogVersion': '2.0.0',
      'languages': <Object>[],
      'packs': <Object>[],
    };
    final signature = await algorithm.sign(
      utf8.encode(canonicalResourceJson(document)),
      keyPair: keyPair,
    );
    document['signature'] = base64Encode(signature.bytes);
    final verifier = Ed25519ResourceSignatureVerifier(
      publicKeyBase64: base64Encode(publicKey.bytes),
    );

    expect(await verifier.verify(document), isTrue);
    document['catalogVersion'] = '9.9.9';
    expect(await verifier.verify(document), isFalse);
  });

  test('공개키나 서명이 없으면 원격 catalog를 거부한다', () async {
    final verifier = Ed25519ResourceSignatureVerifier();

    expect(await verifier.verify({'catalogVersion': '1.0.0'}), isFalse);
  });
}
