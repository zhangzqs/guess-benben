import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:guess_benben/dialog.dart';
import 'package:guess_benben/hex.dart';
import 'package:guess_benben/kv_storage.dart';
import 'package:guess_benben/time_range.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '猜本本',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: '猜本本',
      ),
      builder: EasyLoading.init(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

Map<String, dynamic>? s3CfgCache = null;

Future<KvStorage> getS3Database() async {
  const configFileUrl = "http://sq4vzrgad.hd-bkt.clouddn.com/config-v1.json";
  if (s3CfgCache == null) {
    final cfgResp = await Dio().get<Map<String, dynamic>>(configFileUrl);
    s3CfgCache = cfgResp.data!;
  }
  final cfg = s3CfgCache!;

  final db = S3KvStorage(
    bucket: cfg["bucket"],
    region: cfg["region"],
    endPoint: cfg["endPoint"],
    accessKey: cfg["accessKey"],
    secretKey: cfg["secretKey"],
    sessionToken: cfg["sessionToken"],
  );
  return db;
}

class _MyHomePageState extends State<MyHomePage> {
  final totalTimeRange = getTimeRange();
  late final hitsMap = HashMap<(String, String), List<String>>.fromEntries(
    totalTimeRange.map((x) => MapEntry(x, [])),
  );
  bool loaded = false;
  late final KvStorage db;
  late final betTable = NamespaceStorage(
    db,
    namespace: "bet/${todayDate()}/",
  );

  String genTitle((String, String) x) {
    return "[${x.$1},${x.$2})";
  }

  (String, String) parseTitle(String x) {
    // 去掉开头和结尾的字符
    String trimmed = x.substring(1, x.length - 1);

    // 按逗号分割
    List<String> parts = trimmed.split(',');

    // 返回解析后的元组
    return (parts[0], parts[1]);
  }

  @override
  void initState() {
    super.initState();
    () async {
      db = await getS3Database();
      await refresh();
      loaded = true;
    }();
    Timer.periodic(Duration(seconds: 10), (t) => refresh());
  }

  Future<void> refresh() async {
    if (!mounted) return;

    final keys = await betTable.list();
    final values = await Future.wait(
        keys.map((k) => betTable.getText(k).then((x) => x ?? "[]")));
    for (var i = 0; i < keys.length; i++) {
      final key = String.fromCharCodes(HexUtils.decode(keys[i]));
      hitsMap[parseTitle(key)] = (jsonDecode(values[i]) as List<dynamic>)
          .map((x) => x as String)
          .toList();
    }
    // debugPrint(hitsMap.toString());
    setState(() {});
  }

  Future<String> _showInputDialog() async {
    final ret = await showDialog<String>(
      context: context,
      builder: (context) {
        return InputDialog(
          title: '请输入您的昵称',
          hintText: '昵称',
          confirmText: '押注',
          cancelText: '取消',
        );
      },
    );
    return ret ?? "";
  }

  Future<void> _showHitsPeople((String, String) x) async {
    await showDialog(
      context: context,
      builder: (context) {
        return ListViewDialog(
          items: hitsMap[x]!,
          title: "押注人员",
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Text("正在加载..."),
            ],
          ),
        ),
      );
    }
    final ordered = totalTimeRange.toList();
    ordered.sort((a, b) {
      return (hitsMap[b]?.length ?? 0).compareTo(hitsMap[a]?.length ?? 0);
    });
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset("assets/favicon.png"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: "猜本本",
                applicationVersion: "1.0.0",
                applicationIcon: Image.asset("assets/favicon.png"),
                children: [
                  Text("一个猜本本老师什么时候起床的押注程序"),
                ],
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: ordered.map((x) {
          final title = genTitle(x);
          final b64Title = HexUtils.encode(title.codeUnits);
          final range = parseTitle(title);
          final now = currentTime();
          final currentPos = checkTimePosition(now, range);
          return Column(
            children: [
              ListTile(
                title: Row(children: [
                  Text(title),
                  SizedBox(
                    width: 30,
                  ),
                  () {
                    switch (currentPos) {
                      case TimePosition.Before:
                        return Text(
                          "即将揭晓",
                          style: TextStyle(color: Colors.green),
                        );
                      case TimePosition.Within:
                        return Text(
                          "当前时间",
                          style: TextStyle(color: Colors.blue),
                        );
                      case TimePosition.After:
                        return Text(
                          "已过期",
                          style: TextStyle(color: Colors.red),
                        );
                    }
                  }(),
                ]),
                subtitle: Row(
                  children: [
                    Text("当前押注人数: ${hitsMap[x]!.length}"),
                    if (hitsMap[x]!.length > 0)
                      TextButton(
                        onPressed: () {
                          debugPrint(hitsMap[x].toString());
                          _showHitsPeople(x);
                        },
                        child: Text("点击查看"),
                      ),
                  ],
                ),
                trailing: currentPos == TimePosition.After
                    ? null
                    : ElevatedButton(
                        onPressed: () async {
                          final name = await _showInputDialog();
                          if (name == "") {
                            EasyLoading.showError("昵称输入有误");
                            return;
                          }

                          final clickStr = await betTable.getText(b64Title);
                          final clickPeople =
                              (jsonDecode(clickStr ?? "[]") as List<dynamic>)
                                  .map((x) => x as String)
                                  .toList();

                          clickPeople
                              .add("押注时间: ${currentTime()}  押注人员: ${name}");
                          debugPrint(jsonEncode(clickPeople));
                          await betTable.setText(
                              b64Title, jsonEncode(clickPeople));

                          EasyLoading.show(
                            status: '正在押注...',
                            maskType: EasyLoadingMaskType.black,
                          );
                          await Future.delayed(Duration(milliseconds: 300));
                          for (var i = 1; i <= 10; i++) {
                            // 检查云端是否刷新成功
                            if (await betTable.getText(b64Title) != clickStr) {
                              // 只要数据发生变更，认为成功
                              await refresh();
                              EasyLoading.dismiss();
                              EasyLoading.showToast(
                                '押注成功',
                                toastPosition: EasyLoadingToastPosition.bottom,
                              );
                              return;
                            }
                            EasyLoading.show(
                              status: '正在押注(当前尝试$i/10次)...',
                              maskType: EasyLoadingMaskType.black,
                            );
                            await Future.delayed(Duration(seconds: 1));
                          }
                          await refresh();
                          EasyLoading.dismiss();
                          EasyLoading.showToast(
                            '押注失败, 请重试',
                            toastPosition: EasyLoadingToastPosition.bottom,
                          );
                        },
                        child: Text("点击押注"),
                      ),
              ),
              Divider(
                // 手动添加 Divider
                color: Colors.grey,
                height: 1,
              )
            ],
          );
        }).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // 当前选中的索引
        onTap: (value) {
          if (value == 1) {
            EasyLoading.showToast("暂不支持, 敬请期待");
          }
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Text("🎲"),
            label: '押注',
          ),
          BottomNavigationBarItem(
            icon: Text("📖"),
            label: '押注历史',
          ),
        ],
      ),
    );
  }
}
