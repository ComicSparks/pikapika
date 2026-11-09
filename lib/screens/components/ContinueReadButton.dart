import 'package:pikapika/i18.dart';
import 'package:flutter/material.dart';
import 'package:pikapika/basic/Entities.dart';

// 继续阅读按钮
class ContinueReadButton extends StatefulWidget {
  final Future<ViewLog?> viewFuture;
  final Function(int? epOrder, int? pictureRank) onChoose;

  const ContinueReadButton({
    Key? key,
    required this.viewFuture,
    required this.onChoose,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ContinueReadButtonState();
}

class _ContinueReadButtonState extends State<ContinueReadButton> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        var width = constraints.maxWidth;
        return FutureBuilder(
          future: widget.viewFuture,
          builder: (BuildContext context, AsyncSnapshot<ViewLog?> snapshot) {
            late void Function() onPressed;
            late String text;
            if (snapshot.connectionState != ConnectionState.done) {
              onPressed = () {};
              text = tr('app.loading');
            }
            if (snapshot.data != null && snapshot.data!.lastViewEpOrder > 0) {
              onPressed = () => widget.onChoose(
                    snapshot.data?.lastViewEpOrder,
                    snapshot.data?.lastViewPictureRank,
                  );
              text =
                  '${tr('app.continue_reading')} ${snapshot.data?.lastViewEpTitle} P. ${(snapshot.data?.lastViewPictureRank ?? 0) + 1}';
            } else {
              onPressed = () => widget.onChoose(null, null);
              text = tr('app.start_reading');
            }
            return Container(
              padding: const EdgeInsets.only(left: 10, right: 10),
              margin: const EdgeInsets.only(bottom: 10),
              width: width,
              child: MaterialButton(
                onPressed: onPressed,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .color!
                            .withOpacity(.05),
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
