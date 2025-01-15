import 'package:flutter/material.dart';

class InputDialog extends StatefulWidget {
  final String title; // 弹框标题
  final String hintText; // 输入框提示文本
  final String confirmText; // 确认按钮文本
  final String cancelText; // 取消按钮文本
  final ValueChanged<String>? onSubmitted; // 输入内容提交回调
  final TextInputType keyboardType; // 输入类型

  const InputDialog({
    Key? key,
    required this.title,
    this.hintText = '',
    this.confirmText = '确认',
    this.cancelText = '取消',
    this.onSubmitted,
    this.keyboardType = TextInputType.text,
  }) : super(key: key);

  @override
  State<InputDialog> createState() => _InputDialogState();
}

class _InputDialogState extends State<InputDialog> {
  String inputString = "";
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title), // 弹框标题
      content: TextField(
        decoration: InputDecoration(
          hintText: widget.hintText, // 提示文本
          border: OutlineInputBorder(), // 边框样式
        ),
        keyboardType: widget.keyboardType, // 输入类型
        onChanged: (s) {
          inputString = s;
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // 关闭弹框
          },
          child: Text(widget.cancelText), // 取消按钮
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(inputString); // 关闭弹框
          },
          child: Text(widget.confirmText), // 确认按钮
        ),
      ],
    );
  }
}

class ListViewDialog extends StatelessWidget {
  final List<String> items; // 需要展示的数据列表
  final String title; // 弹框标题

  const ListViewDialog({
    Key? key,
    required this.items,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title), // 弹框标题
      content: Container(
        width: double.maxFinite, // 设置宽度为最大
        child: ListView.builder(
          shrinkWrap: true, // 根据内容调整高度
          itemCount: items.length, // 列表项数量
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(items[index]), // 显示每一项的内容
              onTap: () {
                Navigator.of(context).pop(items[index]); // 返回选中的项
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // 关闭弹框
          },
          child: Text('关闭'),
        ),
      ],
    );
  }
}
