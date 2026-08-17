class AvatarUtils {
  static String getCorrectedAvatarPath(String? legacyPath, [String fallback = 'assets/images/characters/human/human_student_1.png']) {
    if (legacyPath == null || legacyPath.isEmpty) {
      return fallback;
    }

    // If it's already using the new paths, return as is
    if (legacyPath.startsWith('assets/images/characters/')) {
      return legacyPath;
    }

    // Fix legacy paths
    if (legacyPath.startsWith('assets/images/mascots/')) {
      if (legacyPath.contains('human_')) {
        return legacyPath.replaceFirst(
            'assets/images/mascots/', 'assets/images/characters/human/');
      } else {
        return legacyPath.replaceFirst(
            'assets/images/mascots/', 'assets/images/characters/mascots/');
      }
    }

    // Fallback if it's some completely unknown path
    return legacyPath;
  }
}
