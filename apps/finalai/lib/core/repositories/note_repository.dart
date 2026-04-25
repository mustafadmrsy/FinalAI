import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/note_model.dart';

class NoteRepository {
  NoteRepository(this._client);

  final SupabaseClient _client;

  String _sanitizeStorageFileName(String fileName) {
    final trimmed = fileName.trim();
    final lowered = trimmed.toLowerCase();

    final replaced = lowered
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');

    final buffer = StringBuffer();
    for (final codeUnit in replaced.codeUnits) {
      final c = String.fromCharCode(codeUnit);
      final isAllowed = RegExp(r'[a-z0-9._-]').hasMatch(c);
      buffer.write(isAllowed ? c : '_');
    }

    final collapsed = buffer.toString().replaceAll(RegExp(r'_+'), '_');
    return collapsed.isEmpty ? 'file.pdf' : collapsed;
  }

  String _requireUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Not authenticated');
    }
    return userId;
  }

  Future<String> uploadPdf(List<int> bytes, String fileName) async {
    try {
      final userId = _requireUserId();
      final safeName = _sanitizeStorageFileName(fileName);
      final path = '$userId/$safeName';
      final data = Uint8List.fromList(bytes);
      await _client.storage.from('pdfs').uploadBinary(
            path,
            data,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      return path;
    } catch (e) {
      throw Exception('NoteRepository.uploadPdf failed: $e');
    }
  }

  Future<String> uploadTextAsFile(String text, String fileName) async {
    try {
      final userId = _requireUserId();
      final safeName = _sanitizeStorageFileName(fileName.replaceAll('.docx', '.txt'));
      final path = '$userId/$safeName';
      final data = Uint8List.fromList(utf8.encode(text));
      await _client.storage.from('pdfs').uploadBinary(
            path,
            data,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );
      return path;
    } catch (e) {
      throw Exception('NoteRepository.uploadTextAsFile failed: $e');
    }
  }

  Future<String> saveNote({
    required String subject,
    required String filePath,
    required Map<String, dynamic> summary,
  }) async {
    try {
      final userId = _requireUserId();
      final data = {
        'user_id': userId,
        'subject': subject,
        'file_path': filePath,
        'summary_short': summary['summary_short'],
        'summary_long': summary['summary_long'],
        'questions': summary['questions'],
        'flashcards': summary['flashcards'],
      };

      final res = await _client.from('notes').insert(data).select('id').single();
      return res['id'] as String;
    } catch (e) {
      throw Exception('NoteRepository.saveNote failed: $e');
    }
  }

  Future<List<NoteModel>> getRecentNotes({int limit = 10}) async {
    try {
      final userId = _requireUserId();
      final res = await _client
          .from('notes')
          .select('id, subject, file_path, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (res as List)
          .map((e) => NoteModel.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw Exception('NoteRepository.getRecentNotes failed: $e');
    }
  }

  Future<Map<String, dynamic>> getNoteById(String noteId) async {
    try {
      final userId = _requireUserId();
      final res = await _client
          .from('notes')
          .select('id, subject, summary_short, summary_long, questions, flashcards, created_at')
          .eq('user_id', userId)
          .eq('id', noteId)
          .single();
      return (res as Map).cast<String, dynamic>();
    } catch (e) {
      throw Exception('NoteRepository.getNoteById failed: $e');
    }
  }

  Future<void> updateNoteSubject(String noteId, String newSubject) async {
    try {
      final userId = _requireUserId();
      await _client
          .from('notes')
          .update({'subject': newSubject, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('id', noteId);
    } catch (e) {
      throw Exception('NoteRepository.updateNoteSubject failed: $e');
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      final userId = _requireUserId();
      await _client.from('notes').delete().eq('user_id', userId).eq('id', noteId);
    } catch (e) {
      throw Exception('NoteRepository.deleteNote failed: $e');
    }
  }

  Future<void> updateNoteSummary({
    required String noteId,
    String? summaryShort,
    String? summaryLong,
  }) async {
    try {
      final userId = _requireUserId();
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (summaryShort != null) updates['summary_short'] = summaryShort;
      if (summaryLong != null) updates['summary_long'] = summaryLong;

      await _client.from('notes').update(updates).eq('user_id', userId).eq('id', noteId);
    } catch (e) {
      throw Exception('NoteRepository.updateNoteSummary failed: $e');
    }
  }
}
