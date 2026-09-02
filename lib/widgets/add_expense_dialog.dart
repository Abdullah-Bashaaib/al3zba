import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ezba_provider.dart';
import '../models/expense_item.dart';

class AddExpenseDialog extends StatefulWidget {
  final ExpenseItem? itemToEdit;

  const AddExpenseDialog({super.key, this.itemToEdit});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  late TextEditingController _titleController;
  late TextEditingController _costController;
  late TextEditingController _notesController;

  late SplitType _splitType;
  late List<String> _includedMemberIds;
  late Map<String, TextEditingController> _customControllers;
  String? _paidByMemberId;

  final List<String> _commonSuggestions = [
    'الراشن',
    'الكهرباء',
    'الماء',
    'الغاز',
    'صيانة البيت',
    'خضار وفواكه',
    'دجاج ولحوم',
    'إنترنت',
    'منظفات',
    'أخرى',
  ];

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _titleController = TextEditingController(text: item?.title ?? '');
    _costController = TextEditingController(
      text: item != null && item.totalCost > 0
          ? item.totalCost.toStringAsFixed(0)
          : '',
    );
    _notesController = TextEditingController(text: item?.notes ?? '');
    _splitType = item?.splitType ?? SplitType.equalAll;
    _includedMemberIds = List.from(item?.includedMemberIds ?? []);
    _paidByMemberId = item?.paidByMemberId;

    _customControllers = {};
  }

  @override
  void dispose() {
    _titleController.dispose();
    _costController.dispose();
    _notesController.dispose();
    for (final c in _customControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initCustomControllers(EzbaProvider provider) {
    for (final m in provider.members) {
      if (!_customControllers.containsKey(m.id)) {
        final existingVal = widget.itemToEdit?.customShares[m.id];
        _customControllers[m.id] = TextEditingController(
          text: existingVal != null && existingVal > 0
              ? existingVal.toStringAsFixed(0)
              : '',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EzbaProvider>();
    final members = provider.members;
    final currency = provider.currency;
    final isEditing = widget.itemToEdit != null;

    _initCustomControllers(provider);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Icon(
                    isEditing ? Icons.edit_note : Icons.add_shopping_cart,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEditing ? 'تعديل بند المصروف' : 'إضافة بند مصروف جديد',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Suggestions Chips
                    if (!isEditing) ...[
                      const Text(
                        'بنود شائعة:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _commonSuggestions.map((suggestion) {
                          final isSelected =
                              _titleController.text.trim() == suggestion;
                          return ChoiceChip(
                            label: Text(suggestion),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _titleController.text = suggestion;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Title
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'اسم البند / المصروف *',
                        hintText: 'مثال: الراشن، فواتير الكهرباء...',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Cost
                    TextField(
                      controller: _costController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'المبلغ الإجمالي ($currency) *',
                        hintText: '0',
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Paid By
                    const Text(
                      'من قام بالدفع؟',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String?>(
                      value: _paidByMemberId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('الصندوق المشترك / لم يُحدد'),
                        ),
                        ...members.map((m) => DropdownMenuItem<String?>(
                              value: m.id,
                              child: Text(
                                '${m.name} ${m.isHouseFund ? '(حساب البيت)' : ''}',
                              ),
                            )),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _paidByMemberId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 18),

                    // Split Mode
                    const Text(
                      'طريقة تقسيم المبلغ:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),

                    SegmentedButton<SplitType>(
                      segments: const [
                        ButtonSegment(
                          value: SplitType.equalAll,
                          label: Text('بالتساوي'),
                          icon: Icon(Icons.group),
                        ),
                        ButtonSegment(
                          value: SplitType.equalSelected,
                          label: Text('محددون'),
                          icon: Icon(Icons.how_to_reg),
                        ),
                        ButtonSegment(
                          value: SplitType.customAmounts,
                          label: Text('مخصص'),
                          icon: Icon(Icons.tune),
                        ),
                      ],
                      selected: {_splitType},
                      onSelectionChanged: (set) {
                        setState(() {
                          _splitType = set.first;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Split Sub-options
                    if (_splitType == SplitType.equalSelected) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'حدد الأعضاء المشاركين في هذا البند:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...members.map((m) {
                              final isChecked =
                                  _includedMemberIds.isEmpty ||
                                  _includedMemberIds.contains(m.id);
                              return CheckboxListTile(
                                dense: true,
                                title: Text(m.name),
                                value: isChecked,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      if (!_includedMemberIds.contains(m.id)) {
                                        _includedMemberIds.add(m.id);
                                      }
                                    } else {
                                      // If all were selected before, populate explicitly first
                                      if (_includedMemberIds.isEmpty) {
                                        _includedMemberIds = members
                                            .map((mem) => mem.id)
                                            .toList();
                                      }
                                      _includedMemberIds.remove(m.id);
                                    }
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    ] else if (_splitType == SplitType.customAmounts) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'حدد مبلغ كل شخص:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...members.map((m) {
                              final ctrl = _customControllers[m.id]!;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        m.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: TextField(
                                        controller: ctrl,
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        decoration: InputDecoration(
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          suffixText: currency,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Notes
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        prefixIcon: Icon(Icons.notes),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 24),

            // Footer Actions
            Row(
              children: [
                if (isEditing)
                  IconButton.outlined(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'حذف البند',
                    onPressed: () {
                      provider.deleteExpenseItem(widget.itemToEdit!.id);
                      Navigator.pop(context);
                    },
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  child: Text(isEditing ? 'حفظ التعديلات' : 'إضافة البند'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم البند')),
      );
      return;
    }

    final totalCost = double.tryParse(_costController.text.trim()) ?? 0.0;

    Map<String, double> customShares = {};
    if (_splitType == SplitType.customAmounts) {
      for (final entry in _customControllers.entries) {
        final amt = double.tryParse(entry.value.text.trim()) ?? 0.0;
        if (amt > 0) {
          customShares[entry.key] = amt;
        }
      }
    }

    final provider = context.read<EzbaProvider>();
    final isEditing = widget.itemToEdit != null;

    final item = ExpenseItem(
      id: isEditing
          ? widget.itemToEdit!.id
          : 'item_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      totalCost: totalCost,
      splitType: _splitType,
      includedMemberIds: _splitType == SplitType.equalSelected
          ? _includedMemberIds
          : const [],
      customShares: customShares,
      paidByMemberId: _paidByMemberId,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      date: isEditing ? widget.itemToEdit!.date : DateTime.now(),
    );

    provider.saveExpenseItem(item);
    Navigator.pop(context);
  }
}
