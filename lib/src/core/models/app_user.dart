class AppUser {
  final String uid;
  final String email;
  final String displayName;
  final String? groupId;

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.groupId,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] as String,
      displayName: data['displayName'] as String,
      groupId: data['groupId'] as String?,
    );
  }
}
