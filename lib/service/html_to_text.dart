

import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

/// Converts HTML content to plain text while preserving hashtags, mentions, and URLs
String htmlToText(String html) {
  final document = html_parser.parse(html);
  return _processNode(document.body);
}

String _processNode(dom.Node? node) {
  if (node == null) return '';

  if (node.nodeType == dom.Node.TEXT_NODE) {
    return node.text ?? '';
  }

  if (node is dom.Element) {
    final tag = node.localName?.toLowerCase();

    // Handle links (hashtags, mentions, URLs)
    if (tag == 'a') {
      final classes = node.classes.toList();
      final href = node.attributes['href'] ?? '';

      // Hashtag
      if (classes.contains('hashtag') || href.contains('/tags/')) {
        final text = node.text.trim();
        // If text already has #, return as is, otherwise add #
        return text.startsWith('#') ? text : '#$text';
      }

      // Mention
      if (classes.contains('mention') ||
          href.startsWith('@') ||
          href.contains('/@')) {
        final text = node.text.trim();
        // Return the mention as is (usually already has @)
        return text;
      }

      // Regular URL - return the href or text
      return node.text.trim();
    }

    // Handle line breaks
    if (tag == 'br') {
      return '\n';
    }

    // Handle paragraphs
    if (tag == 'p') {
      final content = node.nodes.map(_processNode).join('');
      return '$content\n\n';
    }

    // Handle other block elements (div, blockquote, etc.)
    if (tag == 'div' || tag == 'blockquote' || tag == 'article') {
      return node.nodes.map(_processNode).join('');
    }

    // Recursively process child nodes for other elements
    return node.nodes.map(_processNode).join('');
  }

  return '';
}

/// Alternative simpler version using RegEx (less accurate but faster)
String htmlToTextSimple(String html) {
  String text = html;

  // Extract hashtags from links and preserve them
  text = text.replaceAllMapped(
    RegExp(
      r'<a[^>]*class="[^"]*hashtag[^"]*"[^>]*>([^<]+)</a>',
      caseSensitive: false,
    ),
    (match) {
      final tagText = match.group(1) ?? '';
      return tagText.startsWith('#') ? tagText : '#$tagText';
    },
  );

  // Extract mentions from links and preserve them
  text = text.replaceAllMapped(
    RegExp(
      r'<a[^>]*class="[^"]*mention[^"]*"[^>]*>([^<]+)</a>',
      caseSensitive: false,
    ),
    (match) => match.group(1) ?? '',
  );

  // Replace <br> with newlines
  text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

  // Replace </p> with double newlines
  text = text.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');

  // Remove all other HTML tags
  text = text.replaceAll(RegExp(r'<[^>]*>'), '');

  // Decode HTML entities
  text = _decodeHtmlEntities(text);

  // Clean up extra whitespace
  text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  text = text.trim();

  return text;
}

/// Decode common HTML entities
String _decodeHtmlEntities(String text) {
  return text
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ');
}
