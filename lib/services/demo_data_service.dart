import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DemoDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedDemoDataForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Bạn cần đăng nhập trước khi tạo dữ liệu demo.');
    }

    final uid = user.uid;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final categories = <String, _DemoCategory>{
      'food': _DemoCategory('Ăn uống', 'expense', 'e532', 'FFF44336'),
      'transport': _DemoCategory('Di chuyển', 'expense', 'e531', 'FF2196F3'),
      'shopping': _DemoCategory('Mua sắm', 'expense', 'e8cc', 'FFFF9800'),
      'bills': _DemoCategory('Hóa đơn', 'expense', 'e8b0', 'FF9C27B0'),
      'health': _DemoCategory('Sức khỏe', 'expense', 'e87d', 'FF00BCD4'),
      'education': _DemoCategory('Học tập', 'expense', 'e80c', 'FF3F51B5'),
      'entertainment': _DemoCategory('Giải trí', 'expense', 'e01d', 'FFE91E63'),
      'saving': _DemoCategory('Tiết kiệm', 'expense', 'e890', 'FF4CAF50'),
      'salary': _DemoCategory('Lương', 'income', 'e53d', 'FF4CAF50'),
      'bonus': _DemoCategory('Thưởng', 'income', 'e838', 'FFFFC107'),
      'freelance': _DemoCategory('Freelance', 'income', 'e8f9', 'FF009688'),
      'interest': _DemoCategory('Lãi tiết kiệm', 'income', 'e263', 'FF607D8B'),
    };

    final categoryIds = <String, String>{};
    for (final entry in categories.entries) {
      categoryIds[entry.key] = await _getOrCreateCategory(
        uid: uid,
        fallbackId: 'demo_cat_${entry.key}',
        category: entry.value,
      );
    }

    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(uid);
    batch.set(userRef, {
      'fullName': 'Nguyễn Minh Anh',
      'email': user.email ?? 'demo@finance.app',
      'birthday': Timestamp.fromDate(DateTime(1997, 6, 18)),
      'phoneNumber': user.phoneNumber ?? '0901234567',
      'avatarUrl': 'https://i.pravatar.cc/150?img=47',
      'onboardingCompleted': true,
      'demoDataSeededAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final walletsRef = userRef.collection('wallets');
    final wallets = [
      _DemoWallet('demo_wallet_cash', 'Ví tiền mặt', 'Cash', 4850000),
      _DemoWallet('demo_wallet_momo', 'MoMo cá nhân', 'E-Wallet', 2420000),
      _DemoWallet('demo_wallet_bank', 'Tài khoản ngân hàng', 'Bank', 38300000),
      _DemoWallet('demo_wallet_saving', 'Quỹ tiết kiệm', 'Savings', 14000000),
    ];

    for (final wallet in wallets) {
      batch.set(walletsRef.doc(wallet.id), {
        'id': wallet.id,
        'name': wallet.name,
        'type': wallet.type,
        'balance': wallet.balance,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 90))),
        'isDemo': true,
      }, SetOptions(merge: true));
    }

    void addTx({
      required String walletId,
      required String id,
      required double amount,
      required String type,
      required String categoryKey,
      required String note,
      required DateTime createdAt,
      bool isRecurring = false,
    }) {
      final category = categories[categoryKey]!;
      batch.set(
        walletsRef.doc(walletId).collection('transactions').doc(id),
        {
          'id': id,
          'amount': amount,
          'type': type,
          'category': category.name,
          'categoryId': categoryIds[categoryKey],
          'note': note,
          'createdAt': Timestamp.fromDate(createdAt),
          'isRecurring': isRecurring,
          'walletId': walletId,
          'isDemo': true,
        },
        SetOptions(merge: true),
      );
    }

    addTx(
      walletId: 'demo_wallet_bank',
      id: 'demo_tx_salary',
      amount: 32000000,
      type: 'income',
      categoryKey: 'salary',
      note: 'Lương tháng này',
      createdAt: _day(now, 1, 9),
    );
    addTx(
      walletId: 'demo_wallet_bank',
      id: 'demo_tx_freelance',
      amount: 8500000,
      type: 'income',
      categoryKey: 'freelance',
      note: 'Dự án thiết kế dashboard',
      createdAt: _day(now, 5, 20),
    );
    addTx(
      walletId: 'demo_wallet_saving',
      id: 'demo_tx_interest',
      amount: 450000,
      type: 'income',
      categoryKey: 'interest',
      note: 'Lãi tiết kiệm kỳ hạn',
      createdAt: _day(now, 8, 8),
    );
    addTx(
      walletId: 'demo_wallet_momo',
      id: 'demo_tx_bonus',
      amount: 2500000,
      type: 'income',
      categoryKey: 'bonus',
      note: 'Thưởng hoàn thành KPI',
      createdAt: _day(now, 12, 18),
    );

    addTx(
      walletId: 'demo_wallet_cash',
      id: 'demo_tx_food_1',
      amount: 185000,
      type: 'expense',
      categoryKey: 'food',
      note: 'Cà phê gặp khách hàng',
      createdAt: _day(now, 2, 8),
    );
    addTx(
      walletId: 'demo_wallet_cash',
      id: 'demo_tx_food_2',
      amount: 320000,
      type: 'expense',
      categoryKey: 'food',
      note: 'Ăn tối gia đình',
      createdAt: _day(now, 6, 19),
    );
    addTx(
      walletId: 'demo_wallet_momo',
      id: 'demo_tx_food_3',
      amount: 740000,
      type: 'expense',
      categoryKey: 'food',
      note: 'Đi siêu thị cuối tuần',
      createdAt: _day(now, 9, 16),
    );
    addTx(
      walletId: 'demo_wallet_cash',
      id: 'demo_tx_food_4',
      amount: 2600000,
      type: 'expense',
      categoryKey: 'food',
      note: 'Tiệc sinh nhật bạn thân',
      createdAt: _day(now, 14, 20),
    );
    addTx(
      walletId: 'demo_wallet_momo',
      id: 'demo_tx_transport_1',
      amount: 420000,
      type: 'expense',
      categoryKey: 'transport',
      note: 'Grab đi làm',
      createdAt: _day(now, 3, 7),
    );
    addTx(
      walletId: 'demo_wallet_cash',
      id: 'demo_tx_transport_2',
      amount: 1000000,
      type: 'expense',
      categoryKey: 'transport',
      note: 'Bảo dưỡng xe máy',
      createdAt: _day(now, 11, 10),
    );
    addTx(
      walletId: 'demo_wallet_bank',
      id: 'demo_tx_shopping_1',
      amount: 3150000,
      type: 'expense',
      categoryKey: 'shopping',
      note: 'Mua áo sơ mi và giày',
      createdAt: _day(now, 7, 15),
    );
    addTx(
      walletId: 'demo_wallet_momo',
      id: 'demo_tx_shopping_2',
      amount: 1100000,
      type: 'expense',
      categoryKey: 'shopping',
      note: 'Phụ kiện điện thoại',
      createdAt: _day(now, 13, 21),
    );
    addTx(
      walletId: 'demo_wallet_bank',
      id: 'demo_tx_bills_1',
      amount: 1200000,
      type: 'expense',
      categoryKey: 'bills',
      note: 'Tiền điện nước',
      createdAt: _day(now, 4, 10),
      isRecurring: true,
    );
    addTx(
      walletId: 'demo_wallet_bank',
      id: 'demo_tx_bills_2',
      amount: 950000,
      type: 'expense',
      categoryKey: 'bills',
      note: 'Internet và điện thoại',
      createdAt: _day(now, 10, 11),
      isRecurring: true,
    );
    addTx(
      walletId: 'demo_wallet_bank',
      id: 'demo_tx_bills_3',
      amount: 500000,
      type: 'expense',
      categoryKey: 'bills',
      note: 'Netflix, Spotify',
      createdAt: _day(now, 15, 8),
      isRecurring: true,
    );
    addTx(
      walletId: 'demo_wallet_momo',
      id: 'demo_tx_health',
      amount: 680000,
      type: 'expense',
      categoryKey: 'health',
      note: 'Khám sức khỏe định kỳ',
      createdAt: _day(now, 16, 9),
    );
    addTx(
      walletId: 'demo_wallet_bank',
      id: 'demo_tx_education',
      amount: 2400000,
      type: 'expense',
      categoryKey: 'education',
      note: 'Khóa học tiếng Anh',
      createdAt: _day(now, 18, 20),
    );
    addTx(
      walletId: 'demo_wallet_cash',
      id: 'demo_tx_entertainment',
      amount: 560000,
      type: 'expense',
      categoryKey: 'entertainment',
      note: 'Xem phim cuối tuần',
      createdAt: _day(now, 20, 19),
    );
    addTx(
      walletId: 'demo_wallet_bank',
      id: 'demo_tx_goal_vacation_1',
      amount: 12000000,
      type: 'expense',
      categoryKey: 'saving',
      note: 'Góp mục tiêu: Du lịch Đà Nẵng',
      createdAt: _day(now, 21, 9),
    );
    addTx(
      walletId: 'demo_wallet_momo',
      id: 'demo_tx_goal_vacation_2',
      amount: 9500000,
      type: 'expense',
      categoryKey: 'saving',
      note: 'Góp mục tiêu: Du lịch Đà Nẵng',
      createdAt: _day(now, 22, 9),
    );
    addTx(
      walletId: 'demo_wallet_bank',
      id: 'demo_tx_goal_laptop',
      amount: 10000000,
      type: 'expense',
      categoryKey: 'saving',
      note: 'Góp mục tiêu: MacBook làm việc',
      createdAt: _day(now, 23, 9),
    );
    addTx(
      walletId: 'demo_wallet_saving',
      id: 'demo_tx_goal_course',
      amount: 8000000,
      type: 'expense',
      categoryKey: 'saving',
      note: 'Góp mục tiêu: Khóa học nâng cao',
      createdAt: _day(now, 24, 9),
    );

    batch.set(
      walletsRef
          .doc('demo_wallet_bank')
          .collection('transactions')
          .doc('demo_tx_transfer_out'),
      {
        'id': 'demo_tx_transfer_out',
        'amount': 3000000,
        'type': 'transfer',
        'category': 'Chuyển tiền',
        'note': 'Đến: Quỹ tiết kiệm - Chuyển sang quỹ dự phòng',
        'createdAt': Timestamp.fromDate(_day(now, 25, 10)),
        'walletId': 'demo_wallet_bank',
        'isDemo': true,
      },
      SetOptions(merge: true),
    );
    batch.set(
      walletsRef
          .doc('demo_wallet_saving')
          .collection('transactions')
          .doc('demo_tx_transfer_in'),
      {
        'id': 'demo_tx_transfer_in',
        'amount': 3000000,
        'type': 'transfer',
        'category': 'Nhận tiền',
        'note': 'Từ: Tài khoản ngân hàng - Chuyển sang quỹ dự phòng',
        'createdAt': Timestamp.fromDate(_day(now, 25, 10)),
        'walletId': 'demo_wallet_saving',
        'isDemo': true,
      },
      SetOptions(merge: true),
    );

    void addBudget(
      String id,
      String categoryKey,
      String name,
      double limit,
      double spent,
      String status,
      String note,
    ) {
      batch.set(_firestore.collection('budgets').doc(id), {
        'id': id,
        'userId': uid,
        'categoryId': categoryIds[categoryKey],
        'walletId': null,
        'name': name,
        'limitAmount': limit,
        'spentAmount': spent,
        'remainAmount': limit - spent,
        'progressPercent': limit > 0 ? spent / limit : 0,
        'startDate': Timestamp.fromDate(monthStart),
        'endDate': Timestamp.fromDate(monthEnd),
        'periodType': 'MONTHLY',
        'note': note,
        'status': status,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 20))),
        'updatedAt': Timestamp.fromDate(now),
        'isDemo': true,
      }, SetOptions(merge: true));
    }

    addBudget(
      'demo_budget_food',
      'food',
      'Ăn uống trong tháng',
      5000000,
      3845000,
      'SAFE',
      'Giữ mức chi ăn uống hợp lý.',
    );
    addBudget(
      'demo_budget_transport',
      'transport',
      'Di chuyển',
      1500000,
      1420000,
      'DANGER',
      'Gần chạm ngưỡng, nên hạn chế gọi xe.',
    );
    addBudget(
      'demo_budget_shopping',
      'shopping',
      'Mua sắm cá nhân',
      4000000,
      4250000,
      'OVER_LIMIT',
      'Đã vượt hạn mức để demo cảnh báo.',
    );
    addBudget(
      'demo_budget_bills',
      'bills',
      'Hóa đơn cố định',
      3000000,
      2650000,
      'WARNING',
      'Theo dõi các khoản thanh toán định kỳ.',
    );
    addBudget(
      'demo_budget_education',
      'education',
      'Đầu tư học tập',
      6000000,
      2400000,
      'SAFE',
      'Ngân sách cho khóa học và sách.',
    );

    void addGoal(
      String id,
      String name,
      double target,
      double current,
      DateTime targetDate,
      String colorHex,
      String iconCode,
      String status,
      String note,
    ) {
      batch.set(_firestore.collection('goals').doc(id), {
        'userId': uid,
        'name': name,
        'targetAmount': target,
        'currentAmount': current,
        'remainAmount': target - current < 0 ? 0 : target - current,
        'progressPercent': target > 0 ? current / target : 0,
        'targetDate': Timestamp.fromDate(targetDate),
        'note': note,
        'colorHex': colorHex,
        'iconCode': iconCode,
        'status': status,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 45))),
        'updatedAt': Timestamp.fromDate(now),
        'isDemo': true,
      }, SetOptions(merge: true));
    }

    addGoal(
      'demo_goal_vacation',
      'Du lịch Đà Nẵng',
      25000000,
      21500000,
      now.add(const Duration(days: 70)),
      'FF2196F3',
      'e55b',
      'NEAR_TARGET',
      'Gói nghỉ dưỡng 4 ngày 3 đêm cho gia đình.',
    );
    addGoal(
      'demo_goal_laptop',
      'MacBook làm việc',
      30000000,
      10000000,
      now.add(const Duration(days: 120)),
      'FF9C27B0',
      'e31e',
      'ON_GOING',
      'Nâng cấp thiết bị làm việc cá nhân.',
    );
    addGoal(
      'demo_goal_course',
      'Khóa học nâng cao',
      8000000,
      8000000,
      now.add(const Duration(days: 30)),
      'FF4CAF50',
      'e80c',
      'COMPLETED',
      'Đã đủ tiền đăng ký khóa học.',
    );
    addGoal(
      'demo_goal_emergency',
      'Quỹ dự phòng 6 tháng',
      20000000,
      4000000,
      now.subtract(const Duration(days: 10)),
      'FFFF9800',
      'e8b2',
      'FAILED',
      'Mục tiêu quá hạn để demo trạng thái thất bại.',
    );

    void addContribution(
      String id,
      String goalId,
      String walletId,
      String transactionId,
      double amount,
      String note,
      DateTime createdAt,
    ) {
      batch.set(
        _firestore.collection('goal_contributions').doc(id),
        {
          'goalId': goalId,
          'walletId': walletId,
          'transactionId': transactionId,
          'amount': amount,
          'note': note,
          'createdAt': Timestamp.fromDate(createdAt),
          'isDemo': true,
        },
        SetOptions(merge: true),
      );
    }

    addContribution(
      'demo_contribution_vacation_1',
      'demo_goal_vacation',
      'demo_wallet_bank',
      'demo_tx_goal_vacation_1',
      12000000,
      'Đợt 1 từ lương',
      _day(now, 21, 9),
    );
    addContribution(
      'demo_contribution_vacation_2',
      'demo_goal_vacation',
      'demo_wallet_momo',
      'demo_tx_goal_vacation_2',
      9500000,
      'Đợt 2 từ thưởng',
      _day(now, 22, 9),
    );
    addContribution(
      'demo_contribution_laptop',
      'demo_goal_laptop',
      'demo_wallet_bank',
      'demo_tx_goal_laptop',
      10000000,
      'Góp lần đầu',
      _day(now, 23, 9),
    );
    addContribution(
      'demo_contribution_course',
      'demo_goal_course',
      'demo_wallet_saving',
      'demo_tx_goal_course',
      8000000,
      'Hoàn tất mục tiêu',
      _day(now, 24, 9),
    );
    addContribution(
      'demo_contribution_emergency',
      'demo_goal_emergency',
      'demo_wallet_saving',
      'demo_tx_transfer_in',
      4000000,
      'Dự phòng ban đầu',
      now.subtract(const Duration(days: 35)),
    );

    void addRecurring(
      String id,
      String name,
      double amount,
      String type,
      String categoryKey,
      String walletId,
      String frequency,
      DateTime nextDueDate,
      DateTime? endDate,
    ) {
      batch.set(
        _firestore.collection('recurring_transactions').doc(id),
        {
          'id': id,
          'userId': uid,
          'name': name,
          'amount': amount,
          'type': type,
          'categoryId': categoryIds[categoryKey],
          'walletId': walletId,
          'frequency': frequency,
          'nextDueDate': Timestamp.fromDate(nextDueDate),
          'createdAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 35)),
          ),
          if (endDate != null) 'endDate': Timestamp.fromDate(endDate),
          'isDemo': true,
        },
        SetOptions(merge: true),
      );
    }

    addRecurring(
      'demo_recurring_rent',
      'Tiền thuê nhà',
      8000000,
      'expense',
      'bills',
      'demo_wallet_bank',
      'Hằng tháng',
      now.subtract(const Duration(days: 1)),
      null,
    );
    addRecurring(
      'demo_recurring_internet',
      'Internet gia đình',
      350000,
      'expense',
      'bills',
      'demo_wallet_bank',
      'Hằng tháng',
      now.add(const Duration(days: 2)),
      null,
    );
    addRecurring(
      'demo_recurring_gym',
      'Gói tập gym',
      250000,
      'expense',
      'health',
      'demo_wallet_momo',
      'Hằng tuần',
      now.add(const Duration(days: 3)),
      now.add(const Duration(days: 120)),
    );
    addRecurring(
      'demo_recurring_salary',
      'Lương công ty',
      32000000,
      'income',
      'salary',
      'demo_wallet_bank',
      'Hằng tháng',
      now.add(const Duration(days: 20)),
      null,
    );
    addRecurring(
      'demo_recurring_insurance',
      'Bảo hiểm sức khỏe',
      4500000,
      'expense',
      'health',
      'demo_wallet_bank',
      'Hằng năm',
      now.add(const Duration(days: 60)),
      null,
    );

    void addDebt(
      String id,
      String type,
      String personName,
      double amount,
      double paidAmount,
      DateTime dueDate,
      String note,
    ) {
      final remain = amount - paidAmount;
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
      final daysLeft = due.difference(today).inDays;
      String status = 'OPEN';
      if (remain <= 0) {
        status = 'PAID';
      } else if (daysLeft < 0) {
        status = 'OVERDUE';
      } else if (daysLeft <= 3) {
        status = 'DUE_SOON';
      }

      batch.set(_firestore.collection('debts').doc(id), {
        'id': id,
        'userId': uid,
        'type': type,
        'personName': personName,
        'amount': amount,
        'paidAmount': paidAmount,
        'dueDate': Timestamp.fromDate(dueDate),
        'note': note,
        'status': status,
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 15))),
        'updatedAt': Timestamp.fromDate(now),
        'isDemo': true,
      }, SetOptions(merge: true));
    }

    addDebt(
      'demo_debt_borrowed',
      'borrowed',
      'Chị Linh',
      5000000,
      2000000,
      now.add(const Duration(days: 2)),
      'Vay tạm đóng học phí, còn 3 triệu.',
    );
    addDebt(
      'demo_debt_lent',
      'lent',
      'Anh Huy',
      3500000,
      0,
      now.subtract(const Duration(days: 1)),
      'Cho vay sửa xe, đã quá hạn để demo nhắc nhở.',
    );
    addDebt(
      'demo_debt_paid',
      'lent',
      'Bạn Mai',
      1200000,
      1200000,
      now.subtract(const Duration(days: 5)),
      'Khoản đã tất toán.',
    );

    await batch.commit();
  }

  Future<String> _getOrCreateCategory({
    required String uid,
    required String fallbackId,
    required _DemoCategory category,
  }) async {
    final snapshot = await _firestore
        .collection('categories')
        .where('userId', isEqualTo: uid)
        .where('type', isEqualTo: category.type)
        .where('name', isEqualTo: category.name)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id;
    }

    await _firestore.collection('categories').doc(fallbackId).set({
      'id': fallbackId,
      'userId': uid,
      'name': category.name,
      'type': category.type,
      'iconCode': category.iconCode,
      'colorHex': category.colorHex,
      'isDefault': true,
      'isDemo': true,
    }, SetOptions(merge: true));
    return fallbackId;
  }

  DateTime _day(DateTime now, int preferredDay, int hour) {
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final day = preferredDay.clamp(1, lastDay);
    return DateTime(now.year, now.month, day, hour);
  }
}

class _DemoCategory {
  final String name;
  final String type;
  final String iconCode;
  final String colorHex;

  const _DemoCategory(this.name, this.type, this.iconCode, this.colorHex);
}

class _DemoWallet {
  final String id;
  final String name;
  final String type;
  final double balance;

  const _DemoWallet(this.id, this.name, this.type, this.balance);
}
