import 'dart:convert';

import 'Entities.dart';

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse('$value') ?? 0;
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((item) => '$item').toList();
  }
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.map((item) => '$item').toList();
      }
    } catch (_) {}
  }
  return [];
}

RemoteImageInfo _thumbOf(Map<String, dynamic> json) {
  final thumb = json['thumb'];
  final map = thumb is Map ? Map<String, dynamic>.from(thumb) : <String, dynamic>{};
  return RemoteImageInfo(
    originalName: '${map['originalName'] ?? ''}',
    path: '${map['path'] ?? ''}',
    fileServer: '${map['fileServer'] ?? ''}',
  );
}

ComicSimple comicSimpleFromStored(Map<String, dynamic> json) {
  return ComicSimple(
    id: '${json['_id'] ?? json['id'] ?? ''}',
    title: '${json['title'] ?? ''}',
    author: '${json['author'] ?? ''}',
    pagesCount: _asInt(json['pagesCount']),
    epsCount: _asInt(json['epsCount']),
    finished: json['finished'] == true,
    categories: _stringList(json['categories']),
    thumb: _thumbOf(json),
    likesCount: _asInt(json['likesCount']),
  );
}

ComicSimple comicSimpleFromView(ViewLog view) {
  return ComicSimple(
    id: view.id,
    title: view.title,
    author: view.author,
    pagesCount: view.pagesCount,
    epsCount: view.epsCount,
    finished: view.finished,
    categories: _stringList(view.categories),
    thumb: RemoteImageInfo(
      originalName: view.thumbOriginalName,
      fileServer: view.thumbFileServer,
      path: view.thumbPath,
    ),
    likesCount: 0,
  );
}

ComicSimple comicSimpleFromInfo(ComicInfo info) {
  return ComicSimple(
    id: info.id,
    title: info.title,
    author: info.author,
    pagesCount: info.pagesCount,
    epsCount: info.epsCount,
    finished: info.finished,
    categories: info.categories,
    thumb: info.thumb,
    likesCount: info.likesCount,
  );
}

ComicSimple comicSimpleFromSubscribe(ComicSubscribe subscribe) {
  return ComicSimple(
    id: subscribe.id,
    title: subscribe.title,
    author: subscribe.author,
    pagesCount: subscribe.pagesCount,
    epsCount: subscribe.epsCount,
    finished: subscribe.finished,
    categories: _stringList(subscribe.categories),
    thumb: RemoteImageInfo(
      originalName: subscribe.thumbOriginalName,
      fileServer: subscribe.thumbFileServer,
      path: subscribe.thumbPath,
    ),
    likesCount: subscribe.likesCount,
  );
}
