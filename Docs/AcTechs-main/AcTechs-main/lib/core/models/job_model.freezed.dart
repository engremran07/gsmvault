// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'job_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AcUnit {

 String get type; int get quantity;
/// Create a copy of AcUnit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AcUnitCopyWith<AcUnit> get copyWith => _$AcUnitCopyWithImpl<AcUnit>(this as AcUnit, _$identity);

  /// Serializes this AcUnit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AcUnit&&(identical(other.type, type) || other.type == type)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,quantity);

@override
String toString() {
  return 'AcUnit(type: $type, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class $AcUnitCopyWith<$Res>  {
  factory $AcUnitCopyWith(AcUnit value, $Res Function(AcUnit) _then) = _$AcUnitCopyWithImpl;
@useResult
$Res call({
 String type, int quantity
});




}
/// @nodoc
class _$AcUnitCopyWithImpl<$Res>
    implements $AcUnitCopyWith<$Res> {
  _$AcUnitCopyWithImpl(this._self, this._then);

  final AcUnit _self;
  final $Res Function(AcUnit) _then;

/// Create a copy of AcUnit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? quantity = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AcUnit].
extension AcUnitPatterns on AcUnit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AcUnit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AcUnit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AcUnit value)  $default,){
final _that = this;
switch (_that) {
case _AcUnit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AcUnit value)?  $default,){
final _that = this;
switch (_that) {
case _AcUnit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  int quantity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AcUnit() when $default != null:
return $default(_that.type,_that.quantity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  int quantity)  $default,) {final _that = this;
switch (_that) {
case _AcUnit():
return $default(_that.type,_that.quantity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  int quantity)?  $default,) {final _that = this;
switch (_that) {
case _AcUnit() when $default != null:
return $default(_that.type,_that.quantity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AcUnit implements AcUnit {
  const _AcUnit({required this.type, this.quantity = 1});
  factory _AcUnit.fromJson(Map<String, dynamic> json) => _$AcUnitFromJson(json);

@override final  String type;
@override@JsonKey() final  int quantity;

/// Create a copy of AcUnit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AcUnitCopyWith<_AcUnit> get copyWith => __$AcUnitCopyWithImpl<_AcUnit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AcUnitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AcUnit&&(identical(other.type, type) || other.type == type)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,quantity);

@override
String toString() {
  return 'AcUnit(type: $type, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class _$AcUnitCopyWith<$Res> implements $AcUnitCopyWith<$Res> {
  factory _$AcUnitCopyWith(_AcUnit value, $Res Function(_AcUnit) _then) = __$AcUnitCopyWithImpl;
@override @useResult
$Res call({
 String type, int quantity
});




}
/// @nodoc
class __$AcUnitCopyWithImpl<$Res>
    implements _$AcUnitCopyWith<$Res> {
  __$AcUnitCopyWithImpl(this._self, this._then);

  final _AcUnit _self;
  final $Res Function(_AcUnit) _then;

/// Create a copy of AcUnit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? quantity = null,}) {
  return _then(_AcUnit(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$InvoiceCharges {

 bool get acBracket; int get bracketCount; double get bracketAmount; bool get deliveryCharge; double get deliveryAmount; String get deliveryNote;
/// Create a copy of InvoiceCharges
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceChargesCopyWith<InvoiceCharges> get copyWith => _$InvoiceChargesCopyWithImpl<InvoiceCharges>(this as InvoiceCharges, _$identity);

  /// Serializes this InvoiceCharges to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvoiceCharges&&(identical(other.acBracket, acBracket) || other.acBracket == acBracket)&&(identical(other.bracketCount, bracketCount) || other.bracketCount == bracketCount)&&(identical(other.bracketAmount, bracketAmount) || other.bracketAmount == bracketAmount)&&(identical(other.deliveryCharge, deliveryCharge) || other.deliveryCharge == deliveryCharge)&&(identical(other.deliveryAmount, deliveryAmount) || other.deliveryAmount == deliveryAmount)&&(identical(other.deliveryNote, deliveryNote) || other.deliveryNote == deliveryNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,acBracket,bracketCount,bracketAmount,deliveryCharge,deliveryAmount,deliveryNote);

@override
String toString() {
  return 'InvoiceCharges(acBracket: $acBracket, bracketCount: $bracketCount, bracketAmount: $bracketAmount, deliveryCharge: $deliveryCharge, deliveryAmount: $deliveryAmount, deliveryNote: $deliveryNote)';
}


}

/// @nodoc
abstract mixin class $InvoiceChargesCopyWith<$Res>  {
  factory $InvoiceChargesCopyWith(InvoiceCharges value, $Res Function(InvoiceCharges) _then) = _$InvoiceChargesCopyWithImpl;
@useResult
$Res call({
 bool acBracket, int bracketCount, double bracketAmount, bool deliveryCharge, double deliveryAmount, String deliveryNote
});




}
/// @nodoc
class _$InvoiceChargesCopyWithImpl<$Res>
    implements $InvoiceChargesCopyWith<$Res> {
  _$InvoiceChargesCopyWithImpl(this._self, this._then);

  final InvoiceCharges _self;
  final $Res Function(InvoiceCharges) _then;

/// Create a copy of InvoiceCharges
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? acBracket = null,Object? bracketCount = null,Object? bracketAmount = null,Object? deliveryCharge = null,Object? deliveryAmount = null,Object? deliveryNote = null,}) {
  return _then(_self.copyWith(
acBracket: null == acBracket ? _self.acBracket : acBracket // ignore: cast_nullable_to_non_nullable
as bool,bracketCount: null == bracketCount ? _self.bracketCount : bracketCount // ignore: cast_nullable_to_non_nullable
as int,bracketAmount: null == bracketAmount ? _self.bracketAmount : bracketAmount // ignore: cast_nullable_to_non_nullable
as double,deliveryCharge: null == deliveryCharge ? _self.deliveryCharge : deliveryCharge // ignore: cast_nullable_to_non_nullable
as bool,deliveryAmount: null == deliveryAmount ? _self.deliveryAmount : deliveryAmount // ignore: cast_nullable_to_non_nullable
as double,deliveryNote: null == deliveryNote ? _self.deliveryNote : deliveryNote // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InvoiceCharges].
extension InvoiceChargesPatterns on InvoiceCharges {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvoiceCharges value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvoiceCharges() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvoiceCharges value)  $default,){
final _that = this;
switch (_that) {
case _InvoiceCharges():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvoiceCharges value)?  $default,){
final _that = this;
switch (_that) {
case _InvoiceCharges() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool acBracket,  int bracketCount,  double bracketAmount,  bool deliveryCharge,  double deliveryAmount,  String deliveryNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvoiceCharges() when $default != null:
return $default(_that.acBracket,_that.bracketCount,_that.bracketAmount,_that.deliveryCharge,_that.deliveryAmount,_that.deliveryNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool acBracket,  int bracketCount,  double bracketAmount,  bool deliveryCharge,  double deliveryAmount,  String deliveryNote)  $default,) {final _that = this;
switch (_that) {
case _InvoiceCharges():
return $default(_that.acBracket,_that.bracketCount,_that.bracketAmount,_that.deliveryCharge,_that.deliveryAmount,_that.deliveryNote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool acBracket,  int bracketCount,  double bracketAmount,  bool deliveryCharge,  double deliveryAmount,  String deliveryNote)?  $default,) {final _that = this;
switch (_that) {
case _InvoiceCharges() when $default != null:
return $default(_that.acBracket,_that.bracketCount,_that.bracketAmount,_that.deliveryCharge,_that.deliveryAmount,_that.deliveryNote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvoiceCharges implements InvoiceCharges {
  const _InvoiceCharges({this.acBracket = false, this.bracketCount = 0, this.bracketAmount = 0.0, this.deliveryCharge = false, this.deliveryAmount = 0.0, this.deliveryNote = ''});
  factory _InvoiceCharges.fromJson(Map<String, dynamic> json) => _$InvoiceChargesFromJson(json);

@override@JsonKey() final  bool acBracket;
@override@JsonKey() final  int bracketCount;
@override@JsonKey() final  double bracketAmount;
@override@JsonKey() final  bool deliveryCharge;
@override@JsonKey() final  double deliveryAmount;
@override@JsonKey() final  String deliveryNote;

/// Create a copy of InvoiceCharges
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceChargesCopyWith<_InvoiceCharges> get copyWith => __$InvoiceChargesCopyWithImpl<_InvoiceCharges>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvoiceChargesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvoiceCharges&&(identical(other.acBracket, acBracket) || other.acBracket == acBracket)&&(identical(other.bracketCount, bracketCount) || other.bracketCount == bracketCount)&&(identical(other.bracketAmount, bracketAmount) || other.bracketAmount == bracketAmount)&&(identical(other.deliveryCharge, deliveryCharge) || other.deliveryCharge == deliveryCharge)&&(identical(other.deliveryAmount, deliveryAmount) || other.deliveryAmount == deliveryAmount)&&(identical(other.deliveryNote, deliveryNote) || other.deliveryNote == deliveryNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,acBracket,bracketCount,bracketAmount,deliveryCharge,deliveryAmount,deliveryNote);

@override
String toString() {
  return 'InvoiceCharges(acBracket: $acBracket, bracketCount: $bracketCount, bracketAmount: $bracketAmount, deliveryCharge: $deliveryCharge, deliveryAmount: $deliveryAmount, deliveryNote: $deliveryNote)';
}


}

/// @nodoc
abstract mixin class _$InvoiceChargesCopyWith<$Res> implements $InvoiceChargesCopyWith<$Res> {
  factory _$InvoiceChargesCopyWith(_InvoiceCharges value, $Res Function(_InvoiceCharges) _then) = __$InvoiceChargesCopyWithImpl;
@override @useResult
$Res call({
 bool acBracket, int bracketCount, double bracketAmount, bool deliveryCharge, double deliveryAmount, String deliveryNote
});




}
/// @nodoc
class __$InvoiceChargesCopyWithImpl<$Res>
    implements _$InvoiceChargesCopyWith<$Res> {
  __$InvoiceChargesCopyWithImpl(this._self, this._then);

  final _InvoiceCharges _self;
  final $Res Function(_InvoiceCharges) _then;

/// Create a copy of InvoiceCharges
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? acBracket = null,Object? bracketCount = null,Object? bracketAmount = null,Object? deliveryCharge = null,Object? deliveryAmount = null,Object? deliveryNote = null,}) {
  return _then(_InvoiceCharges(
acBracket: null == acBracket ? _self.acBracket : acBracket // ignore: cast_nullable_to_non_nullable
as bool,bracketCount: null == bracketCount ? _self.bracketCount : bracketCount // ignore: cast_nullable_to_non_nullable
as int,bracketAmount: null == bracketAmount ? _self.bracketAmount : bracketAmount // ignore: cast_nullable_to_non_nullable
as double,deliveryCharge: null == deliveryCharge ? _self.deliveryCharge : deliveryCharge // ignore: cast_nullable_to_non_nullable
as bool,deliveryAmount: null == deliveryAmount ? _self.deliveryAmount : deliveryAmount // ignore: cast_nullable_to_non_nullable
as double,deliveryNote: null == deliveryNote ? _self.deliveryNote : deliveryNote // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$JobModel {

 String get id; String get techId; String get techName; String get companyId; String get companyName; String get invoiceNumber; String get clientName; String get clientContact; List<AcUnit> get acUnits; JobStatus get status; double get expenses; String get expenseNote; String get adminNote; JobSettlementStatus get settlementStatus; String get settlementBatchId; int get settlementRound; double get settlementAmount; String get settlementPaymentMethod; String get settlementAdminNote; String get settlementTechnicianComment; String get settlementRequestedBy; Map<String, dynamic> get importMeta; String? get approvedBy; bool get isSharedInstall; String get sharedInstallGroupKey; int get sharedInvoiceTotalUnits; int get sharedContributionUnits; int get sharedInvoiceSplitUnits; int get sharedInvoiceWindowUnits; int get sharedInvoiceFreestandingUnits; int get sharedInvoiceUninstallSplitUnits; int get sharedInvoiceUninstallWindowUnits; int get sharedInvoiceUninstallFreestandingUnits; int get sharedInvoiceBracketCount; int get sharedDeliveryTeamCount; double get sharedInvoiceDeliveryAmount;// Tech's personal installation share (how many of the invoice ACs they personally installed).
 int get techSplitShare; int get techWindowShare; int get techFreestandingShare; int get techUninstallSplitShare; int get techUninstallWindowShare; int get techUninstallFreestandingShare; int get techBracketShare;/// Additional invoice charges (bracket, delivery).
 InvoiceCharges? get charges;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get date;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get submittedAt;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get reviewedAt;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get settlementRequestedAt;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get settlementRespondedAt;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get settlementPaidAt;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get settlementCorrectedAt;@JsonKey(defaultValue: false) bool get isDeleted;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get deletedAt;@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? get editRequestedAt;
/// Create a copy of JobModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JobModelCopyWith<JobModel> get copyWith => _$JobModelCopyWithImpl<JobModel>(this as JobModel, _$identity);

  /// Serializes this JobModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JobModel&&(identical(other.id, id) || other.id == id)&&(identical(other.techId, techId) || other.techId == techId)&&(identical(other.techName, techName) || other.techName == techName)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.invoiceNumber, invoiceNumber) || other.invoiceNumber == invoiceNumber)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.clientContact, clientContact) || other.clientContact == clientContact)&&const DeepCollectionEquality().equals(other.acUnits, acUnits)&&(identical(other.status, status) || other.status == status)&&(identical(other.expenses, expenses) || other.expenses == expenses)&&(identical(other.expenseNote, expenseNote) || other.expenseNote == expenseNote)&&(identical(other.adminNote, adminNote) || other.adminNote == adminNote)&&(identical(other.settlementStatus, settlementStatus) || other.settlementStatus == settlementStatus)&&(identical(other.settlementBatchId, settlementBatchId) || other.settlementBatchId == settlementBatchId)&&(identical(other.settlementRound, settlementRound) || other.settlementRound == settlementRound)&&(identical(other.settlementAmount, settlementAmount) || other.settlementAmount == settlementAmount)&&(identical(other.settlementPaymentMethod, settlementPaymentMethod) || other.settlementPaymentMethod == settlementPaymentMethod)&&(identical(other.settlementAdminNote, settlementAdminNote) || other.settlementAdminNote == settlementAdminNote)&&(identical(other.settlementTechnicianComment, settlementTechnicianComment) || other.settlementTechnicianComment == settlementTechnicianComment)&&(identical(other.settlementRequestedBy, settlementRequestedBy) || other.settlementRequestedBy == settlementRequestedBy)&&const DeepCollectionEquality().equals(other.importMeta, importMeta)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.isSharedInstall, isSharedInstall) || other.isSharedInstall == isSharedInstall)&&(identical(other.sharedInstallGroupKey, sharedInstallGroupKey) || other.sharedInstallGroupKey == sharedInstallGroupKey)&&(identical(other.sharedInvoiceTotalUnits, sharedInvoiceTotalUnits) || other.sharedInvoiceTotalUnits == sharedInvoiceTotalUnits)&&(identical(other.sharedContributionUnits, sharedContributionUnits) || other.sharedContributionUnits == sharedContributionUnits)&&(identical(other.sharedInvoiceSplitUnits, sharedInvoiceSplitUnits) || other.sharedInvoiceSplitUnits == sharedInvoiceSplitUnits)&&(identical(other.sharedInvoiceWindowUnits, sharedInvoiceWindowUnits) || other.sharedInvoiceWindowUnits == sharedInvoiceWindowUnits)&&(identical(other.sharedInvoiceFreestandingUnits, sharedInvoiceFreestandingUnits) || other.sharedInvoiceFreestandingUnits == sharedInvoiceFreestandingUnits)&&(identical(other.sharedInvoiceUninstallSplitUnits, sharedInvoiceUninstallSplitUnits) || other.sharedInvoiceUninstallSplitUnits == sharedInvoiceUninstallSplitUnits)&&(identical(other.sharedInvoiceUninstallWindowUnits, sharedInvoiceUninstallWindowUnits) || other.sharedInvoiceUninstallWindowUnits == sharedInvoiceUninstallWindowUnits)&&(identical(other.sharedInvoiceUninstallFreestandingUnits, sharedInvoiceUninstallFreestandingUnits) || other.sharedInvoiceUninstallFreestandingUnits == sharedInvoiceUninstallFreestandingUnits)&&(identical(other.sharedInvoiceBracketCount, sharedInvoiceBracketCount) || other.sharedInvoiceBracketCount == sharedInvoiceBracketCount)&&(identical(other.sharedDeliveryTeamCount, sharedDeliveryTeamCount) || other.sharedDeliveryTeamCount == sharedDeliveryTeamCount)&&(identical(other.sharedInvoiceDeliveryAmount, sharedInvoiceDeliveryAmount) || other.sharedInvoiceDeliveryAmount == sharedInvoiceDeliveryAmount)&&(identical(other.techSplitShare, techSplitShare) || other.techSplitShare == techSplitShare)&&(identical(other.techWindowShare, techWindowShare) || other.techWindowShare == techWindowShare)&&(identical(other.techFreestandingShare, techFreestandingShare) || other.techFreestandingShare == techFreestandingShare)&&(identical(other.techUninstallSplitShare, techUninstallSplitShare) || other.techUninstallSplitShare == techUninstallSplitShare)&&(identical(other.techUninstallWindowShare, techUninstallWindowShare) || other.techUninstallWindowShare == techUninstallWindowShare)&&(identical(other.techUninstallFreestandingShare, techUninstallFreestandingShare) || other.techUninstallFreestandingShare == techUninstallFreestandingShare)&&(identical(other.techBracketShare, techBracketShare) || other.techBracketShare == techBracketShare)&&(identical(other.charges, charges) || other.charges == charges)&&(identical(other.date, date) || other.date == date)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.settlementRequestedAt, settlementRequestedAt) || other.settlementRequestedAt == settlementRequestedAt)&&(identical(other.settlementRespondedAt, settlementRespondedAt) || other.settlementRespondedAt == settlementRespondedAt)&&(identical(other.settlementPaidAt, settlementPaidAt) || other.settlementPaidAt == settlementPaidAt)&&(identical(other.settlementCorrectedAt, settlementCorrectedAt) || other.settlementCorrectedAt == settlementCorrectedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.editRequestedAt, editRequestedAt) || other.editRequestedAt == editRequestedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,techId,techName,companyId,companyName,invoiceNumber,clientName,clientContact,const DeepCollectionEquality().hash(acUnits),status,expenses,expenseNote,adminNote,settlementStatus,settlementBatchId,settlementRound,settlementAmount,settlementPaymentMethod,settlementAdminNote,settlementTechnicianComment,settlementRequestedBy,const DeepCollectionEquality().hash(importMeta),approvedBy,isSharedInstall,sharedInstallGroupKey,sharedInvoiceTotalUnits,sharedContributionUnits,sharedInvoiceSplitUnits,sharedInvoiceWindowUnits,sharedInvoiceFreestandingUnits,sharedInvoiceUninstallSplitUnits,sharedInvoiceUninstallWindowUnits,sharedInvoiceUninstallFreestandingUnits,sharedInvoiceBracketCount,sharedDeliveryTeamCount,sharedInvoiceDeliveryAmount,techSplitShare,techWindowShare,techFreestandingShare,techUninstallSplitShare,techUninstallWindowShare,techUninstallFreestandingShare,techBracketShare,charges,date,submittedAt,reviewedAt,settlementRequestedAt,settlementRespondedAt,settlementPaidAt,settlementCorrectedAt,isDeleted,deletedAt,editRequestedAt]);

@override
String toString() {
  return 'JobModel(id: $id, techId: $techId, techName: $techName, companyId: $companyId, companyName: $companyName, invoiceNumber: $invoiceNumber, clientName: $clientName, clientContact: $clientContact, acUnits: $acUnits, status: $status, expenses: $expenses, expenseNote: $expenseNote, adminNote: $adminNote, settlementStatus: $settlementStatus, settlementBatchId: $settlementBatchId, settlementRound: $settlementRound, settlementAmount: $settlementAmount, settlementPaymentMethod: $settlementPaymentMethod, settlementAdminNote: $settlementAdminNote, settlementTechnicianComment: $settlementTechnicianComment, settlementRequestedBy: $settlementRequestedBy, importMeta: $importMeta, approvedBy: $approvedBy, isSharedInstall: $isSharedInstall, sharedInstallGroupKey: $sharedInstallGroupKey, sharedInvoiceTotalUnits: $sharedInvoiceTotalUnits, sharedContributionUnits: $sharedContributionUnits, sharedInvoiceSplitUnits: $sharedInvoiceSplitUnits, sharedInvoiceWindowUnits: $sharedInvoiceWindowUnits, sharedInvoiceFreestandingUnits: $sharedInvoiceFreestandingUnits, sharedInvoiceUninstallSplitUnits: $sharedInvoiceUninstallSplitUnits, sharedInvoiceUninstallWindowUnits: $sharedInvoiceUninstallWindowUnits, sharedInvoiceUninstallFreestandingUnits: $sharedInvoiceUninstallFreestandingUnits, sharedInvoiceBracketCount: $sharedInvoiceBracketCount, sharedDeliveryTeamCount: $sharedDeliveryTeamCount, sharedInvoiceDeliveryAmount: $sharedInvoiceDeliveryAmount, techSplitShare: $techSplitShare, techWindowShare: $techWindowShare, techFreestandingShare: $techFreestandingShare, techUninstallSplitShare: $techUninstallSplitShare, techUninstallWindowShare: $techUninstallWindowShare, techUninstallFreestandingShare: $techUninstallFreestandingShare, techBracketShare: $techBracketShare, charges: $charges, date: $date, submittedAt: $submittedAt, reviewedAt: $reviewedAt, settlementRequestedAt: $settlementRequestedAt, settlementRespondedAt: $settlementRespondedAt, settlementPaidAt: $settlementPaidAt, settlementCorrectedAt: $settlementCorrectedAt, isDeleted: $isDeleted, deletedAt: $deletedAt, editRequestedAt: $editRequestedAt)';
}


}

/// @nodoc
abstract mixin class $JobModelCopyWith<$Res>  {
  factory $JobModelCopyWith(JobModel value, $Res Function(JobModel) _then) = _$JobModelCopyWithImpl;
@useResult
$Res call({
 String id, String techId, String techName, String companyId, String companyName, String invoiceNumber, String clientName, String clientContact, List<AcUnit> acUnits, JobStatus status, double expenses, String expenseNote, String adminNote, JobSettlementStatus settlementStatus, String settlementBatchId, int settlementRound, double settlementAmount, String settlementPaymentMethod, String settlementAdminNote, String settlementTechnicianComment, String settlementRequestedBy, Map<String, dynamic> importMeta, String? approvedBy, bool isSharedInstall, String sharedInstallGroupKey, int sharedInvoiceTotalUnits, int sharedContributionUnits, int sharedInvoiceSplitUnits, int sharedInvoiceWindowUnits, int sharedInvoiceFreestandingUnits, int sharedInvoiceUninstallSplitUnits, int sharedInvoiceUninstallWindowUnits, int sharedInvoiceUninstallFreestandingUnits, int sharedInvoiceBracketCount, int sharedDeliveryTeamCount, double sharedInvoiceDeliveryAmount, int techSplitShare, int techWindowShare, int techFreestandingShare, int techUninstallSplitShare, int techUninstallWindowShare, int techUninstallFreestandingShare, int techBracketShare, InvoiceCharges? charges,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? date,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? submittedAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? reviewedAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? settlementRequestedAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? settlementRespondedAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? settlementPaidAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? settlementCorrectedAt,@JsonKey(defaultValue: false) bool isDeleted,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? deletedAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? editRequestedAt
});


$InvoiceChargesCopyWith<$Res>? get charges;

}
/// @nodoc
class _$JobModelCopyWithImpl<$Res>
    implements $JobModelCopyWith<$Res> {
  _$JobModelCopyWithImpl(this._self, this._then);

  final JobModel _self;
  final $Res Function(JobModel) _then;

/// Create a copy of JobModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? techId = null,Object? techName = null,Object? companyId = null,Object? companyName = null,Object? invoiceNumber = null,Object? clientName = null,Object? clientContact = null,Object? acUnits = null,Object? status = null,Object? expenses = null,Object? expenseNote = null,Object? adminNote = null,Object? settlementStatus = null,Object? settlementBatchId = null,Object? settlementRound = null,Object? settlementAmount = null,Object? settlementPaymentMethod = null,Object? settlementAdminNote = null,Object? settlementTechnicianComment = null,Object? settlementRequestedBy = null,Object? importMeta = null,Object? approvedBy = freezed,Object? isSharedInstall = null,Object? sharedInstallGroupKey = null,Object? sharedInvoiceTotalUnits = null,Object? sharedContributionUnits = null,Object? sharedInvoiceSplitUnits = null,Object? sharedInvoiceWindowUnits = null,Object? sharedInvoiceFreestandingUnits = null,Object? sharedInvoiceUninstallSplitUnits = null,Object? sharedInvoiceUninstallWindowUnits = null,Object? sharedInvoiceUninstallFreestandingUnits = null,Object? sharedInvoiceBracketCount = null,Object? sharedDeliveryTeamCount = null,Object? sharedInvoiceDeliveryAmount = null,Object? techSplitShare = null,Object? techWindowShare = null,Object? techFreestandingShare = null,Object? techUninstallSplitShare = null,Object? techUninstallWindowShare = null,Object? techUninstallFreestandingShare = null,Object? techBracketShare = null,Object? charges = freezed,Object? date = freezed,Object? submittedAt = freezed,Object? reviewedAt = freezed,Object? settlementRequestedAt = freezed,Object? settlementRespondedAt = freezed,Object? settlementPaidAt = freezed,Object? settlementCorrectedAt = freezed,Object? isDeleted = null,Object? deletedAt = freezed,Object? editRequestedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,techId: null == techId ? _self.techId : techId // ignore: cast_nullable_to_non_nullable
as String,techName: null == techName ? _self.techName : techName // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,invoiceNumber: null == invoiceNumber ? _self.invoiceNumber : invoiceNumber // ignore: cast_nullable_to_non_nullable
as String,clientName: null == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String,clientContact: null == clientContact ? _self.clientContact : clientContact // ignore: cast_nullable_to_non_nullable
as String,acUnits: null == acUnits ? _self.acUnits : acUnits // ignore: cast_nullable_to_non_nullable
as List<AcUnit>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JobStatus,expenses: null == expenses ? _self.expenses : expenses // ignore: cast_nullable_to_non_nullable
as double,expenseNote: null == expenseNote ? _self.expenseNote : expenseNote // ignore: cast_nullable_to_non_nullable
as String,adminNote: null == adminNote ? _self.adminNote : adminNote // ignore: cast_nullable_to_non_nullable
as String,settlementStatus: null == settlementStatus ? _self.settlementStatus : settlementStatus // ignore: cast_nullable_to_non_nullable
as JobSettlementStatus,settlementBatchId: null == settlementBatchId ? _self.settlementBatchId : settlementBatchId // ignore: cast_nullable_to_non_nullable
as String,settlementRound: null == settlementRound ? _self.settlementRound : settlementRound // ignore: cast_nullable_to_non_nullable
as int,settlementAmount: null == settlementAmount ? _self.settlementAmount : settlementAmount // ignore: cast_nullable_to_non_nullable
as double,settlementPaymentMethod: null == settlementPaymentMethod ? _self.settlementPaymentMethod : settlementPaymentMethod // ignore: cast_nullable_to_non_nullable
as String,settlementAdminNote: null == settlementAdminNote ? _self.settlementAdminNote : settlementAdminNote // ignore: cast_nullable_to_non_nullable
as String,settlementTechnicianComment: null == settlementTechnicianComment ? _self.settlementTechnicianComment : settlementTechnicianComment // ignore: cast_nullable_to_non_nullable
as String,settlementRequestedBy: null == settlementRequestedBy ? _self.settlementRequestedBy : settlementRequestedBy // ignore: cast_nullable_to_non_nullable
as String,importMeta: null == importMeta ? _self.importMeta : importMeta // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,approvedBy: freezed == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as String?,isSharedInstall: null == isSharedInstall ? _self.isSharedInstall : isSharedInstall // ignore: cast_nullable_to_non_nullable
as bool,sharedInstallGroupKey: null == sharedInstallGroupKey ? _self.sharedInstallGroupKey : sharedInstallGroupKey // ignore: cast_nullable_to_non_nullable
as String,sharedInvoiceTotalUnits: null == sharedInvoiceTotalUnits ? _self.sharedInvoiceTotalUnits : sharedInvoiceTotalUnits // ignore: cast_nullable_to_non_nullable
as int,sharedContributionUnits: null == sharedContributionUnits ? _self.sharedContributionUnits : sharedContributionUnits // ignore: cast_nullable_to_non_nullable
as int,sharedInvoiceSplitUnits: null == sharedInvoiceSplitUnits ? _self.sharedInvoiceSplitUnits : sharedInvoiceSplitUnits // ignore: cast_nullable_to_non_nullable
as int,sharedInvoiceWindowUnits: null == sharedInvoiceWindowUnits ? _self.sharedInvoiceWindowUnits : sharedInvoiceWindowUnits // ignore: cast_nullable_to_non_nullable
as int,sharedInvoiceFreestandingUnits: null == sharedInvoiceFreestandingUnits ? _self.sharedInvoiceFreestandingUnits : sharedInvoiceFreestandingUnits // ignore: cast_nullable_to_non_nullable
as int,sharedInvoiceUninstallSplitUnits: null == sharedInvoiceUninstallSplitUnits ? _self.sharedInvoiceUninstallSplitUnits : sharedInvoiceUninstallSplitUnits // ignore: cast_nullable_to_non_nullable
as int,sharedInvoiceUninstallWindowUnits: null == sharedInvoiceUninstallWindowUnits ? _self.sharedInvoiceUninstallWindowUnits : sharedInvoiceUninstallWindowUnits // ignore: cast_nullable_to_non_nullable
as int,sharedInvoiceUninstallFreestandingUnits: null == sharedInvoiceUninstallFreestandingUnits ? _self.sharedInvoiceUninstallFreestandingUnits : sharedInvoiceUninstallFreestandingUnits // ignore: cast_nullable_to_non_nullable
as int,sharedInvoiceBracketCount: null == sharedInvoiceBracketCount ? _self.sharedInvoiceBracketCount : sharedInvoiceBracketCount // ignore: cast_nullable_to_non_nullable
as int,sharedDeliveryTeamCount: null == sharedDeliveryTeamCount ? _self.sharedDeliveryTeamCount : sharedDeliveryTeamCount // ignore: cast_nullable_to_non_nullable
as int,sharedInvoiceDeliveryAmount: null == sharedInvoiceDeliveryAmount ? _self.sharedInvoiceDeliveryAmount : sharedInvoiceDeliveryAmount // ignore: cast_nullable_to_non_nullable
as double,techSplitShare: null == techSplitShare ? _self.techSplitShare : techSplitShare // ignore: cast_nullable_to_non_nullable
as int,techWindowShare: null == techWindowShare ? _self.techWindowShare : techWindowShare // ignore: cast_nullable_to_non_nullable
as int,techFreestandingShare: null == techFreestandingShare ? _self.techFreestandingShare : techFreestandingShare // ignore: cast_nullable_to_non_nullable
as int,techUninstallSplitShare: null == techUninstallSplitShare ? _self.techUninstallSplitShare : techUninstallSplitShare // ignore: cast_nullable_to_non_nullable
as int,techUninstallWindowShare: null == techUninstallWindowShare ? _self.techUninstallWindowShare : techUninstallWindowShare // ignore: cast_nullable_to_non_nullable
as int,techUninstallFreestandingShare: null == techUninstallFreestandingShare ? _self.techUninstallFreestandingShare : techUninstallFreestandingShare // ignore: cast_nullable_to_non_nullable
as int,techBracketShare: null == techBracketShare ? _self.techBracketShare : techBracketShare // ignore: cast_nullable_to_non_nullable
as int,charges: freezed == charges ? _self.charges : charges // ignore: cast_nullable_to_non_nullable
as InvoiceCharges?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,settlementRequestedAt: freezed == settlementRequestedAt ? _self.settlementRequestedAt : settlementRequestedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,settlementRespondedAt: freezed == settlementRespondedAt ? _self.settlementRespondedAt : settlementRespondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,settlementPaidAt: freezed == settlementPaidAt ? _self.settlementPaidAt : settlementPaidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,settlementCorrectedAt: freezed == settlementCorrectedAt ? _self.settlementCorrectedAt : settlementCorrectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,editRequestedAt: freezed == editRequestedAt ? _self.editRequestedAt : editRequestedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of JobModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvoiceChargesCopyWith<$Res>? get charges {
    if (_self.charges == null) {
    return null;
  }

  return $InvoiceChargesCopyWith<$Res>(_self.charges!, (value) {
    return _then(_self.copyWith(charges: value));
  });
}
}


/// Adds pattern-matching-related methods to [JobModel].
extension JobModelPatterns on JobModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JobModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JobModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JobModel value)  $default,){
final _that = this;
switch (_that) {
case _JobModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JobModel value)?  $default,){
final _that = this;
switch (_that) {
case _JobModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String techId,  String techName,  String companyId,  String companyName,  String invoiceNumber,  String clientName,  String clientContact,  List<AcUnit> acUnits,  JobStatus status,  double expenses,  String expenseNote,  String adminNote,  JobSettlementStatus settlementStatus,  String settlementBatchId,  int settlementRound,  double settlementAmount,  String settlementPaymentMethod,  String settlementAdminNote,  String settlementTechnicianComment,  String settlementRequestedBy,  Map<String, dynamic> importMeta,  String? approvedBy,  bool isSharedInstall,  String sharedInstallGroupKey,  int sharedInvoiceTotalUnits,  int sharedContributionUnits,  int sharedInvoiceSplitUnits,  int sharedInvoiceWindowUnits,  int sharedInvoiceFreestandingUnits,  int sharedInvoiceUninstallSplitUnits,  int sharedInvoiceUninstallWindowUnits,  int sharedInvoiceUninstallFreestandingUnits,  int sharedInvoiceBracketCount,  int sharedDeliveryTeamCount,  double sharedInvoiceDeliveryAmount,  int techSplitShare,  int techWindowShare,  int techFreestandingShare,  int techUninstallSplitShare,  int techUninstallWindowShare,  int techUninstallFreestandingShare,  int techBracketShare,  InvoiceCharges? charges, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? submittedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? reviewedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? settlementRequestedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? settlementRespondedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? settlementPaidAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? settlementCorrectedAt, @JsonKey(defaultValue: false)  bool isDeleted, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? deletedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? editRequestedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JobModel() when $default != null:
return $default(_that.id,_that.techId,_that.techName,_that.companyId,_that.companyName,_that.invoiceNumber,_that.clientName,_that.clientContact,_that.acUnits,_that.status,_that.expenses,_that.expenseNote,_that.adminNote,_that.settlementStatus,_that.settlementBatchId,_that.settlementRound,_that.settlementAmount,_that.settlementPaymentMethod,_that.settlementAdminNote,_that.settlementTechnicianComment,_that.settlementRequestedBy,_that.importMeta,_that.approvedBy,_that.isSharedInstall,_that.sharedInstallGroupKey,_that.sharedInvoiceTotalUnits,_that.sharedContributionUnits,_that.sharedInvoiceSplitUnits,_that.sharedInvoiceWindowUnits,_that.sharedInvoiceFreestandingUnits,_that.sharedInvoiceUninstallSplitUnits,_that.sharedInvoiceUninstallWindowUnits,_that.sharedInvoiceUninstallFreestandingUnits,_that.sharedInvoiceBracketCount,_that.sharedDeliveryTeamCount,_that.sharedInvoiceDeliveryAmount,_that.techSplitShare,_that.techWindowShare,_that.techFreestandingShare,_that.techUninstallSplitShare,_that.techUninstallWindowShare,_that.techUninstallFreestandingShare,_that.techBracketShare,_that.charges,_that.date,_that.submittedAt,_that.reviewedAt,_that.settlementRequestedAt,_that.settlementRespondedAt,_that.settlementPaidAt,_that.settlementCorrectedAt,_that.isDeleted,_that.deletedAt,_that.editRequestedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String techId,  String techName,  String companyId,  String companyName,  String invoiceNumber,  String clientName,  String clientContact,  List<AcUnit> acUnits,  JobStatus status,  double expenses,  String expenseNote,  String adminNote,  JobSettlementStatus settlementStatus,  String settlementBatchId,  int settlementRound,  double settlementAmount,  String settlementPaymentMethod,  String settlementAdminNote,  String settlementTechnicianComment,  String settlementRequestedBy,  Map<String, dynamic> importMeta,  String? approvedBy,  bool isSharedInstall,  String sharedInstallGroupKey,  int sharedInvoiceTotalUnits,  int sharedContributionUnits,  int sharedInvoiceSplitUnits,  int sharedInvoiceWindowUnits,  int sharedInvoiceFreestandingUnits,  int sharedInvoiceUninstallSplitUnits,  int sharedInvoiceUninstallWindowUnits,  int sharedInvoiceUninstallFreestandingUnits,  int sharedInvoiceBracketCount,  int sharedDeliveryTeamCount,  double sharedInvoiceDeliveryAmount,  int techSplitShare,  int techWindowShare,  int techFreestandingShare,  int techUninstallSplitShare,  int techUninstallWindowShare,  int techUninstallFreestandingShare,  int techBracketShare,  InvoiceCharges? charges, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? submittedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? reviewedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? settlementRequestedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? settlementRespondedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? settlementPaidAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? settlementCorrectedAt, @JsonKey(defaultValue: false)  bool isDeleted, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? deletedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? editRequestedAt)  $default,) {final _that = this;
switch (_that) {
case _JobModel():
return $default(_that.id,_that.techId,_that.techName,_that.companyId,_that.companyName,_that.invoiceNumber,_that.clientName,_that.clientContact,_that.acUnits,_that.status,_that.expenses,_that.expenseNote,_that.adminNote,_that.settlementStatus,_that.settlementBatchId,_that.settlementRound,_that.settlementAmount,_that.settlementPaymentMethod,_that.settlementAdminNote,_that.settlementTechnicianComment,_that.settlementRequestedBy,_that.importMeta,_that.approvedBy,_that.isSharedInstall,_that.sharedInstallGroupKey,_that.sharedInvoiceTotalUnits,_that.sharedContributionUnits,_that.sharedInvoiceSplitUnits,_that.sharedInvoiceWindowUnits,_that.sharedInvoiceFreestandingUnits,_that.sharedInvoiceUninstallSplitUnits,_that.sharedInvoiceUninstallWindowUnits,_that.sharedInvoiceUninstallFreestandingUnits,_that.sharedInvoiceBracketCount,_that.sharedDeliveryTeamCount,_that.sharedInvoiceDeliveryAmount,_that.techSplitShare,_that.techWindowShare,_that.techFreestandingShare,_that.techUninstallSplitShare,_that.techUninstallWindowShare,_that.techUninstallFreestandingShare,_that.techBracketShare,_that.charges,_that.date,_that.submittedAt,_that.reviewedAt,_that.settlementRequestedAt,_that.settlementRespondedAt,_that.settlementPaidAt,_that.settlementCorrectedAt,_that.isDeleted,_that.deletedAt,_that.editRequestedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String techId,  String techName,  String companyId,  String companyName,  String invoiceNumber,  String clientName,  String clientContact,  List<AcUnit> acUnits,  JobStatus status,  double expenses,  String expenseNote,  String adminNote,  JobSettlementStatus settlementStatus,  String settlementBatchId,  int settlementRound,  double settlementAmount,  String settlementPaymentMethod,  String settlementAdminNote,  String settlementTechnicianComment,  String settlementRequestedBy,  Map<String, dynamic> importMeta,  String? approvedBy,  bool isSharedInstall,  String sharedInstallGroupKey,  int sharedInvoiceTotalUnits,  int sharedContributionUnits,  int sharedInvoiceSplitUnits,  int sharedInvoiceWindowUnits,  int sharedInvoiceFreestandingUnits,  int sharedInvoiceUninstallSplitUnits,  int sharedInvoiceUninstallWindowUnits,  int sharedInvoiceUninstallFreestandingUnits,  int sharedInvoiceBracketCount,  int sharedDeliveryTeamCount,  double sharedInvoiceDeliveryAmount,  int techSplitShare,  int techWindowShare,  int techFreestandingShare,  int techUninstallSplitShare,  int techUninstallWindowShare,  int techUninstallFreestandingShare,  int techBracketShare,  InvoiceCharges? charges, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? submittedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? reviewedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? settlementRequestedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? settlementRespondedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? settlementPaidAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? settlementCorrectedAt, @JsonKey(defaultValue: false)  bool isDeleted, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? deletedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)  DateTime? editRequestedAt)?  $default,) {final _that = this;
switch (_that) {
case _JobModel() when $default != null:
return $default(_that.id,_that.techId,_that.techName,_that.companyId,_that.companyName,_that.invoiceNumber,_that.clientName,_that.clientContact,_that.acUnits,_that.status,_that.expenses,_that.expenseNote,_that.adminNote,_that.settlementStatus,_that.settlementBatchId,_that.settlementRound,_that.settlementAmount,_that.settlementPaymentMethod,_that.settlementAdminNote,_that.settlementTechnicianComment,_that.settlementRequestedBy,_that.importMeta,_that.approvedBy,_that.isSharedInstall,_that.sharedInstallGroupKey,_that.sharedInvoiceTotalUnits,_that.sharedContributionUnits,_that.sharedInvoiceSplitUnits,_that.sharedInvoiceWindowUnits,_that.sharedInvoiceFreestandingUnits,_that.sharedInvoiceUninstallSplitUnits,_that.sharedInvoiceUninstallWindowUnits,_that.sharedInvoiceUninstallFreestandingUnits,_that.sharedInvoiceBracketCount,_that.sharedDeliveryTeamCount,_that.sharedInvoiceDeliveryAmount,_that.techSplitShare,_that.techWindowShare,_that.techFreestandingShare,_that.techUninstallSplitShare,_that.techUninstallWindowShare,_that.techUninstallFreestandingShare,_that.techBracketShare,_that.charges,_that.date,_that.submittedAt,_that.reviewedAt,_that.settlementRequestedAt,_that.settlementRespondedAt,_that.settlementPaidAt,_that.settlementCorrectedAt,_that.isDeleted,_that.deletedAt,_that.editRequestedAt);case _:
  return null;

}
}

}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _JobModel implements JobModel {
  const _JobModel({this.id = '', required this.techId, required this.techName, this.companyId = '', this.companyName = '', required this.invoiceNumber, required this.clientName, this.clientContact = '', final  List<AcUnit> acUnits = const <AcUnit>[], this.status = JobStatus.pending, this.expenses = 0.0, this.expenseNote = '', this.adminNote = '', this.settlementStatus = JobSettlementStatus.unpaid, this.settlementBatchId = '', this.settlementRound = 0, this.settlementAmount = 0.0, this.settlementPaymentMethod = '', this.settlementAdminNote = '', this.settlementTechnicianComment = '', this.settlementRequestedBy = '', final  Map<String, dynamic> importMeta = const <String, dynamic>{}, this.approvedBy, this.isSharedInstall = false, this.sharedInstallGroupKey = '', this.sharedInvoiceTotalUnits = 0, this.sharedContributionUnits = 0, this.sharedInvoiceSplitUnits = 0, this.sharedInvoiceWindowUnits = 0, this.sharedInvoiceFreestandingUnits = 0, this.sharedInvoiceUninstallSplitUnits = 0, this.sharedInvoiceUninstallWindowUnits = 0, this.sharedInvoiceUninstallFreestandingUnits = 0, this.sharedInvoiceBracketCount = 0, this.sharedDeliveryTeamCount = 0, this.sharedInvoiceDeliveryAmount = 0.0, this.techSplitShare = 0, this.techWindowShare = 0, this.techFreestandingShare = 0, this.techUninstallSplitShare = 0, this.techUninstallWindowShare = 0, this.techUninstallFreestandingShare = 0, this.techBracketShare = 0, this.charges, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.date, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.submittedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.reviewedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.settlementRequestedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.settlementRespondedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.settlementPaidAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.settlementCorrectedAt, @JsonKey(defaultValue: false) this.isDeleted = false, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.deletedAt, @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) this.editRequestedAt}): _acUnits = acUnits,_importMeta = importMeta;
  factory _JobModel.fromJson(Map<String, dynamic> json) => _$JobModelFromJson(json);

@override@JsonKey() final  String id;
@override final  String techId;
@override final  String techName;
@override@JsonKey() final  String companyId;
@override@JsonKey() final  String companyName;
@override final  String invoiceNumber;
@override final  String clientName;
@override@JsonKey() final  String clientContact;
 final  List<AcUnit> _acUnits;
@override@JsonKey() List<AcUnit> get acUnits {
  if (_acUnits is EqualUnmodifiableListView) return _acUnits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_acUnits);
}

@override@JsonKey() final  JobStatus status;
@override@JsonKey() final  double expenses;
@override@JsonKey() final  String expenseNote;
@override@JsonKey() final  String adminNote;
@override@JsonKey() final  JobSettlementStatus settlementStatus;
@override@JsonKey() final  String settlementBatchId;
@override@JsonKey() final  int settlementRound;
@override@JsonKey() final  double settlementAmount;
@override@JsonKey() final  String settlementPaymentMethod;
@override@JsonKey() final  String settlementAdminNote;
@override@JsonKey() final  String settlementTechnicianComment;
@override@JsonKey() final  String settlementRequestedBy;
 final  Map<String, dynamic> _importMeta;
@override@JsonKey() Map<String, dynamic> get importMeta {
  if (_importMeta is EqualUnmodifiableMapView) return _importMeta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_importMeta);
}

@override final  String? approvedBy;
@override@JsonKey() final  bool isSharedInstall;
@override@JsonKey() final  String sharedInstallGroupKey;
@override@JsonKey() final  int sharedInvoiceTotalUnits;
@override@JsonKey() final  int sharedContributionUnits;
@override@JsonKey() final  int sharedInvoiceSplitUnits;
@override@JsonKey() final  int sharedInvoiceWindowUnits;
@override@JsonKey() final  int sharedInvoiceFreestandingUnits;
@override@JsonKey() final  int sharedInvoiceUninstallSplitUnits;
@override@JsonKey() final  int sharedInvoiceUninstallWindowUnits;
@override@JsonKey() final  int sharedInvoiceUninstallFreestandingUnits;
@override@JsonKey() final  int sharedInvoiceBracketCount;
@override@JsonKey() final  int sharedDeliveryTeamCount;
@override@JsonKey() final  double sharedInvoiceDeliveryAmount;
// Tech's personal installation share (how many of the invoice ACs they personally installed).
@override@JsonKey() final  int techSplitShare;
@override@JsonKey() final  int techWindowShare;
@override@JsonKey() final  int techFreestandingShare;
@override@JsonKey() final  int techUninstallSplitShare;
@override@JsonKey() final  int techUninstallWindowShare;
@override@JsonKey() final  int techUninstallFreestandingShare;
@override@JsonKey() final  int techBracketShare;
/// Additional invoice charges (bracket, delivery).
@override final  InvoiceCharges? charges;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? date;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? submittedAt;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? reviewedAt;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? settlementRequestedAt;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? settlementRespondedAt;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? settlementPaidAt;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? settlementCorrectedAt;
@override@JsonKey(defaultValue: false) final  bool isDeleted;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? deletedAt;
@override@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) final  DateTime? editRequestedAt;

/// Create a copy of JobModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JobModelCopyWith<_JobModel> get copyWith => __$JobModelCopyWithImpl<_JobModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JobModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JobModel&&(identical(other.id, id) || other.id == id)&&(identical(other.techId, techId) || other.techId == techId)&&(identical(other.techName, techName) || other.techName == techName)&&(identical(other.companyId, companyId) || other.companyId == companyId)&&(identical(other.companyName, companyName) || other.companyName == companyName)&&(identical(other.invoiceNumber, invoiceNumber) || other.invoiceNumber == invoiceNumber)&&(identical(other.clientName, clientName) || other.clientName == clientName)&&(identical(other.clientContact, clientContact) || other.clientContact == clientContact)&&const DeepCollectionEquality().equals(other._acUnits, _acUnits)&&(identical(other.status, status) || other.status == status)&&(identical(other.expenses, expenses) || other.expenses == expenses)&&(identical(other.expenseNote, expenseNote) || other.expenseNote == expenseNote)&&(identical(other.adminNote, adminNote) || other.adminNote == adminNote)&&(identical(other.settlementStatus, settlementStatus) || other.settlementStatus == settlementStatus)&&(identical(other.settlementBatchId, settlementBatchId) || other.settlementBatchId == settlementBatchId)&&(identical(other.settlementRound, settlementRound) || other.settlementRound == settlementRound)&&(identical(other.settlementAmount, settlementAmount) || other.settlementAmount == settlementAmount)&&(identical(other.settlementPaymentMethod, settlementPaymentMethod) || other.settlementPaymentMethod == settlementPaymentMethod)&&(identical(other.settlementAdminNote, settlementAdminNote) || other.settlementAdminNote == settlementAdminNote)&&(identical(other.settlementTechnicianComment, settlementTechnicianComment) || other.settlementTechnicianComment == settlementTechnicianComment)&&(identical(other.settlementRequestedBy, settlementRequestedBy) || other.settlementRequestedBy == settlementRequestedBy)&&const DeepCollectionEquality().equals(other._importMeta, _importMeta)&&(identical(other.approvedBy, approvedBy) || other.approvedBy == approvedBy)&&(identical(other.isSharedInstall, isSharedInstall) || other.isSharedInstall == isSharedInstall)&&(identical(other.sharedInstallGroupKey, sharedInstallGroupKey) || other.sharedInstallGroupKey == sharedInstallGroupKey)&&(identical(other.sharedInvoiceTotalUnits, sharedInvoiceTotalUnits) || other.sharedInvoiceTotalUnits == sharedInvoiceTotalUnits)&&(identical(other.sharedContributionUnits, sharedContributionUnits) || other.sharedContributionUnits == sharedContributionUnits)&&(identical(other.sharedInvoiceSplitUnits, sharedInvoiceSplitUnits) || other.sharedInvoiceSplitUnits == sharedInvoiceSplitUnits)&&(identical(other.sharedInvoiceWindowUnits, sharedInvoiceWindowUnits) || other.sharedInvoiceWindowUnits == sharedInvoiceWindowUnits)&&(identical(other.sharedInvoiceFreestandingUnits, sharedInvoiceFreestandingUnits) || other.sharedInvoiceFreestandingUnits == sharedInvoiceFreestandingUnits)&&(identical(other.sharedInvoiceUninstallSplitUnits, sharedInvoiceUninstallSplitUnits) || other.sharedInvoiceUninstallSplitUnits == sharedInvoiceUninstallSplitUnits)&&(identical(other.sharedInvoiceUninstallWindowUnits, sharedInvoiceUninstallWindowUnits) || other.sharedInvoiceUninstallWindowUnits == sharedInvoiceUninstallWindowUnits)&&(identical(other.sharedInvoiceUninstallFreestandingUnits, sharedInvoiceUninstallFreestandingUnits) || other.sharedInvoiceUninstallFreestandingUnits == sharedInvoiceUninstallFreestandingUnits)&&(identical(other.sharedInvoiceBracketCount, sharedInvoiceBracketCount) || other.sharedInvoiceBracketCount == sharedInvoiceBracketCount)&&(identical(other.sharedDeliveryTeamCount, sharedDeliveryTeamCount) || other.sharedDeliveryTeamCount == sharedDeliveryTeamCount)&&(identical(other.sharedInvoiceDeliveryAmount, sharedInvoiceDeliveryAmount) || other.sharedInvoiceDeliveryAmount == sharedInvoiceDeliveryAmount)&&(identical(other.techSplitShare, techSplitShare) || other.techSplitShare == techSplitShare)&&(identical(other.techWindowShare, techWindowShare) || other.techWindowShare == techWindowShare)&&(identical(other.techFreestandingShare, techFreestandingShare) || other.techFreestandingShare == techFreestandingShare)&&(identical(other.techUninstallSplitShare, techUninstallSplitShare) || other.techUninstallSplitShare == techUninstallSplitShare)&&(identical(other.techUninstallWindowShare, techUninstallWindowShare) || other.techUninstallWindowShare == techUninstallWindowShare)&&(identical(other.techUninstallFreestandingShare, techUninstallFreestandingShare) || other.techUninstallFreestandingShare == techUninstallFreestandingShare)&&(identical(other.techBracketShare, techBracketShare) || other.techBracketShare == techBracketShare)&&(identical(other.charges, charges) || other.charges == charges)&&(identical(other.date, date) || other.date == date)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt)&&(identical(other.settlementRequestedAt, settlementRequestedAt) || other.settlementRequestedAt == settlementRequestedAt)&&(identical(other.settlementRespondedAt, settlementRespondedAt) || other.settlementRespondedAt == settlementRespondedAt)&&(identical(other.settlementPaidAt, settlementPaidAt) || other.settlementPaidAt == settlementPaidAt)&&(identical(other.settlementCorrectedAt, settlementCorrectedAt) || other.settlementCorrectedAt == settlementCorrectedAt)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.deletedAt, deletedAt) || other.deletedAt == deletedAt)&&(identical(other.editRequestedAt, editRequestedAt) || other.editRequestedAt == editRequestedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,techId,techName,companyId,companyName,invoiceNumber,clientName,clientContact,const DeepCollectionEquality().hash(_acUnits),status,expenses,expenseNote,adminNote,settlementStatus,settlementBatchId,settlementRound,settlementAmount,settlementPaymentMethod,settlementAdminNote,settlementTechnicianComment,settlementRequestedBy,const DeepCollectionEquality().hash(_importMeta),approvedBy,isSharedInstall,sharedInstallGroupKey,sharedInvoiceTotalUnits,sharedContributionUnits,sharedInvoiceSplitUnits,sharedInvoiceWindowUnits,sharedInvoiceFreestandingUnits,sharedInvoiceUninstallSplitUnits,sharedInvoiceUninstallWindowUnits,sharedInvoiceUninstallFreestandingUnits,sharedInvoiceBracketCount,sharedDeliveryTeamCount,sharedInvoiceDeliveryAmount,techSplitShare,techWindowShare,techFreestandingShare,techUninstallSplitShare,techUninstallWindowShare,techUninstallFreestandingShare,techBracketShare,charges,date,submittedAt,reviewedAt,settlementRequestedAt,settlementRespondedAt,settlementPaidAt,settlementCorrectedAt,isDeleted,deletedAt,editRequestedAt]);

@override
String toString() {
  return 'JobModel(id: $id, techId: $techId, techName: $techName, companyId: $companyId, companyName: $companyName, invoiceNumber: $invoiceNumber, clientName: $clientName, clientContact: $clientContact, acUnits: $acUnits, status: $status, expenses: $expenses, expenseNote: $expenseNote, adminNote: $adminNote, settlementStatus: $settlementStatus, settlementBatchId: $settlementBatchId, settlementRound: $settlementRound, settlementAmount: $settlementAmount, settlementPaymentMethod: $settlementPaymentMethod, settlementAdminNote: $settlementAdminNote, settlementTechnicianComment: $settlementTechnicianComment, settlementRequestedBy: $settlementRequestedBy, importMeta: $importMeta, approvedBy: $approvedBy, isSharedInstall: $isSharedInstall, sharedInstallGroupKey: $sharedInstallGroupKey, sharedInvoiceTotalUnits: $sharedInvoiceTotalUnits, sharedContributionUnits: $sharedContributionUnits, sharedInvoiceSplitUnits: $sharedInvoiceSplitUnits, sharedInvoiceWindowUnits: $sharedInvoiceWindowUnits, sharedInvoiceFreestandingUnits: $sharedInvoiceFreestandingUnits, sharedInvoiceUninstallSplitUnits: $sharedInvoiceUninstallSplitUnits, sharedInvoiceUninstallWindowUnits: $sharedInvoiceUninstallWindowUnits, sharedInvoiceUninstallFreestandingUnits: $sharedInvoiceUninstallFreestandingUnits, sharedInvoiceBracketCount: $sharedInvoiceBracketCount, sharedDeliveryTeamCount: $sharedDeliveryTeamCount, sharedInvoiceDeliveryAmount: $sharedInvoiceDeliveryAmount, techSplitShare: $techSplitShare, techWindowShare: $techWindowShare, techFreestandingShare: $techFreestandingShare, techUninstallSplitShare: $techUninstallSplitShare, techUninstallWindowShare: $techUninstallWindowShare, techUninstallFreestandingShare: $techUninstallFreestandingShare, techBracketShare: $techBracketShare, charges: $charges, date: $date, submittedAt: $submittedAt, reviewedAt: $reviewedAt, settlementRequestedAt: $settlementRequestedAt, settlementRespondedAt: $settlementRespondedAt, settlementPaidAt: $settlementPaidAt, settlementCorrectedAt: $settlementCorrectedAt, isDeleted: $isDeleted, deletedAt: $deletedAt, editRequestedAt: $editRequestedAt)';
}


}

/// @nodoc
abstract mixin class _$JobModelCopyWith<$Res> implements $JobModelCopyWith<$Res> {
  factory _$JobModelCopyWith(_JobModel value, $Res Function(_JobModel) _then) = __$JobModelCopyWithImpl;
@override @useResult
$Res call({
 String id, String techId, String techName, String companyId, String companyName, String invoiceNumber, String clientName, String clientContact, List<AcUnit> acUnits, JobStatus status, double expenses, String expenseNote, String adminNote, JobSettlementStatus settlementStatus, String settlementBatchId, int settlementRound, double settlementAmount, String settlementPaymentMethod, String settlementAdminNote, String settlementTechnicianComment, String settlementRequestedBy, Map<String, dynamic> importMeta, String? approvedBy, bool isSharedInstall, String sharedInstallGroupKey, int sharedInvoiceTotalUnits, int sharedContributionUnits, int sharedInvoiceSplitUnits, int sharedInvoiceWindowUnits, int sharedInvoiceFreestandingUnits, int sharedInvoiceUninstallSplitUnits, int sharedInvoiceUninstallWindowUnits, int sharedInvoiceUninstallFreestandingUnits, int sharedInvoiceBracketCount, int sharedDeliveryTeamCount, double sharedInvoiceDeliveryAmount, int techSplitShare, int techWindowShare, int techFreestandingShare, int techUninstallSplitShare, int techUninstallWindowShare, int techUninstallFreestandingShare, int techBracketShare, InvoiceCharges? charges,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? date,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? submittedAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? reviewedAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? settlementRequestedAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? settlementRespondedAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? settlementPaidAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? settlementCorrectedAt,@JsonKey(defaultValue: false) bool isDeleted,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? deletedAt,@JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson) DateTime? editRequestedAt
});


@override $InvoiceChargesCopyWith<$Res>? get charges;

}
/// @nodoc
class __$JobModelCopyWithImpl<$Res>
    implements _$JobModelCopyWith<$Res> {
  __$JobModelCopyWithImpl(this._self, this._then);

  final _JobModel _self;
  final $Res Function(_JobModel) _then;

/// Create a copy of JobModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? techId = null,Object? techName = null,Object? companyId = null,Object? companyName = null,Object? invoiceNumber = null,Object? clientName = null,Object? clientContact = null,Object? acUnits = null,Object? status = null,Object? expenses = null,Object? expenseNote = null,Object? adminNote = null,Object? settlementStatus = null,Object? settlementBatchId = null,Object? settlementRound = null,Object? settlementAmount = null,Object? settlementPaymentMethod = null,Object? settlementAdminNote = null,Object? settlementTechnicianComment = null,Object? settlementRequestedBy = null,Object? importMeta = null,Object? approvedBy = freezed,Object? isSharedInstall = null,Object? sharedInstallGroupKey = null,Object? sharedInvoiceTotalUnits = null,Object? sharedContributionUnits = null,Object? sharedInvoiceSplitUnits = null,Object? sharedInvoiceWindowUnits = null,Object? sharedInvoiceFreestandingUnits = null,Object? sharedInvoiceUninstallSplitUnits = null,Object? sharedInvoiceUninstallWindowUnits = null,Object? sharedInvoiceUninstallFreestandingUnits = null,Object? sharedInvoiceBracketCount = null,Object? sharedDeliveryTeamCount = null,Object? sharedInvoiceDeliveryAmount = null,Object? techSplitShare = null,Object? techWindowShare = null,Object? techFreestandingShare = null,Object? techUninstallSplitShare = null,Object? techUninstallWindowShare = null,Object? techUninstallFreestandingShare = null,Object? techBracketShare = null,Object? charges = freezed,Object? date = freezed,Object? submittedAt = freezed,Object? reviewedAt = freezed,Object? settlementRequestedAt = freezed,Object? settlementRespondedAt = freezed,Object? settlementPaidAt = freezed,Object? settlementCorrectedAt = freezed,Object? isDeleted = null,Object? deletedAt = freezed,Object? editRequestedAt = freezed,}) {
  return _then(_JobModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,techId: null == techId ? _self.techId : techId // ignore: cast_nullable_to_non_nullable
as String,techName: null == techName ? _self.techName : techName // ignore: cast_nullable_to_non_nullable
as String,companyId: null == companyId ? _self.companyId : companyId // ignore: cast_nullable_to_non_nullable
as String,companyName: null == companyName ? _self.companyName : companyName // ignore: cast_nullable_to_non_nullable
as String,invoiceNumber: null == invoiceNumber ? _self.invoiceNumber : invoiceNumber // ignore: cast_nullable_to_non_nullable
as String,clientName: null == clientName ? _self.clientName : clientName // ignore: cast_nullable_to_non_nullable
as String,clientContact: null == clientContact ? _self.clientContact : clientContact // ignore: cast_nullable_to_non_nullable
as String,acUnits: null == acUnits ? _self._acUnits : acUnits // ignore: cast_nullable_to_non_nullable
as List<AcUnit>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as JobStatus,expenses: null == expenses ? _self.expenses : expenses // ignore: cast_nullable_to_non_nullable
as double,expenseNote: null == expenseNote ? _self.expenseNote : expenseNote // ignore: cast_nullable_to_non_nullable
as String,adminNote: null == adminNote ? _self.adminNote : adminNote // ignore: cast_nullable_to_non_nullable
as String,settlementStatus: null == settlementStatus ? _self.settlementStatus : settlementStatus // ignore: cast_nullable_to_non_nullable
as JobSettlementStatus,settlementBatchId: null == settlementBatchId ? _self.settlementBatchId : settlementBatchId // ignore: cast_nullable_to_non_nullable
as String,settlementRound: null == settlementRound ? _self.settlementRound : settlementRound // ignore: cast_nullable_to_non_nullable
as int,settlementAmount: null == settlementAmount ? _self.settlementAmount : settlementAmount // ignore: cast_nullable_to_non_nullable
as double,settlementPaymentMethod: null == settlementPaymentMethod ? _self.settlementPaymentMethod : settlementPaymentMethod // ignore: cast_nullable_to_non_nullable
as String,settlementAdminNote: null == settlementAdminNote ? _self.settlementAdminNote : settlementAdminNote // ignore: cast_nullable_to_non_nullable
as String,settlementTechnicianComment: null == settlementTechnicianComment ? _self.settlementTechnicianComment : settlementTechnicianComment // ignore: cast_nullable_to_non_nullable
as String,settlementRequestedBy: null == settlementRequestedBy ? _self.settlementRequestedBy : settlementRequestedBy // ignore: cast_nullable_to_non_nullable
as String,importMeta: null == importMeta ? _self._importMeta : importMeta // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,approvedBy: freezed == approvedBy ? _self.approvedBy : approvedBy // ignore: cast_nullable_to_non_nullable
as String?,isSharedInstall: null == isSharedInstall ? _self.isSharedInstall : isSharedInstall // ignore: cast_nullable_to_non_nullable
as bool,sharedInstallGroupKey: null == sharedInstallGroupKey ? _self.sharedInstallGroupKey : sharedInstallGroupKey // ignore: cast_nullable_to_non_nullable
as String,sharedInvoiceTotalUnits: null == sharedInvoiceTotalUnits ? _self.sharedInvoiceTotalUnits : sharedInvoiceTotalUnits // ignore: cast_nullable_to_non_nullable
as int,sharedContributionUnits: null == sharedContributionUnits ? _self.sharedContributionUnits : sharedContributionUnits // ignore: cast_nullable_to_non_nullable
as int,sharedInvoiceSplitUnits: null == sharedInvoiceSplitUnits ? _self.sharedInvoiceSplitUnits : sharedInvoiceSplitUnits // ignore: cast_nullable_to_non_nullable
as int,sharedInvoiceWindowUnits: null == sharedInvoiceWindowUnits ? _self.sharedInvoiceWindowUnits : sharedInvoiceWindowUnits // ignore: cast_nullable_to_non_nullable
as int,sharedInvoiceFreestandingUnits: null == sharedInvoiceFreestandingUnits ? _self.sharedInvoiceFreestandingUnits : sharedInvoiceFreestandingUnits // ignore: cast_nullable_to_non_nullable
as int,sharedInvoiceUninstallSplitUnits: null == sharedInvoiceUninstallSplitUnits ? _self.sharedInvoiceUninstallSplitUnits : sharedInvoiceUninstallSplitUnits // ignore: cast_nullable_to_non_nullable
as int,sharedInvoiceUninstallWindowUnits: null == sharedInvoiceUninstallWindowUnits ? _self.sharedInvoiceUninstallWindowUnits : sharedInvoiceUninstallWindowUnits // ignore: cast_nullable_to_non_nullable
as int,sharedInvoiceUninstallFreestandingUnits: null == sharedInvoiceUninstallFreestandingUnits ? _self.sharedInvoiceUninstallFreestandingUnits : sharedInvoiceUninstallFreestandingUnits // ignore: cast_nullable_to_non_nullable
as int,sharedInvoiceBracketCount: null == sharedInvoiceBracketCount ? _self.sharedInvoiceBracketCount : sharedInvoiceBracketCount // ignore: cast_nullable_to_non_nullable
as int,sharedDeliveryTeamCount: null == sharedDeliveryTeamCount ? _self.sharedDeliveryTeamCount : sharedDeliveryTeamCount // ignore: cast_nullable_to_non_nullable
as int,sharedInvoiceDeliveryAmount: null == sharedInvoiceDeliveryAmount ? _self.sharedInvoiceDeliveryAmount : sharedInvoiceDeliveryAmount // ignore: cast_nullable_to_non_nullable
as double,techSplitShare: null == techSplitShare ? _self.techSplitShare : techSplitShare // ignore: cast_nullable_to_non_nullable
as int,techWindowShare: null == techWindowShare ? _self.techWindowShare : techWindowShare // ignore: cast_nullable_to_non_nullable
as int,techFreestandingShare: null == techFreestandingShare ? _self.techFreestandingShare : techFreestandingShare // ignore: cast_nullable_to_non_nullable
as int,techUninstallSplitShare: null == techUninstallSplitShare ? _self.techUninstallSplitShare : techUninstallSplitShare // ignore: cast_nullable_to_non_nullable
as int,techUninstallWindowShare: null == techUninstallWindowShare ? _self.techUninstallWindowShare : techUninstallWindowShare // ignore: cast_nullable_to_non_nullable
as int,techUninstallFreestandingShare: null == techUninstallFreestandingShare ? _self.techUninstallFreestandingShare : techUninstallFreestandingShare // ignore: cast_nullable_to_non_nullable
as int,techBracketShare: null == techBracketShare ? _self.techBracketShare : techBracketShare // ignore: cast_nullable_to_non_nullable
as int,charges: freezed == charges ? _self.charges : charges // ignore: cast_nullable_to_non_nullable
as InvoiceCharges?,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,settlementRequestedAt: freezed == settlementRequestedAt ? _self.settlementRequestedAt : settlementRequestedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,settlementRespondedAt: freezed == settlementRespondedAt ? _self.settlementRespondedAt : settlementRespondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,settlementPaidAt: freezed == settlementPaidAt ? _self.settlementPaidAt : settlementPaidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,settlementCorrectedAt: freezed == settlementCorrectedAt ? _self.settlementCorrectedAt : settlementCorrectedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,deletedAt: freezed == deletedAt ? _self.deletedAt : deletedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,editRequestedAt: freezed == editRequestedAt ? _self.editRequestedAt : editRequestedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of JobModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvoiceChargesCopyWith<$Res>? get charges {
    if (_self.charges == null) {
    return null;
  }

  return $InvoiceChargesCopyWith<$Res>(_self.charges!, (value) {
    return _then(_self.copyWith(charges: value));
  });
}
}

// dart format on
