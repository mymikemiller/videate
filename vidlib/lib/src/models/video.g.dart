// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializer<Video> _$videoSerializer = new _$VideoSerializer();

class _$VideoSerializer implements StructuredSerializer<Video> {
  @override
  final Iterable<Type> types = const [Video, _$Video];
  @override
  final String wireName = 'Video';

  @override
  Iterable<Object> serialize(Serializers serializers, Video object,
      {FullType specifiedType = FullType.unspecified}) {
    final result = <Object>[
      'title',
      serializers.serialize(object.title,
          specifiedType: const FullType(String)),
      'description',
      serializers.serialize(object.description,
          specifiedType: const FullType(String)),
      'url',
      serializers.serialize(object.url, specifiedType: const FullType(String)),
      'date',
      serializers.serialize(object.date,
          specifiedType: const FullType(DateTime)),
    ];

    return result;
  }

  @override
  Video deserialize(Serializers serializers, Iterable<Object> serialized,
      {FullType specifiedType = FullType.unspecified}) {
    final result = new VideoBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current as String;
      iterator.moveNext();
      final dynamic value = iterator.current;
      switch (key) {
        case 'title':
          result.title = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'description':
          result.description = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'url':
          result.url = serializers.deserialize(value,
              specifiedType: const FullType(String)) as String;
          break;
        case 'date':
          result.date = serializers.deserialize(value,
              specifiedType: const FullType(DateTime)) as DateTime;
          break;
      }
    }

    return result.build();
  }
}

class _$Video extends Video {
  @override
  final String title;
  @override
  final String description;
  @override
  final String url;
  @override
  final DateTime date;

  factory _$Video([void Function(VideoBuilder) updates]) =>
      (new VideoBuilder()..update(updates)).build();

  _$Video._({this.title, this.description, this.url, this.date}) : super._() {
    if (title == null) {
      throw new BuiltValueNullFieldError('Video', 'title');
    }
    if (description == null) {
      throw new BuiltValueNullFieldError('Video', 'description');
    }
    if (url == null) {
      throw new BuiltValueNullFieldError('Video', 'url');
    }
    if (date == null) {
      throw new BuiltValueNullFieldError('Video', 'date');
    }
  }

  @override
  Video rebuild(void Function(VideoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VideoBuilder toBuilder() => new VideoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Video &&
        title == other.title &&
        description == other.description &&
        url == other.url &&
        date == other.date;
  }

  @override
  int get hashCode {
    return $jf($jc(
        $jc($jc($jc(0, title.hashCode), description.hashCode), url.hashCode),
        date.hashCode));
  }
}

class VideoBuilder implements Builder<Video, VideoBuilder> {
  _$Video _$v;

  String _title;
  String get title => _$this._title;
  set title(String title) => _$this._title = title;

  String _description;
  String get description => _$this._description;
  set description(String description) => _$this._description = description;

  String _url;
  String get url => _$this._url;
  set url(String url) => _$this._url = url;

  DateTime _date;
  DateTime get date => _$this._date;
  set date(DateTime date) => _$this._date = date;

  VideoBuilder();

  VideoBuilder get _$this {
    if (_$v != null) {
      _title = _$v.title;
      _description = _$v.description;
      _url = _$v.url;
      _date = _$v.date;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Video other) {
    if (other == null) {
      throw new ArgumentError.notNull('other');
    }
    _$v = other as _$Video;
  }

  @override
  void update(void Function(VideoBuilder) updates) {
    if (updates != null) updates(this);
  }

  @override
  _$Video build() {
    final _$result = _$v ??
        new _$Video._(
            title: title, description: description, url: url, date: date);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: always_put_control_body_on_new_line,always_specify_types,annotate_overrides,avoid_annotating_with_dynamic,avoid_as,avoid_catches_without_on_clauses,avoid_returning_this,lines_longer_than_80_chars,omit_local_variable_types,prefer_expression_function_bodies,sort_constructors_first,test_types_in_equals,unnecessary_const,unnecessary_new
