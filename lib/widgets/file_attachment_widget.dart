import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../constants/app_colors.dart';
import '../models/task.dart';
import '../models/file.dart';
import '../providers/file_provider.dart';

class FileAttachmentWidget extends ConsumerStatefulWidget {
  final Task task;
  final bool showCompact;
  final VoidCallback? onAttachmentsChanged;

  const FileAttachmentWidget({
    required this.task,
    this.showCompact = false,
    this.onAttachmentsChanged,
    super.key,
  });

  @override
  ConsumerState<FileAttachmentWidget> createState() => _FileAttachmentWidgetState();
}

class _FileAttachmentWidgetState extends ConsumerState<FileAttachmentWidget> {
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Load files when the widget is initialized
    if (widget.task.id != null) {
      Future.microtask(() {
        ref.read(fileProvider.notifier).loadTaskFiles(widget.task.id!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileState = ref.watch(fileProvider);
    final taskFiles = fileState.files[widget.task.id] ?? [];

    if (widget.showCompact) {
      return _buildCompactView(taskFiles);
    } else {
      return _buildExpandedView(taskFiles);
    }
  }

  Widget _buildCompactView(List<TaskFile> files) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          Icons.attach_file,
          size: 14,
          color: AppColors.gray500,
        ),
        const SizedBox(width: 4),
        Text(
          '${files.length}',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedView(List<TaskFile> files) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.attach_file,
              size: 20,
              color: AppColors.primaryColor,
            ),
            const SizedBox(width: 8),
            const Text(
              'Attachments',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _isUploading ? null : _pickAndUploadFile,
              icon: _isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                      ),
                    )
                  : const Icon(Icons.add, size: 20),
              color: AppColors.primaryColor,
              tooltip: 'Add attachment',
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (files.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gray300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  color: AppColors.gray400,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No attachments yet',
                        style: TextStyle(
                          color: AppColors.gray600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Upload files to share with your team',
                        style: TextStyle(
                          color: AppColors.gray500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          ...files.map((file) => _buildFileItem(file)),
      ],
    );
  }

  Widget _buildFileItem(TaskFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getFileTypeColor(file.mimeType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileTypeIcon(file.mimeType),
              color: _getFileTypeColor(file.mimeType),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.originalName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_formatFileSize(file.size)} • ${_formatDate(file.uploadedAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _downloadFile(file),
                icon: const Icon(Icons.download, size: 18),
                color: AppColors.primaryColor,
                tooltip: 'Download',
              ),
              IconButton(
                onPressed: () => _deleteFile(file),
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.errorColor,
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final success = await ref.read(fileProvider.notifier).uploadFile(
        widget.task.id!,
        File(file.path!),
        file.name,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
        widget.onAttachmentsChanged?.call();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload file'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _downloadFile(TaskFile file) async {
    try {
      final success = await ref.read(fileProvider.notifier).downloadFile(file);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File downloaded successfully'),
            backgroundColor: AppColors.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download file: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteFile(TaskFile file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.originalName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorColor),
            child: const Text('Delete', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(fileProvider.notifier).deleteFile(file.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted successfully')),
        );
        widget.onAttachmentsChanged?.call();
      }
    }
  }

  IconData _getFileTypeIcon(String mimeType) {
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.startsWith('video/')) return Icons.video_file;
    if (mimeType.startsWith('audio/')) return Icons.audio_file;
    if (mimeType == 'application/pdf') return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('document')) return Icons.description;
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) return Icons.table_chart;
    if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) return Icons.slideshow;
    if (mimeType.startsWith('text/')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  Color _getFileTypeColor(String mimeType) {
    if (mimeType.startsWith('image/')) return Colors.green;
    if (mimeType.startsWith('video/')) return Colors.blue;
    if (mimeType.startsWith('audio/')) return Colors.orange;
    if (mimeType == 'application/pdf') return Colors.red;
    if (mimeType.contains('word') || mimeType.contains('document')) return Colors.blue;
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet')) return Colors.green;
    if (mimeType.contains('powerpoint') || mimeType.contains('presentation')) return Colors.orange;
    return AppColors.gray600;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}