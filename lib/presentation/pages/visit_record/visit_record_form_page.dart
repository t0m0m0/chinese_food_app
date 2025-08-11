import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/error_message_helper.dart';
import '../../../domain/entities/store.dart';
import '../../../domain/usecases/add_visit_record_usecase.dart';

class VisitRecordFormPage extends StatefulWidget {
  final Store store;

  const VisitRecordFormPage({
    super.key,
    required this.store,
  });

  @override
  State<VisitRecordFormPage> createState() => _VisitRecordFormPageState();
}

class _VisitRecordFormPageState extends State<VisitRecordFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _menuController = TextEditingController();
  final _memoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _menuController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訪問記録の追加'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 店舗情報カード
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.store.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.store.address,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 訪問日時フィールド
              InkWell(
                key: const Key('date_selector'),
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '訪問日時',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    '${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day} ${_selectedDate.hour}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // メニューフィールド
              TextFormField(
                key: const Key('menu_field'),
                controller: _menuController,
                decoration: const InputDecoration(
                  labelText: 'メニュー *',
                  border: OutlineInputBorder(),
                  hintText: '例: チャーハン、餃子定食',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'メニューを入力してください。';
                  }
                  if (value.trim().length > 100) {
                    return 'メニューは100文字以内で入力してください。';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // メモフィールド
              TextFormField(
                key: const Key('memo_field'),
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: 'メモ・感想',
                  border: OutlineInputBorder(),
                  hintText: '味、雰囲気、感想などを記録できます',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value != null && value.trim().length > 500) {
                    return 'メモは500文字以内で入力してください。';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // 保存ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const Key('save_button'),
                  onPressed: _isLoading ? null : _saveVisitRecord,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          '保存',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveVisitRecord() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final addVisitRecordUsecase = Provider.of<AddVisitRecordUsecase>(
        context,
        listen: false,
      );

      await addVisitRecordUsecase.call(
        storeId: widget.store.id,
        visitedAt: _selectedDate,
        menu: _menuController.text.trim(),
        memo: _memoController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('訪問記録を保存しました'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        // 具体的なエラーメッセージを取得
        final errorMessage =
            ErrorMessageHelper.getVisitRecordErrorFromException(e);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4), // 少し長めに表示
          ),
        );

        // デバッグ用のログ出力
        debugPrint('Visit record save error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
