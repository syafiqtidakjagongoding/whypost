import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InstanceLink extends StatelessWidget {
  final String uri;
  const InstanceLink({super.key, required this.uri});

  Future<void> _launchURL() async {
    final url = Uri.parse(uri.startsWith('http') ? uri : 'https://$uri');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw "Can't open $url";
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _launchURL,
      child: Text(
        uri,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.blue,
              fontSize: 20
            ),
      ),
    );
  }
}
