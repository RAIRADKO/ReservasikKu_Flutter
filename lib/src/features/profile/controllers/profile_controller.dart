class ProfileFormState {
  final String name;
  final String phone;

  ProfileFormState({
    required this.name,
    required this.phone,
  });

  ProfileFormState copyWith({
    String? name,
    String? phone,
  }) {
    return ProfileFormState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
    );
  }
}