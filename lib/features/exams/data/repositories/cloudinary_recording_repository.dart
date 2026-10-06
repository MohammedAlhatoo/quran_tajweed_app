import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/app_failure.dart';
import '../../domain/repositories/recording_repository.dart';

String _urlKey(String examId) => 'recording_url_$examId';

/// The Cloudinary link of the recitation last uploaded for [examId] from this
/// device, or null when none was.
Future<String?> uploadedRecordingUrl(String examId) async {
  final preferences = await SharedPreferences.getInstance();
  return preferences.getString(_urlKey(examId));
}

/// Uploads the recitation recordings to Cloudinary with an unsigned upload
/// preset, so the app holds no API secret.
///
/// An unsigned upload never replaces a file: every upload gets a new public
/// ID under the examination's ID, and the link of the last one is kept on the
/// device until the examination is submitted with it.
class CloudinaryRecordingRepository implements RecordingRepository {
  CloudinaryRecordingRepository({http.Client? client})
    : _client = client ?? http.Client();

  /// The cloud name of the Cloudinary account.
  static const String cloudName = 'cyzyw617';

  /// The name of the unsigned upload preset.
  static const String uploadPreset = 'quran_exam_audio';

  static const AppFailure _offline = AppFailure(
    'تعذّر الاتصال. تحقق من الإنترنت وحاول مرة أخرى.',
  );
  static const AppFailure _refused = AppFailure(
    'تعذّر رفع التسجيل. حاول مرة أخرى.',
  );

  final http.Client _client;

  @override
  Future<void> uploadRecording({
    required String examId,
    required String filePath,
    void Function(double progress)? onProgress,
  }) async {
    final String url;
    try {
      // Audio is uploaded as the `video` resource type.
      final form =
          http.MultipartRequest(
              'POST',
              Uri.https(
                'api.cloudinary.com',
                '/v1_1/$cloudName/video/upload',
              ),
            )
            ..fields['upload_preset'] = uploadPreset
            ..fields['public_id'] =
                'exam_recordings/$examId/'
                '${DateTime.now().millisecondsSinceEpoch}'
            ..files.add(await http.MultipartFile.fromPath('file', filePath));

      // The form is sent as a stream so the uploaded share can be reported.
      final total = form.contentLength;
      final request = http.StreamedRequest(form.method, form.url)
        ..contentLength = total;
      final body = form.finalize();
      request.headers.addAll(form.headers);
      var sent = 0;
      body.listen(
        (chunk) {
          request.sink.add(chunk);
          sent += chunk.length;
          if (total > 0) onProgress?.call(sent / total);
        },
        onError: request.sink.addError,
        onDone: request.sink.close,
        cancelOnError: true,
      );

      final response = await http.Response.fromStream(
        await _client.send(request),
      );
      if (response.statusCode != 200) throw _refused;
      final secureUrl = (jsonDecode(response.body) as Map)['secure_url'];
      if (secureUrl is! String || secureUrl.isEmpty) throw _refused;
      url = secureUrl;
    } on http.ClientException {
      throw _offline;
    } on SocketException {
      throw _offline;
    } on FileSystemException {
      throw const AppFailure('تعذّر قراءة التسجيل من الجهاز.');
    } on FormatException {
      throw _refused;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_urlKey(examId), url);
  }

  @override
  Future<bool> hasRecording(String examId) async =>
      await uploadedRecordingUrl(examId) != null;
}
