/// User roles in the application
enum UserRole {
  trainer('trainer'),
  client('client');

  final String value;

  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.client,
    );
  }
}
