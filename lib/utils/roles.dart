/// Centralized account-role checks used by the authentication gate and UI.
const supportedAcademyRoles = <String>{'student', 'teacher', 'admin'};

bool isSupportedAcademyRole(Object? role) =>
    role is String && supportedAcademyRoles.contains(role);

bool canManageAcademyCourses(Object? role) =>
    role == 'teacher' || role == 'admin';
