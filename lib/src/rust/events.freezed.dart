// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'events.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AppEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(DownloadComic comic) download,
    required TResult Function(String message) export_,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(DownloadComic comic)? download,
    TResult? Function(String message)? export_,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(DownloadComic comic)? download,
    TResult Function(String message)? export_,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppEvent_Download value) download,
    required TResult Function(AppEvent_Export value) export_,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppEvent_Download value)? download,
    TResult? Function(AppEvent_Export value)? export_,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppEvent_Download value)? download,
    TResult Function(AppEvent_Export value)? export_,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppEventCopyWith<$Res> {
  factory $AppEventCopyWith(AppEvent value, $Res Function(AppEvent) then) =
      _$AppEventCopyWithImpl<$Res, AppEvent>;
}

/// @nodoc
class _$AppEventCopyWithImpl<$Res, $Val extends AppEvent>
    implements $AppEventCopyWith<$Res> {
  _$AppEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppEvent
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$AppEvent_DownloadImplCopyWith<$Res> {
  factory _$$AppEvent_DownloadImplCopyWith(
    _$AppEvent_DownloadImpl value,
    $Res Function(_$AppEvent_DownloadImpl) then,
  ) = __$$AppEvent_DownloadImplCopyWithImpl<$Res>;
  @useResult
  $Res call({DownloadComic comic});
}

/// @nodoc
class __$$AppEvent_DownloadImplCopyWithImpl<$Res>
    extends _$AppEventCopyWithImpl<$Res, _$AppEvent_DownloadImpl>
    implements _$$AppEvent_DownloadImplCopyWith<$Res> {
  __$$AppEvent_DownloadImplCopyWithImpl(
    _$AppEvent_DownloadImpl _value,
    $Res Function(_$AppEvent_DownloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? comic = null}) {
    return _then(
      _$AppEvent_DownloadImpl(
        comic: null == comic
            ? _value.comic
            : comic // ignore: cast_nullable_to_non_nullable
                  as DownloadComic,
      ),
    );
  }
}

/// @nodoc

class _$AppEvent_DownloadImpl extends AppEvent_Download {
  const _$AppEvent_DownloadImpl({required this.comic}) : super._();

  @override
  final DownloadComic comic;

  @override
  String toString() {
    return 'AppEvent.download(comic: $comic)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppEvent_DownloadImpl &&
            (identical(other.comic, comic) || other.comic == comic));
  }

  @override
  int get hashCode => Object.hash(runtimeType, comic);

  /// Create a copy of AppEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppEvent_DownloadImplCopyWith<_$AppEvent_DownloadImpl> get copyWith =>
      __$$AppEvent_DownloadImplCopyWithImpl<_$AppEvent_DownloadImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(DownloadComic comic) download,
    required TResult Function(String message) export_,
  }) {
    return download(comic);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(DownloadComic comic)? download,
    TResult? Function(String message)? export_,
  }) {
    return download?.call(comic);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(DownloadComic comic)? download,
    TResult Function(String message)? export_,
    required TResult orElse(),
  }) {
    if (download != null) {
      return download(comic);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppEvent_Download value) download,
    required TResult Function(AppEvent_Export value) export_,
  }) {
    return download(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppEvent_Download value)? download,
    TResult? Function(AppEvent_Export value)? export_,
  }) {
    return download?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppEvent_Download value)? download,
    TResult Function(AppEvent_Export value)? export_,
    required TResult orElse(),
  }) {
    if (download != null) {
      return download(this);
    }
    return orElse();
  }
}

abstract class AppEvent_Download extends AppEvent {
  const factory AppEvent_Download({required final DownloadComic comic}) =
      _$AppEvent_DownloadImpl;
  const AppEvent_Download._() : super._();

  DownloadComic get comic;

  /// Create a copy of AppEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppEvent_DownloadImplCopyWith<_$AppEvent_DownloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$AppEvent_ExportImplCopyWith<$Res> {
  factory _$$AppEvent_ExportImplCopyWith(
    _$AppEvent_ExportImpl value,
    $Res Function(_$AppEvent_ExportImpl) then,
  ) = __$$AppEvent_ExportImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$AppEvent_ExportImplCopyWithImpl<$Res>
    extends _$AppEventCopyWithImpl<$Res, _$AppEvent_ExportImpl>
    implements _$$AppEvent_ExportImplCopyWith<$Res> {
  __$$AppEvent_ExportImplCopyWithImpl(
    _$AppEvent_ExportImpl _value,
    $Res Function(_$AppEvent_ExportImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppEvent
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$AppEvent_ExportImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AppEvent_ExportImpl extends AppEvent_Export {
  const _$AppEvent_ExportImpl({required this.message}) : super._();

  @override
  final String message;

  @override
  String toString() {
    return 'AppEvent.export_(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppEvent_ExportImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of AppEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppEvent_ExportImplCopyWith<_$AppEvent_ExportImpl> get copyWith =>
      __$$AppEvent_ExportImplCopyWithImpl<_$AppEvent_ExportImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(DownloadComic comic) download,
    required TResult Function(String message) export_,
  }) {
    return export_(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(DownloadComic comic)? download,
    TResult? Function(String message)? export_,
  }) {
    return export_?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(DownloadComic comic)? download,
    TResult Function(String message)? export_,
    required TResult orElse(),
  }) {
    if (export_ != null) {
      return export_(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(AppEvent_Download value) download,
    required TResult Function(AppEvent_Export value) export_,
  }) {
    return export_(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(AppEvent_Download value)? download,
    TResult? Function(AppEvent_Export value)? export_,
  }) {
    return export_?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(AppEvent_Download value)? download,
    TResult Function(AppEvent_Export value)? export_,
    required TResult orElse(),
  }) {
    if (export_ != null) {
      return export_(this);
    }
    return orElse();
  }
}

abstract class AppEvent_Export extends AppEvent {
  const factory AppEvent_Export({required final String message}) =
      _$AppEvent_ExportImpl;
  const AppEvent_Export._() : super._();

  String get message;

  /// Create a copy of AppEvent
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppEvent_ExportImplCopyWith<_$AppEvent_ExportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
