import 'package:flutter/material.dart';

import '../../../models/app_config_model.dart';
import '../../../services/admin_service.dart';
import '../../../utils/currency_input_formatter.dart';

class AdminAppConfigTab extends StatefulWidget {
  const AdminAppConfigTab({super.key});

  @override
  State<AdminAppConfigTab> createState() => _AdminAppConfigTabState();
}

class _AdminAppConfigTabState extends State<AdminAppConfigTab> {
  final AdminService _service = AdminService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppConfigModel>(
      stream: _service.watchAppConfig(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Không thể tải cấu hình: ${snapshot.error}'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return _AppConfigForm(
          key: ValueKey(snapshot.data!.updatedAt?.millisecondsSinceEpoch),
          service: _service,
          initialConfig: snapshot.data!,
        );
      },
    );
  }
}

class _AppConfigForm extends StatefulWidget {
  final AdminService service;
  final AppConfigModel initialConfig;

  const _AppConfigForm({
    super.key,
    required this.service,
    required this.initialConfig,
  });

  @override
  State<_AppConfigForm> createState() => _AppConfigFormState();
}

class _AppConfigFormState extends State<_AppConfigForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _appNameController;
  late final TextEditingController _supportEmailController;
  late final TextEditingController _supportPhoneController;
  late final TextEditingController _maxAmountController;
  late bool _maintenanceMode;
  late bool _registrationEnabled;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig;
    _appNameController = TextEditingController(text: config.appName);
    _supportEmailController = TextEditingController(text: config.supportEmail);
    _supportPhoneController = TextEditingController(text: config.supportPhone);
    _maxAmountController = TextEditingController(
      text: formatCurrencyInput(config.maxTransactionAmount),
    );
    _maintenanceMode = config.maintenanceMode;
    _registrationEnabled = config.registrationEnabled;
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _supportEmailController.dispose();
    _supportPhoneController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final maxAmount = parseCurrencyInput(_maxAmountController.text)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    try {
      await widget.service.saveAppConfig(
        AppConfigModel(
          appName: _appNameController.text.trim(),
          supportEmail: _supportEmailController.text.trim(),
          supportPhone: _supportPhoneController.text.trim(),
          maxTransactionAmount: maxAmount,
          maintenanceMode: _maintenanceMode,
          registrationEnabled: _registrationEnabled,
        ),
      );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Đã lưu cấu hình ứng dụng thành công.')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Không thể lưu cấu hình: $error'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle(icon: Icons.tune, title: 'Thông tin chung'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _appNameController,
            maxLength: 40,
            decoration: const InputDecoration(
              labelText: 'Tên ứng dụng',
              border: OutlineInputBorder(),
            ),
            validator: (value) => (value?.trim().length ?? 0) < 2
                ? 'Tên ứng dụng phải có ít nhất 2 ký tự'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _maxAmountController,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Hạn mức mỗi giao dịch',
              suffixText: 'đ',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final amount = parseCurrencyInput(value ?? '');
              if (amount == null || amount <= 0) {
                return 'Hạn mức phải lớn hơn 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            icon: Icons.support_agent,
            title: 'Thông tin hỗ trợ',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _supportEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email hỗ trợ',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final email = value?.trim() ?? '';
              return email.contains('@') ? null : 'Email không hợp lệ';
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _supportPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Số điện thoại hỗ trợ',
              border: OutlineInputBorder(),
            ),
            validator: (value) => (value?.trim().length ?? 0) < 5
                ? 'Số điện thoại không hợp lệ'
                : null,
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Kiểm soát hệ thống',
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _maintenanceMode,
            title: const Text('Chế độ bảo trì'),
            subtitle: const Text(
              'Người dùng thường sẽ thấy màn hình bảo trì; Admin vẫn truy cập được.',
            ),
            onChanged: (value) => setState(() => _maintenanceMode = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _registrationEnabled,
            title: const Text('Cho phép đăng ký tài khoản mới'),
            subtitle: const Text(
              'Áp dụng cho đăng ký email và lần đăng nhập Google đầu tiên.',
            ),
            onChanged: (value) => setState(() => _registrationEnabled = value),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Lưu cấu hình'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color(0xFFB02A76),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFB02A76)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
