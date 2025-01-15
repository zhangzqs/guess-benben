import 'package:intl/intl.dart'; // 用于时间格式化

String todayDate() {
  DateTime now = DateTime.now();
  DateTime utcPlus8 = now.toUtc().add(Duration(hours: 8));
  String formattedDate = DateFormat('yyyy-MM-dd').format(utcPlus8);
  return formattedDate;
}

String currentTime() {
  DateTime now = DateTime.now();
  DateTime utcPlus8 = now.toUtc().add(Duration(hours: 8));
  String formattedDate = DateFormat('HH:mm:ss').format(utcPlus8);
  return formattedDate;
}

List<(String, String)> getTimeRange() {
  DateTime startTime = DateTime(2023, 1, 1, 8, 0);
  DateTime endTime = DateTime(2023, 1, 1, 16, 0); // 18:00
  Duration step = Duration(minutes: 10);
  DateTime currentTime = startTime;

  final ret = List<(String, String)>.empty(growable: true);
  while (
      currentTime.isBefore(endTime) || currentTime.isAtSameMomentAs(endTime)) {
    String beginTime = DateFormat('HH:mm').format(currentTime);
    currentTime = currentTime.add(step);
    String endTime = DateFormat('HH:mm').format(currentTime);
    ret.add((beginTime, endTime));
  }
  return ret;
}
