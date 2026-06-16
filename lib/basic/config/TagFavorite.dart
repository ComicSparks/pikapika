import 'dart:convert';
import 'package:pikapika/i18.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import '../Method.dart';

const _enablePropertyName = "tagFavoriteEnable";
const _dataPropertyName = "tagFavorites";

late bool _tagFavoriteEnable;

final List<TagFavorite> _tagFavorites = [];

bool get tagFavoriteEnable => _tagFavoriteEnable;

// 设置开关变化事件
var tagFavoriteEnableEvent = Event<EventArgs>();

// 收藏列表变化事件
var tagFavoritesEvent = Event<EventArgs>();

class TagFavorite {
  final String tag;
  final int time;

  TagFavorite(this.tag, this.time);

  TagFavorite.fromJson(Map<String, dynamic> json)
      : tag = json["tag"] as String,
        time = json["time"] as int;

  Map<String, dynamic> toJson() => {"tag": tag, "time": time};
}

Future initTagFavorite() async {
  _tagFavoriteEnable =
      (await method.loadProperty(_enablePropertyName, "false")) == "true";
  final data = await method.loadProperty(_dataPropertyName, "[]");
  _tagFavorites.clear();
  _tagFavorites.addAll(
    (jsonDecode(data) as List)
        .map((e) => TagFavorite.fromJson(e as Map<String, dynamic>)),
  );
  _sortTagFavorites();
}

// 由新到旧
void _sortTagFavorites() {
  _tagFavorites.sort((a, b) => b.time.compareTo(a.time));
}

List<TagFavorite> get tagFavorites => List.unmodifiable(_tagFavorites);

bool isTagFavorite(String tag) => _tagFavorites.any((e) => e.tag == tag.trim());

Future<void> _saveTagFavorites() async {
  await method.saveProperty(
    _dataPropertyName,
    jsonEncode(_tagFavorites.map((e) => e.toJson()).toList()),
  );
}

Future<void> addTagFavorite(String tag) async {
  tag = tag.trim();
  if (tag.isEmpty) return;
  if (isTagFavorite(tag)) return;
  _tagFavorites.add(TagFavorite(tag, DateTime.now().millisecondsSinceEpoch));
  _sortTagFavorites();
  await _saveTagFavorites();
  tagFavoritesEvent.broadcast();
}

Future<void> removeTagFavorite(String tag) async {
  _tagFavorites.removeWhere((e) => e.tag == tag.trim());
  await _saveTagFavorites();
  tagFavoritesEvent.broadcast();
}

Future<void> removeTagFavorites(Iterable<String> tags) async {
  final removing = tags.map((e) => e.trim()).toSet();
  if (removing.isEmpty) return;
  _tagFavorites.removeWhere((e) => removing.contains(e.tag));
  await _saveTagFavorites();
  tagFavoritesEvent.broadcast();
}

Future setTagFavoriteEnable(bool value) async {
  await method.saveProperty(_enablePropertyName, value ? "true" : "false");
  _tagFavoriteEnable = value;
  tagFavoriteEnableEvent.broadcast();
}

Widget tagFavoriteSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return SwitchListTile(
        title: Text(tr("settings.tag_favorite.title")),
        subtitle: Text(tr("settings.tag_favorite.desc")),
        value: _tagFavoriteEnable,
        onChanged: (value) async {
          await setTagFavoriteEnable(value);
          setState(() {});
        },
      );
    },
  );
}
