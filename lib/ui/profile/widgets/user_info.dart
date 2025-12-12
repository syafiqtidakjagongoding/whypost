import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:whypost/ui/utils/FullHTMLContent.dart';
import 'package:url_launcher/url_launcher.dart';

class UserInfoTextCard extends StatelessWidget {
  final Map<String, dynamic> account;
  UserInfoTextCard({super.key, required this.account});

  void _action(
    String? url,
    Map<String, String> attributes,
    dynamic element,
  ) async {
    final text = element?.text.trim() ?? url ?? '';
    if (text.isEmpty) return;

    final uri = Uri.parse(url!.startsWith('http') ? url : 'https://$url');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final emojis = account['emojis'] as List<dynamic>? ?? [];
    final fields = account['fields'] as List<dynamic>? ?? [];
    final roles = account['roles'] as List<dynamic>? ?? [];
    final role = account['role'] as Map<String, dynamic>?;
    final language = account['language'] ?? "";
    final isBot = account['bot'] == true;
    final isLocked = account['locked'] == true;
    final isSuspended = account['suspended'] == true;
    final isGroup = account['group'] == true;
    final discoverable = account['discoverable'] == true;
    final noindex = account['noindex'] == true;
    final textTheme = Theme.of(context).textTheme;

    DateTime? createdAt;
    if (account['created_at'] != null) {
      createdAt = DateTime.parse(account['created_at']).toLocal();
    }

    DateTime? lastStatusAt;
    if (account['last_status_at'] != null) {
      lastStatusAt = DateTime.parse(account['last_status_at']).toLocal();
    }

    final createdAtText = createdAt != null
        ? DateFormat('MMM dd, yyyy').format(createdAt)
        : 'N/A';
    final lastStatusAtText = lastStatusAt != null
        ? _getRelativeTime(lastStatusAt)
        : 'Never';

    return Padding(
      padding: EdgeInsetsGeometry.symmetric(vertical: 5, horizontal: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + Basic Info
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (isBot) _buildBadge(Icons.smart_toy, "Bot", Colors.blue),
              if (isLocked) _buildBadge(Icons.lock, "Private", Colors.orange),
              if (isSuspended)
                _buildBadge(Icons.block, "Suspended", Colors.red),
              if (isGroup) _buildBadge(Icons.group, "Group", Colors.purple),
              if (role != null) _buildRoleBadge(role['name'], role['color']),
            ],
          ),

          const SizedBox(height: 20),

          // Bio/Note
          if (account['note'] != null &&
              account['note'].toString().trim().isNotEmpty) ...[
            Text(
              "About",
              style: textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            FullHTMLContent(
              content: account['note'],
              emojis: emojis,
              mentions: [],
            ),
            SizedBox(height: 16),
          ],

          // Custom Fields
          if (fields.isNotEmpty) ...[
            Text(
              "Profile Fields",
              style: textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...fields.map((field) => _buildFieldItem(field)),
            SizedBox(height: 16),
          ],

          // Account Details Section
          Text(
            "Account Details",
            style: textTheme.labelMedium!.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),

          _buildDetailRow(
            Icons.calendar_today,
            "Joined",
            textTheme,

            createdAtText,
          ),
          _buildDetailRow(
            Icons.update,
            "Last Active",
            textTheme,

            lastStatusAtText,
          ),

          if (language.isNotEmpty)
            _buildDetailRow(
              Icons.language,
              "Language",
              textTheme,
              language.toUpperCase(),
            ),

          if (account['url'] != null)
            _buildDetailRow(
              Icons.link,
              "Profile URL",
              textTheme,

              account['url'],
              isLink: true,
            ),

          // Privacy & Visibility Settings
          if (discoverable || noindex || account['source'] != null) ...[
            SizedBox(height: 16),
            Text(
              "Privacy & Settings",
              style: textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),

            if (account['source'] != null) ...[
              if (account['source']['privacy'] != null)
                _buildDetailRow(
                  Icons.visibility,
                  "Default Privacy",
                  textTheme,
                  _formatPrivacy(account['source']['privacy']),
                ),
              if (account['source']['sensitive'] != null)
                _buildDetailRow(
                  Icons.warning_amber,
                  "Mark as Sensitive",
                  textTheme,

                  account['source']['sensitive'] ? "Yes" : "No",
                ),
            ],

            _buildDetailRow(
              Icons.search,
              "Discoverable",
              textTheme,

              discoverable ? "Yes" : "No",
            ),
            _buildDetailRow(
              Icons.visibility_off,
              "No Index",
              textTheme,

              noindex ? "Yes" : "No",
            ),
          ],

          // Additional Roles
          if (roles.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              "Additional Roles",
              style: textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles
                  .map(
                    (r) => Chip(
                      label: Text(
                        r['name'] ?? 'Unknown',
                        style: textTheme.labelSmall,
                      ),
                      backgroundColor: Colors.grey.shade200,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String label, String? colorHex) {
    Color color = Colors.grey;
    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
      } catch (e) {
        color = Colors.grey;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldItem(Map<String, dynamic> field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              field['name'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Html(
              data: field['value'] ?? '',
              style: {
                "body": Style(
                  fontSize: FontSize(14),
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                ),
                "a": Style(
                  color: const Color.fromRGBO(255, 117, 31, 1),
                  textDecoration: TextDecoration.none,
                  fontWeight: FontWeight.w600,
                ),
              },
              onLinkTap: _action,
            ),
          ),
          if (field['verified_at'] != null)
            const Icon(Icons.verified, color: Colors.green, size: 18),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    TextTheme textTheme,
    String value, {
    bool isLink = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: textTheme.labelMedium!.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w500
                  )
                ),
                const SizedBox(height: 2),
                isLink
                    ? GestureDetector(
                        onTap: () async {
                          final uri = Uri.parse(value);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: Text(
                          value,
                          style: textTheme.labelMedium!.copyWith(
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    : Text(
                        value,
                         style: textTheme.labelMedium!.copyWith(
                          decoration: TextDecoration.underline,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return "${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() > 1 ? 's' : ''} ago";
    } else if (difference.inDays > 30) {
      return "${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago";
    } else if (difference.inDays > 0) {
      return "${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago";
    } else {
      return "Just now";
    }
  }

  String _formatPrivacy(String privacy) {
    switch (privacy) {
      case 'public':
        return 'Public';
      case 'unlisted':
        return 'Unlisted';
      case 'private':
        return 'Followers Only';
      case 'direct':
        return 'Direct Messages';
      default:
        return privacy;
    }
  }
}
