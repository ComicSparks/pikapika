import 'package:pikapika/i18.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Cross.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/SearchScreen.dart';
import 'package:pikapika/basic/Navigator.dart';

import '../../basic/config/CopyFullName.dart';
import '../../basic/config/CopyFullNameTemplate.dart';
import 'ComicInfoCard.dart';
import 'PkzImages.dart';

// 漫画卡片
class PkzComicInfoCard extends StatefulWidget {
  final String pkzPath;
  final PkzComic info;
  final bool linkItem;
  final PkzComicViewLog? displayViewLog;

  const PkzComicInfoCard({
    required this.info,
    required this.pkzPath,
    this.linkItem = false,
    Key? key,
    this.displayViewLog,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ComicInfoCard();
}

class _ComicInfoCard extends State<PkzComicInfoCard> {
  @override
  Widget build(BuildContext context) {
    var info = widget.info;
    final theme = Theme.of(context);
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
            child: PkzImage(
              pkzPath: widget.pkzPath,
              path: info.coverPath,
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
                                var fin =
                                copyFullNameTemplate()
                                    .replaceAll("{title}", info.title)
                                    .replaceAll("{author}", info.author);
                                if (fin.isEmpty) {
                                  fin = info.title;
                                }
                                if (copyFullName()) {
                                  confirmCopy(
                                      context, fin);
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
                                // todo
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
                                  TextSpan(text: tr('app.categories') + ' :'),
                                  ...info.categories.map(
                                    (e) => TextSpan(
                                      children: [
                                        const TextSpan(text: ' '),
                                        TextSpan(
                                            text: e,
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                // todo
                                              }),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : TextSpan(
                                text: "${tr('app.categories')} : ${info.categories.join(' ')}"),
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
                      widget.displayViewLog != null &&
                              widget.displayViewLog!.lastViewEpId.isNotEmpty
                          ? Container(
                              padding: EdgeInsets.only(bottom: 5),
                              child: Text(
                                "${tr('app.last_viewed')} ${widget.displayViewLog!.lastViewEpName}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: authorStyleX,
                              ),
                            )
                          : Container(),
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
}
