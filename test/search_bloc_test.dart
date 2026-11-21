import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:loomea/data/models/salon_model.dart';
import 'package:loomea/data/models/smart_search_model.dart';
import 'package:loomea/data/repositories/loomea_repository.dart';
import 'package:loomea/logic/blocs/search/search_bloc.dart';
import 'package:loomea/logic/blocs/search/search_event.dart';

class _FakeRepository implements LoomeeaRepository {
  final smartResponses = <Completer<SmartSearchResult>>[];

  @override
  Future<SmartSearchResult> smartSearch(String query) {
    final completer = Completer<SmartSearchResult>();
    smartResponses.add(completer);
    return completer.future;
  }

  @override
  Future<List<Salon>> searchSalons(String query) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('smart search exposes the interpreted filters', () async {
    final repository = _FakeRepository();
    final bloc = SearchBloc(repository: repository);

    bloc.add(const SmartSearch('manucure à Sousse demain'));
    await _settle();
    repository.smartResponses.single.complete(const SmartSearchResult(
      salons: [],
      aiUsed: true,
      filters: SmartSearchFilters(category: 'Nails', location: 'Sousse'),
    ));
    await _settle();

    expect(bloc.state.isSmartMode, isTrue);
    expect(bloc.state.aiUsed, isTrue);
    expect(bloc.state.smartFilters?.location, 'Sousse');
    await bloc.close();
  });

  test('a slow smart search does not overwrite newer keyword results',
      () async {
    final repository = _FakeRepository();
    final bloc = SearchBloc(repository: repository);

    bloc.add(const SmartSearch('haircut tomorrow'));
    await _settle();
    bloc.add(const SearchSalons('hair'));
    await _settle();
    repository.smartResponses.single.complete(const SmartSearchResult(
      salons: [],
      aiUsed: true,
      filters: SmartSearchFilters(category: 'Hair'),
    ));
    await _settle();

    expect(bloc.state.query, 'hair');
    expect(bloc.state.isSmartMode, isFalse);
    expect(bloc.state.smartFilters, isNull);
    await bloc.close();
  });
}
