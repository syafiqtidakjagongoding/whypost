import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutApp extends StatelessWidget {
  const AboutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About App'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "What is the Fediverse?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "The Fediverse is a decentralized social network made up of many "
                "servers (instances) that are connected to each other. Users are free "
                "to choose any server they like, yet still interact with people on "
                "other servers. The network uses the ActivityPub protocol, which allows "
                "different platforms such as Mastodon, Misskey, Pleroma, Lemmy, and "
                "many others to communicate with each other even though they are separate apps.",
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 32),

              const Text(
                "Resources",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              const Text(
                "Here are some useful resources to learn more about the Fediverse, "
                "ActivityPub, and available servers:",
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 16),

              ListTile(
                leading: const Icon(Icons.link),
                title: const Text("The Federation – List of Fediverse servers"),
                onTap: () {
                  launchUrl(Uri.parse("https://the-federation.info/"));
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text(
                  "JoinFediverse – Beginner-friendly explanation",
                ),
                onTap: () {
                  launchUrl(Uri.parse("https://joinfediverse.wiki/"));
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text("ActivityPub Specification (W3C)"),
                onTap: () {
                  launchUrl(Uri.parse("https://www.w3.org/TR/activitypub/"));
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text("Mastodon Documentation"),
                onTap: () {
                  launchUrl(Uri.parse("https://docs.joinmastodon.org/"));
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text("Misskey Documentation"),
                onTap: () {
                  launchUrl(Uri.parse("https://misskey-hub.net/en/"));
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text("Pleroma Documentation"),
                onTap: () {
                  launchUrl(Uri.parse("https://docs-develop.pleroma.social/"));
                },
              ),

              const SizedBox(height: 20),

              const SizedBox(height: 20),

              const SizedBox(height: 32),

              const Text(
                "About Whypost",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Whypost is a Fediverse client for mobile application designed to help you explore and interact "
                "with decentralized social networks. With Whypost, you can browse your "
                "timeline, create posts, boost, favorite, reply, follow users from any "
                "server, and manage your profile with a smooth and lightweight experience. Tthis app are support for mastodon, akkoma,pleroma, friendica instance",
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 32),

              const Text(
                "Contribute",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Whypost is an open project. You are welcome to provide feedback or "
                "contribute to the development through Matrix",
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  launchUrl(
                    Uri.parse("https://matrix.to/#/#whypost:matrix.org"),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: const Text(
                  "#whypost:matrix.org",
                  style: TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                    color: Color.fromRGBO(255, 117, 31, 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
