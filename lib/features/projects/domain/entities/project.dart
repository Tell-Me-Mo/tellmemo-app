enum ProjectStatus {
  active,
  archived,
}

class Project {
  final String id;
  final String name;
  final String? description;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProjectStatus status;
  final String? portfolioId;
  final String? programId;
  final int? memberCount;

  const Project({
    required this.id,
    required this.name,
    this.description,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.portfolioId,
    this.programId,
    this.memberCount,
  });

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProjectStatus? status,
    String? portfolioId,
    String? programId,
    int? memberCount,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      portfolioId: portfolioId ?? this.portfolioId,
      programId: programId ?? this.programId,
      memberCount: memberCount ?? this.memberCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Project && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Project{id: $id, name: $name, status: $status}';
  }
}