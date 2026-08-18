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
    // Read defensively: a partially-written profile doc must not throw, or the
    // user stream would error and the app would bounce a signed-in user back
    // to the login screen.
    return AppUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      groupId: data['groupId'] as String?,
    );
  }
}
