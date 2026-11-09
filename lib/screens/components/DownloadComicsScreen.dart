import 'package:flutter/material.dart';

import '../../basic/Channels.dart';
import '../../basic/Common.dart';
import '../../basic/Method.dart';
import 'ContentLoading.dart';

class DownloadComicsScreen extends StatefulWidget {
  final List<String> comicIds;

  const DownloadComicsScreen(this.comicIds, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DownloadComicsScreenState();
}

class _DownloadComicsScreenState extends State<DownloadComicsScreen> {
  bool exporting = false;
  bool exported = false;
  bool exportFail = false;
  dynamic e;
  String exportMessage = "正在创建下载任务";

  @override
  void initState() {
    registerEvent(_onMessageChange, "EXPORT");
    super.initState();
  }

  @override
  void dispose() {
    unregisterEvent(_onMessageChange);
    super.dispose();
  }

  void _onMessageChange(AppEvent event) {
    if (event case AppEvent_Export(:final message)) {
      setState(() {
        exportMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("批量下载"),
        ),
        body: _body(),
      ),
      onWillPop: () async {
        if (exporting) {
          defaultToast(context, "创建下载任务中, 请稍后");
          return false;
        }
        return true;
      },
    );
  }

  Widget _body() {
    if (exporting) {
      return ContentLoading(label: exportMessage);
    }
    if (exportFail) {
      return Center(child: Text("失败\n$e"));
    }
    if (exported) {
      return const Center(child: Text("成功"));
    }
    return ListView(
      children: [
        Container(height: 20),
        Container(height: 20),
        _buildButtonInner("您即将下载${widget.comicIds.length}部漫画, 如果漫画已经存在, 则补充新增加的章节"),
        Container(height: 20),
        Container(height: 20),
        MaterialButton(
          onPressed: _create,
          child: _buildButtonInner("确认"),
        ),
        Container(height: 20),
        Container(height: 20),
        Container(height: 20),
      ],
    );
  }

  _create() async {
    var name = "";
    try {
      setState(() {
        exporting = true;
      });
      await method.downloadAll(
        widget.comicIds,
      );
      exported = true;
    } catch (err) {
      e = err;
      exportFail = true;
    } finally {
      setState(() {
        exporting = false;
      });
    }
  }

  Widget _buildButtonInner(String text) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Container(
          width: constraints.maxWidth,
          padding: const EdgeInsets.all(15),
          color: (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black)
              .withOpacity(.05),
          child: Text(
            text,
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
