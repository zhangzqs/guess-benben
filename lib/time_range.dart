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
  String formattedDate = DateFormat('HH:mm').format(utcPlus8);
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

enum TimePosition { Before, Within, After }

TimePosition checkTimePosition(String t, (String, String) range) {
// 辅助函数：将 "HH:mm" 转换为分钟数
  int timeToMinutes(String time) {
    List<String> parts = time.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  // 将时间字符串转换为分钟数
  int timeMinutes = timeToMinutes(t);
  int startMinutes = timeToMinutes(range.$1);
  int endMinutes = timeToMinutes(range.$2);

  // 判断时间位置
  if (timeMinutes < startMinutes) {
    return TimePosition.Before;
  } else if (timeMinutes >= startMinutes && timeMinutes < endMinutes) {
    return TimePosition.Within;
  } else {
    return TimePosition.After;
  }
}
