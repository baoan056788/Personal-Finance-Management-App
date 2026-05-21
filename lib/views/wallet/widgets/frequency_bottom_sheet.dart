import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FrequencyBottomSheet extends StatefulWidget {
  final String initialFrequency;
  final DateTime? initialEndDate;

  const FrequencyBottomSheet({
    super.key,
    required this.initialFrequency,
    this.initialEndDate,
  });

  @override
  State<FrequencyBottomSheet> createState() => _FrequencyBottomSheetState();
}

class _FrequencyBottomSheetState extends State<FrequencyBottomSheet> {
  late String _selectedFrequency;
  DateTime? _selectedEndDate;

  final List<String> _frequencies = [
    'Không lặp lại',
    'Hằng ngày',
    'Hằng tuần',
    'Hằng tháng',
    'Hằng năm'
  ];

  final Color momoPink = const Color(0xFFD82D8B);

  @override
  void initState() {
    super.initState();
    _selectedFrequency = widget.initialFrequency;
    // Map old values if any
    if (_selectedFrequency == 'Hàng ngày') _selectedFrequency = 'Hằng ngày';
    if (_selectedFrequency == 'Hàng tuần') _selectedFrequency = 'Hằng tuần';
    if (_selectedFrequency == 'Hàng tháng') _selectedFrequency = 'Hằng tháng';
    if (_selectedFrequency == 'Hàng năm') _selectedFrequency = 'Hằng năm';
    
    if (!_frequencies.contains(_selectedFrequency)) {
      _selectedFrequency = 'Không lặp lại';
    }
    
    _selectedEndDate = widget.initialEndDate;
  }

  Future<void> _pickEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: momoPink,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 24), // Placeholder for balance
                const Text(
                  'Tần suất lặp lại',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tần suất', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  
                  // Radio list
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: _frequencies.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final String freq = entry.value;
                        final bool isSelected = _selectedFrequency == freq;
                        
                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedFrequency = freq;
                                  if (freq == 'Không lặp lại') {
                                    _selectedEndDate = null;
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: isSelected ? BoxDecoration(
                                  color: const Color(0xFFFFF0F6), // momoLightPink
                                  border: Border.all(color: momoPink.withValues(alpha: 0.5)),
                                  borderRadius: BorderRadius.circular(8),
                                ) : null,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      freq,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isSelected ? Colors.black87 : Colors.black87,
                                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                      ),
                                    ),
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? momoPink : Colors.grey.shade400,
                                          width: isSelected ? 6 : 2,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            if (index < _frequencies.length - 1)
                              const Divider(height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  if (_selectedFrequency != 'Không lặp lại') ...[
                    const Text('Ngày kết thúc', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickEndDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedEndDate == null 
                                ? 'Không bao giờ' 
                                : DateFormat('dd/MM/yyyy', 'vi_VN').format(_selectedEndDate!),
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Bottom button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'frequency': _selectedFrequency,
                    'endDate': _selectedEndDate,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: momoPink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Lưu cài đặt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
