import 'dart:typed_data';

class HexUtils {
  /// 将字节数组编码为 Hex 字符串
  static String encode(Iterable<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  /// 将 Hex 字符串解码为字节数组
  static Uint8List decode(String hexString) {
    // 确保 Hex 字符串长度为偶数
    if (hexString.length % 2 != 0) {
      throw FormatException('Hex 字符串长度必须为偶数');
    }

    // 解析 Hex 字符串为字节数组
    return Uint8List.fromList(List.generate(hexString.length ~/ 2,
        (i) => int.parse(hexString.substring(i * 2, i * 2 + 2), radix: 16)));
  }
}
