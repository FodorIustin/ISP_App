import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  Future<bool> checkAccessCode(String code) async {
    final doc =
        await _firestore.collection('config').doc('accessCode').get();
    return doc.exists && doc.data()?['code'] == code;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await _auth.signInWithCredential(credential);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.exists;
  }

  Future<void> saveProfile({
    required String uid,
    required String name,
    required String country,
    required String language,
    String? photoPath,
  }) async {
    String? photoUrl;
    if (photoPath != null) {
      final ref = _storage.ref('users/$uid/profile.jpg');
      await ref.putFile(File(photoPath));
      photoUrl = await ref.getDownloadURL();
    }
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'country': country,
      'language': language,
      'photoUrl': photoUrl,
      'points': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      GoogleSignIn.instance.signOut(),
    ]);
  }
}
