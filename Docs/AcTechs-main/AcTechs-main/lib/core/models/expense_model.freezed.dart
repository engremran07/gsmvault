// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExpenseModel {

 String get id; String get techId; String get techName; String get category; double get amount; String get note; ExpenseApprovalStatus get status; String get approvedBy; String get adminNote;/// 'work' for regular expenses, 'home' for home chores
 String get expenseType;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get date;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get createdAt;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get reviewedAt;@JsonKey(defaultValue: false) bool get isDeleted;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get deletedAt;
/// Create a copy of ExpenseModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseModelCopyWith<ExpenseModel> get copyWith => _$ExpenseModelCopyWithImpl<ExpenseModel>(this as ExpenseModel, _$identity);

  /// Serializes this ExpenseModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpenseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.techId, techId) || other.techId == techId)&&(identical(other.techName, techName) || other.techName == techName)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note)&&(identical(other.status, status) || other.status == status)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.adminNote, adminNote) || other.adminNote == adminNote)&&(identical(other.expenseType, expenseType) || other.expenseType == expenseType)&&(identical(other.date, date) || other.date == date)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,techId,techName,category,amount,note,status,approvedBy,adminNote,expenseType,date,createdAt,reviewedAt,isDeleted,deletedAt);

@override
String toString() {
  return 'ExpenseModel(id: $id, techId: $techId, techName: $techName, category: $category, amount: $amount, note: $note, status: $status, approvedBy: $approvedBy, adminNote: $adminNote, expenseType: $expenseType, date: $date, createdAt: $createdAt, reviewedAt: $reviewedAt, isDeleted: $isDeleted, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class $ExpenseModelCopyWith<$Res>  {
  factory $ExpenseModelCopyWith(ExpenseModel value, $Res Function(ExpenseModel) _then) = _$ExpenseModelCopyWithImpl;
@useResult
$Res call({
 String id, String techId, String techName, String category, double amount, String note, ExpenseApprovalStatus status, String approvedBy, String adminNote, String expenseType,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? date,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? createdAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? reviewedAt,@JsonKey(defaultValue: false) bool isDeleted,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? deletedAt
});




}
/// @nodoc
class _$ExpenseModelCopyWithImpl<$Res>
    implements $ExpenseModelCopyWith<$Res> {
  _$ExpenseModelCopyWithImpl(this._self, this._then);

  final ExpenseModel _self;
  final $Res Function(ExpenseModel) _then;

/// Create a copy of ExpenseModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? techId = null,Object? techName = null,Object? category = null,Object? amount = null,Object? note = null,Object? status = null,Object? approvedBy = null,Object? adminNote = null,Object? expenseType = null,Object? date = freezed,Object? createdAt = freezed,Object? reviewedAt = freezed,Object? isDeleted = null,Object? deletedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,techId: null == techId ? _self.techId : techId // ignore: cast_nullable_to_non_nullable
as String,techName: null == techName ? _self.techName : techName // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ExpenseApprovalStatus,approvedBy: null == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as String,adminNote: null == adminNote ? _self.adminNote : adminNote // ignore: cast_nullable_to_non_nullable
as String,expenseType: null == expenseType ? _self.expenseType : expenseType // ignore: cast_nullable_to_non_nullable
as String,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpenseModel].
extension ExpenseModelPatterns on ExpenseModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpenseModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpenseModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpenseModel value)  $default,){
final _that = this;
switch (_that) {
case _ExpenseModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpenseModel value)?  $default,){
final _that = this;
switch (_that) {
case _ExpenseModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String techId,  String techName,  String category,  double amount,  String note,  ExpenseApprovalStatus status,  String approvedBy,  String adminNote,  String expenseType, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? createdAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? reviewedAt, @JsonKey(defaultValue: false)  bool isDeleted, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? deletedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpenseModel() when $default != null:
return $default(_that.id,_that.techId,_that.techName,_that.category,_that.amount,_that.note,_that.status,_that.approvedBy,_that.adminNote,_that.expenseType,_that.date,_that.createdAt,_that.reviewedAt,_that.isDeleted,_that.deletedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String techId,  String techName,  String category,  double amount,  String note,  ExpenseApprovalStatus status,  String approvedBy,  String adminNote,  String expenseType, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? createdAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? reviewedAt, @JsonKey(defaultValue: false)  bool isDeleted, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? deletedAt)  $default,) {final _that = this;
switch (_that) {
case _ExpenseModel():
return $default(_that.id,_that.techId,_that.techName,_that.category,_that.amount,_that.note,_that.status,_that.approvedBy,_that.adminNote,_that.expenseType,_that.date,_that.createdAt,_that.reviewedAt,_that.isDeleted,_that.deletedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String techId,  String techName,  String category,  double amount,  String note,  ExpenseApprovalStatus status,  String approvedBy,  String adminNote,  String expenseType, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? createdAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? reviewedAt, @JsonKey(defaultValue: false)  bool isDeleted, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? deletedAt)?  $default,) {final _that = this;
switch (_that) {
case _ExpenseModel() when $default != null:
return $default(_that.id,_that.techId,_that.techName,_that.category,_that.amount,_that.note,_that.status,_that.approvedBy,_that.adminNote,_that.expenseType,_that.date,_that.createdAt,_that.reviewedAt,_that.isDeleted,_that.deletedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExpenseModel implements ExpenseModel {
  const _ExpenseModel({this.id = '', required this.techId, required this.techName, required this.category, required this.amount, this.note = '', this.status = ExpenseApprovalStatus.pending, this.approvedBy = '', this.adminNote = '', this.expenseType = 'work', @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.createdAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.reviewedAt, @JsonKey(defaultValue: false) this.isDeleted = false, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.deletedAt});
  factory _ExpenseModel.fromJson(Map<String, dynamic> json) => _$ExpenseModelFromJson(json);

@override@JsonKey() final  String id;
@override final  String techId;
@override final  String techName;
@override final  String category;
@override final  double amount;
@override@JsonKey() final  String note;
@override@JsonKey() final  ExpenseApprovalStatus status;
@override@JsonKey() final  String approvedBy;
@override@JsonKey() final  String adminNote;
/// 'work' for regular expenses, 'home' for home chores
@override@JsonKey() final  String expenseType;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? date;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? createdAt;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? reviewedAt;
@override@JsonKey(defaultValue: false) final  bool isDeleted;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? deletedAt;

/// Create a copy of ExpenseModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseModelCopyWith<_ExpenseModel> get copyWith => __$ExpenseModelCopyWithImpl<_ExpenseModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExpenseModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpenseModel&&(identical(other.id, id) || other.id == id)&&(identical(other.techId, techId) || other.techId == techId)&&(identical(other.techName, techName) || other.techName == techName)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.note, note) || other.note == note)&&(identical(other.status, status) || other.status == status)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.adminNote, adminNote) || other.adminNote == adminNote)&&(identical(other.expenseType, expenseType) || other.expenseType == expenseType)&&(identical(other.date, date) || other.date == date)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,techId,techName,category,amount,note,status,approvedBy,adminNote,expenseType,date,createdAt,reviewedAt,isDeleted,deletedAt);

@override
String toString() {
  return 'ExpenseModel(id: $id, techId: $techId, techName: $techName, category: $category, amount: $amount, note: $note, status: $status, approvedBy: $approvedBy, adminNote: $adminNote, expenseType: $expenseType, date: $date, createdAt: $createdAt, reviewedAt: $reviewedAt, isDeleted: $isDeleted, deletedAt: $deletedAt)';
}


}

/// @nodoc
abstract mixin class _$ExpenseModelCopyWith<$Res> implements $ExpenseModelCopyWith<$Res> {
  factory _$ExpenseModelCopyWith(_ExpenseModel value, $Res Function(_ExpenseModel) _then) = __$ExpenseModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String techId, String techName, String category, double amount, String note, ExpenseApprovalStatus status, String approvedBy, String adminNote, String expenseType,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? date,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? createdAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? reviewedAt,@JsonKey(defaultValue: false) bool isDeleted,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? deletedAt
});




}
/// @nodoc
class __$ExpenseModelCopyWithImpl<$Res>
    implements _$ExpenseModelCopyWith<$Res> {
  __$ExpenseModelCopyWithImpl(this._self, this._then);

  final _ExpenseModel _self;
  final $Res Function(_ExpenseModel) _then;

/// Create a copy of ExpenseModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? techId = null,Object? techName = null,Object? category = null,Object? amount = null,Object? note = null,Object? status = null,Object? approvedBy = null,Object? adminNote = null,Object? expenseType = null,Object? date = freezed,Object? createdAt = freezed,Object? reviewedAt = freezed,Object? isDeleted = null,Object? deletedAt = freezed,}) {
  return _then(_ExpenseModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,techId: null == techId ? _self.techId : techId // ignore: cast_nullable_to_non_nullable
as String,techName: null == techName ? _self.techName : techName // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ExpenseApprovalStatus,approvedBy: null == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as String,adminNote: null == adminNote ? _self.adminNote : adminNote // ignore: cast_nullable_to_non_nullable
as String,expenseType: null == expenseType ? _self.expenseType : expenseType // ignore: cast_nullable_to_non_nullable
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
