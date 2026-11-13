import 'package:flutter/material.dart';
import 'package:pikapika/i18.dart';

import '../basic/config/HiddenCommentWords.dart';
import 'components/ContentBuilder.dart';
import 'components/ListView.dart';
import 'components/RightClickPop.dart';

class HiddenCommentWordsScreen extends StatefulWidget {
  const HiddenCommentWordsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HiddenCommentWordsScreenState();
}

class _HiddenCommentWordsScreenState extends State<HiddenCommentWordsScreen> {
  late Future<String> _future = initHiddenCommentWords();
  late Key _key = UniqueKey();
  final TextEditingController _textController = TextEditingController();

  Future<void> _addWord() async {
    if (_textController.text.trim().isEmpty) return;
    await addHiddenCommentWord(_textController.text.trim());
    _textController.clear();
    setState(() {
      _future = initHiddenCommentWords();
      _key = UniqueKey();
    });
  }

  Future<void> _removeWord(String word) async {
    await removeHiddenCommentWord(word);
    setState(() {
      _future = initHiddenCommentWords();
      _key = UniqueKey();
    });
  }

  Future<void> _clearAll() async {
    await clearHiddenCommentWords();
    setState(() {
      _future = initHiddenCommentWords();
      _key = UniqueKey();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
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
        title: Text(tr("settings.hidden_comment_words.title")),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(tr("settings.hidden_comment_words.clear_all")),
                  content:
                      Text(tr("settings.hidden_comment_words.clear_all_desc")),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(tr("app.cancel")),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(tr("app.confirm")),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _clearAll();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: tr("settings.hidden_comment_words.input_hint"),
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addWord(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addWord,
                ),
              ],
            ),
          ),
          Expanded(
            child: ContentBuilder(
              key: _key,
              future: _future,
              onRefresh: () async {
                setState(() {
                  _future = initHiddenCommentWords();
                  _key = UniqueKey();
                });
              },
              successBuilder:
                  (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (hiddenCommentWords.isEmpty) {
                  return Center(
                    child: Text(tr("settings.hidden_comment_words.no_words")),
                  );
                }
                return PikaListView(
                  children: hiddenCommentWords
                      .map((word) => ListTile(
                            title: Text(word),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeWord(word),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
