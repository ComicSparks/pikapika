import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pikapika/basic/Entities.dart';

/// 使用MethodChannel与平台通信

final method = Method._();

class Method {
  /// 禁止其他页面构造此类
  Method._();

  /// channel
  final MethodChannel _channel = const MethodChannel("method");

  /// 平铺调用, 为了直接与golang进行通信
  Future<dynamic> _flatInvoke(String method, dynamic params) {
    return _channel.invokeMethod("flatInvoke", {
      "method": method,
      "params": params is String ? params : jsonEncode(params),
    });
  }

  /// 读取配置文件
  Future<String> loadProperty(String propertyName, String defaultValue) async {
    return await _flatInvoke("loadProperty", {
      "name": propertyName,
      "defaultValue": defaultValue,
    });
  }

  /// 远程推荐链接（来自 pikapika-config）
  Future<Map<String, String>> configLinks() async {
    final rsp = await _flatInvoke("configLinks", "");
    final decoded = jsonDecode(rsp);
    if (decoded is! Map) {
      return {};
    }
    return decoded.map((key, value) => MapEntry("$key", "$value"));
  }

  /// 应用配置（版本信息、下载地址等）
  Future<Map<String, dynamic>> appConfig() async {
    final rsp = await _flatInvoke("appConfig", "");
    final decoded = jsonDecode(rsp);
    if (decoded is! Map) {
      return {};
    }
    return Map<String, dynamic>.from(decoded);
  }

  /// 保存配置文件
  Future<dynamic> saveProperty(String propertyName, String value) {
    return _flatInvoke("saveProperty", {
      "name": propertyName,
      "value": value,
    });
  }

  /// 获取当前的分流
  Future<String> getSwitchAddress() async {
    return await _flatInvoke("getSwitchAddress", "");
  }

  /// 更换分流
  Future<dynamic> setSwitchAddress(String switchAddress) async {
    return await _flatInvoke("setSwitchAddress", switchAddress);
  }

  /// 获取当前的图片分流
  Future<String> getImageSwitchAddress() async {
    return await _flatInvoke("getImageSwitchAddress", "");
  }

  /// 更换图片分流
  Future<dynamic> setImageSwitchAddress(String switchAddress) async {
    return await _flatInvoke("setImageSwitchAddress", switchAddress);
  }

  Future<String> getUseApiClientLoadImage() async {
    return await _flatInvoke("getUseApiClientLoadImage", "");
  }

  Future<dynamic> setUseApiClientLoadImage(String switchAddress) async {
    return await _flatInvoke("setUseApiClientLoadImage", switchAddress);
  }

  /// 获取代理
  Future<String> getProxy() async {
    return await _flatInvoke("getProxy", "");
  }

  /// 更换当前的代理
  Future<dynamic> setProxy(String proxy) async {
    return await _flatInvoke("setProxy", proxy);
  }

  /// 获取用户名
  Future<String> getUsername() async {
    return await _flatInvoke("getUsername", "");
  }

  /// 设置用户名
  Future<dynamic> setUsername(String username) async {
    return await _flatInvoke("setUsername", username);
  }

  /// 获取密码
  Future<String> getPassword() async {
    return await _flatInvoke("getPassword", "");
  }

  /// 设置密码
  Future<dynamic> setPassword(String password) async {
    return await _flatInvoke("setPassword", password);
  }

  /// 预登录, 程序启用时会调用
  /// 如果又账号密码或token, 且登录成功, 将返回true
  Future<bool> preLogin() async {
    String rsp = await _flatInvoke("preLogin", "");
    return rsp == "true";
  }

  /// 登录
  Future<dynamic> login() async {
    return _flatInvoke("login", "");
  }

  /// 注册
  Future<dynamic> register(
      String email,
      String name,
      String password,
      String gender,
      String birthday,
      String question1,
      String answer1,
      String question2,
      String answer2,
      String question3,
      String answer3) {
    return _flatInvoke("register", {
      "email": email,
      "name": name,
      "password": password,
      "gender": gender,
      "birthday": birthday,
      "question1": question1,
      "answer1": answer1,
      "question2": question2,
      "answer2": answer2,
      "question3": question3,
      "answer3": answer3,
    });
  }

  /// 退出登录
  Future<dynamic> clearToken() {
    return _flatInvoke("clearToken", "");
  }

  /// 获取用户自身基础信息
  Future<UserProfile> userProfile() async {
    String rsp = await _flatInvoke("userProfile", "");
    return UserProfile.fromJson(json.decode(rsp));
  }

  /// 打卡
  Future<dynamic> punchIn() {
    return _flatInvoke("punchIn", "");
  }

  /// 使用服务器地址以及路径获取图片用户显示
  /// 如果本地有缓存会返回路径, 如果本地没有缓存会下载再返回路径, 没有下载成功则会抛出异常
  Future<RemoteImageData> remoteImageData(
      String fileServer, String path) async {
    var data = await _flatInvoke("remoteImageData", {
      "fileServer": fileServer,
      "path": path,
    });
    return RemoteImageData.fromJson(json.decode(data));
  }

  /// 功能同上, 用于预加载
  Future<dynamic> remoteImagePreload(String fileServer, String path) async {
    return _flatInvoke("remoteImagePreload", {
      "fileServer": fileServer,
      "path": path,
    });
  }

  /// 获取已经下载好图片的保存位置
  Future<String> downloadImagePath(String path) async {
    return await _flatInvoke("downloadImagePath", path);
  }

  /// 获取分类
  Future<List<Category>> categories() async {
    String rsp = await _flatInvoke("categories", "");
    List list = json.decode(rsp);
    return list.map((e) => Category.fromJson(e)).toList();
  }

  /// 列出漫画
  /// [sort] 排序方式
  /// [page] 页数
  /// [category] 分类
  /// [tag] 标签
  /// [creatorId] 创建人ID
  /// [chineseTeam] 汉化组名称
  /// * 几种条件使用且的关系
  Future<ComicsPage> comics(
    String sort,
    int page, {
    String category = "",
    String tag = "",
    String author = "",
    String creatorId = "",
    String chineseTeam = "",
  }) async {
    String rsp = await _flatInvoke("comics", {
      "category": category,
      "tag": tag,
      "author": author,
      "creatorId": creatorId,
      "chineseTeam": chineseTeam,
      "sort": sort,
      "page": page,
    });
    return ComicsPage.fromJson(json.decode(rsp));
  }

  /// 搜索漫画
  Future<ComicsPage> searchComics(String keyword, String sort, int page) {
    return searchComicsInCategories(keyword, sort, page, []);
  }

  /// 搜索漫画, 在多个分类中
  Future<ComicsPage> searchComicsInCategories(
      String keyword, String sort, int page, List<String> categories) async {
    String rsp = await _flatInvoke("searchComics", {
      "keyword": keyword,
      "sort": sort,
      "page": page,
      "categories": categories,
    });
    return ComicsPage.fromJson(json.decode(rsp));
  }

  /// 随机漫画
  Future<List<ComicSimple>> randomComics() async {
    String data = await _flatInvoke("randomComics", "");
    return List.of(jsonDecode(data))
        .map((e) => Map<String, dynamic>.of(e))
        .map((e) => ComicSimple.fromJson(e))
        .toList();
  }

  /// 漫画榜单
  /// [type] 榜单类型 H24 D7 D30
  Future<List<ComicSimple>> leaderboard(String type) async {
    String data = await _flatInvoke("leaderboard", type);
    return List.of(jsonDecode(data))
        .map((e) => Map<String, dynamic>.of(e))
        .map((e) => ComicSimple.fromJson(e))
        .toList();
  }

  /// 获取漫画详情
  Future<ComicInfo> comicInfo(String comicId, bool ignoreHistory) async {
    String rsp =
        await _flatInvoke(ignoreHistory ? "comicInfoA" : "comicInfo", comicId);
    return ComicInfo.fromJson(json.decode(rsp));
  }

  /// 分页获取漫画的章节
  Future<EpPage> comicEpPage(String comicId, int page) async {
    String rsp = await _flatInvoke("comicEpPage", {
      "comicId": comicId,
      "page": page,
    });
    return EpPage.fromJson(json.decode(rsp));
  }

  /// 分页获取一个章节的图片, 并且需要图片的质量参数
  Future<PicturePage> comicPicturePageWithQuality(
      String comicId, int epOrder, int page, String quality) async {
    String data = await _flatInvoke("comicPicturePageWithQuality", {
      "comicId": comicId,
      "epOrder": epOrder,
      "page": page,
      "quality": quality,
    });
    return PicturePage.fromJson(json.decode(data));
  }

  /// 对漫画进行点赞/取消点赞操作
  Future<String> switchLike(String comicId) async {
    return await _flatInvoke("switchLike", comicId);
  }

  /// 对漫画进行收藏/取消收藏操作
  Future<String> switchFavourite(String comicId) async {
    return await _flatInvoke("switchFavourite", comicId);
  }

  /// 收藏漫画列表
  Future<ComicsPage> favouriteComics(String sort, int page) async {
    var rsp = await _flatInvoke("favouriteComics", {
      "sort": sort,
      "page": page,
    });
    return ComicsPage.fromJson(json.decode(rsp));
  }

  /// 看了此漫画的人还看了...
  Future<List<ComicSimple>> recommendation(String comicId) async {
    String rsp = await _flatInvoke("recommendation", comicId);
    List list = json.decode(rsp);
    return list.map((e) => ComicSimple.fromJson(e)).toList();
  }

  /// 对漫画发送评论
  Future<dynamic> postComment(String comicId, String content) {
    return _flatInvoke("postComment", {
      "comicId": comicId,
      "content": content,
    });
  }

  /// 发送子评论
  Future<dynamic> postChildComment(String commentId, String content) {
    return _flatInvoke("postChildComment", {
      "commentId": commentId,
      "content": content,
    });
  }

  /// 漫画的评论列表
  Future<CommentPage> comments(String comicId, int page) async {
    var rsp = await _flatInvoke("comments", {
      "comicId": comicId,
      "page": page,
    });
    return CommentPage.fromJson(json.decode(rsp));
  }

  /// 拉取子评论
  Future<CommentChildrenPage> commentChildren(
    String comicId,
    String commentId,
    int page,
  ) async {
    var rsp = await _flatInvoke("commentChildren", {
      "comicId": comicId,
      "commentId": commentId,
      "page": page,
    });
    return CommentChildrenPage.fromJson(json.decode(rsp));
  }

  /// 喜欢/取消喜欢 一条评论
  Future switchLikeComment(String commentId, String comicId) {
    return _flatInvoke("switchLikeComment", {
      "commentId": commentId,
      "comicId": comicId,
    });
  }

  /// 我的评论列表
  Future<MyCommentsPage> myComments(int page) async {
    String response = await _flatInvoke("myComments", "$page");
    return MyCommentsPage.fromJson(jsonDecode(response));
  }

  /// 浏览记录
  Future<List<ViewLog>> viewLogPage(int offset, int limit) async {
    var data = await _flatInvoke("viewLogPage", {
      "offset": offset,
      "limit": limit,
    });
    List list = json.decode(data);
    return list.map((e) => ViewLog.fromJson(e)).toList();
  }

  /// 清除所有的浏览记录
  Future<dynamic> clearAllViewLog() {
    return _flatInvoke("clearAllViewLog", "");
  }

  /// 删除一个漫画的浏览记录
  Future<dynamic> deleteViewLog(String id) {
    return _flatInvoke("deleteViewLog", id);
  }

  /// 删除一个漫画的浏览记录
  Future<dynamic> viewComic(String id) {
    return _flatInvoke("viewComic", id);
  }

  /// 游戏列表
  Future<GamePage> games(int page) async {
    var data = await _flatInvoke("games", "$page");
    return GamePage.fromJson(json.decode(data));
  }

  /// 游戏详情
  Future<GameInfo> game(String gameId) async {
    var data = await _flatInvoke("game", gameId);
    return GameInfo.fromJson(json.decode(data));
  }

  /// 游戏的评论列表
  Future<GameCommentPage> gameComments(String gameId, int page) async {
    var rsp = await _flatInvoke("gameComments", {
      "gameId": gameId,
      "page": page,
    });
    return GameCommentPage.fromJson(json.decode(rsp));
  }

  /// 对游戏发送评论
  Future<dynamic> postGameComment(String gameId, String content) {
    return _flatInvoke("postGameComment", {
      "gameId": gameId,
      "content": content,
    });
  }

  /// 拉取游戏子评论
  Future<GameCommentChildrenPage> gameCommentChildren(
    String gameId,
    String commentId,
    int page,
  ) async {
    var rsp = await _flatInvoke("gameCommentChildren", {
      "gameId": gameId,
      "commentId": commentId,
      "page": page,
    });
    return GameCommentChildrenPage.fromJson(json.decode(rsp));
  }

  /// 喜欢/取消喜欢 一条游戏评论
  Future switchLikeGameComment(String commentId, String gameId) {
    return _flatInvoke("switchLikeGameComment", {
      "commentId": commentId,
      "gameId": gameId,
    });
  }

  /// 发送游戏子评论
  Future<dynamic> postGameChildComment(String commentId, String content) {
    return _flatInvoke("postGameChildComment", {
      "commentId": commentId,
      "content": content,
    });
  }

  /// 清理网络缓存
  Future cleanNetworkCache() {
    return _flatInvoke("cleanNetworkCache", "");
  }

  /// 清理图片缓存
  Future cleanImageCache() {
    return _flatInvoke("cleanImageCache", "");
  }

  /// 清理缓存
  Future clean() {
    return _flatInvoke("clean", "");
  }

  /// 清理[expireSec]秒以前的缓存
  Future autoClean(String expireSec) {
    return _flatInvoke("autoClean", expireSec);
  }

  /// 保存当前浏览器的进度
  Future storeViewEp(
      String comicId, int epOrder, String epTitle, int pictureRank) {
    return _flatInvoke("storeViewEp", {
      "comicId": comicId,
      "epOrder": epOrder,
      "epTitle": epTitle,
      "pictureRank": pictureRank,
    });
  }

  /// 加载浏览进度
  Future<ViewLog?> loadView(String comicId) async {
    String data = await _flatInvoke("loadView", comicId);
    if (data == "") {
      return null;
    }
    return ViewLog.fromJson(jsonDecode(data));
  }

  /// 下载是否在后台运行
  Future<bool> downloadRunning() async {
    String rsp = await _flatInvoke("downloadRunning", "");
    return rsp == "true";
  }

  /// 暂停/继续 下载
  Future<dynamic> setDownloadRunning(bool status) async {
    return _flatInvoke("setDownloadRunning", "$status");
  }

  /// 下载漫画
  Future<dynamic> createDownload(
      Map<String, dynamic> comic, List<Map<String, dynamic>> epList) async {
    return _flatInvoke("createDownload", {
      "comic": comic,
      "epList": epList,
    });
  }

  /// 追加下载的章节
  Future<dynamic> addDownload(
      Map<String, dynamic> comic, List<Map<String, dynamic>> epList) async {
    await _flatInvoke("addDownload", {
      "comic": comic,
      "epList": epList,
    });
  }

  /// 下载详情
  Future<DownloadComic?> loadDownloadComic(String comicId) async {
    var data = await _flatInvoke("loadDownloadComic", comicId);
    // 未找到 且 未异常
    if (data == "") {
      return null;
    }
    return DownloadComic.fromJson(json.decode(data));
  }

  /// 所有下载
  Future<List<DownloadComic>> allDownloads(String search,
      {String customFolder = ""}) async {
    var data = await _flatInvoke("allDownloads", {
      "search": search,
      "customFolder": customFolder,
    });
    data = jsonDecode(data);
    if (data == null) {
      return [];
    }
    List list = data;
    return list.map((e) => DownloadComic.fromJson(e)).toList();
  }

  Future<List<String>> allCustomFolders() async {
    var data = await _flatInvoke("allCustomFolders", "");
    return List.of(jsonDecode(data)).map((e) => e.toString()).toList();
  }

  /// 删除一个下载
  Future<dynamic> deleteDownloadComic(String comicId) async {
    return _flatInvoke("deleteDownloadComic", comicId);
  }

  Future<dynamic> moveDownloadComic(
      List<String> comicIdList, String customFolder) {
    return _flatInvoke("moveDownloadComic", {
      "comicIdList": comicIdList,
      "customFolder": customFolder,
    });
  }

  /// 所有下载的EP
  Future<List<DownloadEp>> downloadEpList(String comicId) async {
    var data = await _flatInvoke("downloadEpList", comicId);
    List list = json.decode(data);
    return list.map((e) => DownloadEp.fromJson(e)).toList();
  }

  /// 下载漫画这个EP下的图片
  Future<List<DownloadPicture>> downloadPicturesByEpId(String epId) async {
    var data = await _flatInvoke("downloadPicturesByEpId", epId);
    List list = json.decode(data);
    return list.map((e) => DownloadPicture.fromJson(e)).toList();
  }

  /// 重置所有下载失败的漫画
  Future<dynamic> resetFailed() async {
    return _flatInvoke("resetAllDownloads", "");
  }

  /// 导出下载的漫画到zip
  Future<dynamic> exportComicDownload(String comicId, String dir, String name) {
    return _flatInvoke("exportComicDownload", {
      "comicId": comicId,
      "dir": dir,
      "name": name,
    });
  }

  /// 导出下载的漫画到pki
  Future<dynamic> exportComicDownloadToPki(
      String comicId, String dir, String name) {
    return _flatInvoke("exportComicDownloadToPki", {
      "comicId": comicId,
      "dir": dir,
      "name": name,
    });
  }

  /// 导出下载的图片到HTML+JPG (即使没有下载完成)
  Future<dynamic> exportComicJpegsEvenNotFinish(
    String comicId,
    String dir,
    String name,
  ) {
    return _flatInvoke("exportComicJpegsEvenNotFinish", {
      "comicId": comicId,
      "dir": dir,
      "name": name,
    });
  }

  /// 导出下载的图片到HTML+JPG
  Future<dynamic> exportComicDownloadToJPG(
    String comicId,
    String dir,
    String name,
  ) {
    return _flatInvoke("exportComicDownloadToJPG", {
      "comicId": comicId,
      "dir": dir,
      "name": name,
    });
  }

  /// 导出下载的图片到HTML+JPG
  Future<dynamic> exportComicDownloadToPDF(
    String comicId,
    String dir,
    String name,
  ) {
    return _flatInvoke("exportComicDownloadToPDF", {
      "comicId": comicId,
      "dir": dir,
      "name": name,
    });
  }

  /// 导出下载的图片到HTML+JPG
  Future<dynamic> exportComicDownloadToEpub(
    String comicId,
    String dir,
    String name,
  ) {
    return _flatInvoke("exportComicDownloadToEpub", {
      "comicId": comicId,
      "dir": dir,
      "name": name,
    });
  }

  /// 导出下载的图片到PDF文件夹
  Future<dynamic> exportComicDownloadToPDFFolder(
    String comicId,
    String dir,
    String name,
  ) {
    return _flatInvoke("exportComicDownloadToPDFFolder", {
      "comicId": comicId,
      "dir": dir,
      "name": name,
    });
  }

  /// 导出下载的图片到HTML+JPG
  Future<dynamic> exportComicDownloadJpegZip(
    String comicId,
    String dir,
    String name,
  ) {
    return _flatInvoke("exportComicDownloadJpegZip", {
      "comicId": comicId,
      "dir": dir,
      "name": name,
    });
  }

  /// 导出下载的图片到PKZ
  Future<dynamic> exportComicDownloadToPkz(
    List<String> comicIds,
    String dir,
    String name,
  ) {
    return _flatInvoke("exportComicDownloadToPkz", {
      "comicIds": comicIds,
      "dir": dir,
      "name": name,
    });
  }

  /// 导出zip
  Future<dynamic> exportAnyComicDownloadsToZip(
    List<String> comicIds,
    String dir,
  ) {
    return _flatInvoke("exportAnyComicDownloadsToZip", {
      "comicIds": comicIds,
      "dir": dir,
    });
  }

  /// 导出pki
  Future<dynamic> exportAnyComicDownloadsToPki(
    List<String> comicIds,
    String dir,
  ) {
    return _flatInvoke("exportAnyComicDownloadsToPki", {
      "comicIds": comicIds,
      "dir": dir,
    });
  }

  /// 导出下载的漫画到cbzs.zip
  Future<dynamic> exportComicDownloadToCbzsZip(
      String comicId, String dir, String name) {
    return _flatInvoke("exportComicDownloadToCbzsZip", {
      "comicId": comicId,
      "dir": dir,
      "name": name,
    });
  }

  /// 导入文件夹所有的文件
  Future<dynamic> importComicDownloadDir(
    String dir,
  ) {
    return _flatInvoke("importComicDownloadDir", dir);
  }

  /// 使用网络将下载传输到其他设备
  Future<int> exportComicUsingSocket(String comicId) async {
    return int.parse(await _flatInvoke("exportComicUsingSocket", comicId));
  }

  /// 传输窗口关闭时调用, 令socket关闭(如果传输没有结束)
  Future<dynamic> exportComicUsingSocketExit() {
    return _flatInvoke("exportComicUsingSocketExit", "");
  }

  /// 从zip导入漫画
  Future<dynamic> importComicDownload(String zipPath) {
    return _flatInvoke("importComicDownload", zipPath);
  }

  /// 从pki导入漫画
  Future<dynamic> importComicDownloadPki(String zipPath) {
    return _flatInvoke("importComicDownloadPki", zipPath);
  }

  /// 从网络接收漫画
  Future<dynamic> importComicDownloadUsingSocket(String addr) {
    return _flatInvoke("importComicDownloadUsingSocket", addr);
  }

  /// 获取本机的所有ip地址
  Future<String> clientIpSet() async {
    return await _flatInvoke("clientIpSet", "");
  }

  /// 获取一个游戏的下载地址
  Future<List<String>> downloadGame(String url) async {
    if (url.startsWith("https://game.eroge.xyz/hhh.php")) {
      var data = await _flatInvoke("downloadGame", url);
      return [
        url,
        ...List.of(jsonDecode(data)).map((e) => e.toString()),
      ];
    }
    return [url];
  }

  /// 保存图片(ios)
  Future<dynamic> iosSaveFileToImage(String path) async {
    return _channel.invokeMethod("iosSaveFileToImage", {
      "path": path,
    });
  }

  /// 保存图片(android)
  Future androidSaveFileToImage(String path) async {
    return _channel.invokeMethod("androidSaveFileToImage", {
      "path": path,
    });
  }

  /// 保存图片(PC)
  Future convertImageToJPEG100(String path, String dir) async {
    return _flatInvoke("convertImageToJPEG100", {
      "path": path,
      "dir": dir,
    });
  }

  /// 获取安卓的屏幕刷新率
  Future<List<String>> loadAndroidModes() async {
    return List.of(await _channel.invokeMethod("androidGetModes"))
        .map((e) => "$e")
        .toList();
  }

  /// 设置安卓的屏幕刷新率
  Future setAndroidMode(String androidDisplayMode) {
    return _channel
        .invokeMethod("androidSetMode", {"mode": androidDisplayMode});
  }

  /// 获取安卓的版本
  Future<int> androidGetVersion() async {
    return await _channel.invokeMethod("androidGetVersion", {});
  }

  /// 数据文件保存位置
  Future<String> dataLocal() async {
    return await _channel.invokeMethod("dataLocal", {});
  }

  /// 获取安卓支持的文件保存路径
  Future<List<String>> androidGetExtendDirs() async {
    String? tmp = await _channel.invokeMethod("androidGetExtendDirs", {});
    if (tmp != null && tmp.isNotEmpty) {
      return tmp.split("|");
    }
    return [];
  }

  /// 安卓文件迁移
  Future migrate(String path) async {
    return _channel.invokeMethod("migrate", {"path": path});
  }

  /// 下载的同时导出-配置获取
  Future loadDownloadAndExportPath() {
    return _flatInvoke("loadDownloadAndExportPath", "");
  }

  /// 下载的同时导出-设置
  Future saveDownloadAndExportPath(String folder) {
    return _flatInvoke("saveDownloadAndExportPath", folder);
  }

  /// 使用下载缓存-配置获取
  Future loadDownloadCachePath() {
    return _flatInvoke("loadDownloadCachePath", "");
  }

  /// 使用下载缓存-设置
  Future saveDownloadCachePath(String folder) {
    return _flatInvoke("saveDownloadCachePath", folder);
  }

  /// 切换安全策略 (安卓禁止截图, 录屏, 不显示在任务视图)
  Future androidSecureFlag(bool flag) {
    return _channel.invokeMethod("androidSecureFlag", {
      "flag": flag,
    });
  }

  /// 获取下载线程数量
  Future<int> loadDownloadThreadCount() async {
    var strValue = await _flatInvoke("loadDownloadThreadCount", {});
    return int.parse(strValue);
  }

  /// 设置下载线程数
  Future saveDownloadThreadCount(int value) {
    return _flatInvoke("saveDownloadThreadCount", "$value");
  }

  /// HTTP-GET-STRING
  Future<String> defaultHttpClientGet(String url) async {
    return await _flatInvoke("defaultHttpClientGet", url);
  }

  /// 更新签名
  Future updateSlogan(String input) async {
    return await _flatInvoke("updateSlogan", input);
  }

  /// 更新签名
  Future updateAvatar(String data) async {
    return await _flatInvoke("updateAvatar", data);
  }

  /// 修改密码
  Future updatePassword(String oldPassword, String newPassword) {
    return _flatInvoke("updatePassword", {
      "oldPassword": oldPassword,
      "newPassword": newPassword,
    });
  }

  Future<List<String>> loadViewedList(List<String> list) async {
    return List.of(jsonDecode(await _flatInvoke("loadViewedList", list)))
        .cast();
  }

  Future<List<Collection>> collections() async {
    String rsp = await _flatInvoke("collections", "");
    List list = json.decode(rsp);
    return list.map((e) => Collection.fromJson(e)).toList();
  }

  Future<bool> verifyAuthentication() async {
    return await _channel.invokeMethod("verifyAuthentication");
  }

  Future<PkzArchive> pkzInfo(String pkzPath) async {
    return PkzArchive.fromJson(
        jsonDecode(await _flatInvoke("pkzInfo", pkzPath)));
  }

  Future<Uint8List> loadPkzFile(String pkzPath, String path) async {
    return base64Decode(await _flatInvoke("loadPkzFile", {
      "pkzPath": pkzPath,
      "path": path,
    }));
  }

  Future<List<PkzComicViewLog>> pkzComicViewLogs(
    String fileName,
    String comicId,
  ) async {
    return List.of(jsonDecode(await _flatInvoke("pkzComicViewLogs", fileName)))
        .map((e) => PkzComicViewLog.fromJson(e))
        .toList();
  }

  Future<PkzComicViewLog?> pkzComicViewLogByPkzNameAndId(
    String fileName,
    String comicId,
  ) async {
    String data = await _flatInvoke("pkzComicViewLogByPkzNameAndId", {
      "fileName": fileName,
      "comicId": comicId,
    });
    if (data == "" || data == "nil" || data == "null") {
      return null;
    }
    return PkzComicViewLog.fromJson(jsonDecode(data));
  }

  Future viewPkz(
    String fileName,
    String filePath,
  ) async {
    return _flatInvoke("viewPkz", {
      "fileName": fileName,
      "filePath": filePath,
    });
  }

  Future viewPkzComic(
    String fileName,
    String filePath,
    String comicId,
    String comicTitle,
  ) async {
    return _flatInvoke("viewPkzComic", {
      "fileName": fileName,
      "filePath": filePath,
      "comicId": comicId,
      "comicTitle": comicTitle,
    });
  }

  Future viewPkzEpAndPicture(
    String fileName,
    String filePath,
    String comicId,
    String comicTitle,
    String epId,
    String epTitle,
    int pictureRank,
  ) async {
    return _flatInvoke("viewPkzEpAndPicture", {
      "fileName": fileName,
      "filePath": filePath,
      "comicId": comicId,
      "comicTitle": comicTitle,
      "epId": epId,
      "epTitle": epTitle,
      "pictureRank": pictureRank,
    });
  }

  Future<List<Knight>> leaderboardOfKnight() async {
    return List.of(jsonDecode(await _flatInvoke("leaderboardOfKnight", "")))
        .map((e) => Knight.fromJson(e))
        .toList();
  }

  Future<ProInfoAll> proInfoAll() async {
    return ProInfoAll.fromJson(jsonDecode(await _flatInvoke("proInfoAll", "")));
  }

  Future reloadPro() {
    return _flatInvoke("reloadPro", "");
  }

  Future inputCdKey(String cdKey) {
    return _flatInvoke("inputCdKey", cdKey);
  }

  Future reloadSwitchAddress() {
    return _flatInvoke("reloadSwitchAddress", "");
  }

  Future resetSwitchAddress() {
    return _flatInvoke("resetSwitchAddress", "");
  }

  Future<String> iosGetDocumentDir() async {
    return await _channel.invokeMethod('iosGetDocumentDir', '');
  }

  /// 找回密码1
  Future<ForgotPasswordResult> forgotPassword(email) async {
    String data = await _flatInvoke("forgotPassword", email);
    return ForgotPasswordResult.fromJson(jsonDecode(data));
  }

  /// 找回密码2
  Future<ResetPasswordResult> resetPassword(
    String email,
    int questionNo,
    String answer,
  ) async {
    String data = await _flatInvoke("resetPassword", {
      "email": email,
      "questionNo": questionNo,
      "answer": answer,
    });
    return ResetPasswordResult.fromJson(jsonDecode(data));
  }

  Future mergeHistoriesFromWebDav(
    String root,
    String username,
    String password,
    String file,
    String direction,
  ) {
    return _flatInvoke("mergeHistoriesFromWebDav", {
      "root": root,
      "username": username,
      "password": password,
      "file": file,
      "direction": direction,
    });
  }

  Future mergeHistoriesFromLocal(String localPath) {
    return _flatInvoke("mergeHistoriesFromLocal", localPath);
  }

  Future<int> ping(String idx) async {
    String ms = await _flatInvoke("ping", idx);
    return int.parse(ms);
  }

  Future<int> pingImg(String idx) async {
    String ms = await _flatInvoke("pingImg", idx);
    return int.parse(ms);
  }

  Future<String> androidStorageRoot() async {
    return await _channel.invokeMethod("androidStorageRoot");
  }

  Future importComicViewFormOff(String dbPath) {
    return _flatInvoke("importComicViewFormOff", dbPath);
  }

  Future startWebServer() {
    return _flatInvoke("startWebServer", "");
  }

  Future stopWebServer() {
    return _flatInvoke("stopWebServer", "");
  }

  Future<String> androidDefaultExportsDir() async {
    return await _channel.invokeMethod("androidDefaultExportsDir");
  }

  Future getHomeDir() {
    return _flatInvoke("getHomeDir", "");
  }

  Future mkdirs(String path) {
    return _flatInvoke("mkdirs", path);
  }

  Future androidMkdirs(String path) async {
    return await _channel.invokeMethod("androidMkdirs", path);
  }

  Future downloadAll(List<String> comicIds) {
    return _flatInvoke("downloadAll", comicIds);
  }

  Future setPatAccessKey(String accessKey) {
    return _flatInvoke("setPatAccessKey", accessKey);
  }

  Future reloadPatAccount() {
    return _flatInvoke("reloadPatAccount", "");
  }

  Future bindThisAccount() {
    return _flatInvoke("bindThisAccount", "");
  }

  Future clearPat() {
    return _flatInvoke("clearPat", "");
  }

  /// 加载已订阅
  Future<ComicSubscribe?> loadSubscribed(String comicId) async {
    String data = await _flatInvoke("loadSubscribed", comicId);
    if (data == "") {
      return null;
    }
    return ComicSubscribe.fromJson(jsonDecode(data));
  }

  Future addSubscribed(String comicId) async {
    return _flatInvoke("addSubscribed", comicId);
  }

  Future removeAllSubscribed() async {
    return _flatInvoke("removeAllSubscribed", "");
  }

  Future removeSubscribed(String comicId) async {
    return _flatInvoke("removeSubscribed", comicId);
  }

  Future<List<ComicSubscribe>> allSubscribed() async {
    var data = await _flatInvoke("allSubscribed", "");
    List list = json.decode(data);
    return list.map((e) => ComicSubscribe.fromJson(e)).toList();
  }

  Future updateSubscribed() async {
    return _flatInvoke("updateSubscribed", "");
  }

  Future updateSubscribedForce() async {
    return _flatInvoke("updateSubscribedForce", "");
  }

  Future<List<String>> fontList() async {
    return await _channel.invokeMethod(
        "fontList", {}).then((value) => List.of(value).cast<String>());
  }

  // 本地收藏夹方法
  Future<LocalFavoriteFolder> createLocalFavoriteFolder(String name) async {
    String data =
        await _flatInvoke("createLocalFavoriteFolder", {"name": name});
    return LocalFavoriteFolder.fromJson(jsonDecode(data));
  }

  Future updateLocalFavoriteFolder(LocalFavoriteFolder folder) async {
    return _flatInvoke("updateLocalFavoriteFolder", folder.toJson());
  }

  Future deleteLocalFavoriteFolder(String folderId) async {
    return _flatInvoke("deleteLocalFavoriteFolder", folderId);
  }

  Future<LocalFavoriteFolder> getLocalFavoriteFolder(String folderId) async {
    String data = await _flatInvoke("getLocalFavoriteFolder", folderId);
    return LocalFavoriteFolder.fromJson(jsonDecode(data));
  }

  Future<List<LocalFavoriteFolder>> listLocalFavoriteFolders() async {
    String data = await _flatInvoke("listLocalFavoriteFolders", "");
    List list = jsonDecode(data);
    return list.map((e) => LocalFavoriteFolder.fromJson(e)).toList();
  }

  Future<int> countLocalFavoriteFolders() async {
    String data = await _flatInvoke("countLocalFavoriteFolders", "");
    return int.parse(data);
  }

  Future addLocalFavoriteComic(String comicId, String folderId,
      {String info = ""}) async {
    return _flatInvoke("addLocalFavoriteComic", {
      "comicId": comicId,
      "folderId": folderId,
      "info": info,
    });
  }

  Future removeLocalFavoriteComic(String comicId) async {
    return _flatInvoke("removeLocalFavoriteComic", comicId);
  }

  Future moveLocalFavoriteComics(List<String> comicIds, String folderId) async {
    return _flatInvoke("moveLocalFavoriteComics", {
      "comicIds": comicIds,
      "folderId": folderId,
    });
  }

  Future<LocalFavoriteComic?> getLocalFavoriteComic(String comicId) async {
    try {
      String data = await _flatInvoke("getLocalFavoriteComic", comicId);
      if (data == "") {
        return null;
      }
      return LocalFavoriteComic.fromJson(jsonDecode(data));
    } catch (e) {
      return null;
    }
  }

  Future<List<LocalFavoriteComic>> listLocalFavoriteComics(
      String folderId) async {
    String data =
        await _flatInvoke("listLocalFavoriteComics", {"folderId": folderId});
    List list = jsonDecode(data);
    return list.map((e) => LocalFavoriteComic.fromJson(e)).toList();
  }

  Future<List<LocalFavoriteComic>> listAllLocalFavoriteComics() async {
    String data = await _flatInvoke("listAllLocalFavoriteComics", "");
    List list = jsonDecode(data);
    return list.map((e) => LocalFavoriteComic.fromJson(e)).toList();
  }

  Future mergeLocalFavoritesFromWebDav(
    String webdavRoot,
    String webdavUsername,
    String webdavPassword,
  ) async {
    return _flatInvoke("mergeLocalFavoritesFromWebDav", {
      "webdavRoot": webdavRoot,
      "webdavUsername": webdavUsername,
      "webdavPassword": webdavPassword,
    });
  }
}
