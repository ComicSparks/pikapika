import 'dart:async';

import 'package:pikapika/i18.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/basic/config/IsPro.dart';
import 'package:pikapika/basic/enum/ErrorTypes.dart';
import 'package:pikapika/screens/RegisterScreen.dart';
import 'package:pikapika/screens/components/NetworkSetting.dart';
import 'package:pikapika/screens/components/RecommendLinksPanel.dart';

import '../basic/config/IconLoading.dart';
import '../basic/config/Version.dart';
import 'AppScreen.dart';
import 'DownloadListScreen.dart';
import 'ForgotPasswordScreen.dart';
import 'components/ContentLoading.dart';
import 'components/ListView.dart';

// 账户设置
class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late bool _logging = false;
  late String _username = "";
  late String _password = "";
  late StreamSubscription<Uri> _linkSubscription;
  late int _versionClick = 0;

  @override
  void initState() {
    _linkSubscription = linkSubscript(context);
    _loadProperties();
    super.initState();
    Future.delayed(Duration.zero, () async {
      versionPop(context);
      versionEvent.subscribe(_versionSub);
    });
  }

  @override
  void dispose() {
    _linkSubscription.cancel();
    versionEvent.unsubscribe(_versionSub);
    super.dispose();
  }

  _versionSub(_) {
    versionPop(context);
  }

  Future _loadProperties() async {
    var username = await method.getUsername();
    var password = await method.getPassword();
    setState(() {
      _username = username;
      _password = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_logging) {
      return _buildLogging();
    }
    return _buildGui();
  }

  Widget _buildLogging() {
    return Scaffold(
      body: ContentLoading(label: tr('app.loading')),
    );
  }

  Widget _buildGui() {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('screen.account.title')),
        actions: [
          SizedBox(
            width: 80,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _versionClick++;
                });
              },
              icon: Text(currentVersion()),
            ),
          ),
          IconButton(
            onPressed: _toDownloadList,
            icon: const Icon(Icons.download_rounded),
          ),
          IconButton(
            onPressed: _logIn,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: PikaListView(
        children: [
          ListTile(
            title: Text(tr("screen.account.username")),
            subtitle: Text(
                _username == "" ? tr("screen.account.not_set") : _username),
            onTap: () async {
              String? input = await displayTextInputDialog(
                context,
                src: _username,
                title: tr("screen.account.username"),
                hint: tr("screen.account.username_hint"),
              );
              if (input != null) {
                await method.setUsername(input);
                setState(() {
                  _username = input;
                });
              }
            },
          ),
          ListTile(
            title: Text(tr("screen.account.password")),
            subtitle: Text(
                _password == "" ? tr("screen.account.not_set") : '\u2022' * 10),
            onTap: () async {
              String? input = await displayTextInputDialog(
                context,
                src: _password,
                title: tr("screen.account.password"),
                hint: tr("screen.account.password_hint"),
                isPasswd: true,
              );
              if (input != null) {
                await method.setPassword(input);
                setState(() {
                  _password = input;
                });
              }
            },
          ),
          const NetworkSetting(),
          ..._versionClick >= 7
              ? [
                  Container(
                    padding: const EdgeInsets.all(15),
                    child: Text.rich(TextSpan(
                      text: tr("screen.account.no_account_register"),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => Navigator.push(
                              context,
                              mixRoute(
                                  builder: (BuildContext context) =>
                                      const RegisterScreen()),
                            ).then((value) => _loadProperties()),
                    )),
                  ),
                ]
              : [],
          Container(
            padding: const EdgeInsets.all(15),
            child: Text.rich(TextSpan(
              text: tr("screen.account.password_reset"),
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Navigator.push(
                      context,
                      mixRoute(
                          builder: (BuildContext context) =>
                              const ForgotPasswordScreen()),
                    ).then((value) => _loadProperties()),
            )),
          ),
          const RecommendLinksPanel(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        ],
      ),
    );
  }

  _logIn() async {
    setState(() {
      _logging = true;
    });
    try {
      await method.login();
      await reloadIsPro();
      Navigator.pushReplacement(
        context,
        mixRoute(builder: (context) => const AppScreen()),
      );
    } catch (e, s) {
      print("$e\n$s");
      setState(() {
        _logging = false;
      });
      var message = tr("screen.account.check_username_password_or_network");
      switch (errorType("$e")) {
        case ERROR_TYPE_NETWORK:
          message = tr("screen.account.network_不通");
          break;
        case ERROR_TYPE_TIME:
          message = tr("screen.account.check_device_time");
          break;
      }
      if ("$e".contains("email") && "$e".contains("password")) {
        message = tr("screen.account.username_or_password_error");
      }
      alertDialog(
        context,
        tr("screen.account.login_failed"),
        "$message\n$e",
      );
    }
  }

  _toDownloadList() {
    Navigator.push(
      context,
      mixRoute(builder: (context) => const DownloadListScreen()),
    );
  }
}
