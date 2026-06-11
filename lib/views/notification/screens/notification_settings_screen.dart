import 'package:flutter/material.dart';

import '../../../services/notification_settings_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationSettingsService _service = NotificationSettingsService();
  NotificationSettings _settings = const NotificationSettings();
  bool _isLoading = true;
  bool _isSaving = false;

  Color get _mainColor => const Color(0xFFE0248A);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _service.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await _service.save(_settings);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu cài đặt thông báo.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lưu cài đặt: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Cài đặt thông báo',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _mainColor))
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        SwitchListTile(
                          value: _settings.enabled,
                          activeThumbColor: _mainColor,
                          secondary: Icon(
                            _settings.enabled
                                ? Icons.notifications_active_outlined
                                : Icons.notifications_off_outlined,
                            color: _settings.enabled
                                ? _mainColor
                                : Colors.black45,
                          ),
                          title: const Text(
                            'Thông báo trong ứng dụng',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            _settings.enabled
                                ? 'Hiển thị các khoản sắp đến hạn ở biểu tượng chuông'
                                : 'Tất cả nhắc nhở đang được tắt',
                          ),
                          onChanged: (value) {
                            setState(() {
                              _settings = _settings.copyWith(enabled: value);
                            });
                          },
                        ),
                        const Divider(height: 24),
                        const _SectionLabel('LOẠI NHẮC NHỞ'),
                        SwitchListTile(
                          value: _settings.debtReminders,
                          activeThumbColor: _mainColor,
                          secondary: const Icon(Icons.handshake_outlined),
                          title: const Text('Công nợ đến hạn'),
                          subtitle: const Text(
                            'Nhắc các khoản đi vay và cho vay sắp đến hạn',
                          ),
                          onChanged: _settings.enabled
                              ? (value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      debtReminders: value,
                                    );
                                  });
                                }
                              : null,
                        ),
                        SwitchListTile(
                          value: _settings.recurringReminders,
                          activeThumbColor: _mainColor,
                          secondary: const Icon(Icons.event_repeat_outlined),
                          title: const Text('Giao dịch định kỳ'),
                          subtitle: const Text(
                            'Nhắc hóa đơn và khoản thu chi định kỳ',
                          ),
                          onChanged: _settings.enabled
                              ? (value) {
                                  setState(() {
                                    _settings = _settings.copyWith(
                                      recurringReminders: value,
                                    );
                                  });
                                }
                              : null,
                        ),
                        const Divider(height: 24),
                        const _SectionLabel('THỜI GIAN NHẮC TRƯỚC'),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                          child: SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 1, label: Text('1 ngày')),
                              ButtonSegment(value: 3, label: Text('3 ngày')),
                              ButtonSegment(value: 7, label: Text('7 ngày')),
                            ],
                            selected: {_settings.advanceDays},
                            onSelectionChanged: _settings.enabled
                                ? (values) {
                                    setState(() {
                                      _settings = _settings.copyWith(
                                        advanceDays: values.first,
                                      );
                                    });
                                  }
                                : null,
                            style: ButtonStyle(
                              backgroundColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                return states.contains(WidgetState.selected)
                                    ? _mainColor.withValues(alpha: 0.12)
                                    : Colors.grey.shade50;
                              }),
                              foregroundColor: WidgetStateProperty.resolveWith((
                                states,
                              ) {
                                return states.contains(WidgetState.selected)
                                    ? _mainColor
                                    : Colors.black54;
                              }),
                              side: WidgetStatePropertyAll(
                                BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _mainColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Lưu cài đặt',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black45,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
