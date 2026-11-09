import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/components/ContentBuilder.dart';
import 'package:pikapika/screens/components/ContentLoading.dart';

import 'components/ListView.dart';
import 'components/RightClickPop.dart';

// 数据迁移页面
class MigrateScreen extends StatefulWidget {
  const MigrateScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MigrateScreenState();
}

class _MigrateScreenState extends State<MigrateScreen> {
  late final Key _key = UniqueKey();
  late final Future _future = _load();
  late String _current;
  late List<String> paths;
  String _message = "";

  int _migrate = 0; // 0 没有开始迁移，1 正在迁移，2 迁移成功，3 迁移失败

  Future _load() async {
    await method.setDownloadRunning(false);
    _current = await method.dataLocal();
    if (Platform.isAndroid) {
      paths = await method.androidGetExtendDirs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return rightClickPop(
      child: buildScreen(context),
      context: context,
      canPop: true,
    );
  }

  Widget buildScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据迁移'),
      ),
      body: ContentBuilder(
        key: _key,
        future: _future,
        onRefresh: () async {},
        successBuilder:
            (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          switch (_migrate) {
            case 0:
              return PikaListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: const Text(
                      "1. 为了手机数据存储空间不足, 且具有内存卡的安卓手机设计, 可将数据迁移到内存卡上。\n\n"
                      "2. 您在迁移之前, 请确保您的下载处于暂停状态, 或下载均已完成, 以保证您的数据完整性。\n\n"
                      "3. 如果迁移中断, 迁移失败, 或其他原因导致程序无法启动, 图片失效等问题, 您可在程序管理中清除本应用程序的数据, 以回复正常使用。\n\n"
                      "4. 如果您将数据迁移后将内存卡取出, 将会使用默认本地存储, 再次插入同一张内存卡会继续使用该储存卡, 不支持更换内存卡, 途中您若再次迁移会发生数据覆盖, 这必然会丢失一部分数据.\n\n"
                      "5. 您不能更改, 删除, 移动这些数据, 否则程序可能不能正常执行\n\n"
                      "6. 迁移成功之前一定不要退出应用程序, 也不要按返回键\n\n"
                      "7. 如果您已经了解此功能, 悉知文件迁移的风险, 可以在下面的按钮中选择一项执行\n\n",
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Text("当前文件储存路径 : $_current"),
                  ),
                  ...paths.map((e) => Container(
                        padding: const EdgeInsets.all(10),
                        child: MaterialButton(
                          color: Theme.of(context).colorScheme.secondary,
                          textColor:
                              Theme.of(context).textTheme.bodyLarge?.color,
                          padding: const EdgeInsets.all(10),
                          onPressed: () async {
                            if (!await confirmDialog(context, "文件迁移",
                                "您将要迁移到$e, 迁移过程中一定《 不 要 关 闭 程 序 》")) {
                              return;
                            }
                            setState(() {
                              _migrate = 1;
                            });
                            try {
                              await method.migrate(e);
                              setState(() {
                                _migrate = 2;
                              });
                            } catch (ex, tr) {
                              _message = "$ex\n$tr\n";
                              setState(() {
                                _migrate = 3;
                              });
                            }
                          },
                          child: Text("迁移到 $e"),
                        ),
                      )),
                ],
              );
            case 1:
              return const ContentLoading(label: "迁移中");
            case 2:
              return const Center(child: Text("迁移成功 您需要关闭应用程序重新启动"));
            case 3:
              return Center(child: Text("迁移失败\n$_message"));
            default:
              throw "";
          }
        },
      ),
    );
  }
}
