import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:veon_app/screens/auth/constants/colors.dart';
import 'package:veon_app/models/sale_model.dart';
import 'package:veon_app/models/user_model.dart';
import 'package:veon_app/services/sale_service.dart';
import 'package:veon_app/services/auth_service.dart';
import 'package:veon_app/screens/sales/sale_detail_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:open_file/open_file.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _saleService = SaleService();
  final _authService = AuthService.instance;
  
  bool _isLoading = false;
  DateTimeRange? _dateRange;
  List<Sale> _allSales = [];
  List<Sale> _filteredSales = [];
  List<UserModel> _sellers = [];
  UserModel? _selectedSeller;

  // Statistics
  double _totalRevenue = 0.0;
  int _totalSalesCount = 0;
  int _totalItemsSold = 0;

  @override
  void initState() {
    super.initState();
    // Default to current month
    final now = DateTime.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final sales = await _saleService.getAllSales();
      final allUsers = await _authService.getUsers();
      
      // Extract unique user IDs from sales
      final salesUserIds = sales.map((s) => s.userId).where((id) => id != null).toSet();
      
      // Create a map of existing users for quick lookup
      final userMap = {for (var user in allUsers) user.id: user};
      
      // Identify missing users (present in sales but not in users list)
      final missingUserIds = salesUserIds.where((id) => !userMap.containsKey(id));
      
      // Create placeholder users for missing IDs
      final ghostUsers = missingUserIds.map((id) {
        // Si por alguna razón el usuario existe en userMap, usarlo
        final user = userMap[id] ?? UserModel(
          id: id!,
          name: 'Vendedor (ID: ${id.substring(0, 4)}...)',
          email: '',
          role: 'vendedor',
        );
        return user;
      }).toList();

      
      // Combine real users and ghost users
      final potentialSellers = [...allUsers, ...ghostUsers];
      
      // Filter to show only relevant users:
      // 1. Role contains 'vendedor' OR 'gerente'
      // 2. OR User has at least one sale
      final activeSellers = potentialSellers.where((user) {
        final isSalesRole = user.role.toLowerCase().contains('vendedor') || 
                            user.role.toLowerCase().contains('gerente');
        final hasSales = salesUserIds.contains(user.id);
        return isSalesRole || hasSales;
      }).toList();

      if (mounted) {
        setState(() {
          _allSales = sales;
          _sellers = activeSellers;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Obtener el nombre del vendedor de forma segura
  String _getSellerName(String? userId) {
    if (userId == null || userId.isEmpty) {
      return 'Sin asignar';
    }
    
    try {
      final seller = _sellers.firstWhere(
        (s) => s.id == userId,
        orElse: () => UserModel(id: '', name: 'Desconocido', email: ''),
      );
      return seller.name.isNotEmpty ? seller.name : 'Desconocido';
    } catch (e) {
      return 'Desconocido';
    }
  }

  void _applyFilters() {
    _filteredSales = _allSales.where((sale) {
      // Date Filter
      bool dateMatch = true;
      if (_dateRange != null) {
        dateMatch = sale.date.isAfter(_dateRange!.start.subtract(const Duration(seconds: 1))) &&
            sale.date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }

      // Seller Filter
      bool sellerMatch = true;
      if (_selectedSeller != null) {
        sellerMatch = sale.userId == _selectedSeller!.id;
      }

      return dateMatch && sellerMatch;
    }).toList();

    // Calculate stats
    _totalRevenue = 0.0;
    _totalSalesCount = 0;
    _totalItemsSold = 0;

    for (var sale in _filteredSales) {
      if (sale.status != SaleStatus.cancelled) {
        _totalRevenue += sale.total;
        _totalSalesCount++;
        _totalItemsSold += sale.items.length;
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.black, // Texto negro en botones seleccionados
              surface: const Color(0xFF1E1E1E), // Fondo un poco más claro
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E1E1E),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryGreen, // Color de botones de acción
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _applyFilters();
      });
    }
  }
  
  void _setQuickDateRange(String type) {
    final now = DateTime.now();
    DateTimeRange newRange;
    
    switch (type) {
      case 'today':
        newRange = DateTimeRange(start: now, end: now);
        break;
      case 'week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        newRange = DateTimeRange(start: startOfWeek, end: now);
        break;
      case 'month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        newRange = DateTimeRange(start: startOfMonth, end: now);
        break;
      default:
        return;
    }
    
    setState(() {
      _dateRange = newRange;
      _applyFilters();
    });
  }

  Future<void> _exportPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Sales Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateFormat('MMM dd, yyyy').format(DateTime.now())),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Period: ${_dateRange != null ? "${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd').format(_dateRange!.end)}" : "All Time"}'),
                pw.Text('Seller: ${_selectedSeller?.name ?? "All"}'),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              context: context,
              data: <List<String>>[
                <String>['Date', 'Client', 'Seller', 'Total', 'Status'],
                ..._filteredSales.map((sale) => [
                  DateFormat('yyyy-MM-dd').format(sale.date),
                  sale.clientName,
                  _getSellerName(sale.userId),
                  '\$${sale.total.toStringAsFixed(2)}',
                  sale.status.displayName,
                ]),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Total Revenue: \$${_totalRevenue.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _exportExcel() async {
    var excel = excel_pkg.Excel.createExcel();
    excel_pkg.Sheet sheetObject = excel['Sales'];

    sheetObject.appendRow([
      excel_pkg.TextCellValue('Date'),
      excel_pkg.TextCellValue('Client'),
      excel_pkg.TextCellValue('Seller'),
      excel_pkg.TextCellValue('Total'),
      excel_pkg.TextCellValue('Status')
    ]);

    for (var sale in _filteredSales) {
      sheetObject.appendRow([
        excel_pkg.TextCellValue(DateFormat('yyyy-MM-dd').format(sale.date)),
        excel_pkg.TextCellValue(sale.clientName),
        excel_pkg.TextCellValue(_getSellerName(sale.userId)),
        excel_pkg.DoubleCellValue(sale.total),
        excel_pkg.TextCellValue(sale.status.displayName),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/sales_report_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(excel.encode()!);
    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Sales Reports',
          style: TextStyle(color: AppColors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
            onPressed: _exportPdf,
            tooltip: 'Export PDF',
          ),
          IconButton(
            icon: const Icon(Icons.table_chart, color: Colors.green),
            onPressed: _exportExcel,
            tooltip: 'Export Excel',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filters Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Date Selectors
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildDateChip('Today', 'today'),
                              const SizedBox(width: 8),
                              _buildDateChip('This Week', 'week'),
                              const SizedBox(width: 8),
                              _buildDateChip('This Month', 'month'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Date Range Picker
                        InkWell(
                          onTap: _selectDateRange,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.withOpacity(0.5)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: AppColors.primaryGreen, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _dateRange != null
                                        ? '${DateFormat('MMM dd, yyyy').format(_dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange!.end)}'
                                        : 'All Time',
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Seller Dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<UserModel>(
                              value: _selectedSeller,
                              hint: const Text('All Sellers', style: TextStyle(color: Colors.white)),
                              dropdownColor: const Color(0xFF2A2A2A),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem<UserModel>(
                                  value: null,
                                  child: Text('All Sellers', style: TextStyle(color: Colors.white)),
                                ),
                                ..._sellers.map((seller) {
                                  return DropdownMenuItem<UserModel>(
                                    value: seller,
                                    child: Text(seller.name, style: const TextStyle(color: Colors.white)),
                                  );
                                }),
                              ],
                              onChanged: (UserModel? newValue) {
                                setState(() {
                                  _selectedSeller = newValue;
                                  _applyFilters();
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Revenue',
                          '\$${_totalRevenue.toStringAsFixed(2)}',
                          Icons.attach_money,
                          AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Sales',
                          _totalSalesCount.toString(),
                          Icons.shopping_bag_outlined,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Items Sold',
                          _totalItemsSold.toString(),
                          Icons.inventory_2_outlined,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Avg. Sale',
                          '\$${(_totalSalesCount > 0 ? _totalRevenue / _totalSalesCount : 0).toStringAsFixed(2)}',
                          Icons.analytics_outlined,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  
                  const Text(
                    'Transactions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_filteredSales.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No sales found for this period',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredSales.length,
                      itemBuilder: (context, index) {
                        final sale = _filteredSales[index];
                        return _buildSaleItem(sale);
                      },
                    ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildDateChip(String label, String type) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: const Color(0xFF3A3A3A),
      onPressed: () => _setQuickDateRange(type),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleItem(Sale sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SaleDetailScreen(saleId: sale.id),
            ),
          );
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: sale.status == SaleStatus.cancelled 
                ? Colors.red.withOpacity(0.2) 
                : AppColors.primaryGreen.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            sale.status == SaleStatus.cancelled ? Icons.close : Icons.check,
            color: sale.status == SaleStatus.cancelled ? Colors.red : AppColors.primaryGreen,
            size: 16,
          ),
        ),
        title: Text(
          sale.clientName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('MMM dd, HH:mm').format(sale.date),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (sale.userId != null)
               Text(
                'Seller: ${_getSellerName(sale.userId)}',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${sale.total.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (sale.status == SaleStatus.cancelled)
              const Text(
                'Cancelled',
                style: TextStyle(color: Colors.red, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }
}
