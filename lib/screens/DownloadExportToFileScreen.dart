import 'dart:async';
import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Channels.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/basic/config/ExportRename.dart';
import 'package:pikapika/screens/DownloadExportToSocketScreen.dart';
import '../basic/config/ExportPath.dart';
import '../basic/config/IconLoading.dart';
import '../basic/config/IsPro.dart';
import 'components/ContentError.dart';
import 'components/ContentLoading.dart';
import 'components/DownloadInfoCard.dart';
import 'components/ListView.dart';
import 'components/RightClickPop.dart';

// 导出
class DownloadExportToFileScreen extends StatefulWidget {
  final String comicId;
  final String comicTitle;

  const DownloadExportToFileScreen({
    required this.comicId,
    required this.comicTitle,
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _DownloadExportToFileScreenState();
}

class _DownloadExportToFileScreenState
    extends State<DownloadExportToFileScreen> {
  late DownloadComic _task;
  late Future _future = _load();
  late bool exporting = false;
  late String exportMessage = tr("screen.download_export_group.exporting");
  late String exportResult = "";

  Future _load() async {
    _task = (await method.loadDownloadComic(widget.comicId))!;
  }

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
    return rightClickPop(
      child: buildScreen(context),
      context: context,
      canPop: !exporting,
    );
  }

  Widget buildScreen(BuildContext context) {
    if (exporting) {
      return Scaffold(
        body: ContentLoading(label: exportMessage),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("screen.download_export_to_file.title") + " - " + widget.comicTitle),
      ),
      body: FutureBuilder(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasError) {
            return ContentError(
                error: snapshot.error,
                stackTrace: snapshot.stackTrace,
                onRefresh: () async {
                  setState(() {
                    _future = _load();
                  });
                });
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return ContentLoading(label: tr("app.loading"));
          }
          return PikaListView(
            children: [
              DownloadInfoCard(task: _task),
              Container(
                padding: const EdgeInsets.all(8),
                child: exportResult != "" ? Text(exportResult) : Container(),
              ),
              displayExportPathInfo(),
              Container(height: 15),
              _exportPkzButton(),
              Container(height: 10),
              _exportPkiButton(),
              Container(height: 10),
              _exportHtmlZipButton(),
              Container(height: 10),
              _exportToHtmlJPEGButton(),
              Container(height: 10),
              _exportToHtmlPdfButton(),
              Container(height: 10),
              _exportToHtmlPdfFolderButton(),
              Container(height: 10),
              _exportToHtmlEpubButton(),
              Container(height: 10),
              _exportToJPEGSZIPButton(),
              Container(height: 10),
              _exportToHtmlJPEGNotDownOverButton(),
              Container(height: 10),
              _exportComicDownloadToCbzsZipButton(),
              Container(height: 10),
              MaterialButton(
                onPressed: () async {
                  Navigator.of(context).push(
                    mixRoute(
                      builder: (context) => DownloadExportToSocketScreen(
                        task: _task,
                        comicId: widget.comicId,
                        comicTitle: widget.comicTitle,
                      ),
                    ),
                  );
                },
                child: _buildButtonInner(tr("screen.download_export_to_file.transfer_to_other_device")),
              ),
              Container(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _exportPkzButton() {
    return MaterialButton(
      onPressed: () async {
        var name = "";
        if (currentExportRename()) {
          var rename = await inputString(
            context,
            tr("screen.download_export_to_file.input_save_name"),
            defaultValue: _task.title,
          );
          if (rename != null && rename.isNotEmpty) {
            name = rename;
          } else {
            return;
          }
        } else {
          if (!await confirmDialog(
              context, 
              tr('screen.download_export_to_file.export_confirm'),
              tr('screen.download_export_to_file.export_to_pkz_title') + showExportPath(),
          )) {
            return;
          }
        }
        try {
          setState(() {
            exporting = true;
          });
          await method.exportComicDownloadToPkz(
            [widget.comicId],
            await attachExportPath(),
            name,
          );
          setState(() {
            exportResult = tr("screen.download_export_group.export_success");
          });
        } catch (e) {
          setState(() {
            exportResult = tr("screen.download_export_group.export_failed") + " $e";
          });
        } finally {
          setState(() {
            exporting = false;
          });
        }
      },
      child: _buildButtonInner(
        tr("screen.download_export_group.export_to_pkz_title") + showExportPath(),
      ),
    );
  }

  Widget _exportPkiButton() {
    return MaterialButton(
      onPressed: () async {
        var name = "";
        if (currentExportRename()) {
          var rename = await inputString(
            context,
            tr("screen.download_export_to_file.input_save_name"),
            defaultValue: _task.title,
          );
          if (rename != null && rename.isNotEmpty) {
            name = rename;
          } else {
            return;
          }
        } else {
          if (!await confirmDialog(
              context,
              tr('screen.download_export_to_file.export_confirm'),
              tr('screen.download_export_to_file.export_to_pki_title') + showExportPath(),
          )) {
            return;
          }
        }
        try {
          setState(() {
            exporting = true;
          });
          await method.exportComicDownloadToPki(
            widget.comicId,
            await attachExportPath(),
            name,
          );
          setState(() {
            exportResult = tr("screen.download_export_group.export_success");
          });
        } catch (e) {
          setState(() {
            exportResult = tr("screen.download_export_group.export_failed") + " $e";
          });
        } finally {
          setState(() {
            exporting = false;
          });
        }
      },
      child: _buildButtonInner(
        tr("screen.download_export_group.export_to_pki_title") + showExportPath(),
      ),
    );
  }

  Widget _exportHtmlZipButton() {
    return MaterialButton(
      onPressed: () async {
        if (!isPro) {
          defaultToast(context, tr("screen.download_export_group.please_power_up"));
          return;
        }
        var name = "";
        if (currentExportRename()) {
          var rename = await inputString(
            context,
            tr("screen.download_export_to_file.input_save_name"),
            defaultValue: _task.title,
          );
          if (rename != null && rename.isNotEmpty) {
            name = rename;
          } else {
            return;
          }
        } else {
          if (!await confirmDialog(
              context,
              tr('screen.download_export_to_file.export_confirm'),
              tr('screen.download_export_to_file.export_to_zip_title') + showExportPath(),
          )) {
            return;
          }
        }
        try {
          setState(() {
            exporting = true;
          });
          await method.exportComicDownload(
            widget.comicId,
            await attachExportPath(),
            name,
          );
          setState(() {
            exportResult = tr("screen.download_export_group.export_success");
          });
        } catch (e) {
          setState(() {
            exportResult = tr("screen.download_export_group.export_failed") + " $e";
          });
        } finally {
          setState(() {
            exporting = false;
          });
        }
      },
      child: _buildButtonInner(
        tr("screen.download_export_to_file.export_to_zip_desc") + showExportPath(),
      ),
    );
  }

  Widget _exportToHtmlJPEGButton() {
    return MaterialButton(
      onPressed: () async {
        if (!isPro) {
          defaultToast(context, tr("screen.download_export_group.please_power_up"));
          return;
        }
        var name = "";
        if (currentExportRename()) {
          var rename = await inputString(
            context,
            tr("screen.download_export_to_file.input_save_name"),
            defaultValue: _task.title,
          );
          if (rename != null && rename.isNotEmpty) {
            name = rename;
          } else {
            return;
          }
        } else {
          if (!await confirmDialog(
              context,
              tr('screen.download_export_to_file.export_confirm'),
              tr('screen.download_export_to_file.export_to_jpeg_zip_title') + showExportPath(),
          )) {
            return;
          }
        }
        try {
          setState(() {
            exporting = true;
          });
          await method.exportComicDownloadToJPG(
            widget.comicId,
            await attachExportPath(),
            name,
          );
          setState(() {
            exportResult = tr("screen.download_export_group.export_success");
          });
        } catch (e) {
          setState(() {
            exportResult = tr("screen.download_export_group.export_failed") + " $e";
          });
        } finally {
          setState(() {
            exporting = false;
          });
        }
      },
      child: _buildButtonInner(tr("screen.download_export_group.export_to_jpeg_zip_title") + showExportPath()),
    );
  }

  Widget _exportToHtmlPdfButton() {
    return MaterialButton(
      onPressed: () async {
        if (!isPro) {
          defaultToast(context, tr("screen.download_export_group.please_power_up"));
          return;
        }
        var name = "";
        if (currentExportRename()) {
          var rename = await inputString(
            context,
            tr("screen.download_export_to_file.input_save_name"),
            defaultValue: _task.title,
          );
          if (rename != null && rename.isNotEmpty) {
            name = rename;
          } else {
            return;
          }
        } else {
          if (!await confirmDialog(
              context,
              tr('screen.download_export_to_file.export_confirm'),
              tr('screen.download_export_to_file.export_to_pdf_title') + showExportPath(),
          )) {
            return;
          }
        }
        try {
          setState(() {
            exporting = true;
          });
          await method.exportComicDownloadToPDF(
            widget.comicId,
            await attachExportPath(),
            name,
          );
          setState(() {
            exportResult = tr("screen.download_export_group.export_success");
          });
        } catch (e) {
          setState(() {
            exportResult = tr("screen.download_export_group.export_failed") + " $e";
          });
        } finally {
          setState(() {
            exporting = false;
          });
        }
      },
      child: _buildButtonInner(tr("screen.download_export_group.export_to_pdf_title") + showExportPath()),
    );
  }

  Widget _exportToHtmlEpubButton() {
    return MaterialButton(
      onPressed: () async {
        if (!isPro) {
          defaultToast(context, tr("screen.download_export_group.please_power_up"));
          return;
        }
        var name = "";
        if (currentExportRename()) {
          var rename = await inputString(
            context,
            tr("screen.download_export_to_file.input_save_name"),
            defaultValue: _task.title,
          );
          if (rename != null && rename.isNotEmpty) {
            name = rename;
          } else {
            return;
          }
        } else {
          if (!await confirmDialog(
              context,
              tr('screen.download_export_to_file.export_confirm'),
              tr('screen.download_export_to_file.export_to_epub_title') + showExportPath(),
          )) {
            return;
          }
        }
        try {
          setState(() {
            exporting = true;
          });
          await method.exportComicDownloadToEpub(
            widget.comicId,
            await attachExportPath(),
            name,
          );
          setState(() {
            exportResult = tr("screen.download_export_group.export_success");
          });
        } catch (e) {
          setState(() {
            exportResult = tr("screen.download_export_group.export_failed") + " $e";
          });
        } finally {
          setState(() {
            exporting = false;
          });
        }
      },
      child: _buildButtonInner(tr("screen.download_export_group.export_to_epub_title") + showExportPath()),
    );
  }

  Widget _exportToHtmlPdfFolderButton() {
    return MaterialButton(
      onPressed: () async {
        if (!isPro) {
          defaultToast(context, tr("screen.download_export_group.please_power_up"));
          return;
        }
        var name = "";
        if (currentExportRename()) {
          var rename = await inputString(
            context,
            tr("screen.download_export_to_file.input_save_name"),
            defaultValue: _task.title,
          );
          if (rename != null && rename.isNotEmpty) {
            name = rename;
          } else {
            return;
          }
        } else {
          if (!await confirmDialog(
              context,
              tr('screen.download_export_to_file.export_confirm'),
              tr('screen.download_export_to_file.export_to_pdf_folder_title') + showExportPath(),
          )) {
            return;
          }
        }
        try {
          setState(() {
            exporting = true;
          });
          await method.exportComicDownloadToPDFFolder(
            widget.comicId,
            await attachExportPath(),
            name,
          );
          setState(() {
            exportResult = tr("screen.download_export_group.export_success");
          });
        } catch (e) {
          setState(() {
            exportResult = tr("screen.download_export_group.export_failed") + " $e";
          });
        } finally {
          setState(() {
            exporting = false;
          });
        }
      },
      child: _buildButtonInner(tr("screen.download_export_group.export_to_pdf_folder_title") + showExportPath()),
    );
  }

  Widget _exportToJPEGSZIPButton() {
    return MaterialButton(
      onPressed: () async {
        if (!isPro) {
          defaultToast(context, tr("screen.download_export_group.please_power_up"));
          return;
        }
        var name = "";
        if (currentExportRename()) {
          var rename = await inputString(
            context,
            tr("screen.download_export_to_file.input_save_name"),
            defaultValue: _task.title,
          );
          if (rename != null && rename.isNotEmpty) {
            name = rename;
          } else {
            return;
          }
        } else {
          if (!await confirmDialog(
              context,
              tr('screen.download_export_to_file.export_confirm'),
              tr('screen.download_export_group.export_to_jpeg_zip_title') + showExportPath(),
          )) {
            return;
          }
        }
        try {
          setState(() {
            exporting = true;
          });
          await method.exportComicDownloadJpegZip(
            widget.comicId,
            await attachExportPath(),
            name,
          );
          setState(() {
            exportResult = tr("screen.download_export_group.export_success");
          });
        } catch (e) {
          setState(() {
            exportResult = tr("screen.download_export_group.export_failed") + " $e";
          });
        } finally {
          setState(() {
            exporting = false;
          });
        }
      },
      child: _buildButtonInner(
        tr("screen.download_export_group.export_to_jpeg_zip_title")+ (!isPro ? "\n(${tr('app.pro')})" : ""),
      ),
    );
  }

  Widget _exportToHtmlJPEGNotDownOverButton() {
    return MaterialButton(
      onPressed: () async {
        if (!isPro) {
          defaultToast(context, tr("screen.download_export_group.please_power_up"));
          return;
        }
        var name = "";
        if (currentExportRename()) {
          var rename = await inputString(
            context,
            tr("screen.download_export_to_file.input_save_name"),
            defaultValue: _task.title,
          );
          if (rename != null && rename.isNotEmpty) {
            name = rename;
          } else {
            return;
          }
        } else {
          if (!await confirmDialog(
              context,
              tr('screen.download_export_to_file.export_confirm'),
              tr('screen.download_export_group.export_to_jpeg_zip_title_not_down_over') + showExportPath(),
          )) {
            return;
          }
        }
        try {
          setState(() {
            exporting = true;
          });
          await method.exportComicJpegsEvenNotFinish(
            widget.comicId,
            await attachExportPath(),
            name,
          );
          setState(() {
            exportResult = tr("screen.download_export_group.export_success");
          });
        } catch (e) {
          setState(() {
            exportResult = tr("screen.download_export_group.export_failed") + " $e";
          });
        } finally {
          setState(() {
            exporting = false;
          });
        }
      },
      child: _buildButtonInner(
        tr("screen.download_export_group.export_to_jpeg_zip_title_not_down_over") + (!isPro ? "\n(${tr('app.pro')})" : ""),
      ),
    );
  }

  Widget _exportComicDownloadToCbzsZipButton() {
    return MaterialButton(
      onPressed: () async {
        if (!isPro) {
          defaultToast(context, tr("screen.download_export_group.please_power_up"));
          return;
        }
        var name = "";
        if (currentExportRename()) {
          var rename = await inputString(
            context,
            tr("screen.download_export_to_file.input_save_name"),
            defaultValue: _task.title,
          );
          if (rename != null && rename.isNotEmpty) {
            name = rename;
          } else {
            return;
          }
        } else {
          if (!await confirmDialog(
              context,
              tr('screen.download_export_to_file.export_confirm'),
              tr('screen.download_export_group.export_to_cbz_title') + showExportPath(),
          )) {
            return;
          }
        }
        try {
          setState(() {
            exporting = true;
          });
          await method.exportComicDownloadToCbzsZip(
            widget.comicId,
            await attachExportPath(),
            name,
          );
          setState(() {
            exportResult = tr("screen.download_export_group.export_success");
          });
        } catch (e) {
          setState(() {
            exportResult = tr("screen.download_export_group.export_failed") + " $e";
          });
        } finally {
          setState(() {
            exporting = false;
          });
        }
      },
      child: _buildButtonInner(
        tr("screen.download_export_to_file.export_to_cbz_desc") + (!isPro ? "\n(${tr('app.pro')})" : ""),
      ),
    );
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
