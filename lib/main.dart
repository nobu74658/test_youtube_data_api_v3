import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:test_youtube_data_api_v3/firebase_options.dart';

final credentialStateProvider = StateProvider<UserCredential?>((ref) => null);
final credentialProvider = Provider((ref) => ref.read(credentialStateProvider));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                final UserCredential userCredential = await signInWithGoogle();
                ref.watch(credentialStateProvider.notifier).state =
                    userCredential;
                print("Google認証");
              },
              child: const Text("Gmail認証"),
            ),
            ElevatedButton(
              onPressed: () async {
                ///youtube data api v3 -> get activities
                // try {
                //   await FirebaseAuth.instance.signOut();
                //   print("signOut!!!");
                // } catch (e) {
                //   print("error: $e");
                // }
                //
                // final UserCredential newUserCredential = await signInWithGoogle();
                // ref.watch(credentialStateProvider.notifier).state = newUserCredential;
                final UserCredential? userCredential =
                ref.read(credentialProvider);
                final response = await http.get(
                  Uri.parse(
                    "https://www.googleapis.com/youtube/v3/activities?access_token=${userCredential?.credential?.accessToken}&part=snippet&home=true",
                  ),
                );

                Map<String, dynamic> json = jsonDecode(response.body);
                print(json);
              },
              child: const Text("activities"),
            ),
            ElevatedButton(
              onPressed: () async {
                ///youtube data api v3 -> get subscription
                final UserCredential? userCredential =
                    ref.read(credentialProvider);
                final response = await http.get(
                  Uri.parse(
                    "https://www.googleapis.com/youtube/v3/subscriptions?access_token=${userCredential?.credential?.accessToken}&part=snippet&mine=true",
                  ),
                );
                print(response.body);
                Map<String, dynamic> json = jsonDecode(response.body);
                print(json);
              },
              child: const Text("subscription"),
            ),
          ],
        ),
      ),
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    ///権限をScopeで限定的に与える
    final GoogleSignInAccount? googleUser = await GoogleSignIn(scopes: [
      'email',
      'https://www.googleapis.com/auth/youtube.readonly',
      'https://www.googleapis.com/auth/youtube'
    ]).signIn();

    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    return userCredential;
  }
}
