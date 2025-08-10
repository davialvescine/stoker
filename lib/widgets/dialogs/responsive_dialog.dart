import 'package:flutter/material.dart';
import '../../core/utils/responsive_helper.dart';

class ResponsiveDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<Widget> actions;

  const ResponsiveDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: ResponsiveHelper.isLargeScreen(context)
          ? const EdgeInsets.symmetric(horizontal: 200, vertical: 100)
          : const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      title: Text(title, textAlign: TextAlign.center),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Text(content, textAlign: TextAlign.center),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: actions,
    );
  }
}
