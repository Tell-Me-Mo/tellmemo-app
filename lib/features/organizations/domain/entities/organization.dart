import 'package:equatable/equatable.dart';

class Organization extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final Map<String, dynamic> settings;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? memberCount;
  final String? currentUserRole;
  final String? currentUserId;
  final int? projectCount;
  final int? documentCount;

  const Organization({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    required this.settings,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount,
    this.currentUserRole,
    this.currentUserId,
    this.projectCount,
    this.documentCount,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        description,
        logoUrl,
        settings,
        isActive,
        createdBy,
        createdAt,
        updatedAt,
        memberCount,
        currentUserRole,
        currentUserId,
        projectCount,
        documentCount,
      ];
}