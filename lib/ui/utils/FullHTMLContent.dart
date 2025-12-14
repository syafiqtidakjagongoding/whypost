import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class FullHTMLContent extends StatefulWidget {
  final String content;
  final List emojis;
  final List<dynamic> mentions;
  const FullHTMLContent({
    super.key,
    required this.content,
    required this.emojis,
    required this.mentions,
  });

  @override
  State<FullHTMLContent> createState() => _FullHTMLContentState();
}

class _FullHTMLContentState extends State<FullHTMLContent> {
  late String htmlContent;
 

  @override
  void initState() {
    super.initState();
    htmlContent = widget.content;
    _loadEmojis();
  }

  Future<void> _loadEmojis() async {
    final Map<String, String> emojiMap = {
      for (final e in widget.emojis) e['shortcode']: e['url'],
    };

    final buffer = StringBuffer();
    int lastIndex = 0;
    final regex = RegExp(r':([a-zA-Z0-9_]+):');

    for (final match in regex.allMatches(widget.content)) {
      buffer.write(widget.content.substring(lastIndex, match.start));
      final shortcode = match.group(1)!;
      if (emojiMap.containsKey(shortcode)) {
        buffer.write(
          '<img src="${emojiMap[shortcode]}" '
          'style="width:20px;height:20px;vertical-align:middle;"/>',
        );
      } else {
        buffer.write(match.group(0));
      }
      lastIndex = match.end;
    }

    buffer.write(widget.content.substring(lastIndex));

    await Future.delayed(Duration(milliseconds: 50));

    setState(() {
      htmlContent = buffer.toString();
    });
  }

  @override
  void didUpdateWidget(covariant FullHTMLContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.content != widget.content ||
        oldWidget.emojis != widget.emojis) {
      htmlContent = widget.content;
      _loadEmojis();
    }
  }

  void _action(
    String? url,
    Map<String, String> attributes,
    dynamic element,
  ) async {
    final text = element?.text.trim() ?? url ?? '';
    if (text.isEmpty) return;

    if (text.startsWith('#')) {
      final tag = text.substring(1);

      context.push("/tags/$tag");
      return;
    }

    if (text.startsWith('@')) {
      final username = text.startsWith('@') ? text.substring(1) : text;
      final mentions = widget.mentions.cast<Map<String, dynamic>>();
      final tryWithUsername = mentions.firstWhere(
        (m) => m['username'] == username,
        orElse: () => {},
      );

      final tryWithAcct = mentions.firstWhere(
        (m) => m['acct'] == username,
        orElse: () => {},
      );

      final userToPush = tryWithUsername.isNotEmpty
          ? tryWithUsername
          : tryWithAcct;

      if (userToPush.isNotEmpty) {
        context.push("/user/${userToPush["id"]}");
      }

      return;
    }

    final uri = Uri.parse(url!.startsWith('http') ? url : 'https://$url');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
     final textTheme = Theme.of(context).textTheme;

     Map<String, Style> htmlStyle = {
      "body": Style(
        fontSize: FontSize(15),
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
        lineHeight: LineHeight(1.5),
      ),
      "p": Style(margin: Margins.only(bottom: 8), color: textTheme.labelMedium!.color),
      "b": Style(fontWeight: FontWeight.bold),
      "i": Style(fontStyle: FontStyle.italic),
      "span": Style(fontSize: FontSize(15), color: textTheme.labelMedium!.color,
      ),
      "a": Style(
        color: Color.fromRGBO(255, 117, 31, 1),
        textDecoration: TextDecoration.none,
        fontWeight: FontWeight.w600,
      ),
    };
    return Html(
      data: htmlContent,
      style: htmlStyle,
      onLinkTap: _action,
    );
  }
}
