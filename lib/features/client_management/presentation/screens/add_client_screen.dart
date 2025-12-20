import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/colors.dart';
import '../../domain/usecases/create_client_usecase.dart';
import '../providers/client_provider.dart';
import '../widgets/client_form.dart';

/// Screen for adding a new client
class AddClientScreen extends ConsumerWidget {
  const AddClientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutationState = ref.watch(clientMutationProvider);

    // Listen for success to navigate back
    ref.listen<ClientMutationState>(clientMutationProvider, (previous, next) {
      if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Failed to add client'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Client'),
      ),
      body: ClientForm(
        isLoading: mutationState.isLoading,
        onSubmit: (formData) async {
          await ref.read(clientMutationProvider.notifier).createClient(
                CreateClientParams(
                  name: formData.name,
                  email: formData.email,
                  phone: formData.phone,
                  dateOfBirth: formData.dateOfBirth,
                  gender: formData.gender,
                  height: formData.height,
                  weight: formData.weight,
                  goals: formData.goals,
                  notes: formData.notes,
                ),
              );
        },
      ),
    );
  }
}
