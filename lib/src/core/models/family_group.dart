class FamilyGroup {
  final String id;
  final String createdBy; // uid of the user who created the group
  final String inviteCode;

  FamilyGroup({
    required this.id,
    required this.createdBy,
    required this.inviteCode,
  });
}
