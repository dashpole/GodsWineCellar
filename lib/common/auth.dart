import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import 'package:flutter/material.dart';

class LoginWithGoogleButton extends StatefulWidget {
  final FirebaseUser _user;

  LoginWithGoogleButton(this._user);

  @override
  _LoginWithGoogleButtonState createState() => _LoginWithGoogleButtonState();
}

class _LoginWithGoogleButtonState extends State<LoginWithGoogleButton> {
  static FirebaseAuth _auth = FirebaseAuth.instance;
  static GoogleSignIn _googleSignIn = GoogleSignIn();

  void _handleSignInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.getCredential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final FirebaseUser user =
          (await _auth.signInWithCredential(credential)).user;

      assert(user.email != null);
      assert(user.displayName != null);
      assert(await user.getIdToken() != null);

      final FirebaseUser currentUser = await _auth.currentUser();
      assert(user.uid == currentUser.uid);
    } catch (e) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
    }
  }

  void _handleSignOutWithGoogle() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget._user == null) {
      return GoogleSignInButton(
        onPressed: _handleSignInWithGoogle,
      );
    } else {
      return RaisedButton(
        onPressed: _handleSignOutWithGoogle,
        child: Text('Logout', style: TextStyle(fontSize: 20)),
      );
    }
  }
}
