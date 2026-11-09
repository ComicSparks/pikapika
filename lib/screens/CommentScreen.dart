import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Common.dart';
import 'package:pikapika/basic/Entities.dart';
import 'package:pikapika/basic/Method.dart';
import 'package:pikapika/screens/components/CommentItem.dart';
import 'package:pikapika/screens/components/CommentMainType.dart';
import 'package:pikapika/screens/components/ContentBuilder.dart';

import 'components/BottomSheetInput.dart';
import 'components/ListView.dart';
import 'components/RightClickPop.dart';

class _CommentChildPage {
  final int total;
  final int limit;
  final int page;
  final int pages;
  final List<ChildOfComment> docs;

  _CommentChildPage.ofComic(CommentChildrenPage commentPage)
      : total = commentPage.total,
        limit = commentPage.limit,
        page = commentPage.page,
        pages = commentPage.pages,
        docs = commentPage.docs;

  _CommentChildPage.ofGame(GameCommentChildrenPage commentPage)
      : total = commentPage.total,
        limit = commentPage.limit,
        page = commentPage.page,
        pages = commentPage.pages,
        docs = commentPage.docs;
}

class CommentScreen extends StatefulWidget {
  final CommentMainType mainType;
  final String mainId;
  final CommentBase comment;

  const CommentScreen(this.mainType, this.mainId, this.comment, {Key? key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  late int _currentPage = 1;
  int? _commentsCount;
  late Future<_CommentChildPage> _future = _loadPage();
  late Key _key = UniqueKey();

  int get _shownComments => _commentsCount ?? widget.comment.commentsCount;

  Future<_CommentChildPage> _loadPage() async {
    switch (widget.mainType) {
      case CommentMainType.COMIC:
        return _CommentChildPage.ofComic(await method.commentChildren(
          widget.mainId,
          widget.comment.id,
          _currentPage,
        ));
      case CommentMainType.GAME:
        return _CommentChildPage.ofGame(await method.gameCommentChildren(
          widget.mainId,
          widget.comment.id,
          _currentPage,
        ));
    }
  }

  Widget _buildChildrenPager() {
    return ContentBuilder(
      key: _key,
      future: _future,
      onRefresh: _loadPage,
      successBuilder:
          (BuildContext context, AsyncSnapshot<_CommentChildPage> snapshot) {
        var page = snapshot.data!;
        return PikaListView(
          children: [
            _buildPrePage(page),
            ...page.docs.map((e) => _buildComment(e)),
            _buildNextPage(page),
            _buildPostComment(),
          ],
        );
      },
    );
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
        title: Text(tr('screen.comment.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            onPressed: _onReply,
          ),
        ],
      ),
      body: Column(
        children: [
          ComicCommentItem(
            widget.mainType,
            widget.mainId,
            widget.comment,
            commentsCount: _shownComments,
          ),
          Container(
            height: 3,
            color:
                (Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black)
                    .withOpacity(.05),
          ),
          Expanded(child: _buildChildrenPager())
        ],
      ),
    );
  }

  Widget _buildComment(CommentBase e) {
    return ComicCommentItem(widget.mainType, widget.mainId, e);
  }

  Future _onReply() async {
    showInputModalBottomSheet(
      context: context,
      onSubmitted: (text) async {
        switch (widget.mainType) {
          case CommentMainType.COMIC:
            await method.postChildComment(widget.comment.id, text);
            break;
          case CommentMainType.GAME:
            await method.postGameChildComment(widget.comment.id, text);
            break;
        }
        setState(() {
          _future = _loadPage();
          _key = UniqueKey();
          _commentsCount = _shownComments + 1;
        });
        defaultToast(context, tr('screen.comment.success'));
      },
      hintText: tr('screen.comment.hint_text'),
    );
  }

  Widget _buildPostComment() {
    return InkWell(
      onTap: _onReply,
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
          child: Text(tr('screen.comment.i_have_something_to_say')),
        ),
      ),
    );
  }

  Widget _buildPrePage(_CommentChildPage page) {
    if (page.page > 1) {
      return InkWell(
        onTap: () {
          setState(() {
            _currentPage = page.page - 1;
            _future = _loadPage();
            _key = UniqueKey();
          });
        },
        child: Container(
          padding: const EdgeInsets.all(30),
          child: Center(
            child: Text(tr('app.previous_page')),
          ),
        ),
      );
    }
    return Container();
  }

  Widget _buildNextPage(_CommentChildPage page) {
    if (page.page < page.pages) {
      return InkWell(
        onTap: () {
          setState(() {
            _currentPage = page.page + 1;
            _future = _loadPage();
            _key = UniqueKey();
          });
        },
        child: Container(
          padding: const EdgeInsets.all(30),
          child: Center(
            child: Text(tr('app.next_page')),
          ),
        ),
      );
    }
    return Container();
  }
}
