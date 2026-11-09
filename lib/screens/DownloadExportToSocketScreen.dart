import 'dart:async';

import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Channels.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';

import 'components/ContentError.dart';
import 'components/ContentLoading.dart';
import 'components/DownloadInfoCard.dart';
import 'components/ListView.dart';
import 'components/RightClickPop.dart';

// 传输到其他设备
class DownloadExportToSocketScreen extends StatefulWidget {
  final DownloadComic task;
  final String comicId;
  final String comicTitle;

  const DownloadExportToSocketScreen({
    required this.task,
    required this.comicId,
    required this.comicTitle,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DownloadExportToSocketScreenState();
}

class _DownloadExportToSocketScreenState
    extends State<DownloadExportToSocketScreen> {
  late Future<int> _future = method.exportComicUsingSocket(widget.comicId);
  late final Future<String> _ipFuture = method.clientIpSet();

  late String exportMessage = "";

  @override
  void initState() {
    registerEvent(_onMessageChange, "EXPORT");
    super.initState();
  }

  @override
  void dispose() {
    method.exportComicUsingSocketExit();
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
  Widget build(BuildContext context){
    return rightClickPop(
      child: buildScreen(context),
      context: context,
      canPop: true,
    );
  }

  Widget buildScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("screen.download_export_to_socket.title") + " - " + widget.comicTitle),
      ),
      body: FutureBuilder(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          if (snapshot.hasError) {
            return ContentError(
                error: snapshot.error,
                stackTrace: snapshot.stackTrace,
                onRefresh: () async {
                  setState(() {
                    _future = method.exportComicUsingSocket(widget.comicId);
                  });
                });
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return ContentLoading(label: tr("screen.download_export_to_socket.loading"));
          }
          return PikaListView(
            children: [
              DownloadInfoCard(task: widget.task),
              Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                     Text(
                        tr("screen.download_export_to_socket.tips")),
                    FutureBuilder(
                      future: _ipFuture,
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        if (snapshot.hasError) {
                          return Text(tr("screen.download_export_to_socket.get_ip_failed"));
                        }
                        if (snapshot.connectionState != ConnectionState.done) {
                          return Text(tr("screen.download_export_to_socket.getting_ip"));
                        }
                        return Text('${snapshot.data}');
                      },
                    ),
                    Text(tr("screen.download_export_to_socket.port") + ':${snapshot.data}'),
                    Text(exportMessage),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
