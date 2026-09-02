import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ezba_provider.dart';
import '../models/member.dart';

class ManageMembersDialog extends StatefulWidget {
  const ManageMembersDialog({super.key});

  @override
  State<ManageMembersDialog> createState() => _ManageMembersDialogState();
}

class _ManageMembersDialogState extends State<ManageMembersDialog> {
  final TextEditingController _nameController = TextEditingController();
  bool _isHouseFund = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EzbaProvider>();
    final members = provider.members;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.people_outline, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'إدارة أعضاء العزبة والحصص',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),

            // Add new member section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'اسم العضو الجديد...',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) => _addMember(provider),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _addMember(provider),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('إضافة'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'حساب البيت / الصندوق المشترك (مثل "البيت")',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _isHouseFund,
                    onChanged: (val) {
                      setState(() {
                        _isHouseFund = val ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Members List
            const Text(
              'الأعضاء الحاليون:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),

            Expanded(
              child: ListView.separated(
                itemCount: members.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: member.isHouseFund
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFDBEAFE),
                      child: Icon(
                        member.isHouseFund ? Icons.home : Icons.person,
                        size: 18,
                        color: member.isHouseFund
                            ? const Color(0xFFD97706)
                            : const Color(0xFF2563EB),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (member.isHouseFund) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'صندوق مشترك',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'تعديل الاسم',
                          onPressed: () => _showEditMemberDialog(context, provider, member),
                        ),
                        if (members.length > 1)
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'حذف',
                            onPressed: () => _confirmDeleteMember(context, provider, member),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addMember(EzbaProvider provider) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    provider.addMember(name, isHouseFund: _isHouseFund);
    _nameController.clear();
    setState(() {
      _isHouseFund = false;
    });
  }

  void _showEditMemberDialog(
    BuildContext context,
    EzbaProvider provider,
    Member member,
  ) {
    final editCtrl = TextEditingController(text: member.name);
    bool isHouse = member.isHouseFund;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('تعديل العضو'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editCtrl,
                decoration: const InputDecoration(labelText: 'الاسم'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('حساب البيت / صندوق مشترك'),
                value: isHouse,
                onChanged: (val) {
                  setDialogState(() {
                    isHouse = val ?? false;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                if (editCtrl.text.trim().isNotEmpty) {
                  provider.editMember(
                    member.id,
                    editCtrl.text.trim(),
                    isHouseFund: isHouse,
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMember(
    BuildContext context,
    EzbaProvider provider,
    Member member,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف العضو'),
        content: Text(
          'هل أنت متأكد من حذف "${member.name}"؟ سيتم إعادة توزيع المصاريف على باقي الأعضاء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteMember(member.id);
              Navigator.pop(ctx);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
