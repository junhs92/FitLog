import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/invite_remote_datasource.dart';
import '../../domain/entities/invite_entity.dart';

/// Provider for invite data source
final inviteDataSourceProvider = Provider<InviteRemoteDataSource>((ref) {
  return InviteRemoteDataSourceImpl(Supabase.instance.client);
});

/// Provider for listing trainer's pending invites
final pendingInvitesProvider = FutureProvider.autoDispose<List<InviteEntity>>((ref) async {
  final dataSource = ref.watch(inviteDataSourceProvider);
  return dataSource.listPendingInvites();
});

/// Provider for looking up an invite by code
final inviteByCodeProvider = FutureProvider.autoDispose.family<InviteEntity?, String>((ref, code) async {
  final dataSource = ref.watch(inviteDataSourceProvider);
  return dataSource.getInviteByCode(code);
});

/// Notifier for invite operations
class InviteNotifier extends StateNotifier<AsyncValue<InviteEntity?>> {
  final InviteRemoteDataSource _dataSource;
  final Ref _ref;

  InviteNotifier(this._dataSource, this._ref) : super(const AsyncValue.data(null));

  /// Create a new invite
  Future<InviteEntity?> createInvite({String? clientEmail}) async {
    state = const AsyncValue.loading();
    try {
      final invite = await _dataSource.createInvite(clientEmail: clientEmail);
      if (!mounted) return invite;
      state = AsyncValue.data(invite);
      // Invalidate pending invites list
      _ref.invalidate(pendingInvitesProvider);
      return invite;
    } catch (e, st) {
      if (!mounted) return null;
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Accept an invite (called by client)
  Future<bool> acceptInvite(String code) async {
    state = const AsyncValue.loading();
    try {
      await _dataSource.acceptInvite(code);
      if (!mounted) return true;
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      if (!mounted) return false;
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Cancel an invite (called by trainer)
  Future<bool> cancelInvite(String inviteId) async {
    try {
      await _dataSource.cancelInvite(inviteId);
      // Invalidate pending invites list
      _ref.invalidate(pendingInvitesProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Provider for invite operations
final inviteNotifierProvider = StateNotifierProvider.autoDispose<InviteNotifier, AsyncValue<InviteEntity?>>((ref) {
  final dataSource = ref.watch(inviteDataSourceProvider);
  return InviteNotifier(dataSource, ref);
});
