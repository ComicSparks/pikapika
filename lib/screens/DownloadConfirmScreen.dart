import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/entity_convert.dart';
import 'package:pikapika/screens/components/ContentLoading.dart';
import 'package:pikapika/basic/Method.dart';

import 'components/ComicInfoCard.dart';
import 'components/ListView.dart';
import 'components/RightClickPop.dart';

// 确认下载
class DownloadConfirmScreen extends StatefulWidget {
  final ComicInfo comicInfo;
  final List<Ep> epList;

  const DownloadConfirmScreen({
    Key? key,
    required this.comicInfo,
    required this.epList,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DownloadConfirmScreenState();
}

class _DownloadConfirmScreenState extends State<DownloadConfirmScreen> {
  DownloadComic? _task; // 之前的下载任务
  final List<int> _taskedEps = []; // 已经下载的EP
  final List<int> _selectedEps = []; // 选中的EP
  late Future f = _load();

  Future<dynamic> _load() async {
    _taskedEps.clear();
    _task = await method.loadDownloadComic(widget.comicInfo.id);
    if (_task != null) {
      var epList = await method.downloadEpList(widget.comicInfo.id);
      _taskedEps.addAll(epList.map((e) => e.epOrder));
    }
  }

  void _selectAll() {
    setState(() {
      _selectedEps.clear();
      for (var element in widget.epList) {
        if (!_taskedEps.contains(element.order)) {
          _selectedEps.add(element.order);
        }
      }
    });
  }

  Future<dynamic> _download() async {
    // 必须选中才能下载
    if (_selectedEps.isEmpty) {
      defaultToast(context, tr('screen.download_confirm.please_select_ep'));
      return;
    }
    final episodes = widget.epList
        .where((element) => _selectedEps.contains(element.order))
        .toList();
    try {
      if (_task != null) {
        await method.addDownload(widget.comicInfo, episodes);
      } else {
        await method.createDownload(widget.comicInfo, episodes);
      }
      // 退出
      defaultToast(context, tr('screen.download_confirm.already_added_to_download_list'));
      Navigator.pop(context);
    } catch (e, s) {
      defaultToast(context, e.toString());
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
        title: Text("下载 - ${widget.comicInfo.title}"),
      ),
      body: FutureBuilder(
        future: f,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasError) {
            print(snapshot.error);
            print(snapshot.stackTrace);
            return const Text('error');
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return ContentLoading(label: tr('app.loading'));
          }
          return PikaListView(
            children: [
              ComicInfoCard(
                comicSimpleFromInfo(widget.comicInfo),
                viewsCount: widget.comicInfo.viewsCount,
                liked: widget.comicInfo.isLiked,
                favourite: widget.comicInfo.isFavourite,
              ),
              _buildButtons(),
              Wrap(
                alignment: WrapAlignment.spaceAround,
                runSpacing: 10,
                spacing: 10,
                children: [
                  ...widget.epList.map((e) {
                    return Container(
                      padding: const EdgeInsets.all(5),
                      child: MaterialButton(
                        onPressed: () {
                          _clickOfEp(e);
                        },
                        color: _colorOfEp(e),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _iconOfEp(e),
                            Container(
                              width: 10,
                            ),
                            Text(e.title,
                                style: const TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildButtons() {
    var theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.spaceAround,
        children: [
          MaterialButton(
            color: theme.colorScheme.secondary,
            textColor: Colors.white,
            onPressed: _selectAll,
            child: Text(tr('app.select_all')),
          ),
          MaterialButton(
            color: theme.colorScheme.secondary,
            textColor: Colors.white,
            onPressed: _download,
            child: Text(tr('app.confirm_download')),
          ),
        ],
      ),
    );
  }

  Color _colorOfEp(Ep e) {
    if (_taskedEps.contains(e.order)) {
      return Colors.grey.shade300;
    }
    if (_selectedEps.contains(e.order)) {
      return Colors.blueGrey.shade300;
    }
    return Colors.grey.shade200;
  }

  Icon _iconOfEp(Ep e) {
    if (_taskedEps.contains(e.order)) {
      return const Icon(Icons.download_rounded, color: Colors.black);
    }
    if (_selectedEps.contains(e.order)) {
      return const Icon(Icons.check_box, color: Colors.black);
    }
    return const Icon(Icons.check_box_outline_blank, color: Colors.black);
  }

  void _clickOfEp(Ep e) {
    if (_taskedEps.contains(e.order)) {
      return;
    }
    if (_selectedEps.contains(e.order)) {
      setState(() {
        _selectedEps.remove(e.order);
      });
    } else {
      setState(() {
        _selectedEps.add(e.order);
      });
    }
  }
}
