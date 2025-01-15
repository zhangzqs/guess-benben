import 'dart:convert';
import 'dart:typed_data';
import 'package:minio/minio.dart';

abstract class KvStorage {
  Future<Uint8List?> getBytes(String key);
  Future<void> setBytes(String key, Uint8List? value);
  Future<List<String>> list({String prefix = ""});

  Future<String?> getText(String key) async {
    final v = await getBytes(key);
    if (v == null) {
      return null;
    }
    return utf8.decode(v);
  }

  Future<void> setText(String key, String? value) async {
    if (value == null) {
      setBytes(key, null);
    }

    setBytes(key, utf8.encode(value!));
  }
}

class S3KvStorage extends KvStorage {
  final Minio _s3;
  final String _bucket;
  S3KvStorage({
    required String endPoint,
    required String accessKey,
    required String secretKey,
    required String bucket,
    String namespace = "",
    String? sessionToken,
    int? port,
    bool useSSL = true,
    String? region,
    bool pathStyle = true,
  })  : _bucket = bucket,
        _s3 = Minio(
          endPoint: endPoint,
          accessKey: accessKey,
          secretKey: secretKey,
          sessionToken: sessionToken,
          port: port,
          useSSL: useSSL,
          region: region,
          pathStyle: pathStyle,
        );

  @override
  Future<Uint8List?> getBytes(String key) async {
    try {
      final resp = await _s3.getObject(_bucket, key);
      final bytes = await resp.fold<List<int>>(
        [],
        (accumulated, chunk) => accumulated..addAll(chunk),
      );
      return Uint8List.fromList(bytes);
    } on MinioError catch (e) {
      if (e.message == "The specified key does not exist") {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> setBytes(String key, Uint8List? value) async {
    if (value == null) {
      await _s3.removeObject(
        _bucket,
        key,
      );
    } else {
      await _s3.putObject(
        _bucket,
        key,
        Stream<Uint8List>.value(value),
      );
    }
  }

  @override
  Future<List<String>> list({String prefix = ""}) async {
    final resp = await _s3.listAllObjectsV2(
      _bucket,
      prefix: prefix,
    );
    return resp.objects.map((x) => x.key!).toList();
  }
}

class NamespaceStorage extends KvStorage {
  final KvStorage _inner;
  final String namespace;
  NamespaceStorage(this._inner, {required this.namespace});

  @override
  Future<Uint8List?> getBytes(String key) {
    return _inner.getBytes(namespace + key);
  }

  @override
  Future<List<String>> list({String prefix = ""}) {
    return _inner.list(prefix: namespace + prefix).then(
          (x) => x.map((e) => e.replaceFirst(namespace, '')).toList(),
        );
  }

  @override
  Future<void> setBytes(String key, Uint8List? value) {
    return _inner.setBytes(namespace + key, value);
  }
}
