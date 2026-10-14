import 'package:medicine_app/data/source.dart';
import 'package:medicine_app/logic/matcher.dart';
import 'package:medicine_app/logic/query_parser.dart';

class SearchOutcome {
  const SearchOutcome(this.query, this.result);

  final ParsedQuery query;
  final MatchResult result;
}

class SearchService {
  SearchService(this._repository);

  final MedicineRepository _repository;

  Future<SearchOutcome> search(String input) async {
    final all = await _repository.all();
    final query = QueryParser.parse(input);
    return SearchOutcome(query, MedicineMatcher.match(query, all));
  }
}
