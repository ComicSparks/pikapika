import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pikapika/i18.dart';

import '../../screens/HiddenCommentWordsScreen.dart';
import '../Method.dart';
import 'HiddenWords.dart';

const _key = "hiddenCommentWords";

final List<String> _hiddenCommentWords = [];

List<String> get hiddenCommentWords => _hiddenCommentWords;

Future<String> initHiddenCommentWords() async {
  final words = await method.loadProperty(_key, "[]");
  _hiddenCommentWords.clear();
  _hiddenCommentWords.addAll((jsonDecode(words) as List).cast<String>());
  return words;
}

Future<void> saveHiddenCommentWords(List<String> words) async {
  _hiddenCommentWords.clear();
  _hiddenCommentWords.addAll(words);
  await method.saveProperty(_key, jsonEncode(words));
}

Future<void> addHiddenCommentWord(String word) async {
  if (word.trim().isEmpty) return;
  if (!_hiddenCommentWords.contains(word)) {
    _hiddenCommentWords.add(word);
    await method.saveProperty(_key, jsonEncode(_hiddenCommentWords));
  }
}

Future<void> removeHiddenCommentWord(String word) async {
  _hiddenCommentWords.remove(word);
  await method.saveProperty(_key, jsonEncode(_hiddenCommentWords));
}

Future<void> clearHiddenCommentWords() async {
  _hiddenCommentWords.clear();
  await method.saveProperty(_key, "[]");
}

bool isCommentSealed(String content) {
  if (_hiddenCommentWords.isEmpty || content.isEmpty) {
    return false;
  }
  final lower = content.toLowerCase();
  for (final word in _hiddenCommentWords) {
    if (word.isEmpty) continue;
    if (lower.contains(word.toLowerCase())) {
      return true;
    }
  }
  return false;
}

Widget hiddenCommentWordsSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: Text(tr("settings.hidden_comment_words.title")),
        subtitle: Text(subString(jsonEncode(_hiddenCommentWords))),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const HiddenCommentWordsScreen(),
          ));
          setState(() {});
        },
      );
    },
  );
}
