// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   Future<UserCredential?> signInWithGoogle() async {
//     try {
//       // Trigger the Google Sign-In flow
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) return null;

//       // Obtain the auth details from the request
//       final GoogleSignInAuthentication googleAuth = 
//           await googleUser.authentication;

//       // Create a new credential
//       final OAuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       // Sign in to Firebase with the Google credential
//       return await _auth.signInWithCredential(credential);
//     } catch (e) {
//       print('Google sign-in error: $e');
//       return null;
//     }
//   }

//   Future<String?> handleGoogleSignIn() async {
//     try {
//       final UserCredential? userCredential = await signInWithGoogle();
//       if (userCredential == null) return null;

//       // Get the Firebase ID token
//       final String? idToken = await userCredential.user?.getIdToken();
//       return idToken;
//     } catch (e) {
//       print('Error handling Google sign-in: $e');
//       return null;
//     }
//   }
// }