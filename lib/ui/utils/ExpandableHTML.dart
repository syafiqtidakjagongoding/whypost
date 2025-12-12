import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

Future<int> countTextLines({
  required String text,
  required double maxWidth,
  required TextStyle style,
}) async {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: null,
  )..layout(maxWidth: maxWidth);

  return textPainter.computeLineMetrics().length;
}

String extractPlainText(String html) {
  return HtmlParser.parseHTML(html).text;
}

class ExpandableHtml extends StatefulWidget {
  final String html;
  final Map<String, Style>? style;
  final Function(String?, Map<String, String>, dynamic)? onLinkTap;

  const ExpandableHtml({
    super.key,
    required this.html,
    this.style,
    this.onLinkTap,
  });

  @override
  State<ExpandableHtml> createState() => _ExpandableHtmlState();
}

class _ExpandableHtmlState extends State<ExpandableHtml> {
  bool expanded = false;
  final double maxHeight = 200;
  bool isOverflowing = false;
   final GlobalKey _measureKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
  }

  @override
  void didUpdateWidget(covariant ExpandableHtml oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeight());
    }
  }

  void _measureHeight() {
    final box = _measureKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final height = box.size.height;
    final overflow = height > maxHeight;

    if (overflow != isOverflowing) {
      setState(() => isOverflowing = overflow);
    }
  }

   @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Offstage(
          child: Html(key: _measureKey, data: widget.html, style: widget.style!),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRect(
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: ConstrainedBox(
                  constraints: expanded
                      ? const BoxConstraints()
                      : BoxConstraints(maxHeight: maxHeight),
                  child: Html(
                    data: widget.html,
                    style: widget.style!,
                    onLinkTap: widget.onLinkTap,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            if (isOverflowing)
              GestureDetector(
                onTap: () => setState(() => expanded = !expanded),
                child: Text(
                  expanded ? "Close" : "Read more",
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
