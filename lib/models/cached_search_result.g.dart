// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_search_result.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCachedSearchResultCollection on Isar {
  IsarCollection<CachedSearchResult> get cachedSearchResults =>
      this.collection();
}

const CachedSearchResultSchema = CollectionSchema(
  name: r'CachedSearchResult',
  id: -1175092088283525901,
  properties: {
    r'expiresAt': PropertySchema(
      id: 0,
      name: r'expiresAt',
      type: IsarType.dateTime,
    ),
    r'propertyIds': PropertySchema(
      id: 1,
      name: r'propertyIds',
      type: IsarType.stringList,
    ),
    r'queryKey': PropertySchema(
      id: 2,
      name: r'queryKey',
      type: IsarType.string,
    )
  },
  estimateSize: _cachedSearchResultEstimateSize,
  serialize: _cachedSearchResultSerialize,
  deserialize: _cachedSearchResultDeserialize,
  deserializeProp: _cachedSearchResultDeserializeProp,
  idName: r'id',
  indexes: {
    r'queryKey': IndexSchema(
      id: 1924554350003761257,
      name: r'queryKey',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'queryKey',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _cachedSearchResultGetId,
  getLinks: _cachedSearchResultGetLinks,
  attach: _cachedSearchResultAttach,
  version: '3.1.0+1',
);

int _cachedSearchResultEstimateSize(
  CachedSearchResult object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.propertyIds.length * 3;
  {
    for (var i = 0; i < object.propertyIds.length; i++) {
      final value = object.propertyIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.queryKey.length * 3;
  return bytesCount;
}

void _cachedSearchResultSerialize(
  CachedSearchResult object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.expiresAt);
  writer.writeStringList(offsets[1], object.propertyIds);
  writer.writeString(offsets[2], object.queryKey);
}

CachedSearchResult _cachedSearchResultDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CachedSearchResult(
    expiresAt: reader.readDateTime(offsets[0]),
    propertyIds: reader.readStringList(offsets[1]) ?? [],
    queryKey: reader.readString(offsets[2]),
  );
  object.id = id;
  return object;
}

P _cachedSearchResultDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _cachedSearchResultGetId(CachedSearchResult object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _cachedSearchResultGetLinks(
    CachedSearchResult object) {
  return [];
}

void _cachedSearchResultAttach(
    IsarCollection<dynamic> col, Id id, CachedSearchResult object) {
  object.id = id;
}

extension CachedSearchResultByIndex on IsarCollection<CachedSearchResult> {
  Future<CachedSearchResult?> getByQueryKey(String queryKey) {
    return getByIndex(r'queryKey', [queryKey]);
  }

  CachedSearchResult? getByQueryKeySync(String queryKey) {
    return getByIndexSync(r'queryKey', [queryKey]);
  }

  Future<bool> deleteByQueryKey(String queryKey) {
    return deleteByIndex(r'queryKey', [queryKey]);
  }

  bool deleteByQueryKeySync(String queryKey) {
    return deleteByIndexSync(r'queryKey', [queryKey]);
  }

  Future<List<CachedSearchResult?>> getAllByQueryKey(
      List<String> queryKeyValues) {
    final values = queryKeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'queryKey', values);
  }

  List<CachedSearchResult?> getAllByQueryKeySync(List<String> queryKeyValues) {
    final values = queryKeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'queryKey', values);
  }

  Future<int> deleteAllByQueryKey(List<String> queryKeyValues) {
    final values = queryKeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'queryKey', values);
  }

  int deleteAllByQueryKeySync(List<String> queryKeyValues) {
    final values = queryKeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'queryKey', values);
  }

  Future<Id> putByQueryKey(CachedSearchResult object) {
    return putByIndex(r'queryKey', object);
  }

  Id putByQueryKeySync(CachedSearchResult object, {bool saveLinks = true}) {
    return putByIndexSync(r'queryKey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByQueryKey(List<CachedSearchResult> objects) {
    return putAllByIndex(r'queryKey', objects);
  }

  List<Id> putAllByQueryKeySync(List<CachedSearchResult> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'queryKey', objects, saveLinks: saveLinks);
  }
}

extension CachedSearchResultQueryWhereSort
    on QueryBuilder<CachedSearchResult, CachedSearchResult, QWhere> {
  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CachedSearchResultQueryWhere
    on QueryBuilder<CachedSearchResult, CachedSearchResult, QWhereClause> {
  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterWhereClause>
      queryKeyEqualTo(String queryKey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'queryKey',
        value: [queryKey],
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterWhereClause>
      queryKeyNotEqualTo(String queryKey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'queryKey',
              lower: [],
              upper: [queryKey],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'queryKey',
              lower: [queryKey],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'queryKey',
              lower: [queryKey],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'queryKey',
              lower: [],
              upper: [queryKey],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CachedSearchResultQueryFilter
    on QueryBuilder<CachedSearchResult, CachedSearchResult, QFilterCondition> {
  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      expiresAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      expiresAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      expiresAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expiresAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      expiresAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expiresAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      propertyIdsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      propertyIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'propertyIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      propertyIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'propertyIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      propertyIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'propertyIds',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      propertyIdsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'propertyIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      propertyIdsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'propertyIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      propertyIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'propertyIds',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      propertyIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'propertyIds',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      propertyIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyIds',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      propertyIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'propertyIds',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      propertyIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'propertyIds',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      propertyIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'propertyIds',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      propertyIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'propertyIds',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      propertyIdsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'propertyIds',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      propertyIdsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'propertyIds',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      propertyIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'propertyIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      queryKeyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'queryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      queryKeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'queryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      queryKeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'queryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      queryKeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'queryKey',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      queryKeyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'queryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      queryKeyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'queryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      queryKeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'queryKey',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      queryKeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'queryKey',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      queryKeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'queryKey',
        value: '',
      ));
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterFilterCondition>
      queryKeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'queryKey',
        value: '',
      ));
    });
  }
}

extension CachedSearchResultQueryObject
    on QueryBuilder<CachedSearchResult, CachedSearchResult, QFilterCondition> {}

extension CachedSearchResultQueryLinks
    on QueryBuilder<CachedSearchResult, CachedSearchResult, QFilterCondition> {}

extension CachedSearchResultQuerySortBy
    on QueryBuilder<CachedSearchResult, CachedSearchResult, QSortBy> {
  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterSortBy>
      sortByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.asc);
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterSortBy>
      sortByExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.desc);
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterSortBy>
      sortByQueryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queryKey', Sort.asc);
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterSortBy>
      sortByQueryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queryKey', Sort.desc);
    });
  }
}

extension CachedSearchResultQuerySortThenBy
    on QueryBuilder<CachedSearchResult, CachedSearchResult, QSortThenBy> {
  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterSortBy>
      thenByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.asc);
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterSortBy>
      thenByExpiresAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expiresAt', Sort.desc);
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterSortBy>
      thenByQueryKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queryKey', Sort.asc);
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QAfterSortBy>
      thenByQueryKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'queryKey', Sort.desc);
    });
  }
}

extension CachedSearchResultQueryWhereDistinct
    on QueryBuilder<CachedSearchResult, CachedSearchResult, QDistinct> {
  QueryBuilder<CachedSearchResult, CachedSearchResult, QDistinct>
      distinctByExpiresAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expiresAt');
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QDistinct>
      distinctByPropertyIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'propertyIds');
    });
  }

  QueryBuilder<CachedSearchResult, CachedSearchResult, QDistinct>
      distinctByQueryKey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'queryKey', caseSensitive: caseSensitive);
    });
  }
}

extension CachedSearchResultQueryProperty
    on QueryBuilder<CachedSearchResult, CachedSearchResult, QQueryProperty> {
  QueryBuilder<CachedSearchResult, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CachedSearchResult, DateTime, QQueryOperations>
      expiresAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expiresAt');
    });
  }

  QueryBuilder<CachedSearchResult, List<String>, QQueryOperations>
      propertyIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'propertyIds');
    });
  }

  QueryBuilder<CachedSearchResult, String, QQueryOperations>
      queryKeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'queryKey');
    });
  }
}
