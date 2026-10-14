import 'package:flutter/material.dart';
import 'package:medicine_app/core/strings.dart';
import 'package:medicine_app/data/models.dart';
import 'package:medicine_app/data/source.dart';
import 'package:medicine_app/logic/confirmation.dart';
import 'package:medicine_app/logic/matcher.dart';
import 'package:medicine_app/logic/package_matcher.dart';
import 'package:medicine_app/logic/query_parser.dart';
import 'package:medicine_app/logic/search_service.dart';
import 'package:medicine_app/ocr/ocr_service.dart';
import 'package:medicine_app/state/app_state.dart';
import 'package:medicine_app/ui/details_screen.dart';

enum _LoadState { loading, ready, error }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.source,
    required this.imageSource,
    required this.ocr,
  });

  final MedicineSourceProvider source;
  final ImageSourceService imageSource;
  final OcrService ocr;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MedicineRepository _repository;
  late final SearchService _service;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  _LoadState _state = _LoadState.loading;
  SearchOutcome? _outcome;

  bool _busy = false;
  PhotoMatch? _photo;
  ParsedQuery? _photoQuery;
  bool _photoError = false;

  @override
  void initState() {
    super.initState();
    _repository = MedicineRepository(widget.source);
    _service = SearchService(_repository);
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _repository.all();
      if (!mounted) return;
      setState(() => _state = _LoadState.ready);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _LoadState.error);
    }
  }

  void _retry() {
    setState(() => _state = _LoadState.loading);
    _repository.reset();
    _load();
  }

  Future<void> _onSearch() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();

    final SearchOutcome outcome;
    try {
      outcome = await _service.search(text);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _LoadState.error);
      return;
    }
    if (!mounted) return;

    if (outcome.result.status == MatchStatus.confident) {
      setState(() {
        _outcome = null;
        _photo = null;
        _photoError = false;
      });
      await _openDetails(
        ConfirmedMedicine.fromMatch(outcome.result),
        outcome.query,
      );
    } else {
      setState(() {
        _outcome = outcome;
        _photo = null;
        _photoError = false;
      });
    }
  }

  /// Photo flow: pick or capture an image, read its text, match the text
  /// against the medicine records. No question is needed. If something is
  /// typed in the box it is used only as the question.
  Future<void> _onPhoto(PhotoSource source) async {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    final query = QueryParser.parse(_controller.text);
    setState(() => _busy = true);
    try {
      final path = await widget.imageSource.pick(source);
      if (path == null) {
        // The user cancelled; leave the screen as it was.
        if (mounted) setState(() => _busy = false);
        return;
      }
      if (mounted) {
        setState(() {
          _outcome = null;
          _photo = null;
          _photoError = false;
        });
      }
      final ocr = await widget.ocr.recognize(path);
      final all = await _repository.all();
      final match = PackageMatcher.match(ocr, all);
      if (!mounted) return;
      setState(() => _busy = false);
      if (match.kind == PhotoMatchKind.confident) {
        await _openDetails(
          ConfirmedMedicine.fromMatch(match.toMatchResult(), fromPhoto: true),
          query,
        );
      } else if (mounted) {
        setState(() {
          _photo = match;
          _photoQuery = query;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _photoError = true;
      });
    }
  }

  Future<void> _openDetails(ConfirmedMedicine confirmed, ParsedQuery query) async {
    final all = await _repository.all();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailsScreen(
          confirmed: confirmed,
          allMedicines: all,
          query: query,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lang = app.lang;
    return Scaffold(
      appBar: AppBar(
        title: Text(Strings.t(lang, 'app.title')),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: Strings.t(lang, 'language'),
            onSelected: app.setLang,
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                value: 'bn',
                child: Text(Strings.t(lang, 'lang.bn')),
              ),
              PopupMenuItem<String>(
                value: 'en',
                child: Text(Strings.t(lang, 'lang.en')),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(child: _body(context, lang)),
    );
  }

  Widget _body(BuildContext context, String lang) {
    switch (_state) {
      case _LoadState.loading:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(Strings.t(lang, 'loading')),
            ],
          ),
        );
      case _LoadState.error:
        return _errorView(context, lang);
      case _LoadState.ready:
        return _searchView(context, lang);
    }
  }

  Widget _errorView(BuildContext context, String lang) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: scheme.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Strings.t(lang, 'error.title'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(Strings.t(lang, 'error.body')),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _retry,
                  child: Text(Strings.t(lang, 'retry')),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _searchView(BuildContext context, String lang) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _onSearch(),
          decoration: InputDecoration(
            hintText: Strings.t(lang, 'search.hint'),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: _onSearch,
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _onSearch,
          child: Text(Strings.t(lang, 'search.button')),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _onPhoto(PhotoSource.camera),
                icon: const Icon(Icons.photo_camera),
                label: Text(Strings.t(lang, 'photo.take')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _onPhoto(PhotoSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: Text(Strings.t(lang, 'photo.gallery')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          Strings.t(lang, 'disclaimer'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (_busy) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(Strings.t(lang, 'photo.reading')),
        ] else ...[
          _outcomeView(context, lang),
          _photoView(context, lang),
        ],
      ],
    );
  }

  Widget _outcomeView(BuildContext context, String lang) {
    final outcome = _outcome;
    if (outcome == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;

    if (outcome.result.status == MatchStatus.notFound) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Strings.t(lang, 'notfound.title'),
                  style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(Strings.t(lang, 'notfound.body')),
            ],
          ),
        ),
      );
    }

    final candidates = outcome.result.candidates;
    final title = candidates.length == 1
        ? Strings.t(lang, 'clarify.single')
        : Strings.t(lang, 'clarify.title');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(Strings.t(lang, 'clarify.body')),
        const SizedBox(height: 8),
        // Only identity fields are shown here. No dosage or other
        // medicine-specific details appear until the user confirms.
        for (final c in candidates)
          _candidateTile(lang, c, outcome.query, fromPhoto: false),
      ],
    );
  }

  Widget _photoView(BuildContext context, String lang) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (_photoError) {
      return Card(
        color: scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Strings.t(lang, 'photo.error.title'),
                  style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(Strings.t(lang, 'photo.error.body')),
              const SizedBox(height: 12),
              _retakeButtons(lang),
            ],
          ),
        ),
      );
    }

    final photo = _photo;
    if (photo == null) return const SizedBox.shrink();

    final children = <Widget>[];
    switch (photo.kind) {
      case PhotoMatchKind.unreadable:
        children.addAll([
          Text(Strings.t(lang, 'photo.unreadable.title'),
              style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(Strings.t(lang, 'photo.unreadable.body')),
          const SizedBox(height: 12),
          _retakeButtons(lang),
        ]);
      case PhotoMatchKind.notFound:
        children.addAll([
          Text(Strings.t(lang, 'photo.notfound.title'),
              style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(Strings.t(lang, 'photo.notfound.body')),
          const SizedBox(height: 12),
          _retakeButtons(lang),
        ]);
      case PhotoMatchKind.ambiguous:
      case PhotoMatchKind.confident:
        final query = _photoQuery ?? QueryParser.parse('');
        children.addAll([
          Text(
            photo.candidates.length == 1
                ? Strings.t(lang, 'clarify.single')
                : Strings.t(lang, 'clarify.title'),
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(Strings.t(lang, 'photo.ambiguous.note')),
          const SizedBox(height: 8),
          for (final c in photo.candidates)
            _candidateTile(lang, c, query, fromPhoto: true),
          const SizedBox(height: 8),
          Text(
            Strings.t(lang, 'photo.noAuthenticity'),
            style: textTheme.bodySmall,
          ),
        ]);
    }

    final readText = photo.clues.text;
    if (readText.isNotEmpty) {
      children.add(
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(Strings.t(lang, 'photo.readText')),
          expandedAlignment: Alignment.centerLeft,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(readText)],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _retakeButtons(String lang) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _onPhoto(PhotoSource.camera),
          icon: const Icon(Icons.photo_camera),
          label: Text(Strings.t(lang, 'photo.retake')),
        ),
        OutlinedButton.icon(
          onPressed: () => _focusNode.requestFocus(),
          icon: const Icon(Icons.keyboard),
          label: Text(Strings.t(lang, 'photo.typeName')),
        ),
      ],
    );
  }

  Widget _candidateTile(
    String lang,
    Candidate c,
    ParsedQuery query, {
    required bool fromPhoto,
  }) {
    final m = c.medicine;
    final lines = <String>[_candidateSubtitle(m)];
    if (fromPhoto) {
      lines.add('${Strings.t(lang, 'photo.match')}: ${(c.score * 100).round()}%');
    }
    final subtitle = lines.where((l) => l.isNotEmpty).join('\n');
    return Card(
      child: ListTile(
        title: Text(_candidateTitle(m)),
        subtitle: Text(subtitle),
        isThreeLine: lines.length > 1,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openDetails(
          ConfirmedMedicine.userSelected(m, fromPhoto: fromPhoto),
          query,
        ),
      ),
    );
  }

  String _candidateTitle(Medicine m) {
    final parts = <String>[m.brandName];
    if (m.strength != null) parts.add(m.strength!);
    final base = parts.join(' ');
    return m.dosageForm == null ? base : '$base (${m.dosageForm})';
  }

  String _candidateSubtitle(Medicine m) {
    final parts = <String>[m.genericName];
    if (m.manufacturer != null) parts.add(m.manufacturer!);
    return parts.where((p) => p.isNotEmpty).join(' \u2022 ');
  }
}
