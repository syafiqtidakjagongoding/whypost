import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class TermsRenderer extends StatelessWidget {
  final String? htmlTerms;
  final String? textFallback;

  const TermsRenderer({super.key, required this.htmlTerms, this.textFallback});

  @override
  Widget build(BuildContext context) {
    final hasHtml = htmlTerms != null && htmlTerms!.isNotEmpty;

    if (!hasHtml && (textFallback == null || textFallback!.isEmpty)) {
      return const SizedBox.shrink(); // nggak render apa-apa
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Terms And Use",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                textAlign: TextAlign.left, // opsional, untuk jaga-jaga
              ),
              hasHtml
                  ? Html(
                      data: htmlTerms!,
                      style: {
                        "body": Style(
                          fontSize: FontSize(14),
                          color: Colors.grey[800],
                          lineHeight: LineHeight.number(1.5),
                          margin: Margins.zero,
                        ),
                        "p": Style(margin: Margins.only(bottom: 8)),
                        "ol": Style(padding: HtmlPaddings.only(left: 20)),
                        "li": Style(margin: Margins.only(bottom: 4)),
                      },
                    )
                  : Text(
                      textFallback!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
