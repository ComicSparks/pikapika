import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/config/Themes.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/basic/enum/ErrorTypes.dart';
import 'package:pikapika/screens/RegisterScreen.dart';
import 'package:pikapika/screens/components/NetworkSetting.dart';

import 'AppScreen.dart';
import 'DownloadListScreen.dart';
import 'components/ContentLoading.dart';

// 账户设置
class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late bool _logging = false;
  late String _username = "";
  late String _password = "";

  @override
  void initState() {
    _loadProperties();
    super.initState();
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
      body: ContentLoading(label: '登录中'),
    );
  }

  Widget _buildGui() {
    return Scaffold(
      appBar: AppBar(
        brightness: Brightness.dark,
        title: Text('配置选项'),
        actions: [
          IconButton(
            onPressed: () {
              chooseTheme(context);
            },
            icon: Text('主题'),
          ),
          IconButton(
            onPressed: _toDownloadList,
            icon: Icon(Icons.download_rounded),
          ),
          IconButton(
            onPressed: _logIn,
            icon: Icon(Icons.save),
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text("账号"),
            subtitle: Text(_username == "" ? "未设置" : _username),
            onTap: () async {
              String? input = await displayTextInputDialog(
                context,
                src: _username,
                title: '账号',
                hint: '请输入账号',
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
            title: Text("密码"),
            subtitle: Text(_password == "" ? "未设置" : '\u2022' * 48),
            onTap: () async {
              String? input = await displayTextInputDialog(
                context,
                src: _password,
                title: '密码',
                hint: '请输入密码',
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
          NetworkSetting(),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(15),
                  child: Text.rich(TextSpan(
                    text: '没有账号,我要注册',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    RegisterScreen()),
                          ).then((value) => _loadProperties()),
                  )),
                ),
              ),
            ],
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AppScreen()),
      );
    } catch (e, s) {
      print("$e\n$s");
      setState(() {
        _logging = false;
      });
      var message = "请检查账号密码";
      switch (errorType("$e")) {
        case ERROR_TYPE_NETWORK:
          message = "网络不通";
          break;
        case ERROR_TYPE_TIME:
          message = "请检查设备时间";
          break;
      }
      alertDialog(
        context,
        '登录失败',
        "$message\n$e",
      );
    }
  }

  _toDownloadList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DownloadListScreen()),
    );
  }
}
