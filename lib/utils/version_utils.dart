class VersionUtils {
  static bool isVersionGreaterThan(String currentVersion, String minVersion) {
    if (currentVersion == minVersion) return true;

    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> minimum = minVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (current[i] > minimum[i]) return true;
      if (current[i] < minimum[i]) return false;
    }

    return true;
  }
}
