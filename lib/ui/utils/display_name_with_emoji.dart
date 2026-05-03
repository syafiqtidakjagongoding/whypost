import 'package:flutter/material.dart';

Widget displayNameWithEmoji(
  Map<String, dynamic> account,
  BuildContext context, [
  String? suffix,
]) {
  final displayName = account['display_name'] == ""
      ? account['username']
      : account['display_name'];
  final emojis = account['emojis'] as List<dynamic>? ?? [];

  final regex = RegExp(r':([a-zA-Z0-9_]+):');

  List<InlineSpan> children = [];

  displayName.splitMapJoin(
    regex,
    onMatch: (m) {
      final shortcode = m.group(1);

      final emoji = emojis.firstWhere(
        (e) => e['shortcode'] == shortcode,
        orElse: () => null,
      );

      if (emoji != null) {
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Image.network(emoji['url'], width: 20, height: 20),
          ),
        );
      } else {
        children.add(TextSpan(text: m.group(0)));
      }

      return '';
    },
    onNonMatch: (text) {
      children.add(TextSpan(text: text));
      return '';
    },
  );

  if (suffix != null && suffix.isNotEmpty) {
    children.add(TextSpan(text: suffix));
  }

  return RichText(
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    text: TextSpan(
      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      children: children,
    ),
  );
}
