import 'dart:convert';
import 'package:pikapika/i18.dart';
import 'package:event/event.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/screens/CategoriesHiddenScreen.dart';
import '../Method.dart';

const _propertyName = "categoriesHidden";
List<String> _categoriesHidden = [];

Future initCategoriesHidden() async {
  var json = await method.loadProperty(_propertyName, "[]");
  _categoriesHidden = List<String>.from(jsonDecode(json));
}

Future saveCategoriesHidden(List<String> categoriesHidden) async {
  _categoriesHidden = categoriesHidden;
  await method.saveProperty(_propertyName, jsonEncode(categoriesHidden));
  categoriesHiddenEvent.broadcast();
}

List<String> getCategoriesHidden() {
  return _categoriesHidden;
}

var categoriesHiddenEvent = Event();

Widget categoriesHiddenSetting() {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) {
              return const CategoriesHiddenScreen();
            },
          ));
        },
        title: Text(
          tr('settings.categories_hidden.title'),
        ),
      );
    },
  );
}
