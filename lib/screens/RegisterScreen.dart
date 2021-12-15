import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/components/NetworkSetting.dart';

import 'components/ContentLoading.dart';

/// 注册页面
class RegisterScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  late bool _registering = false;
  late bool _registerOver = false;

  late String _email = "";
  late String _name = "";
  late String _password = "";
  late String _gender = "bot";
  late String _birthday = "2000-01-01";
  late String _question1 = "问题1";
  late String _answer1 = "回答1";
  late String _question2 = "问题2";
  late String _answer2 = "回答2";
  late String _question3 = "问题3";
  late String _answer3 = "回答3";

  Future _register() async {
    setState(() {
      _registering = true;
    });
    try {
      var mustList = <String>[
        _email,
        _name,
        _password,
        _gender,
        _birthday,
        _question1,
        _answer1,
        _question2,
        _answer2,
        _question3,
        _answer3,
      ];
      for (var a in mustList) {
        if (a.isEmpty) {
          throw '请检查表单, 不允许留空';
        }
      }
      await method.register(
        _email,
        _name,
        _password,
        _gender,
        _birthday,
        _question1,
        _answer1,
        _question2,
        _answer2,
        _question3,
        _answer3,
      );
      await method.setUsername(_email);
      await method.setPassword(_password);
      await method.clearToken();
      setState(() {
        _registerOver = true;
      });
    } catch (e) {
      String message = "$e";
      if (message.contains("email is already exist")) {
        message = "账号已存在";
      }
      alertDialog(context, "注册失败", message);
    } finally {
      setState(() {
        _registering = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_registerOver) {
      return Scaffold(
        appBar: AppBar(
          title: Text('注册成功'),
        ),
        body: Center(
          child: Container(
            child: Column(
              children: [
                Expanded(child: Container()),
                Text('您已经注册成功, 请返回登录'),
                Text('账号 : $_email'),
                Text('昵称 : $_name'),
                Expanded(child: Container()),
                Expanded(child: Container()),
              ],
            ),
          ),
        ),
      );
    }
    if (_registering) {
      return Scaffold(
        appBar: AppBar(),
        body: ContentLoading(label: '注册中'),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('注册'), actions: [
        IconButton(onPressed: () => _register(), icon: Icon(Icons.check),),
      ],),
      body: ListView(
        children: [
          Divider(),
          ListTile(
            title: Text("账号 (不一定是邮箱/登录使用)"),
            subtitle: Text(_email == "" ? "未设置" : _email),
            onTap: () async {
              String? input = await displayTextInputDialog(
                context,
                src: _email,
                title: '账号',
                hint: '请输入账号',
              );
              if (input != null) {
                setState(() {
                  _email = input;
                });
              }
            },
          ),
          ListTile(
            title: Text("密码 (8位以上)"),
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
                setState(() {
                  _password = input;
                });
              }
            },
          ),
          ListTile(
            title: Text("昵称 (2-50字)"),
            subtitle: Text(_name == "" ? "未设置" : _name),
            onTap: () async {
              String? input = await displayTextInputDialog(
                context,
                src: _name,
                title: '昵称',
                hint: '请输入昵称',
              );
              if (input != null) {
                setState(() {
                  _name = input;
                });
              }
            },
          ),
          ListTile(
            title: Text("性别"),
            subtitle: Text(_genderText(_gender)),
            onTap: () async {
              String? result = await showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    title: Text('选择您的性别'),
                    children: [
                      SimpleDialogOption(
                        child: Text('扶她'),
                        onPressed: () {
                          Navigator.pop(context, 'bot');
                        },
                      ),
                      SimpleDialogOption(
                        child: Text('公'),
                        onPressed: () {
                          Navigator.pop(context, 'm');
                        },
                      ),
                      SimpleDialogOption(
                        child: Text('母'),
                        onPressed: () {
                          Navigator.pop(context, 'f');
                        },
                      ),
                    ],
                  )
                },
              );
              if (result != null) {
                setState(() {
                  _gender = result;
                });
              }
            },
          ),
          ListTile(
            title: Text("生日"),
            subtitle: Text(_birthday),
            onTap: () async {
              DatePicker.showDatePicker(
                  context,
                  locale: LocaleType.zh,
                  currentTime: DateTime.parse(_birthday),
                  onConfirm: (date) {
                    setState(() {
                      _birthday = formatTimeToDate(date.toString());
                    });
                  }
              );
            },
          ),
          Divider(),
          ListTile(
            title: Text("问题1"),
            subtitle: Text(_question1 == "" ? "未设置" : _question1),
            onTap: () async {
              String? input = await displayTextInputDialog(
                context,
                src: _question1,
                title: '问题1',
                hint: '请输入问题1',
              );
              if (input != null) {
                setState(() {
                  _question1 = input;
                });
              }
            },
          ),
          ListTile(
            title: Text("回答1"),
            subtitle: Text(_answer1 == "" ? "未设置" : _answer1),
            onTap: () async {
              String? input = await displayTextInputDialog(
                context,
                src: _answer1,
                title: '回答1',
                hint: '请输入回答1',
              );
              if (input != null) {
                setState(() {
                  _answer1 = input;
                });
              }
            },
          ),
          ListTile(
            title: Text("问题2"),
            subtitle: Text(_question2 == "" ? "未设置" : _question2),
            onTap: () async {
              String? input = await displayTextInputDialog(
                context,
                src: _question2,
                title: '问题2',
                hint: '请输入问题2',
              );
              if (input != null) {
                setState(() {
                  _question2 = input;
                });
              }
            },
          ),
          ListTile(
            title: Text("回答2"),
            subtitle: Text(_answer2 == "" ? "未设置" : _answer2),
            onTap: () async {
              String? input = await displayTextInputDialog(
                context,
                src: _answer2,
                title: '回答2',
                hint: '请输入回答2',
              );
              if (input != null) {
                setState(() {
                  _answer2 = input;
                });
              }
            },
          ),
          ListTile(
            title: Text("问题3"),
            subtitle: Text(_question3 == "" ? "未设置" : _question3),
            onTap: () async {
              String? input = await displayTextInputDialog(
                context,
                src: _question3,
                title: '问题3',
                hint: '请输入问题3',
              );
              if (input != null) {
                setState(() {
                  _question3 = input;
                });
              }
            },
          ),
          ListTile(
            title: Text("回答3"),
            subtitle: Text(_answer3 == "" ? "未设置" : _answer3),
            onTap: () async {
              String? input = await displayTextInputDialog(
                context,
                src: _answer3,
                title: '回答3',
                hint: '请输入回答3',
              );
              if (input != null) {
                setState(() {
                  _answer3 = input;
                });
              }
            },
          ),
          Divider(),
          NetworkSetting(),
          Divider(),
        ],
      ),
    );
  }

  String _genderText(String gender) {
    switch (gender) {
      case 'bot':
        return "扶她";
      case "m":
        return "公";
      case "f":
        return "母";
      default:
        return "";
    }
  }

}
