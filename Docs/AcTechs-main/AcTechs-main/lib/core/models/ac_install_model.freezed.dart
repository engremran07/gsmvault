// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ac_install_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AcInstallModel {

 String get id; String get techId; String get techName; int get splitTotal; int get splitShare; int get windowTotal; int get windowShare; int get freestandingTotal; int get freestandingShare; String get note; AcInstallStatus get status; String get approvedBy; String get adminNote;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get date;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get createdAt;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get reviewedAt;@JsonKey(defaultValue: false) bool get isDeleted;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get deletedAt;
/// Create a copy of AcInstallModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AcInstallModelCopyWith<AcInstallModel> get copyWith => _$AcInstallModelCopyWithImpl<AcInstallModel>(this as AcInstallModel, _$identity);

  /// Serializes this AcInstallModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AcInstallModel&&(identical(other.id, id) || other.id == id)&&(identical(other.techId, techId) || other.techId == techId)&&(identical(other.techName, techName) || other.techName == techName)&&(identical(other.splitTotal, splitTotal) || other.splitTotal == splitTotal)&&(identical(other.splitShare, splitShare) || other.splitShare == splitShare)&&(identical(other.windowTotal, windowTotal) || other.windowTotal == windowTotal)&&(identical(other.windowShare, windowShare) || other.windowShare == windowShare)&&(identical(other.freestandingTotal, freestandingTotal) || other.freestandingTotal == freestandingTotal)&&(identical(other.freestandingShare, freestandingShare) || other.freestandingShare == freestandingShare)&&(identical(other.note, note) || other.note == note)&&(identical(other.status, status) || other.status == status)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.adminNote, adminNote) || other.adminNote == adminNote)&&(identical(other.date, date) || other.date == date)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,techId,techName,splitTotal,splitShare,windowTotal,windowShare,freestandingTotal,freestandingShare,note,status,approvedBy,adminNote,date,createdAt,reviewedAt,isDeleted,deletedAt);

@override
String toString() {
  return 'AcInstallModel(id: $id, techId: $techId, techName: $techName, splitTotal: $splitTotal, splitShare: $splitShare, windowTotal: $windowTotal, windowShare: $windowShare, freestandingTotal: $freestandingTotal, freestandingShare: $freestandingShare, note: $note, status: $status, approvedBy: $approvedBy, adminNote: $adminNote, date: $date, createdAt: $createdAt, reviewedAt: $reviewedAt, isDeleted: $isDeleted, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class $AcInstallModelCopyWith<$Res>  {
  factory $AcInstallModelCopyWith(AcInstallModel value, $Res Function(AcInstallModel) _then) = _$AcInstallModelCopyWithImpl;
@useResult
$Res call({
 String id, String techId, String techName, int splitTotal, int splitShare, int windowTotal, int windowShare, int freestandingTotal, int freestandingShare, String note, AcInstallStatus status, String approvedBy, String adminNote,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? date,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? createdAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? reviewedAt,@JsonKey(defaultValue: false) bool isDeleted,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? deletedAt
});




}
/// @nodoc
class _$AcInstallModelCopyWithImpl<$Res>
    implements $AcInstallModelCopyWith<$Res> {
  _$AcInstallModelCopyWithImpl(this._self, this._then);

  final AcInstallModel _self;
  final $Res Function(AcInstallModel) _then;

/// Create a copy of AcInstallModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? techId = null,Object? techName = null,Object? splitTotal = null,Object? splitShare = null,Object? windowTotal = null,Object? windowShare = null,Object? freestandingTotal = null,Object? freestandingShare = null,Object? note = null,Object? status = null,Object? approvedBy = null,Object? adminNote = null,Object? date = freezed,Object? createdAt = freezed,Object? reviewedAt = freezed,Object? isDeleted = null,Object? deletedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,techId: null == techId ? _self.techId : techId // ignore: cast_nullable_to_non_nullable
as String,techName: null == techName ? _self.techName : techName // ignore: cast_nullable_to_non_nullable
as String,splitTotal: null == splitTotal ? _self.splitTotal : splitTotal // ignore: cast_nullable_to_non_nullable
as int,splitShare: null == splitShare ? _self.splitShare : splitShare // ignore: cast_nullable_to_non_nullable
as int,windowTotal: null == windowTotal ? _self.windowTotal : windowTotal // ignore: cast_nullable_to_non_nullable
as int,windowShare: null == windowShare ? _self.windowShare : windowShare // ignore: cast_nullable_to_non_nullable
as int,freestandingTotal: null == freestandingTotal ? _self.freestandingTotal : freestandingTotal // ignore: cast_nullable_to_non_nullable
as int,freestandingShare: null == freestandingShare ? _self.freestandingShare : freestandingShare // ignore: cast_nullable_to_non_nullable
as int,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AcInstallStatus,approvedBy: null == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as String,adminNote: null == adminNote ? _self.adminNote : adminNote // ignore: cast_nullable_to_non_nullable
as String,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [AcInstallModel].
extension AcInstallModelPatterns on AcInstallModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AcInstallModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AcInstallModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AcInstallModel value)  $default,){
final _that = this;
switch (_that) {
case _AcInstallModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AcInstallModel value)?  $default,){
final _that = this;
switch (_that) {
case _AcInstallModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String techId,  String techName,  int splitTotal,  int splitShare,  int windowTotal,  int windowShare,  int freestandingTotal,  int freestandingShare,  String note,  AcInstallStatus status,  String approvedBy,  String adminNote, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? createdAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? reviewedAt, @JsonKey(defaultValue: false)  bool isDeleted, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AcInstallModel() when $default != null:
return $default(_that.id,_that.techId,_that.techName,_that.splitTotal,_that.splitShare,_that.windowTotal,_that.windowShare,_that.freestandingTotal,_that.freestandingShare,_that.note,_that.status,_that.approvedBy,_that.adminNote,_that.date,_that.createdAt,_that.reviewedAt,_that.isDeleted,_that.deletedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String techId,  String techName,  int splitTotal,  int splitShare,  int windowTotal,  int windowShare,  int freestandingTotal,  int freestandingShare,  String note,  AcInstallStatus status,  String approvedBy,  String adminNote, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? createdAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? reviewedAt, @JsonKey(defaultValue: false)  bool isDeleted, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _AcInstallModel():
return $default(_that.id,_that.techId,_that.techName,_that.splitTotal,_that.splitShare,_that.windowTotal,_that.windowShare,_that.freestandingTotal,_that.freestandingShare,_that.note,_that.status,_that.approvedBy,_that.adminNote,_that.date,_that.createdAt,_that.reviewedAt,_that.isDeleted,_that.deletedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String techId,  String techName,  int splitTotal,  int splitShare,  int windowTotal,  int windowShare,  int freestandingTotal,  int freestandingShare,  String note,  AcInstallStatus status,  String approvedBy,  String adminNote, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? createdAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? reviewedAt, @JsonKey(defaultValue: false)  bool isDeleted, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _AcInstallModel() when $default != null:
return $default(_that.id,_that.techId,_that.techName,_that.splitTotal,_that.splitShare,_that.windowTotal,_that.windowShare,_that.freestandingTotal,_that.freestandingShare,_that.note,_that.status,_that.approvedBy,_that.adminNote,_that.date,_that.createdAt,_that.reviewedAt,_that.isDeleted,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AcInstallModel implements AcInstallModel {
  const _AcInstallModel({this.id = '', required this.techId, required this.techName, this.splitTotal = 0, this.splitShare = 0, this.windowTotal = 0, this.windowShare = 0, this.freestandingTotal = 0, this.freestandingShare = 0, this.note = '', this.status = AcInstallStatus.pending, this.approvedBy = '', this.adminNote = '', @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.createdAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.reviewedAt, @JsonKey(defaultValue: false) this.isDeleted = false, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.deletedAt});
  factory _AcInstallModel.fromJson(Map<String, dynamic> json) => _$AcInstallModelFromJson(json);

@override@JsonKey() final  String id;
@override final  String techId;
@override final  String techName;
@override@JsonKey() final  int splitTotal;
@override@JsonKey() final  int splitShare;
@override@JsonKey() final  int windowTotal;
@override@JsonKey() final  int windowShare;
@override@JsonKey() final  int freestandingTotal;
@override@JsonKey() final  int freestandingShare;
@override@JsonKey() final  String note;
@override@JsonKey() final  AcInstallStatus status;
@override@JsonKey() final  String approvedBy;
@override@JsonKey() final  String adminNote;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? date;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? createdAt;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? reviewedAt;
@override@JsonKey(defaultValue: false) final  bool isDeleted;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? deletedAt;

/// Create a copy of AcInstallModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AcInstallModelCopyWith<_AcInstallModel> get copyWith => __$AcInstallModelCopyWithImpl<_AcInstallModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AcInstallModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AcInstallModel&&(identical(other.id, id) || other.id == id)&&(identical(other.techId, techId) || other.techId == techId)&&(identical(other.techName, techName) || other.techName == techName)&&(identical(other.splitTotal, splitTotal) || other.splitTotal == splitTotal)&&(identical(other.splitShare, splitShare) || other.splitShare == splitShare)&&(identical(other.windowTotal, windowTotal) || other.windowTotal == windowTotal)&&(identical(other.windowShare, windowShare) || other.windowShare == windowShare)&&(identical(other.freestandingTotal, freestandingTotal) || other.freestandingTotal == freestandingTotal)&&(identical(other.freestandingShare, freestandingShare) || other.freestandingShare == freestandingShare)&&(identical(other.note, note) || other.note == note)&&(identical(other.status, status) || other.status == status)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.adminNote, adminNote) || other.adminNote == adminNote)&&(identical(other.date, date) || other.date == date)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,techId,techName,splitTotal,splitShare,windowTotal,windowShare,freestandingTotal,freestandingShare,note,status,approvedBy,adminNote,date,createdAt,reviewedAt,isDeleted,deletedAt);

@override
String toString() {
  return 'AcInstallModel(id: $id, techId: $techId, techName: $techName, splitTotal: $splitTotal, splitShare: $splitShare, windowTotal: $windowTotal, windowShare: $windowShare, freestandingTotal: $freestandingTotal, freestandingShare: $freestandingShare, note: $note, status: $status, approvedBy: $approvedBy, adminNote: $adminNote, date: $date, createdAt: $createdAt, reviewedAt: $reviewedAt, isDeleted: $isDeleted, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$AcInstallModelCopyWith<$Res> implements $AcInstallModelCopyWith<$Res> {
  factory _$AcInstallModelCopyWith(_AcInstallModel value, $Res Function(_AcInstallModel) _then) = __$AcInstallModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String techId, String techName, int splitTotal, int splitShare, int windowTotal, int windowShare, int freestandingTotal, int freestandingShare, String note, AcInstallStatus status, String approvedBy, String adminNote,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? date,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? createdAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? reviewedAt,@JsonKey(defaultValue: false) bool isDeleted,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? deletedAt
});




}
/// @nodoc
class __$AcInstallModelCopyWithImpl<$Res>
    implements _$AcInstallModelCopyWith<$Res> {
  __$AcInstallModelCopyWithImpl(this._self, this._then);

  final _AcInstallModel _self;
  final $Res Function(_AcInstallModel) _then;

/// Create a copy of AcInstallModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? techId = null,Object? techName = null,Object? splitTotal = null,Object? splitShare = null,Object? windowTotal = null,Object? windowShare = null,Object? freestandingTotal = null,Object? freestandingShare = null,Object? note = null,Object? status = null,Object? approvedBy = null,Object? adminNote = null,Object? date = freezed,Object? createdAt = freezed,Object? reviewedAt = freezed,Object? isDeleted = null,Object? deletedAt = freezed,}) {
  return _then(_AcInstallModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,techId: null == techId ? _self.techId : techId // ignore: cast_nullable_to_non_nullable
as String,techName: null == techName ? _self.techName : techName // ignore: cast_nullable_to_non_nullable
as String,splitTotal: null == splitTotal ? _self.splitTotal : splitTotal // ignore: cast_nullable_to_non_nullable
as int,splitShare: null == splitShare ? _self.splitShare : splitShare // ignore: cast_nullable_to_non_nullable
as int,windowTotal: null == windowTotal ? _self.windowTotal : windowTotal // ignore: cast_nullable_to_non_nullable
as int,windowShare: null == windowShare ? _self.windowShare : windowShare // ignore: cast_nullable_to_non_nullable
as int,freestandingTotal: null == freestandingTotal ? _self.freestandingTotal : freestandingTotal // ignore: cast_nullable_to_non_nullable
as int,freestandingShare: null == freestandingShare ? _self.freestandingShare : freestandingShare // ignore: cast_nullable_to_non_nullable
as int,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AcInstallStatus,approvedBy: null == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as String,adminNote: null == adminNote ? _self.adminNote : adminNote // ignore: cast_nullable_to_non_nullable
as String,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
