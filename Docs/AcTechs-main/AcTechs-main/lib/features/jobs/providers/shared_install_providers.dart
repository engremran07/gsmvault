import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ac_techs/core/constants/app_constants.dart';
import 'package:ac_techs/core/models/models.dart';
import 'package:ac_techs/features/auth/providers/auth_providers.dart';

/// Stream of shared_install_aggregates where the current user is a team member.
///
/// Uses the [teamMemberIds] arrayContains index — see firestore.indexes.json.
/// Legacy aggregates (no teamMemberIds field) are NOT returned by this query;
/// they will only appear in the admin view via a full-collection scan.
final pendingSharedInstallAggregatesProvider =
    StreamProvider.autoDispose<List<SharedInstallAggregate>>((ref) {
      final user = ref.watch(currentUserProvider).value;
      if (user == null) return Stream.value([]);

      return FirebaseFirestore.instance
          .collection(AppConstants.sharedInstallAggregatesCollection)
          .where('teamMemberIds', arrayContains: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map(SharedInstallAggregate.fromFirestore)
                // Hide aggregates where all unit types have been fully consumed
                // by the team. Once consumed == invoiceTotals for every field,
                // there is nothing left for any team member to contribute.
                .where((agg) => !agg.isFullyConsumed)
                .toList(),
          );
    });
