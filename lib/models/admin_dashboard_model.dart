class AdminDashboardModel {
  final int totalUsers;
  final int activeUsers;
  final int newUsersThisMonth;
  final List<MonthlyRegistrationModel> registrations;

  const AdminDashboardModel({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsersThisMonth,
    required this.registrations,
  });

  factory AdminDashboardModel.fromMap(Map<String, dynamic> map) {
    final rawRegistrations = map['registrations'];
    return AdminDashboardModel(
      totalUsers: (map['totalUsers'] as num?)?.toInt() ?? 0,
      activeUsers: (map['activeUsers'] as num?)?.toInt() ?? 0,
      newUsersThisMonth: (map['newUsersThisMonth'] as num?)?.toInt() ?? 0,
      registrations: rawRegistrations is List
          ? rawRegistrations
                .whereType<Map>()
                .map(
                  (item) => MonthlyRegistrationModel.fromMap(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

class MonthlyRegistrationModel {
  final String key;
  final String label;
  final int count;

  const MonthlyRegistrationModel({
    required this.key,
    required this.label,
    required this.count,
  });

  factory MonthlyRegistrationModel.fromMap(Map<String, dynamic> map) {
    return MonthlyRegistrationModel(
      key: map['key'] as String? ?? '',
      label: map['label'] as String? ?? '',
      count: (map['count'] as num?)?.toInt() ?? 0,
    );
  }
}
