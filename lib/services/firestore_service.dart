import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Create Post
  Future<void> submitCommunityPost({
    required String content,
    required String authorEmail,
    required String authorNickname,
  }) async {
    await _firestore.collection('community_posts').add({
      'content': content,
      'authorEmail': authorEmail,
      'authorNickname': authorNickname,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': 0,
      'comments': 0,
    });
  }

  // 1b. Update Post
  Future<void> updateCommunityPost({
    required String postId,
    required String newContent,
    required String previousContent,
  }) async {
    await _firestore.collection('community_posts').doc(postId).update({
      'content': newContent,
      'previousContent': previousContent,
      'editedAt': FieldValue.serverTimestamp(),
      'isEdited': true,
    });
  }

  // 2. Submit Song
  Future<void> submitSongSuggestion({
    required String title,
    required String author,
    required String category,
    required String lyrics,
    required String chords,
    required String submittedByEmail,
  }) async {
    await _firestore.collection('song_submissions').add({
      'title': title,
      'author': author,
      'category': category,
      'lyrics': lyrics,
      'chords': chords,
      'submittedBy': submittedByEmail,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending', // for admin review queues
    });
  }

  // 3. Update Center
  Future<void> submitCenterUpdate({
    required String centerId,
    required String centerName,
    required String centerAddress,
    required String updateType,
    required Map<String, dynamic> payload,
    required String submittedByEmail,
  }) async {
    await _firestore.collection('center_updates').add({
      'centerId': centerId,
      'centerName': centerName,
      'centerAddress': centerAddress,
      'updateType': updateType, // 'Location Locator' or 'Contact Person'
      'payload': payload,
      'submittedBy': submittedByEmail,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  // 4. Save User Profile
  Future<void> saveUserProfile({
    required String uid,
    required String email,
    required String name,
    required String firstName,
    required String middleName,
    required String surname,
    required String position,
    required String district,
    required String area,
    required String centerName,
    required String centerAddress,
  }) async {
    if (email.isEmpty) return;
    await _firestore.collection('users').doc(email).set({
      'uid': uid,
      'email': email,
      'name': name,
      'firstName': firstName,
      'middleName': middleName,
      'surname': surname,
      'position': position,
      'district': district,
      'area': area,
      'centerName': centerName,
      'centerAddress': centerAddress,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 4b. Check if email exists
  Future<bool> checkEmailExists(String email) async {
    if (email.isEmpty) return false;
    final doc = await _firestore.collection('users').doc(email).get();
    return doc.exists;
  }

  // 4c. Check if nickname exists
  Future<bool> checkNicknameExists(String nickname) async {
    if (nickname.isEmpty) return false;
    final query = await _firestore
        .collection('users')
        .where('name', isEqualTo: nickname)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // 5. Get Community Posts Stream
  Stream<QuerySnapshot> getCommunityPostsStream() {
    final threshold = DateTime.now().subtract(const Duration(days: 5));
    return _firestore
        .collection('community_posts')
        .where('timestamp', isGreaterThanOrEqualTo: threshold)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 6. Toggle Like (Increment/Decrement)
  Future<void> togglePostLike(
    String postId,
    bool isCurrentlyLiked,
    String uid,
  ) async {
    final postRef = _firestore.collection('community_posts').doc(postId);

    if (isCurrentlyLiked) {
      await postRef.update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([uid]),
      });
    } else {
      await postRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([uid]),
      });
    }
  }

  // 7. Add Comment
  Future<void> addComment({
    required String postId,
    required String content,
    required String authorEmail,
    required String authorNickname,
  }) async {
    final postRef = _firestore.collection('community_posts').doc(postId);

    // Write to subcollection
    await postRef.collection('comments').add({
      'content': content,
      'authorEmail': authorEmail,
      'authorNickname': authorNickname,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Increment comment count on parent
    await postRef.update({'comments': FieldValue.increment(1)});
  }

  // 8. Get Comments Stream
  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _firestore
        .collection('community_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: false) // Chronological
        .snapshots();
  }

  // 9. Report Post
  Future<void> reportPost({
    required String postId,
    required String reason,
    required String reportedBy,
  }) async {
    await _firestore.collection('community_posts').doc(postId).set({
      'isReported': true,
      'reportReason': reason,
      'reportedBy': reportedBy,
      'reportedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 10. Delete Comment
  Future<void> deleteComment(String postId, String commentId) async {
    final postRef = _firestore.collection('community_posts').doc(postId);
    await postRef.collection('comments').doc(commentId).delete();

    // Decrement comment count on parent but prevent it from going below 0
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (snapshot.exists) {
        final currentCount = snapshot.data()?['comments'] as int? ?? 0;
        transaction.update(postRef, {
          'comments': currentCount > 0 ? currentCount - 1 : 0,
        });
      }
    });
  }
}
