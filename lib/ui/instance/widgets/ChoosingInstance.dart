// ignore: file_names
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:whypost/routing/router.dart';
import 'package:whypost/routing/routes.dart';
import 'package:whypost/sharedpreferences/credentials.dart';

class ChooseInstancePage extends ConsumerStatefulWidget {
  const ChooseInstancePage({super.key});

  @override
  ConsumerState<ChooseInstancePage> createState() => _ChooseInstancePageState();
}

class _ChooseInstancePageState extends ConsumerState<ChooseInstancePage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController(text: 'https://mastodon.social');
  bool _loading = false;
  String? _message;

  String? _validateInstance(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter the instance URL.';
    final text = v.trim();
    if (!text.startsWith('http')) {
      return 'Use the full URL format (https://...).';
    }
    if (!text.contains('.')) return 'The instance URL looks invalid.';
    return null;
  }

  Future<void> _checkInstance() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    final instance = _controller.text.trim();

    try {
      final nodeinfo = await detectNodeInfo(instance);
      final software = nodeinfo['software'];

      if (software == null) {
        throw Exception("Node info missing: software");
      }

      if (software is String) {
        await CredentialsRepository.setSoftwareName(software);
      }

      if (software is Map<String, dynamic>) {
        final name = software['name'];

        if (name is String) {
          await CredentialsRepository.setSoftwareName(name);
        } else if (name is Map) {
          await CredentialsRepository.setSoftwareName(name.values.first);
        } else {
          throw Exception("Unknown fediverse software instance format");
        }
      }

      final uri = Uri.parse('$instance/api/v1/instance');
      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 7),
            onTimeout: () {
              throw TimeoutException("Instance take too longer to respond");
            },
          );
      dynamic jsonData;
      if (response.statusCode == 200) {
        jsonData = jsonDecode(response.body);

        final data = jsonDecode(response.body);

        if (data is! Map<String, dynamic>) {
          throw Exception("Response isn't valid (not JSON object)");
        }

        if (data['uri'] == null || data['registrations'] == null) {
          throw Exception("Instance isn't fediverse or mastodon compatible");
        }
      } else {
        throw Exception("Failed to checking instance");
      }

      setState(() {
        _message = 'Instance detected: $instance';
      });
      jsonData['uri'] = normalizeUrl(jsonData['uri']);

      router.push(Routes.instanceAuthPage, extra: {"instanceData": jsonData});
    } on TimeoutException catch (_) {
      setState(() {
        _message = "Request timed out. The server is too slow.";
      });
    } catch (e) {
      setState(() {
        _message = "$e";
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String normalizeUrl(String? url) {
    if (url == null || url.trim().isEmpty) return "";

    var u = url.trim();

    if (!u.startsWith("http://") && !u.startsWith("https://")) {
      u = "https://$u";
    }

    if (u.endsWith("/")) {
      u = u.substring(0, u.length - 1);
    }

    return u;
  }

  Future<dynamic> detectNodeInfo(String instance) async {
    try {
      final wellKnownUri = Uri.parse('$instance/.well-known/nodeinfo');
      final wellKnownRes = await http
          .get(wellKnownUri)
          .timeout(
            const Duration(seconds: 7),
            onTimeout: () {
              throw TimeoutException("Instance is too slow to respond");
            },
          );

      if (wellKnownRes.statusCode != 200) {
        throw Exception("Failed to fetch .well-known/nodeinfo");
      }

      final wellKnownJson = jsonDecode(wellKnownRes.body);

      if (wellKnownJson['links'] == null ||
          wellKnownJson['links'] is! List ||
          wellKnownJson['links'].isEmpty) {
        throw Exception("No nodeinfo links found");
      }

      List links = wellKnownJson['links'];
      links.sort((a, b) => b['rel'].compareTo(a['rel'])); // sort descending
      final firstHref = links.first['href'];
      if (firstHref == null) {
        throw Exception("Nodeinfo href is null");
      }

      final nodeinfoUri = Uri.parse(firstHref);

      final nodeinfoRes = await http
          .get(nodeinfoUri)
          .timeout(
            const Duration(seconds: 7),
            onTimeout: () => throw TimeoutException("Nodeinfo URL timeout"),
          );

      if (nodeinfoRes.statusCode != 200) {
        throw Exception("Failed to fetch nodeinfo detail");
      }

      final nodeinfo = jsonDecode(nodeinfoRes.body);

      return nodeinfo;
    } catch (e) {
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Fediverse Instance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter Fediverse Instance URL\n',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _controller,
                validator: _validateInstance,
                decoration: InputDecoration(
                  labelText: 'Instance URL',
                  fillColor: Colors.white,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  prefixIcon: Icon(Icons.link),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: _loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_done),
                label: Text(
                  _loading ? 'Checking...' : 'Use Instance',
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                // style: ButtonStyle(
                //   backgroundColor: WidgetStateProperty.all(
                //     Theme.of(context).colorScheme.onSurface,
                //   ),
                // ),
                onPressed: _loading ? null : _checkInstance,
              ),
              const SizedBox(height: 20),
              if (_message != null)
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _message!.contains('Fail')
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
