import 'package:flutter/foundation.dart';
import '../models/ezba_period.dart';
import '../models/expense_item.dart';
import '../models/member.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';

class EzbaProvider extends ChangeNotifier {
  final StorageService _storageService;

  List<EzbaPeriod> _periods = [];
  String _activePeriodId = '';

  EzbaProvider(this._storageService) {
    _loadData();
  }

  void _loadData() {
    _periods = _storageService.loadPeriods();
    final savedActiveId = _storageService.getActivePeriodId();
    if (savedActiveId != null && _periods.any((p) => p.id == savedActiveId)) {
      _activePeriodId = savedActiveId;
    } else if (_periods.isNotEmpty) {
      _activePeriodId = _periods.first.id;
    }
    notifyListeners();
  }

  List<EzbaPeriod> get periods => _periods;

  EzbaPeriod get activePeriod {
    return _periods.firstWhere(
      (p) => p.id == _activePeriodId,
      orElse: () {
        if (_periods.isEmpty) {
          final def = EzbaPeriod.createDefault();
          _periods.add(def);
          _activePeriodId = def.id;
          return def;
        }
        return _periods.first;
      },
    );
  }

  String get activePeriodId => _activePeriodId;

  // Active period shortcuts
  List<Member> get members => activePeriod.members;
  List<ExpenseItem> get items => activePeriod.items;
  double get totalExpenses => activePeriod.totalExpenses;
  String get currency => activePeriod.currency;

  Future<void> _save() async {
    await _storageService.savePeriods(_periods);
    await _storageService.saveActivePeriodId(_activePeriodId);
    notifyListeners();
  }

  // Set active period
  void setActivePeriod(String periodId) {
    if (_periods.any((p) => p.id == periodId)) {
      _activePeriodId = periodId;
      _save();
    }
  }

  // Create new period / month
  void createNewPeriod(String title, {String currency = 'YER'}) {
    // Copy existing members from current period
    final newMembers = members.map((m) => m.copyWith()).toList();

    final newPeriod = EzbaPeriod(
      id: 'period_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim().isEmpty ? 'حساب شهر جديد' : title.trim(),
      currency: currency,
      members: newMembers.isNotEmpty ? newMembers : EzbaPeriod.createDefault().members,
      items: const [],
      createdAt: DateTime.now(),
    );

    _periods.insert(0, newPeriod);
    _activePeriodId = newPeriod.id;
    _save();
  }

  // Rename period
  void updatePeriodTitle(String periodId, String newTitle) {
    final idx = _periods.indexWhere((p) => p.id == periodId);
    if (idx != -1) {
      _periods[idx] = _periods[idx].copyWith(title: newTitle);
      _save();
    }
  }

  // Delete period
  void deletePeriod(String periodId) {
    if (_periods.length <= 1) return; // Keep at least one
    _periods.removeWhere((p) => p.id == periodId);
    if (_activePeriodId == periodId) {
      _activePeriodId = _periods.first.id;
    }
    _save();
  }

  // Change currency
  void updateCurrency(String newCurrency) {
    final current = activePeriod;
    final idx = _periods.indexWhere((p) => p.id == current.id);
    if (idx != -1) {
      _periods[idx] = current.copyWith(currency: newCurrency);
      _save();
    }
  }

  // ================= MEMBERS MANAGEMENT =================

  void addMember(String name, {bool isHouseFund = false}) {
    if (name.trim().isEmpty) return;
    final current = activePeriod;
    final newMember = Member(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      isHouseFund: isHouseFund,
    );

    final updatedMembers = [...current.members, newMember];
    final idx = _periods.indexWhere((p) => p.id == current.id);
    if (idx != -1) {
      _periods[idx] = current.copyWith(members: updatedMembers);
      _save();
    }
  }

  void editMember(String memberId, String newName, {bool? isHouseFund}) {
    if (newName.trim().isEmpty) return;
    final current = activePeriod;
    final updatedMembers = current.members.map((m) {
      if (m.id == memberId) {
        return m.copyWith(
          name: newName.trim(),
          isHouseFund: isHouseFund ?? m.isHouseFund,
        );
      }
      return m;
    }).toList();

    final idx = _periods.indexWhere((p) => p.id == current.id);
    if (idx != -1) {
      _periods[idx] = current.copyWith(members: updatedMembers);
      _save();
    }
  }

  void deleteMember(String memberId) {
    final current = activePeriod;
    if (current.members.length <= 1) return;

    final updatedMembers = current.members.where((m) => m.id != memberId).toList();
    // Also clean up items that had this member in customShares or includedMemberIds
    final updatedItems = current.items.map((item) {
      final updatedIncluded = item.includedMemberIds.where((id) => id != memberId).toList();
      final updatedCustom = Map<String, double>.from(item.customShares)..remove(memberId);
      final paidBy = item.paidByMemberId == memberId ? null : item.paidByMemberId;
      return item.copyWith(
        includedMemberIds: updatedIncluded,
        customShares: updatedCustom,
        paidByMemberId: paidBy,
      );
    }).toList();

    final idx = _periods.indexWhere((p) => p.id == current.id);
    if (idx != -1) {
      _periods[idx] = current.copyWith(
        members: updatedMembers,
        items: updatedItems,
      );
      _save();
    }
  }

  // ================= EXPENSE ITEMS MANAGEMENT =================

  void updateItemCost(String itemId, double newCost) {
    final current = activePeriod;
    final updatedItems = current.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(totalCost: newCost >= 0 ? newCost : 0);
      }
      return item;
    }).toList();

    final idx = _periods.indexWhere((p) => p.id == current.id);
    if (idx != -1) {
      _periods[idx] = current.copyWith(items: updatedItems);
      _save();
    }
  }

  void saveExpenseItem(ExpenseItem item) {
    final current = activePeriod;
    final existingIdx = current.items.indexWhere((i) => i.id == item.id);
    List<ExpenseItem> updatedItems;

    if (existingIdx != -1) {
      updatedItems = [...current.items];
      updatedItems[existingIdx] = item;
    } else {
      updatedItems = [...current.items, item];
    }

    final idx = _periods.indexWhere((p) => p.id == current.id);
    if (idx != -1) {
      _periods[idx] = current.copyWith(items: updatedItems);
      _save();
    }
  }

  void deleteExpenseItem(String itemId) {
    final current = activePeriod;
    final updatedItems = current.items.where((i) => i.id != itemId).toList();
    final idx = _periods.indexWhere((p) => p.id == current.id);
    if (idx != -1) {
      _periods[idx] = current.copyWith(items: updatedItems);
      _save();
    }
  }

  void resetToPdfDefault() {
    final defaultPeriod = EzbaPeriod.createDefault();
    final current = activePeriod;
    final idx = _periods.indexWhere((p) => p.id == current.id);
    if (idx != -1) {
      _periods[idx] = defaultPeriod.copyWith(
        id: current.id,
        title: current.title,
        members: current.members.isNotEmpty ? current.members : defaultPeriod.members,
        items: const [],
      );
      _save();
    }
  }

  void clearAllItems() {
    final current = activePeriod;
    final idx = _periods.indexWhere((p) => p.id == current.id);
    if (idx != -1) {
      _periods[idx] = current.copyWith(items: const []);
      _save();
    }
  }

  // ================= SHARING / TEXT SUMMARY =================

  String generateWhatsAppSummary() {
    final p = activePeriod;
    final buffer = StringBuffer();
    buffer.writeln('📋 *كشف حساب مصاريف العزبة*');
    buffer.writeln('🏷️ *الفترة:* ${p.title}');
    buffer.writeln('📅 *التاريخ:* ${EzbaFormatters.formatDate(p.createdAt)}');
    buffer.writeln('💰 *إجمالي المصاريف:* ${EzbaFormatters.formatCurrency(p.totalExpenses, p.currency)}');
    buffer.writeln('👥 *عدد المشتركين:* ${p.members.length}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');

    buffer.writeln('📊 *تفاصيل البنود والمصاريف:*');
    for (final item in p.items) {
      buffer.writeln('• ${item.title}: ${EzbaFormatters.formatCurrency(item.totalCost, p.currency)}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');

    buffer.writeln('👤 *نصيب ومستحقات كل فرد:*');
    for (final m in p.members) {
      final share = p.getMemberTotalShare(m.id);
      final paid = p.getMemberTotalPaid(m.id);
      final net = p.getMemberNetBalance(m.id);

      String netText;
      if (net.abs() < 0.01) {
        netText = 'خالص ✅';
      } else if (net > 0) {
        netText = 'له (+${EzbaFormatters.formatAmount(net)} ${p.currency}) 🟢';
      } else {
        netText = 'عليه (${EzbaFormatters.formatAmount(net.abs())} ${p.currency}) 🔴';
      }

      buffer.writeln('🔹 *${m.name}:*');
      buffer.writeln('   - النصيب: ${EzbaFormatters.formatCurrency(share, p.currency)}');
      buffer.writeln('   - المدفوع: ${EzbaFormatters.formatCurrency(paid, p.currency)}');
      buffer.writeln('   - الصافي: $netText');
    }

    final settlements = p.calculateSettlements();
    if (settlements.isNotEmpty) {
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln('🔄 *مقترحات التسوية وتصفية الحسابات:*');
      for (final s in settlements) {
        buffer.writeln('• يدفع *${s.fromMemberName}* لـ *${s.toMemberName}*: ${EzbaFormatters.formatCurrency(s.amount, p.currency)}');
      }
    }

    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📱 _تم الاستخراج بواسطة تطبيق العزبة_');

    return buffer.toString();
  }
}
