import '../../../../shared/models/result.dart';
import '../entities/client_entity.dart';
import '../repositories/client_repository.dart';

/// Parameters for creating a client relationship
class CreateClientParams {
  final String name;
  final String? email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? height;
  final double? weight;
  final List<String> goals;
  final String? notes; // Trainer's private notes

  const CreateClientParams({
    required this.name,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.goals = const [],
    this.notes,
  });
}

/// Create a new client
class CreateClientUseCase {
  final ClientRepository _repository;

  const CreateClientUseCase(this._repository);

  Future<Result<ClientEntity>> call(CreateClientParams params) async {
    final client = ClientEntity(
      id: '', // Will be assigned by the database
      trainerId: '', // Will be assigned from current user
      name: params.name,
      email: params.email,
      phone: params.phone,
      dateOfBirth: params.dateOfBirth,
      gender: params.gender,
      height: params.height,
      weight: params.weight,
      goals: params.goals,
      notes: params.notes,
      createdAt: DateTime.now(),
    );

    return _repository.createClient(client);
  }
}
