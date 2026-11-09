import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/screens/CommentScreen.dart';
import 'package:pikapika/screens/components/BottomSheetInput.dart';
import 'package:pikapika/screens/components/ItemBuilder.dart';
import 'package:pikapika/basic/Method.dart';
import '../../basic/config/IconLoading.dart';
import 'CommentItem.dart';
import 'CommentMainType.dart';

class _CommentBasePage {
  final int total;
  final int limit;
  final int page;
  final int pages;
  final List<CommentBase> docs;

  _CommentBasePage.ofComic(CommentPage commentPage)
      : total = commentPage.total,
        limit = commentPage.limit,
        page = commentPage.page,
        pages = commentPage.pages,
        docs = commentPage.docs;

  _CommentBasePage.ofGame(GameCommentPage commentPage)
      : total = commentPage.total,
        limit = commentPage.limit,
        page = commentPage.page,
        pages = commentPage.pages,
        docs = commentPage.docs;
}

// 漫画的评论列表
class CommentList extends StatefulWidget {
  final CommentMainType mainType;
  final String mainId;

  const CommentList(this.mainType, this.mainId, {Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CommentListState();
}

class _CommentListState extends State<CommentList> {
  late int _currentPage = 1;
  late Future<_CommentBasePage> _future = _loadPage();

  Future<_CommentBasePage> _loadPage() async {
    switch (widget.mainType) {
      case CommentMainType.COMIC:
        return _CommentBasePage.ofComic(
          await method.comments(widget.mainId, _currentPage),
        );
      case CommentMainType.GAME:
        return _CommentBasePage.ofGame(
          await method.gameComments(widget.mainId, _currentPage),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ItemBuilder(
      future: _future,
      successBuilder:
          (BuildContext context, AsyncSnapshot<_CommentBasePage> snapshot) {
        var page = snapshot.data!;
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPrePage(page),
            ...page.docs.map((e) => _buildComment(e)),
            _buildNextPage(page),
            _buildPostComment(),
          ],
        );
      },
      onRefresh: () async => {
        setState(() {
          _future = _loadPage();
        })
      },
    );
  }

  Widget _buildComment(CommentBase comment) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          mixRoute(
            builder: (context) =>
                CommentScreen(widget.mainType, widget.mainId, comment),
          ),
        );
      },
      child: ComicCommentItem(widget.mainType, widget.mainId, comment),
    );
  }

  Widget _buildPostComment() {
    return InkWell(
      onTap: () async {
        showInputModalBottomSheet(
          context: context,
          onSubmitted: (text) async {
            switch (widget.mainType) {
              case CommentMainType.COMIC:
                await method.postComment(widget.mainId, text);
                break;
              case CommentMainType.GAME:
                await method.postGameComment(widget.mainId, text);
                break;
            }
            setState(() {
              _future = _loadPage();
            });
            defaultToast(context, tr("screen.comment.comment_success"));
          },
          hintText: tr("screen.comment.please_enter_comment"),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              width: .25,
              style: BorderStyle.solid,
              color: Colors.grey.shade500.withOpacity(.5),
            ),
            bottom: BorderSide(
              width: .25,
              style: BorderStyle.solid,
              color: Colors.grey.shade500.withOpacity(.5),
            ),
          ),
        ),
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Text(tr("screen.comment.i_have_something_to_say")),
        ),
      ),
    );
  }

  Widget _buildPrePage(_CommentBasePage page) {
    if (page.page > 1) {
      return InkWell(
        onTap: () {
          setState(() {
            _currentPage = page.page - 1;
            _future = _loadPage();
          });
        },
        child: Container(
          padding: const EdgeInsets.all(30),
          child: Center(
            child: Text(tr("app.previous_page")),
          ),
        ),
      );
    }
    return Container();
  }

  Widget _buildNextPage(_CommentBasePage page) {
    if (page.page < page.pages) {
      return InkWell(
        onTap: () {
          setState(() {
            _currentPage = page.page + 1;
            _future = _loadPage();
          });
        },
        child: Container(
          padding: const EdgeInsets.all(30),
          child: Center(
            child: Text(tr("app.next_page")),
          ),
        ),
      );
    }
    return Container();
  }
}
