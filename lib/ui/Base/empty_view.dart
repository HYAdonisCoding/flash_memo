

import 'package:flutter/material.dart';

/// A reusable widget to display an empty state view with an icon, title, and optional subtitle.
///
/// Parameters:
///   [icon]: The icon to display at the top (required, type IconData).
///   [title]: The title string displayed below the icon (required).
///   [subtitle]: An optional subtitle string displayed below the title.
class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  /// Optional callback when the title is tapped.
  /// If null, tapping the title does nothing.
  final VoidCallback? onTap;

  /// Creates an [EmptyView].
  ///
  /// [icon] and [title] are required, [subtitle] and [onTap] are optional.
  /// [onTap] is called when the title text is tapped, if provided.
  const EmptyView({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap, // New optional onTap parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 72.0,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24.0),
            // Wrap the title with GestureDetector to handle onTap if provided
            GestureDetector(
              onTap: onTap, // Calls onTap if not null
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 12.0),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 14.0,
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}