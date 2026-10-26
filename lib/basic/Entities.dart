import 'dart:convert';

/// 图片
class RemoteImageInfo {
  late String originalName;
  late String path;
  late String fileServer;

  RemoteImageInfo.fromJson(Map<String, dynamic> json) {
    this.originalName = json["originalName"];
    this.path = json["path"];
    this.fileServer = json["fileServer"];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['originalName'] = originalName;
    _data['path'] = path;
    _data['fileServer'] = fileServer;
    return _data;
  }
}

/// 用户基本信息
class BasicUser {
  late String id;
  late String gender;
  late String name;
  late String title;
  late bool verified;
  late int exp;
  late int level;
  late List<String> characters;
  late RemoteImageInfo avatar;
  late String? slogan;

  BasicUser.fromJson(Map<String, dynamic> json) {
    this.id = json["_id"];
    this.gender = json["gender"];
    this.name = json["name"];
    this.title = json["title"];
    this.verified = json["verified"];
    this.exp = json["exp"];
    this.level = json["level"];
    this.characters = json["characters"] == null
        ? []
        : List.of(json["characters"]).map((e) => "$e").toList();
    this.avatar =
        RemoteImageInfo.fromJson(Map<String, dynamic>.of(json["avatar"]));
    this.slogan = json["slogan"];
  }
}

/// 用户自己的信息
class UserProfile extends BasicUser {
  late String birthday;
  late String email;
  late String createdAt;
  late bool isPunched;

  UserProfile.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.birthday = json["birthday"];
    this.email = json["email"];
    this.createdAt = json["created_at"];
    this.isPunched = json["isPunched"];
  }
}

/// 分页
class Page {
  late int total;
  late int limit;
  late int page;
  late int pages;

  Page.fromJson(Map<String, dynamic> json) {
    this.total = json["total"];
    this.limit = json["limit"];
    this.page = json["page"];
    this.pages = json["pages"];
  }

  Page.of(this.total, this.limit, this.page, this.pages);
}

/// 分类
class Category {
  late String id;
  late String title;
  late String description;
  late RemoteImageInfo thumb;
  late bool isWeb;
  late bool active;
  late String link;

  Category.fromJson(Map<String, dynamic> json) {
    this.id = json["_id"];
    this.title = json["title"];
    this.description = json["description"];
    this.thumb = RemoteImageInfo.fromJson(json["thumb"]);
    this.isWeb = json["isWeb"];
    this.active = json["active"];
    this.link = json["link"];
  }
}

/// 漫画分页
class ComicsPage extends Page {
  late List<ComicSimple> docs;

  ComicsPage.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.docs = List.from(json["docs"])
        .map((e) => Map<String, dynamic>.from(e))
        .map((e) => ComicSimple.fromJson(e))
        .toList();
  }
}

/// 漫画基本信息
class ComicSimple {
  late String id;
  late String title;
  late String author;
  late int pagesCount;
  late int epsCount;
  late bool finished;
  late List<String> categories;
  late RemoteImageInfo thumb;
  late int likesCount;

  ComicSimple.fromJson(Map<String, dynamic> json) {
    this.id = json["_id"];
    this.title = json["title"];
    this.author = json["author"];
    this.pagesCount = json["pagesCount"];
    this.epsCount = json["epsCount"];
    this.finished = json["finished"];
    this.categories = List<String>.from(json["categories"]);
    this.thumb = RemoteImageInfo.fromJson(json["thumb"]);
    this.likesCount = json["likesCount"];
  }
}

/// 漫画详情
class ComicInfo extends ComicSimple {
  late String description;
  late String chineseTeam;
  late List<String> tags;
  late String updatedAt;
  late String createdAt;
  late bool allowDownload;
  late int viewsCount;
  late bool isFavourite;
  late bool isLiked;
  late int commentsCount;
  late Creator creator;

  ComicInfo.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.description = json["description"];
    this.chineseTeam = json["chineseTeam"];
    this.tags = List<String>.from(json["tags"]);
    this.updatedAt = (json["updated_at"]);
    this.createdAt = (json["created_at"]);
    this.allowDownload = json["allowDownload"];
    this.viewsCount = json["viewsCount"];
    this.isFavourite = json["isFavourite"];
    this.isLiked = json["isLiked"];
    this.commentsCount = json["commentsCount"];
    this.creator = Creator.fromJson(Map<String, dynamic>.of(json["_creator"]));
  }
}

/// 漫画创建人信息
class Creator extends BasicUser {
  late String role;
  late String character;

  Creator.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.role = json["role"];
    this.character = json["character"];
  }
}

/// 漫画章节
class Ep {
  late String id;
  late String title;
  late int order;
  late String updatedAt;

  Ep.fromJson(Map<String, dynamic> json) {
    this.id = json["_id"];
    this.title = json["title"];
    this.order = json["order"];
    this.updatedAt = (json["updated_at"]);
  }
}

/// 漫画章节分页
class EpPage extends Page {
  late List<Ep> docs;

  EpPage.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.docs = List.from(json["docs"])
        .map((e) => Map<String, dynamic>.from(e))
        .map((e) => Ep.fromJson(e))
        .toList();
  }
}

/// 漫画图片分页
class PicturePage extends Page {
  late List<Picture> docs;

  PicturePage.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.docs = List.from(json["docs"])
        .map((e) => Map<String, dynamic>.from(e))
        .map((e) => Picture.fromJson(e))
        .toList();
  }
}

/// 漫画图片信息
class Picture {
  late String id;
  late RemoteImageInfo media;

  Picture.fromJson(Map<String, dynamic> json) {
    this.id = json["_id"];
    this.media = RemoteImageInfo.fromJson(json["media"]);
  }
}

/// 显示图片数据
class RemoteImageData {
  late int fileSize;
  late String format;
  late int width;
  late int height;
  late String finalPath;

  RemoteImageData.forData(
    this.fileSize,
    this.format,
    this.width,
    this.height,
    this.finalPath,
  );

  RemoteImageData.fromJson(Map<String, dynamic> json) {
    this.fileSize = json["fileSize"];
    this.format = json["format"];
    this.width = json["width"];
    this.height = json["height"];
    this.finalPath = json["finalPath"];
  }
}

/// 漫画评论分页
class CommentPage extends Page {
  late List<Comment> docs;

  CommentPage.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.docs = List.from(json["docs"])
        .map((e) => Map<String, dynamic>.from(e))
        .map((e) => Comment.fromJson(e))
        .toList();
  }
}

class CommentBase {
  late String id;
  late String content;
  late CommentUser user;
  late bool isTop;
  late bool hide;
  late String createdAt;
  late int likesCount;
  late int commentsCount;
  late bool isLiked;

  CommentBase.fromJson(Map<String, dynamic> json) {
    this.id = json["_id"];
    this.content = json["content"];
    this.user = CommentUser.fromJson(Map<String, dynamic>.of(json["_user"]));
    this.isTop = json["isTop"];
    this.hide = json["hide"];
    this.createdAt = json["created_at"];
    this.likesCount = json["likesCount"];
    this.commentsCount = json["commentsCount"];
    this.isLiked = json["isLiked"];
  }
}

/// 子评论
class ChildOfComment extends CommentBase {
  late String parent;

  ChildOfComment.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.parent = json["_parent"];
  }
}

/// 漫画评论详情
class Comment extends CommentBase {
  late String comic;

  Comment.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.comic = json["_comic"];
  }
}

/// 评论的用户信息
class CommentUser extends BasicUser {
  late String role;

  CommentUser.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.role = json["role"];
  }
}

/// 已下载图片的信息
class DownloadPicture {
  late int rankInEp;
  late String fileServer;
  late String path;
  late String localPath;
  late int width;
  late int height;
  late String format;
  late int fileSize;

  DownloadPicture.fromJson(Map<String, dynamic> json) {
    this.rankInEp = json["rankInEp"];
    this.fileServer = json["fileServer"];
    this.path = json["path"];
    this.localPath = json["localPath"];
    this.width = json["width"];
    this.height = json["height"];
    this.format = json["format"];
    this.fileSize = json["fileSize"];
  }
}

/// 浏览历史记录
class ViewLog {
  late String id;
  late String title;
  late String author;
  late int pagesCount;
  late int epsCount;
  late bool finished;
  late String categories;
  late String thumbOriginalName;
  late String thumbFileServer;
  late String thumbPath;
  late String description;
  late String chineseTeam;
  late String tags;
  late String lastViewTime;
  late int lastViewEpOrder;
  late String lastViewEpTitle;
  late int lastViewPictureRank;
  late int pinnedAt;

  ViewLog.fromJson(Map<String, dynamic> json) {
    this.id = json["id"];
    this.title = json["title"];
    this.author = json["author"];
    this.pagesCount = json["pagesCount"];
    this.epsCount = json["epsCount"];
    this.finished = json["finished"];
    this.categories = json["categories"];
    this.thumbOriginalName = json["thumbOriginalName"];
    this.thumbFileServer = json["thumbFileServer"];
    this.thumbPath = json["thumbPath"];
    this.description = json["description"];
    this.chineseTeam = json["chineseTeam"];
    this.tags = json["tags"];
    this.lastViewTime = json["lastViewTime"];
    this.lastViewEpOrder = json["lastViewEpOrder"];
    this.lastViewEpTitle = json["lastViewEpTitle"];
    this.lastViewPictureRank = json["lastViewPictureRank"];
    this.pinnedAt = json["pinnedAt"] ?? 0;
  }
}

/// 已下载漫画的信息
class DownloadComic {
  late String id;
  late String createdAt;
  late String updatedAt;
  late String title;
  late String author;
  late int pagesCount;
  late int epsCount;
  late bool finished;

  late String categories;
  late String thumbOriginalName;
  late String thumbFileServer;
  late String thumbPath;
  late String thumbLocalPath;

  late String description;
  late String chineseTeam;
  late String tags;
  late int selectedEpCount;
  late int selectedPictureCount;
  late int downloadEpCount;
  late int downloadPictureCount;
  late bool downloadFinished;
  late String downloadFinishedTime;
  late bool downloadFailed;
  late bool deleting;

  void copy(DownloadComic other) {
    this.id = other.id;
    this.createdAt = other.createdAt;
    this.updatedAt = other.updatedAt;
    this.title = other.title;
    this.author = other.author;
    this.pagesCount = other.pagesCount;
    this.epsCount = other.epsCount;
    this.finished = other.finished;
    this.categories = other.categories;
    this.thumbOriginalName = other.thumbOriginalName;
    this.thumbFileServer = other.thumbFileServer;
    this.thumbPath = other.thumbPath;
    this.description = other.description;
    this.chineseTeam = other.chineseTeam;
    this.tags = other.tags;
    this.selectedEpCount = other.selectedEpCount;
    this.selectedPictureCount = other.selectedPictureCount;
    this.downloadEpCount = other.downloadEpCount;
    this.downloadPictureCount = other.downloadPictureCount;
    this.downloadFinished = other.downloadFinished;
    this.downloadFinishedTime = other.downloadFinishedTime;
    this.downloadFailed = other.downloadFailed;
    this.thumbLocalPath = other.thumbLocalPath;
    // this.deleting = other.deleting;
  }

  DownloadComic.fromJson(Map<String, dynamic> json) {
    this.id = json["id"];
    this.createdAt = (json["createdAt"]);
    this.updatedAt = (json["updatedAt"]);
    this.title = json["title"];
    this.author = json["author"];
    this.pagesCount = json["pagesCount"];
    this.epsCount = json["epsCount"];
    this.finished = json["finished"];
    this.categories = json["categories"];
    this.thumbOriginalName = json["thumbOriginalName"];
    this.thumbFileServer = json["thumbFileServer"];
    this.thumbPath = json["thumbPath"];
    this.description = json["description"];
    this.chineseTeam = json["chineseTeam"];
    this.tags = json["tags"];
    this.selectedEpCount = json["selectedEpCount"];
    this.selectedPictureCount = json["selectedPictureCount"];
    this.downloadEpCount = json["downloadEpCount"];
    this.downloadPictureCount = json["downloadPictureCount"];
    this.downloadFinished = json["downloadFinished"];
    this.downloadFinishedTime = json["downloadFinishedTime"];
    this.downloadFailed = json["downloadFailed"];
    this.deleting = json["deleting"];
    this.thumbLocalPath = json["thumbLocalPath"];
  }
}

/// 已下载的章节信息
class DownloadEp {
  late String comicId;
  late String id;
  late String updatedAt;

  late int epOrder;
  late String title;

  late bool fetchedPictures;
  late int selectedPictureCount;
  late int downloadPictureCount;
  late bool downloadFinish;
  late String downloadFinishTime;
  late bool downloadFailed;

  DownloadEp.fromJson(Map<String, dynamic> json) {
    this.comicId = json["comicId"];
    this.id = json["id"];
    this.epOrder = json["epOrder"];
    this.title = json["title"];

    this.fetchedPictures = json["fetchedPictures"];
    this.selectedPictureCount = json["selectedPictureCount"];
    this.downloadPictureCount = json["downloadPictureCount"];
    this.downloadFinish = json["downloadFinish"];
    this.downloadFinishTime = json["downloadFinishTime"];
    this.downloadFailed = json["downloadFailed"];
  }
}

/// 游戏的分页
class GamePage extends Page {
  late List<GameSimple> docs;

  GamePage.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.docs = List.of(json["docs"])
        .map((e) => Map<String, dynamic>.of(e))
        .map((e) => GameSimple.fromJson(e))
        .toList();
  }
}

/// 游戏的简要信息
class GameSimple {
  late String id;
  late String title;
  late String version;
  late RemoteImageInfo icon;
  late String publisher;
  late bool adult;
  late bool suggest;
  late int likesCount;
  late bool android;
  late bool ios;

  GameSimple.fromJson(Map<String, dynamic> json) {
    this.id = json["_id"];
    this.title = json["title"];
    this.version = json["version"];
    this.icon = RemoteImageInfo.fromJson(json["icon"]);
    this.publisher = json["publisher"];
    this.adult = json["adult"];
    this.suggest = json["suggest"];
    this.likesCount = json["likesCount"];
    this.android = json["android"];
    this.ios = json["ios"];
  }
}

/// 游戏详情
class GameInfo extends GameSimple {
  late String description;
  late String updateContent;
  late String videoLink;
  late List<RemoteImageInfo> screenshots;
  late int commentsCount;
  late int downloadsCount;
  late bool isLiked;
  late List<String> androidLinks;
  late double androidSize;
  late List<String> iosLinks;
  late double iosSize;
  late String updatedAt;
  late String createdAt;

  GameInfo.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.description = json["description"];
    this.updateContent = json["updateContent"];
    this.videoLink = json["videoLink"];
    this.screenshots = List.of(json["screenshots"])
        .map((e) => Map<String, dynamic>.of(e))
        .map((e) => RemoteImageInfo.fromJson(e))
        .toList();
    this.commentsCount = json["commentsCount"];
    this.downloadsCount = json["downloadsCount"];
    this.isLiked = json["isLiked"];
    this.androidLinks = List.of(json["androidLinks"]).map((e) => "$e").toList();
    this.androidSize = double.parse(json["androidSize"].toString());
    this.iosLinks = List.of(json["iosLinks"]).map((e) => "$e").toList();
    this.iosSize = double.parse(json["iosSize"].toString());
    this.updatedAt = json["updated_at"];
    this.createdAt = json["created_at"];
  }
}

/// 我的评论页面分页
class MyCommentsPage extends Page {
  late List<MyComment> docs;

  MyCommentsPage.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.docs =
        List.of(json["docs"]).map((e) => MyComment.fromJson(e)).toList();
  }
}

/// 我的评论
class MyComment {
  late String id;
  late String content;
  late bool hide;
  late String createdAt;
  late int likesCount;
  late int commentsCount;
  late bool isLiked;
  late MyCommentComic comic;

  MyComment.fromJson(Map<String, dynamic> json) {
    this.id = json["_id"];
    this.content = json["content"];
    this.hide = json["hide"];
    this.createdAt = json["created_at"];
    this.likesCount = json["likesCount"];
    this.commentsCount = json["commentsCount"];
    this.isLiked = json["isLiked"];
    this.comic = MyCommentComic.fromJson(json["_comic"]);
  }
}

/// 我的评论漫画简要信息
class MyCommentComic {
  late String id;
  late String title;

  MyCommentComic.fromJson(Map<String, dynamic> json) {
    this.id = json["_id"];
    this.title = json["title"];
  }
}

/// 子评论分页
class CommentChildrenPage extends Page {
  late List<CommentChild> docs;

  CommentChildrenPage.fromJson(Map<String, dynamic> json)
      : super.fromJson(json) {
    this.docs = [];
    if (json["docs"] != null) {
      docs.addAll(
          List.of(json["docs"]).map((e) => CommentChild.fromJson(e)).toList());
    }
  }
}

/// 子评论
class CommentChild extends ChildOfComment {
  late String comic;

  CommentChild.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.comic = json["_comic"];
  }
}

/// 漫画评论分页
class GameCommentPage extends Page {
  late List<GameComment> docs;

  GameCommentPage.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.docs = List.from(json["docs"])
        .map((e) => Map<String, dynamic>.from(e))
        .map((e) => GameComment.fromJson(e))
        .toList();
  }
}

/// 游戏评论
class GameComment extends CommentBase {
  late String game;

  GameComment.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.game = json["_game"];
  }
}

/// 子评论分页
class GameCommentChildrenPage extends Page {
  late List<GameCommentChild> docs;

  GameCommentChildrenPage.fromJson(Map<String, dynamic> json)
      : super.fromJson(json) {
    this.docs = [];
    if (json["docs"] != null) {
      docs.addAll(List.of(json["docs"])
          .map((e) => GameCommentChild.fromJson(e))
          .toList());
    }
  }
}

/// 子评论
class GameCommentChild extends ChildOfComment {
  late String game;

  GameCommentChild.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    this.game = json["_game"];
  }
}

class Collection {
  late String title;
  late List<ComicSimple> comics;

  Collection.fromJson(Map<String, dynamic> json) {
    this.title = json["title"];
    this.comics = List.from(json["comics"])
        .map((e) => Map<String, dynamic>.from(e))
        .map((e) => ComicSimple.fromJson(e))
        .toList();
  }
}

class PkzArchive {
  PkzArchive({
    required this.coverPath,
    required this.authorAvatarPath,
    required this.comics,
    required this.comicCount,
    required this.volumesCount,
    required this.chapterCount,
    required this.pictureCount,
  });

  late final String coverPath;
  late final String authorAvatarPath;
  late final List<PkzComic> comics;
  late final int comicCount;
  late final int volumesCount;
  late final int chapterCount;
  late final int pictureCount;

  PkzArchive.fromJson(Map<String, dynamic> json) {
    coverPath = json['cover_path'];
    authorAvatarPath = json['author_avatar_path'];
    comics =
        List.from(json['comics']).map((e) => PkzComic.fromJson(e)).toList();
    comicCount = json['comic_count'];
    volumesCount = json['volumes_count'];
    chapterCount = json['chapter_count'];
    pictureCount = json['picture_count'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['cover_path'] = coverPath;
    _data['author_avatar_path'] = authorAvatarPath;
    _data['comics'] = comics.map((e) => e.toJson()).toList();
    _data['comic_count'] = comicCount;
    _data['volumes_count'] = volumesCount;
    _data['chapter_count'] = chapterCount;
    _data['picture_count'] = pictureCount;
    return _data;
  }
}

class PkzComic {
  PkzComic({
    required this.id,
    required this.title,
    required this.categories,
    required this.tags,
    required this.updatedAt,
    required this.createdAt,
    required this.description,
    required this.chineseTeam,
    required this.finished,
    required this.coverPath,
    required this.authorAvatarPath,
    required this.volumes,
    required this.volumesCount,
    required this.chapterCount,
    required this.pictureCount,
    required this.idx,
  });

  late final String id;
  late final String title;
  late final List<String> categories;
  late final List<String> tags;
  late final int updatedAt;
  late final int createdAt;
  late final String description;
  late final String chineseTeam;
  late final bool finished;
  late final String coverPath;
  late final String authorAvatarPath;
  late final List<PkzVolume> volumes;
  late final int volumesCount;
  late final int chapterCount;
  late final int pictureCount;
  late final int idx;
  late final String author;
  late final String authorId;

  PkzComic.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    categories = List.castFrom<dynamic, String>(json['categories']);
    tags = List.castFrom<dynamic, String>(json['tags']);
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    description = json['description'];
    chineseTeam = json['chinese_team'];
    finished = json['finished'];
    coverPath = json['cover_path'];
    authorAvatarPath = json['author_avatar_path'];
    volumes =
        List.from(json['volumes']).map((e) => PkzVolume.fromJson(e)).toList();
    volumesCount = json['volumes_count'];
    chapterCount = json['chapter_count'];
    pictureCount = json['picture_count'];
    idx = json['idx'];
    author = json['author'];
    authorId = json['author_id'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['id'] = id;
    _data['title'] = title;
    _data['categories'] = categories;
    _data['tags'] = tags;
    _data['updated_at'] = updatedAt;
    _data['created_at'] = createdAt;
    _data['description'] = description;
    _data['chinese_team'] = chineseTeam;
    _data['finished'] = finished;
    _data['cover_path'] = coverPath;
    _data['author_avatar_path'] = authorAvatarPath;
    _data['volumes'] = volumes.map((e) => e.toJson()).toList();
    _data['volumes_count'] = volumesCount;
    _data['chapter_count'] = chapterCount;
    _data['picture_count'] = pictureCount;
    _data['idx'] = idx;
    _data['author'] = author;
    _data['author_id'] = authorId;
    return _data;
  }
}

class PkzVolume {
  PkzVolume({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.createdAt,
    required this.coverPath,
    required this.chapters,
    required this.chapterCount,
    required this.pictureCount,
    required this.idx,
  });

  late final String id;
  late final String title;
  late final int updatedAt;
  late final int createdAt;
  late final String coverPath;
  late final List<PkzChapter> chapters;
  late final int chapterCount;
  late final int pictureCount;
  late final int idx;

  PkzVolume.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    coverPath = json['cover_path'];
    chapters =
        List.from(json['chapters']).map((e) => PkzChapter.fromJson(e)).toList();
    chapterCount = json['chapter_count'];
    pictureCount = json['picture_count'];
    idx = json['idx'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['id'] = id;
    _data['title'] = title;
    _data['updated_at'] = updatedAt;
    _data['created_at'] = createdAt;
    _data['cover_path'] = coverPath;
    _data['chapters'] = chapters.map((e) => e.toJson()).toList();
    _data['chapter_count'] = chapterCount;
    _data['picture_count'] = pictureCount;
    _data['idx'] = idx;
    return _data;
  }
}

class PkzChapter {
  PkzChapter({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.createdAt,
    required this.coverPath,
    required this.pictures,
    required this.pictureCount,
    required this.idx,
  });

  late final String id;
  late final String title;
  late final int updatedAt;
  late final int createdAt;
  late final String coverPath;
  late final List<PkzPicture> pictures;
  late final int pictureCount;
  late final int idx;

  PkzChapter.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    updatedAt = json['updated_at'];
    createdAt = json['created_at'];
    coverPath = json['cover_path'];
    pictures =
        List.from(json['pictures']).map((e) => PkzPicture.fromJson(e)).toList();
    pictureCount = json['picture_count'];
    idx = json['idx'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['id'] = id;
    _data['title'] = title;
    _data['updated_at'] = updatedAt;
    _data['created_at'] = createdAt;
    _data['cover_path'] = coverPath;
    _data['pictures'] = pictures.map((e) => e.toJson()).toList();
    _data['picture_count'] = pictureCount;
    _data['idx'] = idx;
    return _data;
  }
}

class PkzPicture {
  PkzPicture({
    required this.id,
    required this.title,
    required this.width,
    required this.height,
    required this.format,
    required this.picturePath,
    required this.idx,
  });

  late final String id;
  late final String title;
  late final int width;
  late final int height;
  late final String format;
  late final String picturePath;
  late final int idx;

  PkzPicture.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    width = json['width'];
    height = json['height'];
    format = json['format'];
    picturePath = json['picture_path'];
    idx = json['idx'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['id'] = id;
    _data['title'] = title;
    _data['width'] = width;
    _data['height'] = height;
    _data['format'] = format;
    _data['picture_path'] = picturePath;
    _data['idx'] = idx;
    return _data;
  }
}

class Knight extends BasicUser {
  late final String role;
  late final String character;
  late final int comicsUploaded;

  Knight.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    role = json['role'];
    character = json['character'];
    comicsUploaded = json['comicsUploaded'];
  }
}

class PkzComicViewLog {
  PkzComicViewLog({
    required this.fileName,
    required this.lastViewComicId,
    required this.filePath,
    required this.lastViewComicTitle,
    required this.lastViewEpId,
    required this.lastViewEpName,
    required this.lastViewPictureRank,
    required this.lastViewTime,
  });

  late final String fileName;
  late final String lastViewComicId;
  late final String filePath;
  late final String lastViewComicTitle;
  late final String lastViewEpId;
  late final String lastViewEpName;
  late final int lastViewPictureRank;
  late final String lastViewTime;

  PkzComicViewLog.fromJson(Map<String, dynamic> json) {
    fileName = json['fileName'];
    lastViewComicId = json['lastViewComicId'];
    filePath = json['filePath'];
    lastViewComicTitle = json['lastViewComicTitle'];
    lastViewEpId = json['lastViewEpId'];
    lastViewEpName = json['lastViewEpName'];
    lastViewPictureRank = json['lastViewPictureRank'];
    lastViewTime = json['lastViewTime'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['fileName'] = fileName;
    _data['lastViewComicId'] = lastViewComicId;
    _data['filePath'] = filePath;
    _data['lastViewComicTitle'] = lastViewComicTitle;
    _data['lastViewEpId'] = lastViewEpId;
    _data['lastViewEpName'] = lastViewEpName;
    _data['lastViewPictureRank'] = lastViewPictureRank;
    _data['lastViewTime'] = lastViewTime;
    return _data;
  }
}

class ProInfoAll {
  ProInfoAll({
    required this.proInfoAf,
    required this.proInfoPat,
  });

  late final ProInfoAf proInfoAf;
  late final ProInfoPat proInfoPat;

  ProInfoAll.fromJson(Map<String, dynamic> json) {
    proInfoAf = ProInfoAf.fromJson(json['pro_info_af']);
    proInfoPat = ProInfoPat.fromJson(json['pro_info_pat']);
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['pro_info_normal'] = proInfoAf.toJson();
    _data['pro_info_pat'] = proInfoPat.toJson();
    return _data;
  }
}

class ProInfoAf {
  ProInfoAf({
    required this.isPro,
    required this.expire,
  });

  late final bool isPro;
  late final int expire;

  ProInfoAf.fromJson(Map<String, dynamic> json) {
    isPro = json['is_pro'];
    expire = json['expire'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['is_pro'] = isPro;
    _data['expire'] = expire;
    return _data;
  }
}

class ProInfoPat {
  ProInfoPat({
    required this.isPro,
    required this.patId,
    required this.bindUid,
    required this.requestDelete,
    required this.reBind,
    required this.errorType,
    required this.errorMsg,
    required this.accessKey,
  });

  late final bool isPro;
  late final String patId;
  late final String bindUid;
  late final int requestDelete;
  late final int reBind;
  late final int errorType;
  late final String errorMsg;
  late final String accessKey;

  ProInfoPat.fromJson(Map<String, dynamic> json) {
    isPro = json['is_pro'];
    patId = json['pat_id'];
    bindUid = json['bind_uid'];
    requestDelete = json['request_delete'];
    reBind = json['re_bind'];
    errorType = json['error_type'];
    errorMsg = json['error_msg'];
    accessKey = json['access_key'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['is_pro'] = isPro;
    _data['pat_id'] = patId;
    _data['bind_uid'] = bindUid;
    _data['request_delete'] = requestDelete;
    _data['re_bind'] = reBind;
    _data['error_type'] = errorType;
    _data['error_msg'] = errorMsg;
    _data['access_key'] = accessKey;
    return _data;
  }
}

class ForgotPasswordResult {
  ForgotPasswordResult({
    required this.question1,
    required this.question2,
    required this.question3,
  });

  late final String question1;
  late final String question2;
  late final String question3;

  ForgotPasswordResult.fromJson(Map<String, dynamic> json) {
    question1 = json['question1'];
    question2 = json['question2'];
    question3 = json['question3'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['question1'] = question1;
    _data['question2'] = question2;
    _data['question3'] = question3;
    return _data;
  }
}

class ResetPasswordResult {
  ResetPasswordResult({
    required this.password,
  });

  late final String password;

  ResetPasswordResult.fromJson(Map<String, dynamic> json) {
    password = json['password'];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['password'] = password;
    return _data;
  }
}

/// 订阅
class ComicSubscribe {
  late String id;
  late String title;
  late String author;
  late int pagesCount;
  late int epsCount;
  late bool finished;
  late String categories;
  late String thumbOriginalName;
  late String thumbFileServer;
  late String thumbPath;
  late String description;
  late String chineseTeam;
  late String tags;
  late int likesCount;
  late String subscribeTime;
  late String updateSubscribeTime;
  late int newEpCount;

  ComicSubscribe.fromJson(Map<String, dynamic> json) {
    print(json);
    this.id = json["id"];
    this.title = json["title"];
    this.author = json["author"];
    this.pagesCount = json["pagesCount"];
    this.epsCount = json["epsCount"];
    this.finished = json["finished"];
    this.categories = json["categories"];
    this.thumbOriginalName = json["thumbOriginalName"];
    this.thumbFileServer = json["thumbFileServer"];
    this.thumbPath = json["thumbPath"];
    this.description = json["description"];
    this.chineseTeam = json["chineseTeam"];
    this.tags = json["tags"];
    this.likesCount = json["likesCount"];
    this.subscribeTime = json["subscribeTime"];
    this.updateSubscribeTime = json["updateSubscribeTime"];
    this.newEpCount = json["newEpCount"];
  }

  Map<String, dynamic> toSimpleJson() {
    final _data = <String, dynamic>{};
    _data['id'] = id;
    _data['_id'] = id;
    _data['title'] = title;
    _data['author'] = author;
    _data['pagesCount'] = pagesCount;
    _data['epsCount'] = epsCount;
    _data['finished'] = finished;
    _data['categories'] = jsonDecode(categories);
    _data['thumbOriginalName'] = thumbOriginalName;
    _data['thumbFileServer'] = thumbFileServer;
    _data['thumbPath'] = thumbPath;
    _data['description'] = description;
    _data['chineseTeam'] = chineseTeam;
    _data['tags'] = tags;
    _data['likesCount'] = likesCount;
    _data['thumb'] = jsonDecode(jsonEncode(RemoteImageInfo.fromJson({
      "originalName": thumbOriginalName,
      "fileServer": thumbFileServer,
      "path": thumbPath
    })));
    _data['subscribeTime'] = subscribeTime;
    _data['updateSubscribeTime'] = updateSubscribeTime;
    _data['newEpCount'] = newEpCount;
    return _data;
  }
}

/// 本地收藏夹文件夹
class LocalFavoriteFolder {
  late String id;
  late String name;
  late int createdAt;
  late int updatedAt;
  late int deletedAt;

  LocalFavoriteFolder.fromJson(Map<String, dynamic> json) {
    this.id = json["id"];
    this.name = json["name"];
    this.createdAt = json["createdAt"];
    this.updatedAt = json["updatedAt"];
    this.deletedAt = json["deletedAt"];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['id'] = id;
    _data['name'] = name;
    _data['createdAt'] = createdAt;
    _data['updatedAt'] = updatedAt;
    _data['deletedAt'] = deletedAt;
    return _data;
  }
}

/// 本地收藏夹漫画
class LocalFavoriteComic {
  late String comicId;
  late String folderId;
  String? info;
  late int createdAt;
  late int updatedAt;
  late int deletedAt;

  LocalFavoriteComic.fromJson(Map<String, dynamic> json) {
    this.comicId = json["comicId"];
    this.folderId = json["folderId"];
    this.info = json["info"];
    this.createdAt = json["createdAt"];
    this.updatedAt = json["updatedAt"];
    this.deletedAt = json["deletedAt"];
  }

  Map<String, dynamic> toJson() {
    final _data = <String, dynamic>{};
    _data['comicId'] = comicId;
    _data['folderId'] = folderId;
    _data['info'] = info;
    _data['createdAt'] = createdAt;
    _data['updatedAt'] = updatedAt;
    _data['deletedAt'] = deletedAt;
    return _data;
  }
}
