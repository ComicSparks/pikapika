import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pikapika/i18.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/AccessKeyReplaceScreen.dart';

import '../basic/config/IconLoading.dart';
import '../basic/config/IsPro.dart';
import 'components/ListView.dart';

class ProScreen extends StatefulWidget {
  const ProScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  String _username = "";

  @override
  void initState() {
    method.getUsername().then((value) {
      setState(() {
        _username = value;
      });
    });
    proEvent.subscribe(_setState);
    super.initState();
  }

  @override
  void dispose() {
    proEvent.unsubscribe(_setState);
    super.dispose();
  }

  _setState(_) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var min = size.width < size.height ? size.width : size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('screen.pro.title')),
      ),
      body: PikaListView(
        children: [
          SizedBox(
            width: min / 2,
            height: min / 2,
            child: Center(
              child: Icon(
                isPro ? Icons.offline_bolt : Icons.offline_bolt_outlined,
                size: min / 3,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          Center(child: Text(_username)),
          Container(height: 20),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(tr('screen.pro.power_guide')),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: Text(tr('screen.pro.sign_in_exchange')),
                  subtitle: Text(
                    proInfoAf.isPro
                        ? "${tr('screen.pro.powered')} (${DateTime.fromMillisecondsSinceEpoch(1000 * proInfoAf.expire).toString()})"
                        : tr('screen.pro.not_powered'),
                  ),
                ),
              ),
              Expanded(
                child: ListTile(
                  title: Text(tr('screen.pro.pat_membership')),
                  subtitle: Text(
                    proInfoPat.isPro ? tr('screen.pro.powered') : tr('screen.pro.not_powered'),
                  ),
                  onTap: () {
                    defaultToast(context, tr('screen.pro.click_pat_to_change'));
                  },
                ),
              ),
            ],
          ),
          const Divider(),
          ListTile(
            title: Text(tr('screen.pro.i_have_powered')),
            onTap: () async {
              try {
                await method.reloadPro();
                defaultToast(context, "SUCCESS");
              } catch (e, s) {
                defaultToast(context, "FAIL");
              }
              await reloadIsPro();
              setState(() {});
            },
          ),
          const Divider(),
          ListTile(
            title: Text(tr('screen.pro.i_just_powered')),
            onTap: () async {
              var code = await inputString(context, tr('screen.pro.enter_code'));
              if (code != null) {
                code = code.trim();
                if (code.isNotEmpty) {
                  try {
                    await method.inputCdKey(code);
                    defaultToast(context, "SUCCESS");
                  } catch (e, s) {
                    defaultToast(context, "FAIL");
                  }
                }
              }
              await reloadIsPro();
              setState(() {});
            },
          ),
          const Divider(),
          ...patPro(),
          const Divider(),
          const Divider(),
        ],
      ),
    );
  }

  List<Widget> patPro() {
    List<Widget> widgets = [];
    if (proInfoPat.accessKey.isNotEmpty) {
      var text = tr('screen.pro.key_recorded');
      if (proInfoPat.patId.isNotEmpty) {
        text += "\n${tr('screen.pro.pat_account')} : ${proInfoPat.patId}";
      }
      if (proInfoPat.bindUid.isNotEmpty) {
        text += "\n${tr('screen.pro.bind_pika_account')} : ${proInfoPat.bindUid}";
      }
      if (proInfoPat.requestDelete > 0) {
        DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
          proInfoPat.requestDelete * 1000,
          isUtc: true,
        );
        String formattedDate =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime.toLocal());
        text += "\n${tr('screen.pro.bind_account_time')} : $formattedDate";
      }
      if (proInfoPat.reBind > 0) {
        DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
          proInfoPat.reBind * 1000,
          isUtc: true,
        );
        String formattedDate =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime.toLocal());
        text += "\n${tr('screen.pro.rebind_time')} : $formattedDate";
      }
      List<TextSpan> append = [];
      if (proInfoPat.bindUid == "") {
        append.add(TextSpan(
          text: "\n(${tr('screen.pro.pat_bind_hint')})",
          style: const TextStyle(color: Colors.blue),
        ));
      } else if (proInfoPat.bindUid != _username) {
        append.add(TextSpan(
          text: "\n(${tr('screen.pro.pat_rebind_hint')})",
          style: const TextStyle(color: Colors.red),
        ));
      } else if (proInfoPat.isPro == false) {
        append.add(TextSpan(
          text: "\n(${tr('screen.pro.pat_not_detected')})",
          style: const TextStyle(color: Colors.orange),
        ));
      } else {
        append.add(TextSpan(
          text: "\n(${tr('screen.pro.pat_normal')})",
          style: const TextStyle(color: Colors.green),
        ));
      }
      widgets.add(ListTile(
        onTap: () async {
          print(jsonEncode(proInfoPat));
          var choose = await chooseMapDialog<int>(
            context,
            {
              tr('screen.pro.update_pat_status'): 2,
              tr('screen.pro.bind_to_account'): 3,
              tr('screen.pro.change_pat_key'): 1,
              tr('screen.pro.clear_pat_info'): 4,
            },
            tr('app.please_select'),
          );
          switch (choose) {
            case 1:
              addPatAccount();
              break;
            case 2:
              reloadPatAccount();
              break;
            case 3:
              bindThisAccount();
              break;
            case 4:
              clearPat();
              break;
          }
        },
        title: Text(tr('screen.pro.pat_membership')),
        subtitle: Text.rich(TextSpan(children: [
          TextSpan(text: text),
          ...append,
        ])),
      ));
    } else {
      widgets.add(ListTile(
        onTap: () {
          addPatAccount();
        },
        title: Text(tr('screen.pro.pat_membership')),
        subtitle: Text(tr('screen.pro.click_to_bind')),
      ));
    }
    return widgets;
  }

  void addPatAccount() async {
    print(jsonEncode(proInfoPat));
    String? key = await inputString(context, tr('screen.pro.enter_auth_code'));
    if (key != null) {
      await Navigator.of(context)
          .push(mixRoute(builder: (BuildContext context) {
        return AccessKeyReplaceScreen(accessKey: key);
      }));
    }
  }

  reloadPatAccount() async {
    defaultToast(context, tr('screen.pro.please_wait'));
    try {
      await method.reloadPatAccount();
      await reloadIsPro();
      defaultToast(context, "SUCCESS");
    } catch (e) {
      defaultToast(context, "FAIL : $e");
    } finally {}
  }

  bindThisAccount() async {
    defaultToast(context, tr('screen.pro.please_wait'));
    try {
      await method.bindThisAccount();
      await method.reloadPatAccount();
      await reloadIsPro();
      defaultToast(context, "SUCCESS");
    } catch (e) {
      defaultToast(context, "FAIL : $e");
    } finally {}
  }

  clearPat() async {
    await method.clearPat();
    await reloadIsPro();
    defaultToast(context, "Success");
  }
}
