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
                defaultToast(context, _proErrorMessage(e));
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
                    defaultToast(context, _proErrorMessage(e));
                  }
                }
              }
              await reloadIsPro();
              setState(() {});
            },
          ),
          const Divider(),
          const ProServerNameWidget(),
          const Divider(),
          ...patPro(),
          const Divider(),
          const _ReferralTiles(),
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

const _defaultProServerId = "ORI";

const _proServerIds = <String>[
  "ORI",
  "jdtvmstd22deytdzenvydyil3e0jkxfu",
  "mek5hrs65poai2eqjjofqr7ynu0nxkqx",
  "6h2odtaft7fuvssx6v5b73pwie0dfgvm",
  "ilsfsfkt75kp2nnfievnqcjmza0ooksc",
  "wuwjgjgautzqf6ybwmma6e2pw40iilcy",
  "phuto27lxoqo4skduakcs4siwu0ffwoh",
  "4sfkal33ch44fle6u6smhwufri0cmgnv",
];

final _proServerIdPattern = RegExp(r'^[a-z0-9]+$');
final _proServerRegionPattern = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)+$');

class ProServerNameWidget extends StatefulWidget {
  const ProServerNameWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ProServerNameWidgetState();
}

class _ProServerNameWidgetState extends State<ProServerNameWidget> {
  String _serverName = "";

  @override
  void initState() {
    method.getProServerName().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        _serverName = value;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(tr('screen.pro.power_method')),
      subtitle: Text(_loadServerName()),
      onTap: () async {
        var serverName = await chooseMapDialog<String>(
          context,
          {
            for (final id in _proServerIds) id: id,
          },
          tr('screen.pro.choose_power_method'),
        );
        if (serverName != null && serverName.isNotEmpty) {
          final name = serverName;
          await method.setProServerName(name);
          if (!mounted) {
            return;
          }
          setState(() {
            _serverName = name;
          });
        }
      },
    );
  }

  String _loadServerName() {
    if (_proServerIds.contains(_serverName)) {
      return _serverName;
    }
    final parts = _serverName.split('|');
    if (parts.length == 2 &&
        _proServerIdPattern.hasMatch(parts[0]) &&
        _proServerRegionPattern.hasMatch(parts[1])) {
      return parts[0];
    }
    return _defaultProServerId;
  }
}

class _ReferralTiles extends StatefulWidget {
  const _ReferralTiles();

  @override
  State<_ReferralTiles> createState() => _ReferralTilesState();
}

class _ReferralTilesState extends State<_ReferralTiles> {
  String _username = "";
  String _referrer = "";
  int _unbindWaitDays = 0;
  int _campaignStart = 0;
  int _campaignEnd = 0;

  @override
  void initState() {
    super.initState();
    method.getUsername().then((value) {
      if (!mounted) return;
      setState(() {
        _username = value;
      });
    });
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await method.referralCall('{"action":"local"}');
      if (!mounted || raw.isEmpty) return;
      _apply(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {}
  }

  Future<void> _referral(String payload, String ok) async {
    try {
      final raw = await method.referralCall(payload);
      if (!mounted) return;
      if (raw.isNotEmpty) {
        _apply(jsonDecode(raw) as Map<String, dynamic>);
      }
      defaultToast(context, ok);
    } catch (e) {
      if (mounted) defaultToast(context, _referralError(e));
    }
  }

  void _apply(Map<String, dynamic> map) {
    setState(() {
      _referrer = (map["referrer"] ?? "").toString();
      _unbindWaitDays = _asInt(map["unbind_wait_days"]);
      _campaignStart = _asInt(map["campaign_start"]);
      _campaignEnd = _asInt(map["campaign_end"]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(tr("screen.pro.referrer")),
          subtitle: Text(_referrer),
          onTap: () async {
            if (_username.isEmpty) {
              defaultToast(context, tr("screen.pro.referrer_login"));
              return;
            }
            if (_referrer.isNotEmpty) return;
            final name = await inputString(context, tr("screen.pro.enter_referrer"));
            if (name == null || name.trim().isEmpty) return;
            await _referral(
              jsonEncode({"action": "bind", "referrer": name.trim()}),
              tr("screen.pro.referrer_bound"),
            );
          },
          onLongPress: () async {
            if (_referrer.isEmpty) return;
            if (_unbindWaitDays > 0) {
              defaultToast(context, tr("screen.pro.unbind_wait").replaceAll("{days}", "$_unbindWaitDays"));
              return;
            }
            final ok = await confirmDialog(
              context,
              tr("screen.pro.unbind_referrer"),
              tr("screen.pro.unbind_confirm"),
            );
            if (!ok || !context.mounted) return;
            await _referral('{"action":"unbind"}', tr("screen.pro.referrer_unbound"));
          },
        ),
        ListTile(
          title: Text(tr("screen.pro.campaign_time")),
          subtitle: Text(_campaignLabel(_campaignStart, _campaignEnd)),
        ),
      ],
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? "") ?? 0;
}

String _campaignLabel(int start, int end) {
  if (start <= 0 || end <= 0) return "";
  String fmt(int seconds) {
    final time = DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true).toLocal();
    String two(int value) => value.toString().padLeft(2, "0");
    return "${time.year}-${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}";
  }

  return "${fmt(start)} — ${fmt(end)}";
}

String _referralError(Object error) {
  final text = error.toString();
  final wait = RegExp(r"REFERRER_UNBIND_WAIT:(\d+)").firstMatch(text);
  if (wait != null) {
    return tr("screen.pro.unbind_wait").replaceAll("{days}", wait.group(1)!);
  }
  if (text.contains("REFERRER_SELF")) return tr("screen.pro.referrer_self");
  if (text.contains("REFERRER_LOCKED")) return tr("screen.pro.referrer_already");
  if (text.contains("REFERRER_MUTUAL")) return tr("screen.pro.referrer_mutual");
  if (text.contains("REFERRER_NOT_BOUND")) return tr("screen.pro.referrer_not_bound");
  return text;
}

String _proErrorMessage(Object e) {
  var text = e.toString();
  const prefixes = ['Bad state: ', 'Exception: ', 'Error: '];
  for (final prefix in prefixes) {
    if (text.startsWith(prefix)) {
      text = text.substring(prefix.length);
      break;
    }
  }
  text = text.trim();
  if (text.isEmpty) {
    text = 'SERVER_FAILED';
  }
  final key = 'screen.pro.error.$text';
  final translated = tr(key);
  if (translated != key) {
    return translated;
  }
  return text;
}
