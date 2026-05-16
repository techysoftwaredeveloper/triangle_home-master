// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_location.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLocalLocationCollection on Isar {
  IsarCollection<LocalLocation> get localLocations => this.collection();
}

const LocalLocationSchema = CollectionSchema(
  name: r'LocalLocation',
  id: -2289705439119577300,
  properties: {
    r'cityName': PropertySchema(
      id: 0,
      name: r'cityName',
      type: IsarType.string,
    ),
    r'isMajor': PropertySchema(
      id: 1,
      name: r'isMajor',
      type: IsarType.bool,
    ),
    r'lastUpdated': PropertySchema(
      id: 2,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'stateName': PropertySchema(
      id: 3,
      name: r'stateName',
      type: IsarType.string,
    )
  },
  estimateSize: _localLocationEstimateSize,
  serialize: _localLocationSerialize,
  deserialize: _localLocationDeserialize,
  deserializeProp: _localLocationDeserializeProp,
  idName: r'id',
  indexes: {
    r'cityName': IndexSchema(
      id: -4855891457126574856,
      name: r'cityName',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'cityName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _localLocationGetId,
  getLinks: _localLocationGetLinks,
  attach: _localLocationAttach,
  version: '3.1.0+1',
);

int _localLocationEstimateSize(
  LocalLocation object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.cityName.length * 3;
  {
    final value = object.stateName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _localLocationSerialize(
  LocalLocation object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cityName);
  writer.writeBool(offsets[1], object.isMajor);
  writer.writeDateTime(offsets[2], object.lastUpdated);
  writer.writeString(offsets[3], object.stateName);
}

LocalLocation _localLocationDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LocalLocation(
    cityName: reader.readString(offsets[0]),
    isMajor: reader.readBoolOrNull(offsets[1]) ?? false,
    stateName: reader.readStringOrNull(offsets[3]),
  );
  object.id = id;
  object.lastUpdated = reader.readDateTime(offsets[2]);
  return object;
}

P _localLocationDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _localLocationGetId(LocalLocation object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _localLocationGetLinks(LocalLocation object) {
  return [];
}

void _localLocationAttach(
    IsarCollection<dynamic> col, Id id, LocalLocation object) {
  object.id = id;
}

extension LocalLocationByIndex on IsarCollection<LocalLocation> {
  Future<LocalLocation?> getByCityName(String cityName) {
    return getByIndex(r'cityName', [cityName]);
  }

  LocalLocation? getByCityNameSync(String cityName) {
    return getByIndexSync(r'cityName', [cityName]);
  }

  Future<bool> deleteByCityName(String cityName) {
    return deleteByIndex(r'cityName', [cityName]);
  }

  bool deleteByCityNameSync(String cityName) {
    return deleteByIndexSync(r'cityName', [cityName]);
  }

  Future<List<LocalLocation?>> getAllByCityName(List<String> cityNameValues) {
    final values = cityNameValues.map((e) => [e]).toList();
    return getAllByIndex(r'cityName', values);
  }

  List<LocalLocation?> getAllByCityNameSync(List<String> cityNameValues) {
    final values = cityNameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'cityName', values);
  }

  Future<int> deleteAllByCityName(List<String> cityNameValues) {
    final values = cityNameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'cityName', values);
  }

  int deleteAllByCityNameSync(List<String> cityNameValues) {
    final values = cityNameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'cityName', values);
  }

  Future<Id> putByCityName(LocalLocation object) {
    return putByIndex(r'cityName', object);
  }

  Id putByCityNameSync(LocalLocation object, {bool saveLinks = true}) {
    return putByIndexSync(r'cityName', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCityName(List<LocalLocation> objects) {
    return putAllByIndex(r'cityName', objects);
  }

  List<Id> putAllByCityNameSync(List<LocalLocation> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'cityName', objects, saveLinks: saveLinks);
  }
}

extension LocalLocationQueryWhereSort
    on QueryBuilder<LocalLocation, LocalLocation, QWhere> {
  QueryBuilder<LocalLocation, LocalLocation, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LocalLocationQueryWhere
    on QueryBuilder<LocalLocation, LocalLocation, QWhereClause> {
  QueryBuilder<LocalLocation, LocalLocation, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<LocalLocation, LocalLocation, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterWhereClause> idBetween(
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

  QueryBuilder<LocalLocation, LocalLocation, QAfterWhereClause> cityNameEqualTo(
      String cityName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'cityName',
        value: [cityName],
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterWhereClause>
      cityNameNotEqualTo(String cityName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cityName',
              lower: [],
              upper: [cityName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cityName',
              lower: [cityName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cityName',
              lower: [cityName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cityName',
              lower: [],
              upper: [cityName],
              includeUpper: false,
            ));
      }
    });
  }
}

extension LocalLocationQueryFilter
    on QueryBuilder<LocalLocation, LocalLocation, QFilterCondition> {
  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      cityNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      cityNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      cityNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      cityNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cityName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      cityNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      cityNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      cityNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cityName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      cityNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cityName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      cityNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cityName',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      cityNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cityName',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
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

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition> idBetween(
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

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      isMajorEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isMajor',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      lastUpdatedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      lastUpdatedGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      lastUpdatedLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      lastUpdatedBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastUpdated',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      stateNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'stateName',
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      stateNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'stateName',
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      stateNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stateName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      stateNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stateName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      stateNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stateName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      stateNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stateName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      stateNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'stateName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      stateNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'stateName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      stateNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'stateName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      stateNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'stateName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      stateNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stateName',
        value: '',
      ));
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterFilterCondition>
      stateNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'stateName',
        value: '',
      ));
    });
  }
}

extension LocalLocationQueryObject
    on QueryBuilder<LocalLocation, LocalLocation, QFilterCondition> {}

extension LocalLocationQueryLinks
    on QueryBuilder<LocalLocation, LocalLocation, QFilterCondition> {}

extension LocalLocationQuerySortBy
    on QueryBuilder<LocalLocation, LocalLocation, QSortBy> {
  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy> sortByCityName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cityName', Sort.asc);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy>
      sortByCityNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cityName', Sort.desc);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy> sortByIsMajor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMajor', Sort.asc);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy> sortByIsMajorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMajor', Sort.desc);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy> sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy>
      sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy> sortByStateName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stateName', Sort.asc);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy>
      sortByStateNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stateName', Sort.desc);
    });
  }
}

extension LocalLocationQuerySortThenBy
    on QueryBuilder<LocalLocation, LocalLocation, QSortThenBy> {
  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy> thenByCityName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cityName', Sort.asc);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy>
      thenByCityNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cityName', Sort.desc);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy> thenByIsMajor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMajor', Sort.asc);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy> thenByIsMajorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isMajor', Sort.desc);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy> thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy>
      thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy> thenByStateName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stateName', Sort.asc);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QAfterSortBy>
      thenByStateNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'stateName', Sort.desc);
    });
  }
}

extension LocalLocationQueryWhereDistinct
    on QueryBuilder<LocalLocation, LocalLocation, QDistinct> {
  QueryBuilder<LocalLocation, LocalLocation, QDistinct> distinctByCityName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cityName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QDistinct> distinctByIsMajor() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isMajor');
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QDistinct>
      distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<LocalLocation, LocalLocation, QDistinct> distinctByStateName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'stateName', caseSensitive: caseSensitive);
    });
  }
}

extension LocalLocationQueryProperty
    on QueryBuilder<LocalLocation, LocalLocation, QQueryProperty> {
  QueryBuilder<LocalLocation, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LocalLocation, String, QQueryOperations> cityNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cityName');
    });
  }

  QueryBuilder<LocalLocation, bool, QQueryOperations> isMajorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isMajor');
    });
  }

  QueryBuilder<LocalLocation, DateTime, QQueryOperations>
      lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<LocalLocation, String?, QQueryOperations> stateNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'stateName');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserLocationPreferenceCollection on Isar {
  IsarCollection<UserLocationPreference> get userLocationPreferences =>
      this.collection();
}

const UserLocationPreferenceSchema = CollectionSchema(
  name: r'UserLocationPreference',
  id: -7813213559808716001,
  properties: {
    r'lastDetectedCity': PropertySchema(
      id: 0,
      name: r'lastDetectedCity',
      type: IsarType.string,
    ),
    r'lastSelectedCity': PropertySchema(
      id: 1,
      name: r'lastSelectedCity',
      type: IsarType.string,
    ),
    r'lastSync': PropertySchema(
      id: 2,
      name: r'lastSync',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _userLocationPreferenceEstimateSize,
  serialize: _userLocationPreferenceSerialize,
  deserialize: _userLocationPreferenceDeserialize,
  deserializeProp: _userLocationPreferenceDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _userLocationPreferenceGetId,
  getLinks: _userLocationPreferenceGetLinks,
  attach: _userLocationPreferenceAttach,
  version: '3.1.0+1',
);

int _userLocationPreferenceEstimateSize(
  UserLocationPreference object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.lastDetectedCity;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.lastSelectedCity;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _userLocationPreferenceSerialize(
  UserLocationPreference object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.lastDetectedCity);
  writer.writeString(offsets[1], object.lastSelectedCity);
  writer.writeDateTime(offsets[2], object.lastSync);
}

UserLocationPreference _userLocationPreferenceDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = UserLocationPreference();
  object.id = id;
  object.lastDetectedCity = reader.readStringOrNull(offsets[0]);
  object.lastSelectedCity = reader.readStringOrNull(offsets[1]);
  object.lastSync = reader.readDateTime(offsets[2]);
  return object;
}

P _userLocationPreferenceDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _userLocationPreferenceGetId(UserLocationPreference object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userLocationPreferenceGetLinks(
    UserLocationPreference object) {
  return [];
}

void _userLocationPreferenceAttach(
    IsarCollection<dynamic> col, Id id, UserLocationPreference object) {
  object.id = id;
}

extension UserLocationPreferenceQueryWhereSort
    on QueryBuilder<UserLocationPreference, UserLocationPreference, QWhere> {
  QueryBuilder<UserLocationPreference, UserLocationPreference, QAfterWhere>
      anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserLocationPreferenceQueryWhere on QueryBuilder<
    UserLocationPreference, UserLocationPreference, QWhereClause> {
  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterWhereClause> idBetween(
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
}

extension UserLocationPreferenceQueryFilter on QueryBuilder<
    UserLocationPreference, UserLocationPreference, QFilterCondition> {
  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> idLessThan(
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

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> idBetween(
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

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastDetectedCityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastDetectedCity',
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastDetectedCityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastDetectedCity',
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastDetectedCityEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastDetectedCity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastDetectedCityGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastDetectedCity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastDetectedCityLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastDetectedCity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastDetectedCityBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastDetectedCity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastDetectedCityStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastDetectedCity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastDetectedCityEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastDetectedCity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
          QAfterFilterCondition>
      lastDetectedCityContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastDetectedCity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
          QAfterFilterCondition>
      lastDetectedCityMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastDetectedCity',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastDetectedCityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastDetectedCity',
        value: '',
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastDetectedCityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastDetectedCity',
        value: '',
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastSelectedCityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lastSelectedCity',
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastSelectedCityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lastSelectedCity',
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastSelectedCityEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSelectedCity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastSelectedCityGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSelectedCity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastSelectedCityLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSelectedCity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastSelectedCityBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSelectedCity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastSelectedCityStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'lastSelectedCity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastSelectedCityEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'lastSelectedCity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
          QAfterFilterCondition>
      lastSelectedCityContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'lastSelectedCity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
          QAfterFilterCondition>
      lastSelectedCityMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'lastSelectedCity',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastSelectedCityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSelectedCity',
        value: '',
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastSelectedCityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'lastSelectedCity',
        value: '',
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastSyncEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastSync',
        value: value,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastSyncGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastSync',
        value: value,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastSyncLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastSync',
        value: value,
      ));
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference,
      QAfterFilterCondition> lastSyncBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastSync',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension UserLocationPreferenceQueryObject on QueryBuilder<
    UserLocationPreference, UserLocationPreference, QFilterCondition> {}

extension UserLocationPreferenceQueryLinks on QueryBuilder<
    UserLocationPreference, UserLocationPreference, QFilterCondition> {}

extension UserLocationPreferenceQuerySortBy
    on QueryBuilder<UserLocationPreference, UserLocationPreference, QSortBy> {
  QueryBuilder<UserLocationPreference, UserLocationPreference, QAfterSortBy>
      sortByLastDetectedCity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastDetectedCity', Sort.asc);
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference, QAfterSortBy>
      sortByLastDetectedCityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastDetectedCity', Sort.desc);
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference, QAfterSortBy>
      sortByLastSelectedCity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSelectedCity', Sort.asc);
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference, QAfterSortBy>
      sortByLastSelectedCityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSelectedCity', Sort.desc);
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference, QAfterSortBy>
      sortByLastSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSync', Sort.asc);
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference, QAfterSortBy>
      sortByLastSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSync', Sort.desc);
    });
  }
}

extension UserLocationPreferenceQuerySortThenBy on QueryBuilder<
    UserLocationPreference, UserLocationPreference, QSortThenBy> {
  QueryBuilder<UserLocationPreference, UserLocationPreference, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference, QAfterSortBy>
      thenByLastDetectedCity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastDetectedCity', Sort.asc);
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference, QAfterSortBy>
      thenByLastDetectedCityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastDetectedCity', Sort.desc);
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference, QAfterSortBy>
      thenByLastSelectedCity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSelectedCity', Sort.asc);
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference, QAfterSortBy>
      thenByLastSelectedCityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSelectedCity', Sort.desc);
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference, QAfterSortBy>
      thenByLastSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSync', Sort.asc);
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference, QAfterSortBy>
      thenByLastSyncDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSync', Sort.desc);
    });
  }
}

extension UserLocationPreferenceQueryWhereDistinct
    on QueryBuilder<UserLocationPreference, UserLocationPreference, QDistinct> {
  QueryBuilder<UserLocationPreference, UserLocationPreference, QDistinct>
      distinctByLastDetectedCity({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastDetectedCity',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference, QDistinct>
      distinctByLastSelectedCity({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSelectedCity',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<UserLocationPreference, UserLocationPreference, QDistinct>
      distinctByLastSync() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSync');
    });
  }
}

extension UserLocationPreferenceQueryProperty on QueryBuilder<
    UserLocationPreference, UserLocationPreference, QQueryProperty> {
  QueryBuilder<UserLocationPreference, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<UserLocationPreference, String?, QQueryOperations>
      lastDetectedCityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastDetectedCity');
    });
  }

  QueryBuilder<UserLocationPreference, String?, QQueryOperations>
      lastSelectedCityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSelectedCity');
    });
  }

  QueryBuilder<UserLocationPreference, DateTime, QQueryOperations>
      lastSyncProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSync');
    });
  }
}
