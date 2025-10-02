class ProjectMember {
  final String? id;
  final String projectId;
  final String name;
  final String email;
  final String role;
  final DateTime? addedAt;

  ProjectMember({
    this.id,
    required this.projectId,
    required this.name,
    required this.email,
    required this.role,
    this.addedAt,
  });

  ProjectMember copyWith({
    String? id,
    String? projectId,
    String? name,
    String? email,
    String? role,
    DateTime? addedAt,
  }) {
    return ProjectMember(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}