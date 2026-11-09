import 'dart:convert';

import 'package:pikapika/i18.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Cross.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/basic/config/AutoDeleteDownloadOnUnfavorite.dart';
import 'package:pikapika/basic/config/AutoDownloadOnFavorite.dart';
import 'package:pikapika/basic/config/CopyFullName.dart';
import 'package:pikapika/basic/config/CopyFullNameTemplate.dart';
import 'package:pikapika/basic/config/DisableAutoDownloadOnMobile.dart';
import 'package:pikapika/basic/config/HideOnlineFavorite.dart';
import 'package:pikapika/basic/config/IsPro.dart';
import 'package:pikapika/basic/config/WebDav.dart';
import 'package:pikapika/screens/SearchAuthorScreen.dart';
import 'package:pikapika/basic/Navigator.dart';
import '../ComicsScreen.dart';
import 'Images.dart';
import 'package:pikapika/basic/connect.dart';

// 漫画卡片
class ComicInfoCard extends StatefulWidget {
  final bool linkItem;
  final ComicSimple info;
  final bool viewed;
  final int? viewsCount;
  final bool? liked;
  final bool? favourite;

  const ComicInfoCard(
    this.info, {
    Key? key,
    this.linkItem = false,
    this.viewed = false,
    this.viewsCount,
    this.liked,
    this.favourite,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicInfoCard();
}

class _ComicInfoCard extends State<ComicInfoCard> {
  bool _favouriteLoading = false;
  bool _likeLoading = false;
  bool _localFavoriteLoading = false;
  bool? _liked;
  bool? _favourite;
  LocalFavoriteComic? _localFavoriteComic;

  @override
  void initState() {
    super.initState();
    if (useLocalFavorite) {
      _loadLocalFavoriteStatus();
    }
  }

  Future<void> _loadLocalFavoriteStatus() async {
    try {
      _localFavoriteComic = await method.getLocalFavoriteComic(widget.info.id);
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Load local favorite status error: $e");
    }
  }

  String _encodeComicSimpleInfo(ComicSimple info) {
    return jsonEncode({
      "_id": info.id,
      "title": info.title,
      "author": info.author,
      "pagesCount": info.pagesCount,
      "epsCount": info.epsCount,
      "finished": info.finished,
      "categories": info.categories,
      "likesCount": info.likesCount,
      "thumb": {
        "originalName": info.thumb.originalName,
        "fileServer": info.thumb.fileServer,
        "path": info.thumb.path,
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    var info = widget.info;
    var theme = Theme.of(context);
    var view = widget.viewsCount ?? 0;
    bool? like = _liked ?? widget.liked;
    bool? favourite = hideOnlineFavorite ? null : (_favourite ?? widget.favourite);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.only(right: 10),
            child: RemoteImage(
              fileServer: info.thumb.fileServer,
              path: info.thumb.path,
              width: imageWidth,
              height: imageHeight,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      widget.linkItem
                          ? GestureDetector(
                              onLongPress: () {
                                if (copyFullName()) {
                                  var fin = copyFullNameTemplate()
                                      .replaceAll("{title}", info.title)
                                      .replaceAll("{author}", info.author);
                                  if (fin.isEmpty) {
                                    fin = info.title;
                                  }
                                  confirmCopy(
                                    context,
                                    fin,
                                  );
                                } else {
                                  confirmCopy(context, info.title);
                                }
                              },
                              child: Text(info.title, style: titleStyle),
                            )
                          : Text(info.title, style: titleStyle),
                      Container(height: 5),
                      widget.linkItem
                          ? InkWell(
                              onTap: () {
                                navPushOrReplace(
                                    context,
                                    (context) => SearchAuthorScreen(
                                        author: info.author));
                              },
                              onLongPress: () {
                                confirmCopy(context, info.author);
                              },
                              child: Text(info.author, style: authorStyle),
                            )
                          : Text(info.author, style: authorStyle),
                      Container(height: 5),
                      Text.rich(
                        widget.linkItem
                            ? TextSpan(
                                children: [
                                  TextSpan(
                                      text:
                                          '${tr('components.comic_info_card.categories')} :'),
                                  ...info.categories.map(
                                    (e) => TextSpan(
                                      children: [
                                        const TextSpan(text: ' '),
                                        TextSpan(
                                          text: e,
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () => navPushOrReplace(
                                                  context,
                                                  (context) => ComicsScreen(
                                                    category: e,
                                                  ),
                                                ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : TextSpan(
                                text:
                                    "${tr('components.comic_info_card.categories')} : ${info.categories.join(' ')}"),
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .color!
                              .withAlpha(0xCC),
                        ),
                      ),
                      Container(height: 5),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        runSpacing: 5,
                        children: [
                          ...info.likesCount > 0
                              ? [
                                  iconFavorite,
                                  iconSpacing,
                                  Text(
                                    '${info.likesCount}',
                                    style: iconLabelStyle,
                                    strutStyle: iconLabelStrutStyle,
                                  ),
                                  iconMargin,
                                ]
                              : [],
                          ...(view > 0
                              ? [
                                  iconVisibility,
                                  iconSpacing,
                                  Text(
                                    '$view',
                                    style: iconLabelStyle,
                                    strutStyle: iconLabelStrutStyle,
                                  ),
                                  iconMargin,
                                ]
                              : []),
                          ...(info.epsCount > 0
                              ? [
                                  Text.rich(TextSpan(children: [
                                    const WidgetSpan(child: iconPage),
                                    WidgetSpan(child: iconSpacing),
                                    WidgetSpan(
                                        child: Text(
                                      "${info.epsCount}E / ${info.pagesCount}P",
                                      style: countLabelStyle,
                                      strutStyle: iconLabelStrutStyle,
                                      softWrap: false,
                                    )),
                                    WidgetSpan(child: iconMargin),
                                  ])),
                                ]
                              : []),
                          iconMargin,
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: imageHeight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      buildFinished(info.finished),
                      ...buildViewed(widget.viewed),
                      Expanded(child: Container()),
                      ...(like == null
                          ? []
                          : [
                              Container(height: 10),
                              SizedBox(
                                height: 26,
                                child: _likeLoading
                                    ? IconButton(
                                        color: Colors.pink[400],
                                        onPressed: () {},
                                        icon: const Icon(
                                          Icons.sync,
                                        ),
                                      )
                                    : IconButton(
                                        color: Colors.pink[400],
                                        onPressed: _changeLike,
                                        icon: Icon(
                                          like
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                        ),
                                      ),
                              ),
                            ]),
                      ...((!useLocalFavorite && favourite == null)
                          ? []
                          : [
                              Container(height: 10),
                              SizedBox(
                                height: 26,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (useLocalFavorite) ...[
                                      _localFavoriteLoading
                                          ? IconButton(
                                              color: Colors.pink[400],
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {},
                                              icon: const Icon(Icons.sync),
                                            )
                                          : IconButton(
                                              color: Colors.pink[400],
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: _changeLocalFavorite,
                                              icon: Icon(
                                                _localFavoriteComic != null
                                                    ? Icons.folder_special
                                                    : Icons.folder_open,
                                              ),
                                            ),
                                    ],
                                    if (useLocalFavorite && favourite != null)
                                      const SizedBox(width: 8),
                                    if (favourite != null)
                                      _favouriteLoading
                                          ? IconButton(
                                              color: Colors.pink[400],
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: () {},
                                              icon: const Icon(Icons.sync),
                                            )
                                          : IconButton(
                                              color: Colors.pink[400],
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              onPressed: _changeFavourite,
                                              icon: Icon(
                                                favourite
                                                    ? Icons.bookmark
                                                    : Icons.bookmark_border,
                                              ),
                                            ),
                                  ],
                                ),
                              ),
                            ]),
                      Container(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future _changeFavourite() async {
    setState(() {
      _favouriteLoading = true;
    });
    try {
      var rst = await method.switchFavourite(widget.info.id);
      final isNowFavourite = !rst.startsWith("un");
      setState(() {
        _favourite = isNowFavourite;
      });
      if (isNowFavourite) {
        await _maybeAutoDownloadOnFavorite();
      } else {
        await _maybeAutoDeleteOnUnfavorite();
      }
    } finally {
      setState(() {
        _favouriteLoading = false;
      });
    }
  }

  Future<void> _maybeAutoDownloadOnFavorite() async {
    if (!autoDownloadOnFavorite()) {
      return;
    }
    if (!isPro) {
      defaultToast(context, tr('app.pro_required'));
      return;
    }
    try {
      if (disableAutoDownloadOnMobile() && await isMobileNetwork()) {
        return;
      }
      await method.downloadAll([widget.info.id]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('local_favorite.download_failed'))),
        );
      }
    }
  }

  Future<void> _maybeAutoDeleteOnUnfavorite() async {
    if (!autoDeleteDownloadOnUnfavorite()) {
      return;
    }
    try {
      await method.deleteDownloadComic(widget.info.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('local_favorite.remove_failed'))),
        );
      }
    }
  }

  Future _changeLike() async {
    setState(() {
      _likeLoading = true;
    });
    try {
      var rst = await method.switchLike(widget.info.id);
      setState(() {
        _liked = !rst.startsWith("un");
      });
    } finally {
      setState(() {
        _likeLoading = false;
      });
    }
  }

  Future<void> _changeLocalFavorite() async {
    if (_localFavoriteComic != null) {
      // 已收藏，显示确认删除对话框
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(tr('local_favorite.remove_confirm_title')),
            content: Text(tr('local_favorite.remove_confirm_content')),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text(tr('app.cancel')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text(tr('app.confirm')),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        setState(() {
          _localFavoriteLoading = true;
        });
        try {
          await method.removeLocalFavoriteComic(widget.info.id);
          setState(() {
            _localFavoriteComic = null;
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(tr('local_favorite.remove_failed'))),
            );
          }
        } finally {
          setState(() {
            _localFavoriteLoading = false;
          });
        }
      }
    } else {
      // 未收藏，显示文件夹选择对话框
      await _showFolderSelector();
    }
  }

  Future<void> _showFolderSelector() async {
    setState(() {
      _localFavoriteLoading = true;
    });

    try {
      List<LocalFavoriteFolder> folders = await method.listLocalFavoriteFolders();
      int folderCount = await method.countLocalFavoriteFolders();

      if (!mounted) return;

      setState(() {
        _localFavoriteLoading = false;
      });

      // 显示文件夹选择对话框
      String? selectedFolderId = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(tr('local_favorite.select_folder')),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.folder_special),
                    title: Text(tr('local_favorite.all_folders')),
                    onTap: () {
                      Navigator.of(context).pop('__ALL__');
                    },
                  ),
                  const Divider(),
                  if (folders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(tr('local_favorite.no_folders')),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final folder = folders[index];
                        return ListTile(
                          leading: const Icon(Icons.folder),
                          title: Text(folder.name),
                          onTap: () {
                            Navigator.of(context).pop(folder.id);
                          },
                        );
                      },
                    ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.create_new_folder,
                      color: (isPro || folderCount < 3) ? null : Colors.grey,
                    ),
                    title: Text(
                      tr('local_favorite.new_folder') +
                          (isPro || folderCount < 3 ? "" : " (${tr('app.pro')})"),
                      style: TextStyle(
                        color: (isPro || folderCount < 3) ? null : Colors.grey,
                      ),
                    ),
                    onTap: () async {
                      if (!isPro && folderCount >= 3) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tr('local_favorite.folder_limit_reached')),
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).pop('__CREATE_NEW__');
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(tr('app.cancel')),
              ),
            ],
          );
        },
      );

      if (selectedFolderId == '__ALL__') {
        await _addToFolder("");
      } else if (selectedFolderId == '__CREATE_NEW__') {
        // 创建新文件夹
        await _createNewFolder();
      } else if (selectedFolderId != null) {
        // 添加到选中的文件夹
        await _addToFolder(selectedFolderId);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localFavoriteLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('local_favorite.load_failed'))),
        );
      }
    }
  }

  Future<void> _createNewFolder() async {
    String? folderName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(tr('local_favorite.new_folder')),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: tr('local_favorite.folder_name'),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(tr('app.cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text.trim());
              },
              child: Text(tr('app.confirm')),
            ),
          ],
        );
      },
    );

    if (folderName != null && folderName.isNotEmpty) {
      setState(() {
        _localFavoriteLoading = true;
      });

      try {
        LocalFavoriteFolder folder = await method.createLocalFavoriteFolder(folderName);
        await _addToFolder(folder.id);
      } catch (e) {
        if (mounted) {
          setState(() {
            _localFavoriteLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr('local_favorite.create_folder_failed'))),
          );
        }
      }
    }
  }

  Future<void> _addToFolder(String folderId) async {
    setState(() {
      _localFavoriteLoading = true;
    });

    try {
      await method.addLocalFavoriteComic(
        widget.info.id,
        folderId,
        info: _encodeComicSimpleInfo(widget.info),
      );
      await _loadLocalFavoriteStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('local_favorite.add_success'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('local_favorite.add_failed'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _localFavoriteLoading = false;
        });
      }
    }
  }
}

double imageWidth = 210 / 3.15;
double imageHeight = 315 / 3.15;

Widget buildFinished(bool comicFinished) {
  if (comicFinished) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade800,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        tr('components.comic_info_card.finished'),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.2,
        ),
        strutStyle: const StrutStyle(
          height: 1.2,
        ),
      ),
    );
  }
  return Container();
}

List<Widget> buildViewed(viewed) {
  if (!viewed) {
    return [];
  }
  return [
    Container(height: 5),
    Container(
      padding: const EdgeInsets.only(left: 8, right: 8),
      decoration: BoxDecoration(
        color: Colors.yellow.shade800,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        tr('components.comic_info_card.viewed'),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.2,
        ),
        strutStyle: const StrutStyle(
          height: 1.2,
        ),
      ),
    ),
  ];
}

const double _iconSize = 15;

final iconFavorite =
    Icon(Icons.favorite, size: _iconSize, color: Colors.pink[400]);
final iconDownload =
    Icon(Icons.download_rounded, size: _iconSize, color: Colors.pink[400]);
final iconVisibility =
    Icon(Icons.visibility, size: _iconSize, color: Colors.pink[400]);

final iconLabelStyle = TextStyle(
  fontSize: 13,
  color: Colors.pink.shade400,
  height: 1.2,
);
const iconLabelStrutStyle = StrutStyle(
  height: 1.2,
);

const iconPage =
    Icon(Icons.ballot_outlined, size: _iconSize, color: Colors.grey);
const countLabelStyle = TextStyle(
  fontSize: 13,
  color: Colors.grey,
  height: 1.2,
);

final iconMargin = Container(width: 20);
final iconSpacing = Container(width: 5);

const titleStyle = TextStyle(fontWeight: FontWeight.bold);
final authorStyle = TextStyle(
  fontSize: 13,
  color: Colors.pink.shade300,
);

final authorStyleX = TextStyle(
  fontSize: 13,
  color: Colors.pink.shade300.withOpacity(.7),
);
