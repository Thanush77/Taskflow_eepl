import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../models/file.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// File state
class FileState {
  final Map<int, List<TaskFile>> files;
  final bool isLoading;
  final String? error;

  const FileState({
    this.files = const {},
    this.isLoading = false,
    this.error,
  });

  FileState copyWith({
    Map<int, List<TaskFile>>? files,
    bool? isLoading,
    String? error,
  }) {
    return FileState(
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// File notifier
class FileNotifier extends StateNotifier<FileState> {
  final ApiService _apiService;

  FileNotifier(this._apiService) : super(const FileState());

  // Load files for a task
  Future<void> loadTaskFiles(int taskId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.getTaskFiles(taskId);
      if (response['success'] == true) {
        final List<dynamic> filesJson = response['data'] ?? [];
        final files = filesJson.map((json) => TaskFile.fromJson(json)).toList();
        
        final updatedFiles = Map<int, List<TaskFile>>.from(state.files);
        updatedFiles[taskId] = files;
        
        state = state.copyWith(
          files: updatedFiles,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to load files',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Upload a file
  Future<bool> uploadFile(int taskId, File file, String originalName) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final request = http.MultipartRequest('POST', Uri.parse('${_apiService.baseUrl}/api/files/upload'));
      
      // Add auth header
      final token = await _apiService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Add task ID
      request.fields['taskId'] = taskId.toString();
      
      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: originalName,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = _apiService.decodeResponse(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Reload files for this task
        await loadTaskFiles(taskId);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: data['message'] ?? 'Failed to upload file',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Download a file
  Future<bool> downloadFile(TaskFile file) async {
    try {
      final response = await _apiService.dio.get(
        file.url,
        options: Options(
          responseType: ResponseType.bytes,
        ),
      );

      if (response.statusCode == 200) {
        // Get downloads directory
        Directory? directory;
        if (Platform.isAndroid) {
          directory = await getExternalStorageDirectory();
        } else if (Platform.isIOS) {
          directory = await getApplicationDocumentsDirectory();
        } else {
          directory = await getDownloadsDirectory();
        }

        if (directory != null) {
          final filePath = '${directory.path}/${file.originalName}';
          final downloadFile = File(filePath);
          await downloadFile.writeAsBytes(response.data);
          return true;
        }
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Delete a file
  Future<bool> deleteFile(int fileId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.deleteFile(fileId);
      if (response['success'] == true) {
        // Remove file from state
        final updatedFiles = Map<int, List<TaskFile>>.from(state.files);
        for (final taskId in updatedFiles.keys) {
          updatedFiles[taskId] = updatedFiles[taskId]!
              .where((file) => file.id != fileId)
              .toList();
        }

        state = state.copyWith(
          files: updatedFiles,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Failed to delete file',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Refresh all files
  Future<void> refresh() async {
    // Reload all currently loaded task files
    for (final taskId in state.files.keys) {
      await loadTaskFiles(taskId);
    }
  }
}

// File provider
final fileProvider = StateNotifierProvider<FileNotifier, FileState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return FileNotifier(apiService);
});