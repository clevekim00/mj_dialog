import 'package:flutter/material.dart';
import 'package:speech_rehab/l10n/app_localizations.dart';
import 'package:speech_rehab/l10n/app_localizations_ko.dart';

AppLocalizations rehabL10n(BuildContext context) =>
    AppLocalizations.of(context) ?? AppLocalizationsKo();
bool rehabEnglish(BuildContext context) =>
    rehabL10n(context).localeName.startsWith('en');

class RehabCard extends StatelessWidget {
  const RehabCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      minVerticalPadding: 18,
      leading: Icon(icon, color: Colors.lightBlueAccent),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(subtitle),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class RehabPage extends StatelessWidget {
  const RehabPage({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.footer,
  });
  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final Widget? footer;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(20),
                  children: children,
                ),
              ),
            ),
          ),
          if (footer != null)
            SafeArea(
              top: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 760,
                  maxHeight: constraints.maxHeight * .55,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: footer!,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
