import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/supabase_provider.dart';
import '../../data/datasources/client_remote_datasource.dart';
import '../../data/repositories/client_repository_impl.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/repositories/client_repository.dart';
import '../../domain/usecases/create_client_usecase.dart';
import '../../domain/usecases/delete_client_usecase.dart';
import '../../domain/usecases/get_client_usecase.dart';
import '../../domain/usecases/get_clients_usecase.dart';
import '../../domain/usecases/update_client_usecase.dart';

// Data source provider
final clientRemoteDataSourceProvider = Provider<ClientRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ClientRemoteDataSourceImpl(client);
});

// Repository provider
final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  final remoteDataSource = ref.watch(clientRemoteDataSourceProvider);
  return ClientRepositoryImpl(remoteDataSource);
});

// Use case providers
final getClientsUseCaseProvider = Provider<GetClientsUseCase>((ref) {
  return GetClientsUseCase(ref.watch(clientRepositoryProvider));
});

final getClientUseCaseProvider = Provider<GetClientUseCase>((ref) {
  return GetClientUseCase(ref.watch(clientRepositoryProvider));
});

final createClientUseCaseProvider = Provider<CreateClientUseCase>((ref) {
  return CreateClientUseCase(ref.watch(clientRepositoryProvider));
});

final updateClientUseCaseProvider = Provider<UpdateClientUseCase>((ref) {
  return UpdateClientUseCase(ref.watch(clientRepositoryProvider));
});

final deleteClientUseCaseProvider = Provider<DeleteClientUseCase>((ref) {
  return DeleteClientUseCase(ref.watch(clientRepositoryProvider));
});

// Clients list provider (auto-refreshes)
final clientsProvider = FutureProvider.autoDispose<List<ClientEntity>>((ref) async {
  final useCase = ref.watch(getClientsUseCaseProvider);
  final result = await useCase();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (clients) => clients,
  );
});

// Single client provider
final clientProvider = FutureProvider.autoDispose.family<ClientEntity, String>((ref, id) async {
  final useCase = ref.watch(getClientUseCaseProvider);
  final result = await useCase(id);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (client) => client,
  );
});

// Client state for mutations
enum ClientMutationStatus { initial, loading, success, error }

class ClientMutationState {
  final ClientMutationStatus status;
  final String? errorMessage;
  final ClientEntity? client;

  const ClientMutationState({
    this.status = ClientMutationStatus.initial,
    this.errorMessage,
    this.client,
  });

  bool get isLoading => status == ClientMutationStatus.loading;
  bool get isSuccess => status == ClientMutationStatus.success;
  bool get hasError => status == ClientMutationStatus.error;

  ClientMutationState copyWith({
    ClientMutationStatus? status,
    String? errorMessage,
    ClientEntity? client,
  }) {
    return ClientMutationState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      client: client ?? this.client,
    );
  }
}

// Client mutation notifier for create/update/delete
class ClientMutationNotifier extends StateNotifier<ClientMutationState> {
  final CreateClientUseCase _createUseCase;
  final UpdateClientUseCase _updateUseCase;
  final DeleteClientUseCase _deleteUseCase;
  final Ref _ref;

  ClientMutationNotifier({
    required CreateClientUseCase createUseCase,
    required UpdateClientUseCase updateUseCase,
    required DeleteClientUseCase deleteUseCase,
    required Ref ref,
  })  : _createUseCase = createUseCase,
        _updateUseCase = updateUseCase,
        _deleteUseCase = deleteUseCase,
        _ref = ref,
        super(const ClientMutationState());

  Future<bool> createClient(CreateClientParams params) async {
    state = state.copyWith(status: ClientMutationStatus.loading);

    final result = await _createUseCase(params);

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: ClientMutationStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (client) {
        state = state.copyWith(
          status: ClientMutationStatus.success,
          client: client,
        );
        _ref.invalidate(clientsProvider);
        return true;
      },
    );
  }

  Future<bool> updateClient(ClientEntity client) async {
    state = state.copyWith(status: ClientMutationStatus.loading);

    final result = await _updateUseCase(client);

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: ClientMutationStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (updated) {
        state = state.copyWith(
          status: ClientMutationStatus.success,
          client: updated,
        );
        _ref.invalidate(clientsProvider);
        _ref.invalidate(clientProvider(client.id));
        return true;
      },
    );
  }

  Future<bool> deleteClient(String id) async {
    state = state.copyWith(status: ClientMutationStatus.loading);

    final result = await _deleteUseCase(id);

    return result.fold(
      (failure) {
        state = state.copyWith(
          status: ClientMutationStatus.error,
          errorMessage: failure.message,
        );
        return false;
      },
      (_) {
        state = state.copyWith(status: ClientMutationStatus.success);
        _ref.invalidate(clientsProvider);
        return true;
      },
    );
  }

  void reset() {
    state = const ClientMutationState();
  }
}

// Client mutation provider
final clientMutationProvider =
    StateNotifierProvider.autoDispose<ClientMutationNotifier, ClientMutationState>((ref) {
  return ClientMutationNotifier(
    createUseCase: ref.watch(createClientUseCaseProvider),
    updateUseCase: ref.watch(updateClientUseCaseProvider),
    deleteUseCase: ref.watch(deleteClientUseCaseProvider),
    ref: ref,
  );
});

// Search query provider
final clientSearchQueryProvider = StateProvider<String>((ref) => '');

// Selected client provider for master-detail layout (tablet/desktop)
// Stores the currently selected client ID in the master list
final selectedClientIdProvider = StateProvider<String?>((ref) => null);

// Master panel collapsed state for tablet/desktop master-detail layout
final masterPanelCollapsedProvider = StateProvider<bool>((ref) => false);

// Selected client entity provider (derived from selectedClientIdProvider)
final selectedClientProvider = Provider.autoDispose<AsyncValue<ClientEntity?>>((ref) {
  final selectedId = ref.watch(selectedClientIdProvider);
  if (selectedId == null) {
    return const AsyncValue.data(null);
  }
  return ref.watch(clientProvider(selectedId)).whenData((client) => client);
});

// Filtered clients provider
final filteredClientsProvider = Provider.autoDispose<AsyncValue<List<ClientEntity>>>((ref) {
  final clientsAsync = ref.watch(clientsProvider);
  final query = ref.watch(clientSearchQueryProvider).toLowerCase();

  return clientsAsync.when(
    data: (clients) {
      if (query.isEmpty) {
        return AsyncValue.data(clients);
      }
      final filtered = clients
          .where((c) => c.name.toLowerCase().contains(query))
          .toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
