import 'package:flutter/material.dart';
import '../api/parent_api.dart';
import '../api/session_store.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String studentCode;
  final String phone;
  final Map<String, dynamic> initialSummary;

  const HomeScreen({
    super.key,
    required this.studentCode,
    required this.phone,
    required this.initialSummary,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ParentApi _api;
  late Map<String, dynamic> _summary;
  List<dynamic> _ledger = [];
  List<dynamic> _payments = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = ParentApi(studentCode: widget.studentCode, phone: widget.phone);
    _summary = widget.initialSummary;
    _loadDetails();
  }

  Future<void> _loadDetails({bool refreshSummary = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        refreshSummary ? _api.getSummary() : Future.value(_summary),
        _api.getLedgerStatus(),
        _api.getPaymentHistory(),
      ]);
      setState(() {
        _summary = results[0] as Map<String, dynamic>;
        _ledger = results[1] as List<dynamic>;
        _payments = results[2] as List<dynamic>;
      });
    } on ParentApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = _summary["is_active"] == true;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_summary["name"] ?? "Student"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : () => _loadDetails(refreshSummary: true),
            ),
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Monthly status"),
              Tab(text: "Payment history"),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () => _loadDetails(refreshSummary: true),
          child: Column(
            children: [
              _SummaryCard(summary: _summary, isActive: isActive),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: TabBarView(
                  children: [
                    _LedgerList(rows: _ledger),
                    _PaymentList(rows: _payments),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  final bool isActive;
  const _SummaryCard({required this.summary, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final double balance = (summary["outstanding_balance"] ?? 0).toDouble();
    final balanceColor = balance > 0 ? Colors.red[700] : Colors.green[700];

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  summary["student_code"] ?? "",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                Chip(
                  label: Text(summary["status"] ?? "Active"),
                  backgroundColor: isActive ? Colors.green[50] : Colors.orange[50],
                  labelStyle: TextStyle(
                    color: isActive ? Colors.green[800] : Colors.orange[800],
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _row("Bus", summary["vehicle_number"]),
            _row("School", summary["school"]),
            _row("Grade", summary["grade"]),
            _row("Pickup", summary["pickup_location"]),
            _row("Monthly fee", summary["monthly_fee_display"]),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Outstanding balance", style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  summary["outstanding_balance_display"] ?? "-",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: balanceColor),
                ),
              ],
            ),
            if (!isActive) ...[
              const SizedBox(height: 8),
              Text(
                "This student is currently inactive — no new monthly fees are being charged.",
                style: TextStyle(color: Colors.orange[800], fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value.toString()),
        ],
      ),
    );
  }
}

class _LedgerList extends StatelessWidget {
  final List<dynamic> rows;
  const _LedgerList({required this.rows});

  static const _months = [
    "", "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
  ];

  Color _statusColor(String status) {
    switch (status) {
      case "Paid":
        return Colors.green;
      case "Partial":
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text("No billing months yet."));
    }
    final reversed = rows.reversed.toList(); // most recent month first
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: reversed.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final r = reversed[i] as Map<String, dynamic>;
        final status = r["status"] as String? ?? "Pending";
        final monthLabel = "${_months[(r["month"] ?? 0) as int]} ${r["year"]}";
        return ListTile(
          tileColor: Colors.grey[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: CircleAvatar(
            backgroundColor: _statusColor(status).withOpacity(0.15),
            child: Icon(
              status == "Paid" ? Icons.check : (status == "Partial" ? Icons.timelapse : Icons.priority_high),
              color: _statusColor(status),
              size: 20,
            ),
          ),
          title: Text(monthLabel),
          subtitle: Text("Fee ${r["fee_amount_display"]} · Paid ${r["paid_amount_display"]}"),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(status, style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.w600)),
              if ((r["balance_due"] ?? 0) > 0)
                Text(r["balance_due_display"] ?? "", style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentList extends StatelessWidget {
  final List<dynamic> rows;
  const _PaymentList({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(child: Text("No payments recorded yet."));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final r = rows[i] as Map<String, dynamic>;
        return ListTile(
          tileColor: Colors.grey[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE8F0FE),
            child: Icon(Icons.receipt_long_outlined, color: Colors.indigo, size: 20),
          ),
          title: Text(r["amount_display"] ?? ""),
          subtitle: Text("${r["payment_method"] ?? ""} · ${r["payment_date"] ?? ""}"),
          trailing: (r["notes"] != null && r["notes"].toString().isNotEmpty)
              ? const Icon(Icons.notes, size: 16, color: Colors.grey)
              : null,
        );
      },
    );
  }
}
