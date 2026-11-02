import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Picks a document photo (camera or gallery) and copies it into the app's
/// own documents directory so it survives cache clears and persists across
/// restarts — only the resulting path is ever stored on a [DocRecord].
class PhotoService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndStore({required bool fromCamera}) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final docsDir = Directory(path.join(dir.path, 'doctrack_photos'));
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    final ext = path.extension(picked.path).isNotEmpty ? path.extension(picked.path) : '.jpg';
    final destPath = path.join(
      docsDir.path,
      '${DateTime.now().microsecondsSinceEpoch}$ext',
    );
    final file = File(picked.path);
    await file.copy(destPath);
    return destPath;
  }

  Future<void> delete(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
