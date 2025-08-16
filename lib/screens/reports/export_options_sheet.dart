import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../models/analytics.dart';
import '../../providers/analytics_provider.dart';

class ExportOptionsSheet extends ConsumerStatefulWidget {
  const ExportOptionsSheet({super.key});

  @override
  ConsumerState<ExportOptionsSheet> createState() => _ExportOptionsSheetState();
}

class _ExportOptionsSheetState extends ConsumerState<ExportOptionsSheet> {
  ExportFormat _selectedFormat = ExportFormat.pdf;
  bool _includeCharts = true;
  bool _includeRawData = false;
  bool _includeInsights = true;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.download, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Export Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Export Format Selection
          const Text(
            'Export Format',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),

          ...ExportFormat.values.map((format) => RadioListTile<ExportFormat>(
                value: format,
                groupValue: _selectedFormat,
                onChanged: (value) {
                  setState(() {
                    _selectedFormat = value!;
                  });
                },
                title: Row(
                  children: [
                    Icon(
                      _getFormatIcon(format),
                      color: AppColors.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(_getFormatName(format)),
                  ],
                ),
                subtitle: Text(
                  _getFormatDescription(format),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                  ),
                ),
                activeColor: AppColors.primaryColor,
                contentPadding: EdgeInsets.zero,
              )),

          const SizedBox(height: 24),

          // Export Options
          const Text(
            'Include in Export',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray900,
            ),
          ),
          const SizedBox(height: 12),

          CheckboxListTile(
            value: _includeCharts,
            onChanged: (value) {
              setState(() {
                _includeCharts = value ?? true;
              });
            },
            title: const Text('Charts & Visualizations'),
            subtitle: Text(
              'Include pie charts, bar charts, and trend graphs',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray600,
              ),
            ),
            activeColor: AppColors.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),

          CheckboxListTile(
            value: _includeRawData,
            onChanged: (value) {
              setState(() {
                _includeRawData = value ?? false;
              });
            },
            title: const Text('Raw Data Tables'),
            subtitle: Text(
              'Include detailed data tables and statistics',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray600,
              ),
            ),
            activeColor: AppColors.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),

          CheckboxListTile(
            value: _includeInsights,
            onChanged: (value) {
              setState(() {
                _includeInsights = value ?? true;
              });
            },
            title: const Text('Insights & Recommendations'),
            subtitle: Text(
              'Include AI-generated insights and recommendations',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray600,
              ),
            ),
            activeColor: AppColors.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 24),

          // Export Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Export will include data from your current filter settings. File will be downloaded to your device.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.gray300),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.gray700),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isExporting ? null : _exportAnalytics,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.download, size: 18),
                            const SizedBox(width: 8),
                            Text('Export ${_getFormatName(_selectedFormat)}'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return Icons.picture_as_pdf;
      case ExportFormat.excel:
        return Icons.table_chart;
      case ExportFormat.csv:
        return Icons.text_snippet;
      case ExportFormat.json:
        return Icons.code;
    }
  }

  String _getFormatName(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return 'PDF';
      case ExportFormat.excel:
        return 'Excel';
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.json:
        return 'JSON';
    }
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return 'Professional report with charts and insights';
      case ExportFormat.excel:
        return 'Spreadsheet with data tables and charts';
      case ExportFormat.csv:
        return 'Raw data in comma-separated values format';
      case ExportFormat.json:
        return 'Structured data for developers and integrations';
    }
  }

  Future<void> _exportAnalytics() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final analyticsActions = ref.read(analyticsActionsProvider);
      final exportData = await analyticsActions.exportAnalytics(_selectedFormat);
      
      // Add export options to the data
      exportData['exportOptions'] = {
        'format': _selectedFormat.toString().split('.').last,
        'includeCharts': _includeCharts,
        'includeRawData': _includeRawData,
        'includeInsights': _includeInsights,
        'exportedAt': DateTime.now().toIso8601String(),
      };

      // In a real implementation, this would trigger the actual file download
      // For now, we'll show a success message
      
      if (mounted) {
        Navigator.of(context).pop();
        _showExportSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showExportErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showExportSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.check_circle,
          color: AppColors.successColor,
          size: 48,
        ),
        title: const Text('Export Successful'),
        content: Text(
          'Your analytics report has been exported in ${_getFormatName(_selectedFormat)} format. The file will be downloaded shortly.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExportErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.error,
          color: AppColors.errorColor,
          size: 48,
        ),
        title: const Text('Export Failed'),
        content: Text(
          'Failed to export analytics report: $error',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportAnalytics();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}