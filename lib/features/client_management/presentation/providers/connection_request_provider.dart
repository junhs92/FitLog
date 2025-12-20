import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/connection_request_datasource.dart';
import '../../domain/entities/connection_request_entity.dart';

/// Provider for data source
final _connectionRequestDataSourceProvider = Provider<ConnectionRequestDataSource>((ref) {
  return ConnectionRequestDataSource(Supabase.instance.client);
});

/// Search results for available clients
class ClientSearchResult {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool hasPendingRequest;

  const ClientSearchResult({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.hasPendingRequest = false,
  });

  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }
}

/// State for connection request operations
class ConnectionRequestState {
  final bool isLoading;
  final String? error;
  final List<ClientSearchResult> searchResults;
  final List<ConnectionRequestEntity> pendingRequests;
  final List<ConnectionRequestEntity> sentRequests;

  const ConnectionRequestState({
    this.isLoading = false,
    this.error,
    this.searchResults = const [],
    this.pendingRequests = const [],
    this.sentRequests = const [],
  });

  ConnectionRequestState copyWith({
    bool? isLoading,
    String? error,
    List<ClientSearchResult>? searchResults,
    List<ConnectionRequestEntity>? pendingRequests,
    List<ConnectionRequestEntity>? sentRequests,
  }) {
    return ConnectionRequestState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchResults: searchResults ?? this.searchResults,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      sentRequests: sentRequests ?? this.sentRequests,
    );
  }
}

/// Notifier for connection request operations
class ConnectionRequestNotifier extends StateNotifier<ConnectionRequestState> {
  final ConnectionRequestDataSource _dataSource;

  ConnectionRequestNotifier(this._dataSource) : super(const ConnectionRequestState());

  /// Load all available clients (trainer only)
  Future<void> loadAvailableClients() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await _dataSource.searchAvailableClients('');
      final clientResults = results.map((json) => ClientSearchResult(
        id: json['id'] as String,
        name: json['full_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        hasPendingRequest: json['has_pending_request'] as bool? ?? false,
      )).toList();

      state = state.copyWith(
        isLoading: false,
        searchResults: clientResults,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        searchResults: [],
      );
    }
  }

  /// Search for available clients (trainer only)
  Future<void> searchClients(String query) async {
    if (query.trim().isEmpty) {
      // Load all clients if query is empty
      await loadAvailableClients();
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await _dataSource.searchAvailableClients(query);
      final clientResults = results.map((json) => ClientSearchResult(
        id: json['id'] as String,
        name: json['full_name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String?,
        hasPendingRequest: json['has_pending_request'] as bool? ?? false,
      )).toList();

      state = state.copyWith(
        isLoading: false,
        searchResults: clientResults,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Send connection request to client (trainer only)
  Future<bool> sendRequest(String clientId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _dataSource.sendRequest(clientId);

      // Update the client in search results to show pending status
      final updatedResults = state.searchResults.map((c) {
        if (c.id == clientId) {
          return ClientSearchResult(
            id: c.id,
            name: c.name,
            email: c.email,
            avatarUrl: c.avatarUrl,
            hasPendingRequest: true,
          );
        }
        return c;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        searchResults: updatedResults,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Load pending requests for client
  Future<void> loadPendingRequests() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final requests = await _dataSource.getPendingRequestsForClient();
      state = state.copyWith(
        isLoading: false,
        pendingRequests: requests,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load sent requests for trainer
  Future<void> loadSentRequests() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final requests = await _dataSource.getSentRequestsByTrainer();
      state = state.copyWith(
        isLoading: false,
        sentRequests: requests,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Accept a connection request (client only)
  Future<bool> acceptRequest(String requestId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _dataSource.acceptRequest(requestId);

      // Remove from pending requests
      state = state.copyWith(
        isLoading: false,
        pendingRequests: state.pendingRequests.where((r) => r.id != requestId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Reject a connection request (client only)
  Future<bool> rejectRequest(String requestId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _dataSource.rejectRequest(requestId);

      // Remove from pending requests
      state = state.copyWith(
        isLoading: false,
        pendingRequests: state.pendingRequests.where((r) => r.id != requestId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Cancel a pending request (trainer only)
  Future<bool> cancelRequest(String requestId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _dataSource.cancelRequest(requestId);

      // Remove from sent requests
      state = state.copyWith(
        isLoading: false,
        sentRequests: state.sentRequests.where((r) => r.id != requestId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Cancel a pending request by client ID (trainer only)
  Future<bool> cancelRequestByClientId(String clientId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _dataSource.cancelRequestByClientId(clientId);

      // Update the client in search results to remove pending status
      final updatedResults = state.searchResults.map((c) {
        if (c.id == clientId) {
          return ClientSearchResult(
            id: c.id,
            name: c.name,
            email: c.email,
            avatarUrl: c.avatarUrl,
            hasPendingRequest: false,
          );
        }
        return c;
      }).toList();

      state = state.copyWith(
        isLoading: false,
        searchResults: updatedResults,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void clearSearch() {
    state = state.copyWith(searchResults: []);
  }
}

/// Provider for connection request state
final connectionRequestProvider =
    StateNotifierProvider<ConnectionRequestNotifier, ConnectionRequestState>((ref) {
  return ConnectionRequestNotifier(ref.read(_connectionRequestDataSourceProvider));
});

/// Provider for pending requests count (for badges/indicators)
final pendingRequestsCountProvider = FutureProvider<int>((ref) async {
  final dataSource = ref.read(_connectionRequestDataSourceProvider);
  try {
    final requests = await dataSource.getPendingRequestsForClient();
    return requests.length;
  } catch (_) {
    return 0;
  }
});
