import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_finance_management_app/views/auth/widgets/custom_text_field.dart';

void main() {
  testWidgets('name field preserves Vietnamese IME text', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomTextField(
            label: 'Họ tên',
            hint: 'Nhập họ và tên',
            controller: controller,
            prefixIcon: Icons.person_outline,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pump();

    const name = 'Phạm Văn Tú';
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: name,
        selection: TextSelection.collapsed(offset: name.length),
        composing: TextRange(start: 9, end: 11),
      ),
    );
    await tester.pump();

    expect(controller.text, name);
    expect(find.text(name), findsOneWidget);
  });
}
