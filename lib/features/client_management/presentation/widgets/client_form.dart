import 'package:flutter/material.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/client_entity.dart';

/// Reusable client form widget for add/edit
class ClientForm extends StatefulWidget {
  final ClientEntity? initialClient;
  final bool isLoading;
  final void Function(ClientFormData) onSubmit;

  const ClientForm({
    this.initialClient,
    this.isLoading = false,
    required this.onSubmit,
    super.key,
  });

  @override
  State<ClientForm> createState() => _ClientFormState();
}

class _ClientFormState extends State<ClientForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _notesController;

  DateTime? _dateOfBirth;
  String? _gender;
  List<String> _selectedGoals = [];

  static const _genderOptions = ['Male', 'Female', 'Other'];
  static const _goalOptions = [
    'Weight Loss',
    'Muscle Gain',
    'General Fitness',
    'Strength',
    'Flexibility',
    'Endurance',
    'Rehabilitation',
    'Sports Performance',
  ];

  @override
  void initState() {
    super.initState();
    final client = widget.initialClient;
    _nameController = TextEditingController(text: client?.name ?? '');
    _emailController = TextEditingController(text: client?.email ?? '');
    _phoneController = TextEditingController(text: client?.phone ?? '');
    _heightController = TextEditingController(
      text: client?.height?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: client?.weight?.toString() ?? '',
    );
    _notesController = TextEditingController(text: client?.notes ?? '');
    _dateOfBirth = client?.dateOfBirth;
    _gender = client?.gender;
    _selectedGoals = List.from(client?.goals ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    widget.onSubmit(ClientFormData(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      height: double.tryParse(_heightController.text),
      weight: double.tryParse(_weightController.text),
      goals: _selectedGoals,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Name (required)
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name *',
              hintText: 'Enter client name',
              prefixIcon: Icon(Icons.person_outlined),
            ),
            textCapitalization: TextCapitalization.words,
            validator: Validators.name,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Email
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter email address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Phone
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone',
              hintText: 'Enter phone number',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Date of Birth
          _buildDatePicker(),
          const SizedBox(height: AppSpacing.lg),

          // Gender
          _buildGenderSelector(),
          const SizedBox(height: AppSpacing.lg),

          // Height & Weight row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    hintText: 'e.g., 175',
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'e.g., 70',
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Goals
          _buildGoalsSelector(),
          const SizedBox(height: AppSpacing.lg),

          // Notes (Trainer's private notes about this client)
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Additional notes about the client',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Submit button
          ElevatedButton(
            onPressed: widget.isLoading ? null : _handleSubmit,
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(widget.initialClient == null ? 'Add Client' : 'Save Changes'),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _dateOfBirth ?? DateTime(1990),
          firstDate: DateTime(1920),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _dateOfBirth = date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date of Birth',
          prefixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          _dateOfBirth != null
              ? '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}'
              : 'Select date',
          style: TextStyle(
            color: _dateOfBirth != null ? null : AppColors.neutral500,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gender',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.neutral700,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: _genderOptions.map((gender) {
            final isSelected = _gender == gender;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(gender),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _gender = selected ? gender : null);
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGoalsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fitness Goals',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _goalOptions.map((goal) {
            final isSelected = _selectedGoals.contains(goal);
            return FilterChip(
              label: Text(goal),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedGoals.add(goal);
                  } else {
                    _selectedGoals.remove(goal);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Form data class
class ClientFormData {
  final String name;
  final String? email;
  final String? phone;
  final DateTime? dateOfBirth;
  final String? gender;
  final double? height;
  final double? weight;
  final List<String> goals;
  final String? notes; // Trainer's private notes

  const ClientFormData({
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
