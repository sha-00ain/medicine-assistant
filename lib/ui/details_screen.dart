import 'package:flutter/material.dart';
import 'package:medicine_app/core/strings.dart';
import 'package:medicine_app/data/models.dart';
import 'package:medicine_app/logic/confirmation.dart';
import 'package:medicine_app/logic/query_parser.dart';
import 'package:medicine_app/logic/section_builder.dart';
import 'package:medicine_app/state/app_state.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailsScreen extends StatelessWidget {
  const DetailsScreen({
    super.key,
    required this.confirmed,
    required this.allMedicines,
    required this.query,
  });

  final ConfirmedMedicine confirmed;
  final List<Medicine> allMedicines;
  final ParsedQuery query;

  @override
  Widget build(BuildContext context) {
    final lang = AppScope.of(context).lang;
    final medicine = confirmed.medicine;
    final views = SectionBuilder.buildAll(confirmed, allMedicines, lang);
    final intent = query.intent;
    final asked = query.looksLikeQuestion;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final children = <Widget>[];

    if (medicine.isDemo) {
      children.add(
        Card(
          color: scheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(Strings.t(lang, 'demo.banner')),
          ),
        ),
      );
    }

    children.add(_Header(medicine: medicine));

    children.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          Strings.t(lang, 'disclaimer'),
          style: textTheme.bodySmall,
        ),
      ),
    );

    if (confirmed.fromPhoto) {
      children.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(Strings.t(lang, 'photo.noAuthenticity')),
          ),
        ),
      );
    }

    if (asked) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('${Strings.t(lang, 'details.question')}: ${query.raw}'),
        ),
      );
    }

    if (intent != null) {
      // The direct answer always comes first, before the full details.
      final answer = SectionBuilder.build(intent, confirmed, allMedicines, lang);
      children.add(
        Card(
          color: scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Strings.t(lang, 'details.direct'),
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  Strings.section(lang, intent),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                _SectionBody(view: answer, lang: lang),
              ],
            ),
          ),
        ),
      );
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            Strings.t(lang, 'details.full'),
            style: textTheme.titleLarge,
          ),
        ),
      );
    } else if (asked) {
      children.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(Strings.t(lang, 'details.noIntent')),
          ),
        ),
      );
    }

    for (final view in views) {
      children.add(
        _SectionTile(
          view: view,
          lang: lang,
          initiallyExpanded: intent == null,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(medicine.brandName)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.medicine});

  final Medicine medicine;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final strengthForm =
        [medicine.strength, medicine.dosageForm].whereType<String>().join(' \u2022 ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(medicine.brandName, style: textTheme.headlineSmall),
            if (medicine.genericName.isNotEmpty) Text(medicine.genericName),
            if (strengthForm.isNotEmpty) Text(strengthForm),
            if (medicine.manufacturer != null) Text(medicine.manufacturer!),
          ],
        ),
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.view,
    required this.lang,
    required this.initiallyExpanded,
  });

  final SectionView view;
  final String lang;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        title: Text(
          Strings.section(lang, view.id),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.centerLeft,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [_SectionBody(view: view, lang: lang)],
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.view, required this.lang});

  final SectionView view;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!view.available)
          Text(Strings.t(lang, 'info.na'))
        else
          for (final line in view.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line),
            ),
        for (final note in view.notes)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              note,
              style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
        for (final source in view.sources)
          _SourceBlock(source: source, lang: lang),
      ],
    );
  }
}

class _SourceBlock extends StatelessWidget {
  const _SourceBlock({required this.source, required this.lang});

  final SourceInfo source;
  final String lang;

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final failedText = Strings.t(lang, 'source.openFailed');
    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse(source.url!),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(failedText)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final verificationKey = 'verification.${source.verification}';
    final verification = Strings.has(verificationKey)
        ? Strings.t(lang, verificationKey)
        : source.verification;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${Strings.t(lang, 'source.label')}: ${source.name}',
            style: textTheme.bodySmall,
          ),
          Text(
            '${Strings.t(lang, 'source.verification')}: $verification'
            ' \u2022 ${Strings.t(lang, 'source.lastChecked')}: ${source.lastChecked}',
            style: textTheme.bodySmall,
          ),
          if (source.url != null)
            TextButton.icon(
              onPressed: () => _open(context),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(Strings.t(lang, 'source.open')),
            ),
        ],
      ),
    );
  }
}
