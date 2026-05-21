import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/recurring_transaction_model.dart';
import '../../../models/transaction_model.dart';
import '../../../controllers/recurring_transaction_controller.dart';
import '../services/transaction_service.dart';
import 'add_recurring_transaction_screen.dart';
import 'transaction_history_screen.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key});

  @override
  State<RecurringTransactionsScreen> createState() => _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  final RecurringTransactionController _controller = RecurringTransactionController();
  final TransactionService _transactionService = TransactionService();
  
  final Color momoPink = const Color(0xFFB2006A);
  final Color momoLightPink = const Color(0xFFFFE0F1);
  final Color momoHeader = const Color(0xFFFDF2F8);

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: momoHeader,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Giao dịch định kỳ',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'), // Placeholder avatar
            ),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm dịch vụ...',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<RecurringTransactionModel>>(
        stream: _controller.getRecurringTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          var transactions = snapshot.data ?? [];
          
          if (_searchQuery.isNotEmpty) {
            transactions = transactions.where((tx) {
              final searchStr = _searchQuery.toLowerCase();
              return tx.name.toLowerCase().contains(searchStr);
            }).toList();
          }
          
          double totalAmount = 0;
          for (var tx in transactions) {
            totalAmount += tx.amount;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: momoLightPink.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TỔNG TIỀN THÁNG NÀY',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${NumberFormat('#,###').format(totalAmount)}đ',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: momoPink.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${transactions.length} Hóa đơn',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: momoPink),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.event, size: 16, color: Colors.black54),
                          const SizedBox(width: 8),
                          Text(
                            transactions.isNotEmpty 
                              ? 'Hạn kế tiếp: ${DateFormat('dd/MM/yyyy').format(transactions.first.nextDueDate)}'
                              : 'Chưa có lịch hẹn',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bills List
                const Text(
                  'HÓA ĐƠN CẦN THANH TOÁN',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                
                if (transactions.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có giao dịch định kỳ nào',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                else
                  ...transactions.map((tx) => _buildBillItem(tx)),

                const SizedBox(height: 32),

                // History section mock
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Lịch sử giao dịch',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
                              );
                            },
                            child: Text(
                              'Xem tất cả',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: momoPink),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<TransactionModel>>(
                        future: _transactionService.getRecentTransactionsGlobal(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Chưa có giao dịch nào gần đây.', style: TextStyle(color: Colors.grey)),
                            );
                          }

                          return Column(
                            children: snapshot.data!.map((tx) {
                              final isIncome = tx.type == 'income';
                              final sign = isIncome ? '+' : '-';
                              final amountStr = '$sign${NumberFormat('#,###').format(tx.amount)}đ';
                              final dateStr = DateFormat('dd/MM/yyyy • HH:mm').format(tx.createdAt);
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildHistoryItem(
                                  tx.note.isNotEmpty ? tx.note : tx.category, 
                                  dateStr, 
                                  amountStr,
                                  isIncome: isIncome,
                                ),
                              );
                            }).toList(),
                          );
                        }
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80), // Padding for FAB
              ],
            ),
          );
        }
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddRecurringTransactionScreen()),
          );
        },
        backgroundColor: momoPink,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thiết lập hóa đơn mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBillItem(RecurringTransactionModel tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.yellow.shade50, // Static color for now
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bolt, color: Colors.yellow.shade700), // Static icon for now
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tx.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: momoPink.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Chờ thanh toán',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: momoPink),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tần suất: ${tx.frequency}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${NumberFormat('#,###').format(tx.amount)}đ',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Hạn: ${DateFormat('dd MMM').format(tx.nextDueDate)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, String time, String amount, {bool isIncome = false}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_circle, color: isIncome ? Colors.green : Colors.red, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 2),
              Text(time, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
        Text(amount, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}
