import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Common.dart';
import '../basic/Channels.dart';
import '../basic/Method.dart';
import '../basic/config/ExportPath.dart';
import '../basic/config/ExportRename.dart';
import '../basic/config/IsPro.dart';
import 'components/ContentLoading.dart';
import 'components/ListView.dart';

class DownloadExportingGroupScreen extends StatefulWidget {
  final List<String> idList;

  const DownloadExportingGroupScreen({Key? key, required this.idList})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _DownloadExportingGroupScreenState();
}

class _DownloadExportingGroupScreenState
    extends State<DownloadExportingGroupScreen> {
  bool exporting = false;
  bool exported = false;
  bool exportFail = false;
  dynamic e;
  String exportMessage = tr("screen.download_export_group.exporting");

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

  Widget _body() {
    if (exporting) {
      return ContentLoading(label: exportMessage);
    }
    if (exportFail) {
      return Center(child: Text(tr("screen.download_export_group.export_failed") + "\n$e"));
    }
    if (exported) {
      return Center(child: Text(tr("screen.download_export_group.export_success")));
    }
    return PikaListView(
      children: [
        Container(height: 20),
        displayExportPathInfo(),
        Container(height: 20),
        MaterialButton(
          onPressed: _exportPkz,
          child: _buildButtonInner(tr("screen.download_export_group.export_to_pkz")),
        ),
        Container(height: 20),
        MaterialButton(
          onPressed: _exportPkis,
          child: _buildButtonInner(tr("screen.download_export_group.export_to_pki")),
        ),
        Container(height: 20),
        MaterialButton(
          onPressed: _exportZips,
          child: _buildButtonInner(
              tr("screen.download_export_group.export_to_zip") +
                  (!isPro ? "\n" + tr("screen.download_export_group.after_power_use") : "")),
        ),
        Container(height: 20),
        MaterialButton(
          onPressed: _exportToJPEGSZips,
          child: _buildButtonInner(
            tr("screen.download_export_group.export_to_jpeg_zip") +
                (!isPro ? "\n" + tr("screen.download_export_group.after_power_use") : ""),
          ),
        ),
        Container(height: 20),
        MaterialButton(
          onPressed: _exportToJPEGSFolders,
          child: _buildButtonInner(
            tr("screen.download_export_group.export_to_jpeg_folder") +
                (!isPro ? "\n" + tr("screen.download_export_group.after_power_use") : ""),
          ),
        ),
        Container(height: 20),
        MaterialButton(
          onPressed: _exportToPdf,
          child: _buildButtonInner(
            tr("screen.download_export_group.export_to_pdf") +
                (!isPro ? "\n" + tr("screen.download_export_group.after_power_use") : ""),
          ),
        ),
        Container(height: 20),
        MaterialButton(
          onPressed: _exportToPdfFolder,
          child: _buildButtonInner(
            tr("screen.download_export_group.export_to_pdf_folder") +
                (!isPro ? "\n" + tr("screen.download_export_group.after_power_use") : ""),
          ),
        ),
        Container(height: 20),
        MaterialButton(
          onPressed: _exportToEpub,
          child: _buildButtonInner(
            tr("screen.download_export_group.export_to_epub") +
                (!isPro ? "\n" + tr("screen.download_export_group.after_power_use") : ""),
          ),
        ),
        Container(height: 20),
        MaterialButton(
          onPressed: _exportComicDownloadToCbzsZip,
          child: _buildButtonInner(
            tr("screen.download_export_group.export_to_cbz") +
                (!isPro ? "\n" + tr("screen.download_export_group.after_power_use") : ""),
          ),
        ),
        Container(height: 20),
      ],
    );
  }

  _exportPkz() async {
    var name = "";
    if (currentExportRename()) {
      var rename = await inputString(
        context,
        tr("screen.download_export_group.input_save_name"),
        defaultValue: "${DateTime.now().millisecondsSinceEpoch}",
      );
      if (rename != null && rename.isNotEmpty) {
        name = rename;
      } else {
        return;
      }
    } else {
      if (!await confirmDialog(
          context,
          tr("screen.download_export_group.export_confirm"),
          tr("screen.download_export_group.export_to_pkz_title") + showExportPath())) {
        return;
      }
    }
    try {
      setState(() {
        exporting = true;
      });
      await method.exportComicDownloadToPkz(
        widget.idList,
        await attachExportPath(),
        name,
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

  _exportPkis() async {
    if (!await confirmDialog(
        context,
        tr("screen.download_export_group.export_confirm"),
        tr("screen.download_export_group.export_to_pki_title") + showExportPath())) {
      return;
    }
    try {
      setState(() {
        exporting = true;
      });
      await method.exportAnyComicDownloadsToPki(
        widget.idList,
        await attachExportPath(),
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

  _exportZips() async {
    if (!isPro) {
      defaultToast(context, tr("screen.download_export_group.please_power_up"));
      return;
    }
    if (!await confirmDialog(
        context,
        tr("screen.download_export_group.export_confirm"),
        tr("screen.download_export_group.export_to_zip_title") + showExportPath())) {
      return;
    }
    try {
      setState(() {
        exporting = true;
      });
      await method.exportAnyComicDownloadsToZip(
        widget.idList,
        await attachExportPath(),
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

  _exportToJPEGSZips() async {
    if (!isPro) {
      defaultToast(context, tr("screen.download_export_group.please_power_up"));
      return;
    }
    if (!await confirmDialog(
        context,
        tr("screen.download_export_group.export_confirm"),
        tr("screen.download_export_group.export_to_jpeg_zip_title") + showExportPath())) {
      return;
    }
    try {
      setState(() {
        exporting = true;
      });
      final path = await attachExportPath();
      for (var id in widget.idList) {
        await method.exportComicDownloadJpegZip(
          id,
          path,
          "",
        );
      }
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

  _exportToJPEGSFolders() async {
    if (!isPro) {
      defaultToast(context, tr("screen.download_export_group.please_power_up"));
      return;
    }
    if (!await confirmDialog(
        context,
        tr("screen.download_export_group.export_confirm"),
        tr("screen.download_export_group.export_to_jpeg_folder_title") + showExportPath())) {
      return;
    }
    try {
      setState(() {
        exporting = true;
      });
      final path = await attachExportPath();
      for (var id in widget.idList) {
        await method.exportComicDownloadToJPG(
          id,
          path,
          "",
        );
      }
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

  _exportToPdf() async {
    if (!isPro) {
      defaultToast(context, tr("screen.download_export_group.please_power_up"));
      return;
    }
    if (!await confirmDialog(
        context,
        tr("screen.download_export_group.export_confirm"),
        tr("screen.download_export_group.export_to_pdf_title") + showExportPath())) {
      return;
    }
    try {
      setState(() {
        exporting = true;
      });
      final path = await attachExportPath();
      for (var id in widget.idList) {
        await method.exportComicDownloadToPDF(
          id,
          path,
          "",
        );
      }
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

  _exportToEpub() async {
    if (!isPro) {
      defaultToast(context, tr("screen.download_export_group.please_power_up"));
      return;
    }
    if (!await confirmDialog(
        context,
        tr("screen.download_export_group.export_confirm"),
        tr("screen.download_export_group.export_to_epub_title") + showExportPath())) {
      return;
    }
    try {
      setState(() {
        exporting = true;
      });
      final path = await attachExportPath();
      for (var id in widget.idList) {
        await method.exportComicDownloadToEpub(
          id,
          path,
          "",
        );
      }
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

  _exportToPdfFolder() async {
    if (!isPro) {
      defaultToast(context, tr("screen.download_export_group.please_power_up"));
      return;
    }
    if (!await confirmDialog(
        context,
        tr("screen.download_export_group.export_confirm"),
        tr("screen.download_export_group.export_to_pdf_folder_title") + showExportPath())) {
      return;
    }
    try {
      setState(() {
        exporting = true;
      });
      final path = await attachExportPath();
      for (var id in widget.idList) {
        await method.exportComicDownloadToPDFFolder(
          id,
          path,
          "",
        );
      }
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

  _exportComicDownloadToCbzsZip() async {
    if (!isPro) {
      defaultToast(context, tr("screen.download_export_group.please_power_up"));
      return;
    }
    if (!await confirmDialog(
        context,
        tr("screen.download_export_group.export_confirm"),
        tr("screen.download_export_group.export_to_cbz_title") + showExportPath())) {
      return;
    }
    try {
      setState(() {
        exporting = true;
      });
      final path = await attachExportPath();
      for (var id in widget.idList) {
        await method.exportComicDownloadToCbzsZip(
          id,
          path,
          "",
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr("screen.download_export_group.title")),
        ),
        body: _body(),
      ),
      onWillPop: () async {
        if (exporting) {
          defaultToast(context, tr("screen.download_export_group.exporting_please_wait"));
          return false;
        }
        return true;
      },
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
