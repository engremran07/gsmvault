// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'earning_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EarningModel _$EarningModelFromJson(Map<String, dynamic> json) =>
    _EarningModel(
      id: json['id'] as String? ?? '',
      techId: json['techId'] as String,
      techName: json['techName'] as String,
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String? ?? '',
      status:
          $enumDecodeNullable(_$EarningApprovalStatusEnumMap, json['status']) ??
          EarningApprovalStatus.pending,
      approvedBy: json['approvedBy'] as String? ?? '',
      adminNote: json['adminNote'] as String? ?? '',
      paymentType:
          $enumDecodeNullable(_$PaymentTypeEnumMap, json['paymentType']) ??
          PaymentType.regular,
      date: _timestampFromJson(json['date']),
      createdAt: _timestampFromJson(json['createdAt']),
      reviewedAt: _timestampFromJson(json['reviewedAt']),
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: _timestampFromJson(json['deletedAt']),
    );

Map<String, dynamic> _$EarningModelToJson(_EarningModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'techId': instance.techId,
      'techName': instance.techName,
      'category': instance.category,
      'amount': instance.amount,
      'note': instance.note,
      'status': _$EarningApprovalStatusEnumMap[instance.status]!,
      'approvedBy': instance.approvedBy,
      'adminNote': instance.adminNote,
      'paymentType': _$PaymentTypeEnumMap[instance.paymentType]!,
      'date': _timestampToJson(instance.date),
      'createdAt': _timestampToJson(instance.createdAt),
      'reviewedAt': _timestampToJson(instance.reviewedAt),
      'isDeleted': instance.isDeleted,
      'deletedAt': _timestampToJson(instance.deletedAt),
    };

const _$EarningApprovalStatusEnumMap = {
  EarningApprovalStatus.pending: 'pending',
  EarningApprovalStatus.approved: 'approved',
  EarningApprovalStatus.rejected: 'rejected',
};

const _$PaymentTypeEnumMap = {
  PaymentType.advance: 'advance',
  PaymentType.settlement: 'settlement',
  PaymentType.regular: 'regular',
};
