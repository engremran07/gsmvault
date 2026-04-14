// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ac_install_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AcInstallModel _$AcInstallModelFromJson(Map<String, dynamic> json) =>
    _AcInstallModel(
      id: json['id'] as String? ?? '',
      techId: json['techId'] as String,
      techName: json['techName'] as String,
      splitTotal: (json['splitTotal'] as num?)?.toInt() ?? 0,
      splitShare: (json['splitShare'] as num?)?.toInt() ?? 0,
      windowTotal: (json['windowTotal'] as num?)?.toInt() ?? 0,
      windowShare: (json['windowShare'] as num?)?.toInt() ?? 0,
      freestandingTotal: (json['freestandingTotal'] as num?)?.toInt() ?? 0,
      freestandingShare: (json['freestandingShare'] as num?)?.toInt() ?? 0,
      note: json['note'] as String? ?? '',
      status:
          $enumDecodeNullable(_$AcInstallStatusEnumMap, json['status']) ??
          AcInstallStatus.pending,
      approvedBy: json['approvedBy'] as String? ?? '',
      adminNote: json['adminNote'] as String? ?? '',
      date: _timestampFromJson(json['date']),
      createdAt: _timestampFromJson(json['createdAt']),
      reviewedAt: _timestampFromJson(json['reviewedAt']),
      isDeleted: json['isDeleted'] as bool? ?? false,
      deletedAt: _timestampFromJson(json['deletedAt']),
    );

Map<String, dynamic> _$AcInstallModelToJson(_AcInstallModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'techId': instance.techId,
      'techName': instance.techName,
      'splitTotal': instance.splitTotal,
      'splitShare': instance.splitShare,
      'windowTotal': instance.windowTotal,
      'windowShare': instance.windowShare,
      'freestandingTotal': instance.freestandingTotal,
      'freestandingShare': instance.freestandingShare,
      'note': instance.note,
      'status': _$AcInstallStatusEnumMap[instance.status]!,
      'approvedBy': instance.approvedBy,
      'adminNote': instance.adminNote,
      'date': _timestampToJson(instance.date),
      'createdAt': _timestampToJson(instance.createdAt),
      'reviewedAt': _timestampToJson(instance.reviewedAt),
      'isDeleted': instance.isDeleted,
      'deletedAt': _timestampToJson(instance.deletedAt),
    };

const _$AcInstallStatusEnumMap = {
  AcInstallStatus.pending: 'pending',
  AcInstallStatus.approved: 'approved',
  AcInstallStatus.rejected: 'rejected',
};
