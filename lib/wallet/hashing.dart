import 'dart:typed_data';

import 'package:agent_dart/principal/utils/get_crc.dart';
import 'package:agent_dart/utils/extension.dart';
import 'package:agent_dart/utils/u8a.dart';
import 'package:crypto/crypto.dart';
// ignore: implementation_imports
import 'package:crypto/src/digest_sink.dart';
import 'package:typed_data/typed_buffers.dart';

Uint8List sha256Chunks(List<dynamic> chunks) {
  final ds = DigestSink();
  final sha = sha256.startChunkedConversion(ds);

  for (final chunk in chunks) {
    sha.add(chunk is ByteBuffer ? chunk.asInt8List() : chunk);
  }
  sha.close();
  return Uint8List.fromList(ds.value.bytes);
}

Map<String, dynamic> makeReadStateFromUpdate(Map update) {
  return {
    'sender': update['sender'],
    'paths': [
      ['request_status'.plainToU8a(), httpCanisterUpdateId(update)],
    ],
    'ingress_expiry': update['ingress_expiry'],
  };
}

Uint8List httpReadStateRepresentationIndependentHash(Map readState) {
  return hashOfMap({
    'request_type': 'read_state',
    'ingress_expiry': readState['ingress_expiry'],
    'paths': readState['paths'],
    'sender': readState['sender'],
  });
}

Uint8List makeSignatureData(Uint8List messageId) {
  return u8aConcat(['\x0Aic-request'.plainToU8a(), messageId]);
}

Uint8List httpCanisterUpdateId(Map update) {
  return httpCanisterUpdateRepresentationIndependentHash(update);
}

Uint8List httpCanisterUpdateRepresentationIndependentHash(Map update) {
  return hashOfMap({
    'request_type': 'call',
    'canister_id': update['canister_id'],
    'method_name': update['method_name'],
    'arg': update['arg'],
    'ingress_expiry': update['ingress_expiry'],
    'sender': update['sender'],
  });
}

Uint8List hashOfMap(Map map) {
  final hashes = <Uint8List>[];
  for (final entry in map.entries) {
    hashes.add(hashKeyValue(entry.key, entry.value));
  }
  return sha256Chunks(u8aSorted(hashes));
}

Uint8List hashKeyValue(dynamic key, dynamic val) {
  return u8aConcat([_hashString(key.toString()), _hashValue(val)]);
}

Uint8List _hashValue(dynamic val) {
  if (val is String) {
    return _hashString(val);
  }
  if (val is Uint8List || val is Uint8Buffer) {
    return _hashBytes(Uint8List.fromList(val));
  }
  if (val is BigInt) {
    return _hashUint64(val);
  }
  if (val is num) {
    return _hashUint64(BigInt.from(val));
  }
  if (val is List) {
    return _hashList(val);
  }
  if (val is Map) {
    return hashOfMap(val);
  }
  throw UnsupportedError('hashValue($val) is not supported.');
}

Uint8List _hashString(String value) {
  return sha256Chunks([value.plainToU8a().buffer]);
}

Uint8List _hashBytes(Uint8List value) {
  return sha256Chunks([value.buffer]);
}

Uint8List _hashUint64(BigInt n) {
  final buf = Uint8List(10);
  int i = 0;
  while (true) {
    final byte = n & BigInt.from(0x7f);
    n >>= BigInt.from(7).toInt();
    if (n == BigInt.zero) {
      buf[i] = byte.toInt();
      break;
    } else {
      buf[i] = byte.toInt() | 0x80;
      ++i;
    }
  }
  return _hashBytes(buf.sublist(0, i + 1));
}

Uint8List _hashList(List elements) {
  return sha256Chunks(elements.map(_hashValue).toList());
}

/// Given an account address with a prepended big-endian CRC32 checksum, verify
/// the checksum and remove it.
Uint8List crc32Del(Uint8List buf) {
  final res = buf.sublist(4);
  assert(getCrc32(res.buffer) == buf.buffer.asByteData().getUint32(0));
  return res;
}

/// Prepend a big-endian CRC32 checksum.
Uint8List crc32Add(Uint8List buf) {
  final view = ByteData(4);
  view.setUint32(0, getCrc32(buf.buffer));
  final checksum = view.buffer.asUint8List();
  final bytes = Uint8List.fromList(buf);
  return Uint8List.fromList([...checksum, ...bytes]);
}
