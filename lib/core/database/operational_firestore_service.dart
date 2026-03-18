import 'package:cloud_firestore/cloud_firestore.dart';

class OperationalFirestoreService {
  OperationalFirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const schoolsCollection = 'operational_schools';
  static const classesCollection = 'operational_classes';
  static const subjectsCollection = 'operational_subjects';
  static const teachersCollection = 'operational_teachers';
  static const classTeacherSubjectsCollection =
      'operational_class_teacher_subjects';
  static const studentsCollection = 'operational_students';
  static const assignmentsCollection = 'operational_assignments';
  static const scoresCollection = 'operational_scores';

  static const int _whereInChunkSize = 10;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> collection(String name) {
    return _firestore.collection(name);
  }

  Future<String> createDocument({
    required String collectionName,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    final document = documentId == null
        ? collection(collectionName).doc()
        : collection(collectionName).doc(documentId);
    await document.set(_sanitizeMap(data));
    return document.id;
  }

  Future<void> setDocument({
    required String collectionName,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    await collection(collectionName).doc(documentId).set(
      _sanitizeMap(data),
      SetOptions(merge: merge),
    );
  }

  Future<Map<String, dynamic>?> getDocument({
    required String collectionName,
    required String documentId,
  }) async {
    final document = await collection(collectionName).doc(documentId).get();
    if (!document.exists) {
      return null;
    }
    return _documentToMap(document);
  }

  Future<List<Map<String, dynamic>>> getAllDocuments({
    required String collectionName,
  }) async {
    final snapshot = await collection(collectionName).get();
    return snapshot.docs.map(_documentToMap).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> queryByField({
    required String collectionName,
    required String field,
    required Object? isEqualTo,
  }) async {
    final snapshot = await collection(
      collectionName,
    ).where(field, isEqualTo: isEqualTo).get();
    return snapshot.docs.map(_documentToMap).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> queryByIds({
    required String collectionName,
    required List<String> ids,
  }) async {
    if (ids.isEmpty) {
      return const [];
    }

    final uniqueIds = ids.toSet().toList(growable: false);
    final results = <Map<String, dynamic>>[];
    for (var index = 0; index < uniqueIds.length; index += _whereInChunkSize) {
      final chunk = uniqueIds.skip(index).take(_whereInChunkSize).toList();
      final snapshot = await collection(
        collectionName,
      ).where(FieldPath.documentId, whereIn: chunk).get();
      results.addAll(snapshot.docs.map(_documentToMap));
    }
    return results;
  }

  Future<List<Map<String, dynamic>>> queryByFieldIn({
    required String collectionName,
    required String field,
    required List<String> values,
  }) async {
    if (values.isEmpty) {
      return const [];
    }

    final uniqueValues = values.toSet().toList(growable: false);
    final results = <Map<String, dynamic>>[];
    for (
      var index = 0;
      index < uniqueValues.length;
      index += _whereInChunkSize
    ) {
      final chunk = uniqueValues.skip(index).take(_whereInChunkSize).toList();
      final snapshot = await collection(
        collectionName,
      ).where(field, whereIn: chunk).get();
      results.addAll(snapshot.docs.map(_documentToMap));
    }
    return results;
  }

  Future<void> deleteDocument({
    required String collectionName,
    required String documentId,
  }) async {
    await collection(collectionName).doc(documentId).delete();
  }

  Future<void> deleteDocumentsByIds({
    required String collectionName,
    required Iterable<String> documentIds,
  }) async {
    final ids = documentIds.where((id) => id.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) {
      return;
    }

    for (var index = 0; index < ids.length; index += 400) {
      final batch = _firestore.batch();
      final chunk = ids.skip(index).take(400);
      for (final documentId in chunk) {
        batch.delete(collection(collectionName).doc(documentId));
      }
      await batch.commit();
    }
  }

  Map<String, dynamic> _documentToMap(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return <String, dynamic>{
      'id': document.id,
      ..._normalizeMap(document.data() ?? const <String, dynamic>{}),
    };
  }

  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> input) {
    final output = <String, dynamic>{};
    input.forEach((key, value) {
      if (key == 'id') {
        return;
      }
      output[key] = value;
    });
    return output;
  }

  Map<String, dynamic> _normalizeMap(Map<String, dynamic> input) {
    return input.map(
      (key, value) => MapEntry(key, _normalizeValue(value)),
    );
  }

  Object? _normalizeValue(Object? value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is Map<String, dynamic>) {
      return _normalizeMap(value);
    }
    if (value is List) {
      return value.map(_normalizeValue).toList(growable: false);
    }
    return value;
  }
}
