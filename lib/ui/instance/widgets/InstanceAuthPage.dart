import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:whypost/constant/config.dart';
import 'package:whypost/constant/instanceConfig.dart';
import 'package:whypost/sharedpreferences/credentials.dart';
import 'package:whypost/ui/instance/widgets/RulesRenderer.dart';
import 'package:whypost/ui/utils/InstanceLink.dart';
import 'package:url_launcher/url_launcher.dart';
import 'TermsRenderer.dart';

class InstanceAuthPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> instanceData;

  const InstanceAuthPage({super.key, required this.instanceData});

  @override
  ConsumerState<InstanceAuthPage> createState() => _InstanceAuthPage();
}

class _InstanceAuthPage extends ConsumerState<InstanceAuthPage> {
  late Map<String, dynamic> instanceData;

  Future<void> _handleAuthorizationToServer() async {
    try {
      final baseUri = instanceData['uri'];
      if (baseUri == null) {
        throw Exception("Instance base URL is missing");
      }
      final appRegUrl = Uri.parse(baseUri).resolve("/api/v1/apps");

      final appRegRes = await http.post(
        appRegUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'client_name': CLIENT_NAME,
          'redirect_uris': REDIRECT_URL,
          'scopes': INSTANCE_SCOPE,
        }),
      );

      if (appRegRes.statusCode != 200) {
        throw Exception("Failed to register app: ${appRegRes.body}");
      }

      final regJson = jsonDecode(appRegRes.body);
      final clientId = regJson['client_id'];
      final clientSecret = regJson['client_secret'];

      if (clientId == null || clientSecret == null) {
        throw Exception("Invalid app registration response");
      }

      final authUrl = Uri.parse(baseUri).replace(
        path: "/oauth/authorize",
        queryParameters: {
          'response_type': 'code',
          'client_id': clientId,
          'redirect_uri': REDIRECT_URL,
          'scope': INSTANCE_SCOPE,
        },
      );
      await CredentialsRepository.saveCredentials(
        null,
        baseUri,
        clientId,
        clientSecret,
      );

      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    instanceData = widget.instanceData;
  }

  @override
  Widget build(BuildContext context) {
    final title = instanceData['title'] ?? instanceData['uri'] ?? 'Unknown';
    final description = instanceData['short_description'] ?? '';
    final uri = instanceData['uri'] ?? '';
    final thumbnail = instanceData['thumbnail'];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (thumbnail != null)
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(thumbnail),
                    backgroundColor: Colors.grey[200],
                  ),
                const SizedBox(height: 16),
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                if (description.isNotEmpty)
                  Html(
                    data: description,
                    style: {
                      "body": Style(
                        fontSize: FontSize(15),
                        textAlign: TextAlign.center,
                      ),
                      "b": Style(fontWeight: FontWeight.bold),
                      "i": Style(fontStyle: FontStyle.italic),
                      "p": Style(margin: Margins.only(bottom: 8)),
                    },
                  ),
                if (uri.isNotEmpty) InstanceLink(uri: uri),
                const SizedBox(height: 24),

                RulesRenderer(rules: instanceData['rules']),
                TermsRenderer(
                  htmlTerms: instanceData['terms'],
                  textFallback: instanceData['terms_text'],
                ),

                const SizedBox(height: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _handleAuthorizationToServer();
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        "Next",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
