// lib/services/storage_service.dart
// Uploads incident photos to Firebase Storage.
// Photos are saved as: incident_images/{incidentId}/{fileName}
// and the download links are stored on the incident in Firestore.

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/constants.dart';

class StorageService {
  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads every picked photo and returns their download URLs, in order.
  /// Throws a FirebaseException if an upload fails.
  Future<List<String>> uploadIncidentImages({
    required String incidentId,
    required List<XFile> images,
  }) async {
    final urls = <String>[];

    for (var i = 0; i < images.length; i++) {
      final image = images[i];

      // Reading bytes (instead of using a file path) works on every platform.
      final bytes = await image.readAsBytes();

      // Unique name so two photos never overwrite each other.
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final ref = _storage
          .ref()
          .child(StoragePaths.incidentImages)
          .child(incidentId)
          .child(fileName);

      await ref.putData(
        bytes,
        SettableMetadata(contentType: image.mimeType ?? 'image/jpeg'),
      );
      urls.add(await ref.getDownloadURL());
    }

    return urls;
  }
}