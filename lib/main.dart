import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
String todayDateKey() {
  final now = DateTime.now();

  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

const String levelPlayAppKey = '28c39d87d';
final ValueNotifier<bool> levelPlayReady =
    ValueNotifier<bool>(false);
class AppLevelPlayInitListener with LevelPlayInitListener {
  @override
  void onInitSuccess(LevelPlayConfiguration configuration) {
    debugPrint(
      'Mzansi Silver: LevelPlay initialized successfully!',
    );

    levelPlayReady.value = true;
  }

  @override
  void onInitFailed(LevelPlayInitError error) {
    levelPlayReady.value = false;

    debugPrint(
      'Mzansi Silver: LevelPlay initialization failed: $error',
    );
  }
}

final appLevelPlayInitListener = AppLevelPlayInitListener();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final initRequest =
      LevelPlayInitRequest.builder(levelPlayAppKey).build();

  await LevelPlay.init(
    initRequest: initRequest,
    initListener: appLevelPlayInitListener,
  );

  runApp(const MzansiSilverApp());
}

// 
//=======================================
//=====================
// MZANSI SILVER APP
// 
//=======================================
//=====================
class MzansiSilverApp extends StatelessWidget {
  const MzansiSilverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mzansi Silver',

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF080808),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Arial',
      ),

      // FRONT DOOR
      home: const AuthGate(),
    );
  }
}
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const MainShell();
        }

        return const WelcomePage();
      },
    );
  }
}
// 
//=======================================
//=====================
// FRONT DOOR / WELCOME
// 
//=======================================
//=====================
class WelcomePage extends StatelessWidget {
const WelcomePage({super.key});
@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFF080808),
body: SafeArea(
child: Padding(
padding: const 
EdgeInsets.symmetric(horizontal: 28),
child: Column(
children: [
const Spacer(),
Container(
width: 115,
height: 115,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: Colors.amber,
boxShadow: [
BoxShadow(
color: Colors.amber.withValues(alpha: .25),
blurRadius: 35,
spreadRadius: 5,
),
 ],
),
child: const Icon(
Icons.diamond,
color: Colors.black,
size: 62,
),
),
const SizedBox(height: 28),
const Text(
'MZANSI SILVER',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 32,
fontWeight: FontWeight.w900,
letterSpacing: 2,
),
),
const SizedBox(height: 10),
const Text(
'WATCH • DISCOVER • EARN',
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.amber,
fontSize: 13,
fontWeight: FontWeight.bold,
letterSpacing: 2,
),
),
const SizedBox(height: 18),
const Text(
'Your journey starts here.\n'
'Discover videos, find treasures and build your Silver.',
textAlign: TextAlign.center,
style: TextStyle(
color: Colors.white54,
fontSize: 14,
height: 1.5,
),
),
const Spacer(),
SizedBox(
width: double.infinity,
child: ElevatedButton(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const CreateAccountPage(),
),
);
},
style: frontDoorButton(),
child: const Text(
'GET STARTED',
style: TextStyle(
fontWeight: FontWeight.w900,
),
),
),
),
const SizedBox(height: 12),
SizedBox(
width: double.infinity,
child: OutlinedButton(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const LoginPage(),
),
);
},
style: OutlinedButton.styleFrom(
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(vertical: 
16),
side: const BorderSide(color: Colors.white24),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(18),
),
),
child: const Text(
'I ALREADY HAVE AN ACCOUNT',
style: TextStyle(
fontWeight: FontWeight.w800,
fontSize: 13,
),
),
),
),
const SizedBox(height: 25),
const Text(
'Your treasure. Your journey. Your Silver.',
style: TextStyle(
color: Colors.white30,
fontSize: 11,
),
),
const SizedBox(height: 15),
],
),
),
),
);
}
}
// 
//=======================================
//=====================
// CREATE ACCOUNT
// 
//=======================================
//=====================
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> createAccount() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Please fill in all fields.';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        errorMessage = 'Password must be at least 6 characters.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // CREATE FIREBASE AUTH ACCOUNT
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user == null) {
        throw Exception('Account creation failed.');
      }

      // SAVE USER DATA TO FIRESTORE
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'username': username,
        'email': email,
        'silver': 0,
'adsWatchedToday': 0,
'totalAdsWatched': 0,
'lastDailyReset': todayDateKey(),
'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainShell(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        if (e.code == 'email-already-in-use') {
          errorMessage = 'An account with this email already exists.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Please enter a valid email address.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Password is too weak.';
        } else {
          errorMessage = 'Account creation failed. Please try again.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),

            const Text(
              'Welcome, Explorer.',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Create your Mzansi Silver account and begin your journey.',
              style: TextStyle(
                color: Colors.white54,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Username',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(
                  Icons.person_outline,
                  color: Colors.amber,
                ),
                filled: true,
                fillColor: const Color(0xFF151515),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Colors.amber,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Colors.amber,
                ),
                filled: true,
                fillColor: const Color(0xFF151515),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Colors.amber,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Colors.amber,
                ),
                filled: true,
                fillColor: const Color(0xFF151515),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Colors.amber,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : createAccount,
                style: frontDoorButton(),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'ENTER MZANSI SILVER',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
// 
//=======================================
//=====================
// LOGIN
// 
//=======================================
//=====================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> loginUser() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainShell(),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'invalid-credential' ||
            e.code == 'invalid-email' ||
            e.code == 'wrong-password' ||
            e.code == 'user-not-found') {
          errorMessage = 'Invalid email or password.';
        } else {
          errorMessage = 'Login failed. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        errorMessage = 'Enter your email address first.';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (!mounted) return;

      setState(() {
        errorMessage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset email sent. Check your inbox.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        if (e.code == 'invalid-email') {
          errorMessage = 'Please enter a valid email address.';
        } else {
          errorMessage =
              'Could not send the reset email. Please try again.';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Something went wrong. Please try again.';
      });
    }
  }
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Login',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            const Center(
              child: Icon(
                Icons.diamond,
                color: Colors.amber,
                size: 70,
              ),
            ),

            const SizedBox(height: 25),

            const Center(
              child: Text(
                'Welcome Back, Explorer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(height: 30),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Colors.amber,
                ),
                filled: true,
                fillColor: const Color(0xFF151515),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Colors.amber,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Colors.amber,
                ),
                filled: true,
                fillColor: const Color(0xFF151515),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Colors.amber,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

           Align(
  alignment: Alignment.centerRight,
  child: TextButton(
    onPressed: isLoading ? null : resetPassword,
    child: const Text(
      'Forgot password?',
      style: TextStyle(color: Colors.amber),
    ),
  ),
),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : loginUser,
                style: frontDoorButton(),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text(
                        'LOGIN',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
// 
//=======================================
//=====================
// FRONT DOOR HELPERS
// 
//=======================================
//=====================
Widget frontDoorField({
required IconData icon,
required String hint,
bool obscureText = false,
}) {
return TextField(
obscureText: obscureText,
style: const TextStyle(color: Colors.white),
decoration: InputDecoration(
hintText: hint,
hintStyle: const TextStyle(color: Colors.white38),
prefixIcon: Icon(
icon,
color: Colors.amber,
),
filled: true,
fillColor: const Color(0xFF151515),
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide: BorderSide.none,
),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(18),
borderSide: const BorderSide(
color: Colors.amber,
),
),
),
);
}
ButtonStyle frontDoorButton() {
return ElevatedButton.styleFrom(
backgroundColor: Colors.amber,
foregroundColor: Colors.black,
padding: const EdgeInsets.symmetric(vertical: 
16),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(18),
),
);
}
// 
//=======================================
//=====================
// MAIN SHELL
// 
//=======================================
//=====================
class MainShell extends StatefulWidget {
const MainShell({super.key});
@override
State<MainShell> createState() => 
_MainShellState();
}
class _MainShellState extends State<MainShell> 
{
int selectedIndex = 0;

int silver = 0;
int adsWatchedToday = 0;
int totalAdsWatched = 0;
String username = 'Mzansi Explorer';

static const int dailyAdLimit = 100;
static const int cashOutTarget = 96000;

bool isLoadingData = true;

@override
void initState() {
  super.initState();
  loadUserData();
}

Future<void> loadUserData() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    if (mounted) {
      setState(() {
        isLoadingData = false;
      });
    }
    return;
  }

  try {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final document = await userRef.get();

    if (document.exists) {
      final data = document.data();

      if (data != null) {
        int savedSilver = (data['silver'] ?? 0) as int;
        int savedAdsWatched =
    (data['adsWatchedToday'] ?? 0) as int;

int savedTotalAds =
    (data['totalAdsWatched'] ?? 0) as int;

String savedUsername =
    (data['username'] ?? 'Mzansi Explorer') as String;
        final savedDate =
            data['lastDailyReset'] as String?;
        final today = todayDateKey();

        // NEW DAY → RESET DAILY AD COUNTER
        if (savedDate != today) {
          savedAdsWatched = 0;

          await userRef.update({
            'adsWatchedToday': 0,
            'lastDailyReset': today,
          });
        }

        if (!mounted) return;

        setState(() {
  silver = savedSilver;
  adsWatchedToday = savedAdsWatched;
  totalAdsWatched = savedTotalAds;
  username = savedUsername;
  isLoadingData = false;
});
      }
    } else {
      if (mounted) {
        setState(() {
          isLoadingData = false;
        });
      }
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        isLoadingData = false;
      });

      showMessage(
        'Could not load your Silver data.',
        icon: Icons.error_outline,
      );
    }
  }
}
@override
Widget build(BuildContext context) {
  if (isLoadingData) {
    return const Scaffold(
      backgroundColor: Color(0xFF080808),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.diamond,
              color: Colors.amber,
              size: 60,
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              color: Colors.amber,
            ),
            SizedBox(height: 15),
            Text(
              'Loading your Silver...',
              style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  final pages = [
HomePage(
  silver: silver,
  adsWatched: adsWatchedToday,
  dailyLimit: dailyAdLimit,
  onWatch: () {
    setState(() => selectedIndex = 1);
  },
  onRewards: () {
    setState(() => selectedIndex = 2);
  },
  onWallet: () {
    setState(() => selectedIndex = 3);
  },
  onProfile: () {
    setState(() => selectedIndex = 4);
  },
),
WatchPage(
silver: silver,
adsWatched: adsWatchedToday,
dailyLimit: dailyAdLimit,
onReward: giveSilver,
onMessage: showMessage,
),
RewardsPage(
  silver: silver,
  onMessage: showMessage,
  onReward: (reward) {
    setState(() {
      silver += reward;
    });
  },
),
WalletPage(
  silver: silver,
  cashOutTarget: cashOutTarget,
  onMessage: showMessage,
  onCashOut: ({
    required String payoutMethod,
    required Map<String, dynamic> payoutDetails,
  }) =>
      requestCashOut(
        payoutMethod: payoutMethod,
        payoutDetails: payoutDetails,
      ),
),
ProfilePage(
  username: username,
  silver: silver,
  adsWatched: adsWatchedToday,
  dailyLimit: dailyAdLimit,
  onMessage: showMessage,
),
];
return Scaffold(
  body: IndexedStack(
    index: selectedIndex,
    children: pages,
  ),
  bottomNavigationBar: MzansiNavigationBar(
    selectedIndex: selectedIndex,
    onChanged: (index) {
      setState(() => selectedIndex = index);
    },
  ),
);
}
Future<void> giveSilver() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    showMessage(
      'You are not logged in.',
      icon: Icons.lock,
    );
    return;
  }

  const int reward = 120;

  try {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    final transactionId =
        '${user.uid}_${DateTime.now().microsecondsSinceEpoch}';

    final transactionRef = FirebaseFirestore.instance
        .collection('silverTransactions')
        .doc(transactionId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);

      if (!userSnapshot.exists) {
        throw Exception('User data not found.');
      }

      final data = userSnapshot.data() as Map<String, dynamic>;

      int currentSilver = (data['silver'] ?? 0) as int;
      int currentAdsToday = (data['adsWatchedToday'] ?? 0) as int;
      int currentTotalAds = (data['totalAdsWatched'] ?? 0) as int;

      final lastDailyReset = data['lastDailyReset'];
      final today = todayDateKey();

      // Reset the daily counter if a new day has started.
      if (lastDailyReset != today) {
        currentAdsToday = 0;
      }

      // Daily protection.
      if (currentAdsToday >= dailyAdLimit) {
        throw Exception(
          'You have reached your daily ad limit.',
        );
      }

      final newAdsToday = currentAdsToday + 1;
      final newTotalAds = currentTotalAds + 1;
      final newSilver = currentSilver + reward;

      transaction.update(userRef, {
        'silver': newSilver,
        'adsWatchedToday': newAdsToday,
        'totalAdsWatched': newTotalAds,
        'lastDailyReset': today,
      });

      transaction.set(transactionRef, {
        'uid': user.uid,
        'type': 'ad_reward',
        'reward': reward,
        'adsWatchedToday': newAdsToday,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    if (!mounted) return;

    setState(() {
      silver += reward;
      adsWatchedToday += 1;
      totalAdsWatched += 1;
    });

    showSilverReward();
  } catch (e) {
    if (!mounted) return;

    showMessage(
      e.toString().replaceFirst('Exception: ', ''),
      icon: Icons.error_outline,
    );
  }
}

Future<void> requestCashOut({
  required String payoutMethod,
  required Map<String, dynamic> payoutDetails,
}) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    showMessage(
      'You are not logged in.',
      icon: Icons.lock,
    );
    return;
  }

  if (silver < cashOutTarget) {
    showMessage(
      'You need ${cashOutTarget - silver} more Silver to cash out.',
      icon: Icons.lock,
    );
    return;
  }

  try {
    final firestore = FirebaseFirestore.instance;

    final userRef = firestore
        .collection('users')
        .doc(user.uid);

    final withdrawalRef = firestore
        .collection('withdrawalRequests')
        .doc();

    await firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);

      if (!userSnapshot.exists) {
        throw Exception('User data not found.');
      }

      final data =
          userSnapshot.data() as Map<String, dynamic>;

      final currentSilver =
          (data['silver'] ?? 0) as int;

      if (currentSilver < cashOutTarget) {
        throw Exception(
          'You do not have enough Silver to cash out.',
        );
      }

      final newSilver =
          currentSilver - cashOutTarget;

      transaction.update(userRef, {
        'silver': newSilver,
      });

      transaction.set(withdrawalRef, {
  'uid': user.uid,
  'payoutMethod': payoutMethod,
  'payoutDetails': payoutDetails,
  'silverAmount': cashOutTarget,
  'cashAmount': 20,
  'status': 'pending',
  'createdAt': FieldValue.serverTimestamp(),
});
    });

    if (!mounted) return;

    setState(() {
      silver -= cashOutTarget;
    });

    showMessage(
      'Cash out request submitted successfully.',
      icon: Icons.check_circle,
    );
  } catch (e) {
    if (!mounted) return;

    showMessage(
      e.toString().replaceFirst('Exception: ', ''),
      icon: Icons.error_outline,
    );
  }
}
 
void showSilverReward() {
showDialog(
context: context,
barrierDismissible: false,
builder: (context) {
return Dialog(
backgroundColor: const Color(0xFF151515),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(28),
),
child: Padding(
padding: const EdgeInsets.all(28),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 80,
height: 80,
decoration: const BoxDecoration(
shape: BoxShape.circle,
color: Colors.amber,
),
child: const Icon(
Icons.monetization_on,
color: Colors.black,
size: 45,
),
),
const SizedBox(height: 18),
const Text(
'TREASURE FOUND!',
style: TextStyle(
fontSize: 21,
fontWeight: FontWeight.w900,
),
),
const SizedBox(height: 8),
const Text(
'+120 SILVER',
style: TextStyle(
color: Colors.amber,
fontSize: 27,
fontWeight: FontWeight.w900,
),
),
const SizedBox(height: 8),
Text(
'Your balance is now $silver Silver.',
textAlign: TextAlign.center,
style: const TextStyle(
color: Colors.white60,
),
),
const SizedBox(height: 22),
SizedBox(
width: double.infinity,
child: ElevatedButton(
onPressed: () => Navigator.pop(context),
style: amberButton(),
child: const Text(
'CONTINUE',
style: TextStyle(
fontWeight: FontWeight.w900,
),
),
),
),
],
),
),
);
},
);
}
void showMessage(
String message, {
IconData? icon,
}) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
backgroundColor: const Color(0xFF181818),
behavior: SnackBarBehavior.floating,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(16),
),
content: Row(
children: [
Icon(
icon ?? Icons.info_outline,
color: Colors.amber,
),
const SizedBox(width: 10),
Expanded(
child: Text(message),
),
 ],
),
),
);
}
}
// 
//=======================================
//=====================
// BOTTOM NAVIGATION
// 
//=======================================
//=====================
class MzansiNavigationBar extends 
StatelessWidget {
final int selectedIndex;
final ValueChanged<int> onChanged;
const MzansiNavigationBar({
super.key,
required this.selectedIndex,
required this.onChanged,
});
@override
Widget build(BuildContext context) {
return Container(
decoration: const BoxDecoration(
color: Color(0xFF101010),
border: Border(
top: BorderSide(
color: Colors.white12,
),
),
),
child: SafeArea(
child: Padding(
padding: const EdgeInsets.symmetric(vertical: 
8),
child: Row(
mainAxisAlignment: 
MainAxisAlignment.spaceAround,
children: [
navItem(Icons.home_rounded, 'Home', 0),
navItem(Icons.play_circle_fill_rounded, 'Watch', 
1),
navItem(Icons.card_giftcard_rounded, 'Rewards', 
2),
navItem(
Icons.account_balance_wallet_rounded,
'Wallet',
3,
),
navItem(Icons.person_rounded, 'Profile', 4),
 ],
),
),
),
);
}
Widget navItem(
IconData icon,
String label,
int index,
) {
final active = selectedIndex == index;
return GestureDetector(
onTap: () => onChanged(index),
child: SizedBox(
width: 65,
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
icon,
size: 23,
color: active ? Colors.amber : Colors.white54,
),
const SizedBox(height: 4),
Text(
label,
style: TextStyle(
fontSize: 10,
color: active ? Colors.amber : Colors.white54,
fontWeight:
active ? FontWeight.bold : FontWeight.normal,
),
),
 ],
),
),
);
}
}
// 
//=======================================
//=====================
// HOME PAGE
// 
//=======================================
//=====================
class HomePage extends StatelessWidget {
  final int silver;
  final int adsWatched;
  final int dailyLimit;

  final VoidCallback onWatch;
  final VoidCallback onRewards;
  final VoidCallback onWallet;
  final VoidCallback onProfile;

  const HomePage({
    super.key,
    required this.silver,
    required this.adsWatched,
    required this.dailyLimit,
    required this.onWatch,
    required this.onRewards,
    required this.onWallet,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        (adsWatched / dailyLimit).clamp(0.0, 1.0);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // HEADER
            Row(
              children: [
                silverLogo(),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'MZANSI SILVER',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                silverPill(silver),
              ],
            ),

            const SizedBox(height: 30),

            // TREASURE BALANCE
            const Text(
              'Your Treasure',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white60,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              '$silver SILVER',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.amber,
              ),
            ),

            const SizedBox(height: 25),

            // DAILY JOURNEY
            Container(
              padding: const EdgeInsets.all(20),
              decoration: cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.explore,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 10),
                    const Expanded(
  child: Text(
    "TODAY'S JOURNEY",
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(
      fontWeight: FontWeight.w900,
    ),
  ),
),
                      const SizedBox(height: 20),
     
                      Text(
                        '$adsWatched / $dailyLimit',
                        style: const TextStyle(
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 9,
                      backgroundColor: Colors.white10,
                      valueColor:
                          const AlwaysStoppedAnimation(
                        Colors.amber,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    '${dailyLimit - adsWatched} earning opportunities remaining today.',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // START EXPLORING
            GestureDetector(
              onTap: onWatch,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF332500),
                      Color(0xFF171717),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: .25),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -25,
                      bottom: -25,
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 160,
                        color: Colors.amber.withValues(alpha: .08),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Text(
                            'READY FOR A NEW\nTREASURE?',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Scroll through videos and discover earning opportunities.',
                            style: TextStyle(
                              color: Colors.white60,
                            ),
                          ),

                          const SizedBox(height: 15),

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'START EXPLORING',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // QUICK ACTIONS — ROW 1
            Row(
              children: [
                quickCard(
                  Icons.play_circle_fill,
                  'Watch',
                  onWatch,
                ),
                const SizedBox(width: 12),
                quickCard(
                  Icons.card_giftcard,
                  'Rewards',
                  onRewards,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // QUICK ACTIONS — ROW 2
            Row(
              children: [
                quickCard(
                  Icons.account_balance_wallet,
                  'Wallet',
                  onWallet,
                ),
                const SizedBox(width: 12),
                quickCard(
                  Icons.person,
                  'Profile',
                  onProfile,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget quickCard(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: cardDecoration(),
          child: Column(
            children: [
              Icon(
                icon,
                color: Colors.amber,
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
// 
//=======================================
//=====================
// WATCH PAGE
// 
//=======================================
//=====================
class PexelsVideoService {
  static const String _baseUrl =
      'https://api.pexels.com/v1/videos/popular';

  static Future<List<String>> fetchVideos({
    required String apiKey,
    String query = '',
    int perPage = 80,
    int page = 1,
  }) async {
    final safePerPage = perPage.clamp(1, 80);

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'per_page': safePerPage.toString(),
        'page': page.toString(),
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': apiKey,
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Pexels request failed: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);
    final List videos = data['videos'] ?? [];
    final List<String> videoUrls = [];

    for (final video in videos) {
      final files = video['video_files'] as List? ?? [];

      String? selectedUrl;
      double smallestSize = double.infinity;

      for (final file in files) {
        final link = file['link'];
        final width = file['width'];
        final height = file['height'];
        final fileSize = file['file_size'];

        if (link is! String ||
            width is! num ||
            height is! num ||
            height <= width) {
          continue;
        }

        final double sizeScore = fileSize is num
            ? fileSize.toDouble()
            : (width * height).toDouble();

        if (sizeScore < smallestSize) {
          smallestSize = sizeScore;
          selectedUrl = link;
        }
      }

      if (selectedUrl != null) {
        videoUrls.add(selectedUrl);
      }
    }

    return videoUrls;
  }
}

class PixabayVideoService {
  static const String _baseUrl =
      'https://pixabay.com/api/videos/';

  static Future<List<String>> fetchVideos({
    required String apiKey,
    String query = '',
    int perPage = 150,
    int page = 1,
  }) async {
    final safePerPage = perPage.clamp(3, 200);

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'key': apiKey,
        if (query.isNotEmpty) 'q': query,
        'per_page': safePerPage.toString(),
        'page': page.toString(),
        'safesearch': 'true',
        'order': 'popular',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Pixabay request failed: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);
    final List hits = data['hits'] ?? [];
    final List<String> videoUrls = [];

    for (final hit in hits) {
      final videoSizes =
          hit['videos'] as Map<String, dynamic>? ?? {};

      final smallVideo =
          videoSizes['small'] as Map<String, dynamic>?;

      final mediumVideo =
          videoSizes['medium'] as Map<String, dynamic>?;

      final smallUrl = smallVideo?['url'];
      final mediumUrl = mediumVideo?['url'];

      String? selectedUrl;

      if (smallUrl is String && smallUrl.isNotEmpty) {
        selectedUrl = smallUrl;
      } else if (mediumUrl is String &&
          mediumUrl.isNotEmpty) {
        selectedUrl = mediumUrl;
      }

      if (selectedUrl != null) {
        videoUrls.add(selectedUrl);
      }
    }

    return videoUrls;
  }
}

class WatchPage extends StatefulWidget {
final int silver;
final int adsWatched;
final int dailyLimit;
final VoidCallback onReward;
final void Function(String, {IconData? icon}) 
onMessage;
const WatchPage({
super.key,
required this.silver,
required this.adsWatched,
required this.dailyLimit,
required this.onReward,
required this.onMessage,
});
@override
State<WatchPage> createState() => 
_WatchPageState();
}
class _WatchPageState extends State<WatchPage>
    with LevelPlayRewardedAdListener {
  final PageController controller = PageController();

  bool isEarning = false;
  bool isLoadingVideos = true;
  bool isLoadingMoreVideos = false;
  bool _rewardGrantedForCurrentAd = false;
  bool showWatchIntro = true;

  String? videoError;

  int currentPage = 0;

  List<String> playedVideos = [];
List<String> videos = [];

static const String _playedVideosKey =
    'mzansi_silver_played_videos';

Future<void> _loadPlayedVideoHistory() async {
  final prefs = await SharedPreferences.getInstance();
  playedVideos = prefs.getStringList(_playedVideosKey) ?? [];

}

Future<void> _savePlayedVideoHistory() async {
  final prefs = await SharedPreferences.getInstance();

  final saved = await prefs.setStringList(
    _playedVideosKey,
    playedVideos,
  );

  debugPrint(
    'VIDEO HISTORY SAVE: ${playedVideos.length} videos, success=$saved',
  );
}

  LevelPlayRewardedAd? _rewardedAd;
  bool _isRewardedAdLoading = false;

  static const String _rewardedAdUnitId =
      'jsblvip2fma7g1oh';

  void _loadRewardedAd() {
  if (kIsWeb ||
      !mounted ||
      !levelPlayReady.value ||
      _isRewardedAdLoading ||
      _rewardedAd != null) {
    return;
  }
    setState(() {
      _isRewardedAdLoading = true;
    });

    final ad = LevelPlayRewardedAd(
      adUnitId: _rewardedAdUnitId,
    );

    _rewardedAd = ad;
    ad.setListener(this);
    ad.loadAd();
  }

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    if (!mounted) return;

    setState(() {
      _isRewardedAdLoading = false;
    });

    debugPrint('Mzansi Silver: LevelPlay rewarded ad loaded.');
  }

  @override
void onAdLoadFailed(LevelPlayAdError error) {
  if (!mounted) return;

  setState(() {
    _rewardedAd = null;
    _isRewardedAdLoading = false;
  });

  debugPrint(
    'LEVELPLAY LOAD ERROR: '
    'code=${error.errorCode}, '
    'message=${error.errorMessage}, '
    'adUnit=${error.adUnitId}',
  );
}
  @override
  void onAdRewarded(
    LevelPlayReward reward,
    LevelPlayAdInfo adInfo,
  ) {
    if (_rewardGrantedForCurrentAd) return;

    _rewardGrantedForCurrentAd = true;
    widget.onReward();

    debugPrint('Mzansi Silver: Reward granted.');
  }

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) {
    if (!mounted) return;

    setState(() {
      isEarning = false;
       _rewardedAd = null;
    });

   
    _loadRewardedAd();
  }

  @override
  void onAdDisplayFailed(
    LevelPlayAdError error,
    LevelPlayAdInfo adInfo,
  ) {
    if (!mounted) return;

    setState(() {
      isEarning = false;
      _rewardedAd = null;
      _isRewardedAdLoading = false;
    });

    debugPrint(
  'LEVELPLAY LOAD FAILED: '
  'code=${error.errorCode}, '
  'message=${error.errorMessage}',
);

    widget.onMessage(
      'The sponsored opportunity could not be shown. Please try again.',
      icon: Icons.error_outline,
    );

    _loadRewardedAd();
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}

@override
void initState() {
  super.initState();

  _prepareVideos();

  levelPlayReady.addListener(
    _onLevelPlayReadyChanged,
  );

  if (levelPlayReady.value) {
    _loadRewardedAd();
  }
}

void _onLevelPlayReadyChanged() {
  if (levelPlayReady.value && mounted) {
    _loadRewardedAd();
  }
}

Future<void> _prepareVideos() async {
  await _loadPlayedVideoHistory();

  if (!mounted) return;

  await _loadPexelsVideos();
}
  Future<void> _loadPexelsVideos() async {
  if (isLoadingMoreVideos) return;

  isLoadingMoreVideos = true;

  const pexelsApiKey =
      String.fromEnvironment('PEXELS_API_KEY');
  const pixabayApiKey =
      String.fromEnvironment('PIXABAY_API_KEY');

  final List<String> loadedVideos = [];
  final List<String> sourceErrors = [];

  try {
    // Fetch multiple pages until we have enough videos.
    if (pexelsApiKey.isNotEmpty) {
      try {
        for (int page = 1;
            page <= 3 && loadedVideos.length < 150;
            page++) {
          final results =
              await PexelsVideoService.fetchVideos(
            apiKey: pexelsApiKey,
            perPage: 80,
            page: page,
          );

          loadedVideos.addAll(results);

          if (results.isEmpty) break;
        }
      } catch (e) {
        sourceErrors.add('Pexels: $e');
        debugPrint('Pexels video loading failed: $e');
      }
    }

    // Pixabay can return up to 150 videos per request.
    if (pixabayApiKey.isNotEmpty &&
        loadedVideos.length < 150) {
      try {
        final results =
            await PixabayVideoService.fetchVideos(
          apiKey: pixabayApiKey,
          perPage: 150,
          page: 1,
        );

        loadedVideos.addAll(results);
      } catch (e) {
        sourceErrors.add('Pixabay: $e');
        debugPrint('Pixabay video loading failed: $e');
      }
    }

    if (pexelsApiKey.isEmpty &&
        pixabayApiKey.isEmpty) {
      sourceErrors.add(
        'No video API keys configured. '
        'Add your Pexels and Pixabay keys to the build command.',
      );
    }

    if (!mounted) return;

    // Shuffle, remove duplicate URLs, and exclude played videos.
    final shuffledVideos = loadedVideos.toSet().toList()
      ..shuffle(Random());

    final existingVideos = videos.toSet();

    final newVideos = shuffledVideos
        .where((video) =>
            !playedVideos.contains(video) &&
            !existingVideos.contains(video))
        .take(150)
        .toList();

    setState(() {
      videos = [...videos, ...newVideos];
      isLoadingVideos = false;

      if (videos.isEmpty) {
        videoError = sourceErrors.isNotEmpty
            ? sourceErrors.join('\n\n')
            : 'No new videos were found. Please try again.';
      } else {
        videoError = null;
      }
    });
  } finally {
    isLoadingMoreVideos = false;
  }
}

  @override
void dispose() {
  levelPlayReady.removeListener(
    _onLevelPlayReadyChanged,
  );

  controller.dispose();
  super.dispose();
}
  @override
  Widget build(BuildContext context) {
    if (isLoadingVideos) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (videoError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Pexels error:\n\n$videoError',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: controller,
          scrollDirection: Axis.vertical,
          itemCount: videos.length,
          onPageChanged: (index) {
  final video = videos[index];

  if (!playedVideos.contains(video)) {
    playedVideos.add(video);
    _savePlayedVideoHistory();
  }

  setState(() {
    currentPage = index;
    if (index != 0) showWatchIntro = false;
  });

  if (index >= videos.length - 2) {
    _loadPexelsVideos();
  }
},
          itemBuilder: (context, index) {
            return WatchVideoCard(
              videoUrl: videos[index],
              index: index,
              isCurrent: index == currentPage,
              onMessage: widget.onMessage,
              onEarn: () => showEarnExperience(context),
            );
          },
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                silverLogo(),
                const SizedBox(width: 9),
                const Text(
                  'MZANSI SILVER',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                silverPill(widget.silver),
              ],
            ),
          ),
        ),
        Positioned(
          right: 7,
          top: MediaQuery.of(context).size.height * .48,
          child: const Column(
            children: [
              Icon(Icons.keyboard_arrow_up, color: Colors.white38),
              Text(
                'SWIPE',
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.white38,
                  letterSpacing: 1,
                ),
              ),
              Icon(Icons.keyboard_arrow_down, color: Colors.white38),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> showEarnExperience(BuildContext context) async {
    if (isEarning) return;

    if (widget.adsWatched >= widget.dailyLimit) {
      widget.onMessage(
        'Daily earning limit reached. Come back tomorrow.',
        icon: Icons.lock,
      );
      return;
    }

    final ad = _rewardedAd;

    if (ad == null) {
      widget.onMessage(
        'Sponsored opportunity is loading. Please try again shortly.',
        icon: Icons.hourglass_empty,
      );
      _loadRewardedAd();
      return;
    }

    if (!await ad.isAdReady()) {
      if (!mounted) return;

      setState(() {
        _rewardedAd = null;
        _isRewardedAdLoading = false;
      });

      widget.onMessage(
        'Sponsored opportunity is not ready yet. Please try again shortly.',
        icon: Icons.hourglass_empty,
      );

      _loadRewardedAd();
      return;
    }

    if (!mounted) return;

    setState(() {
      isEarning = true;
      _rewardGrantedForCurrentAd = false;
      _rewardedAd = null;
    });

    try {
      ad.showAd(placementName: 'Default');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isEarning = false;
      });

      debugPrint('Mzansi Silver: Could not show LevelPlay ad: $e');
      _loadRewardedAd();
    }
  }
}
// 
//=======================================
//=====================
// VIDEO CARD
// 
//=======================================
//=====================
class WatchVideoCard extends StatefulWidget {
final String videoUrl;
final int index;
final bool isCurrent;
final void Function(String, {IconData? icon}) 
onMessage;
final VoidCallback onEarn;
const WatchVideoCard({
super.key,
required this.videoUrl,
required this.index,
required this.isCurrent,
required this.onMessage,
required this.onEarn,
});
@override
State<WatchVideoCard> createState() =>
_WatchVideoCardState();
}
class _WatchVideoCardState extends State<WatchVideoCard> {
  VideoPlayerController? videoController;

  bool liked = false;
  bool initialized = false;
  bool isInitializing = false;

  @override
  void initState() {
    super.initState();

    if (widget.isCurrent) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    if (isInitializing || initialized || !widget.isCurrent) {
      return;
    }

    isInitializing = true;

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    videoController = controller;

    try {
      await controller.initialize();
      debugPrint(
  'VIDEO AUDIO CHECK: '
  '${controller.value.size} | '
  'hasError: ${controller.value.hasError} | '
  'error: ${controller.value.errorDescription}',
);

      if (!mounted || videoController != controller) {
        await controller.dispose();
        return;
      }

      await controller.setVolume(1.0);
      await controller.setLooping(true);

      if (!mounted || !widget.isCurrent) {
        await controller.pause();
        return;
      }

      setState(() {
        initialized = true;
      });

      await controller.play();
    } catch (error) {
      debugPrint('Video initialization failed: $error');

      if (mounted && videoController == controller) {
        setState(() {
          initialized = false;
        });
      }

      await controller.dispose();

      if (videoController == controller) {
        videoController = null;
      }
    } finally {
      isInitializing = false;
    }
  }

  @override
  void didUpdateWidget(covariant WatchVideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.videoUrl != widget.videoUrl) {
      final oldController = videoController;

      videoController = null;
      initialized = false;
      isInitializing = false;

      if (oldController != null) {
        oldController.dispose();
      }
    }

    if (widget.isCurrent) {
      _initializeVideo();
    } else {
      videoController?.pause();
    }
  }

@override
void dispose() {
  videoController?.dispose();
  super.dispose();
}

@override
Widget build(BuildContext context) {
  final controller = videoController;

  return Stack(
    fit: StackFit.expand,
    children: [
      // VIDEO PLAYER — PHONE-SIZE PORTRAIT
      Container(
        color: Colors.black,
        width: double.infinity,
        height: double.infinity,
        child: initialized &&
                controller != null &&
                controller.value.isInitialized
            ? Center(
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  ),
                ),
              )
            : const Center(
                child: CircularProgressIndicator(
                  color: Colors.amber,
                ),
              ),
      ),

      // BOTTOM GRADIENT
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.transparent,
              Color(0xDD000000),
            ],
          ),
        ),
      ),

      // PLAY / PAUSE BUTTON
      Center(
        child: GestureDetector(
          onTap: () {
            if (controller == null ||
                !controller.value.isInitialized) {
              return;
            }

            setState(() {
              if (controller.value.isPlaying) {
                controller.pause();
              } else {
                controller.play();
              }
            });
          },
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.35),
            ),
            child: Icon(
              controller != null &&
                      controller.value.isInitialized &&
                      controller.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.white70,
              size: 38,
            ),
          ),
        ),
      ),

      // RIGHT VIDEO CONTROLS
      Positioned(
        right: 12,
        bottom: 130,
        child: Column(
          children: [
            watchControl(
              liked
                  ? Icons.favorite
                  : Icons.favorite_border,
              'Like',
              active: liked,
              onTap: () {
                setState(() => liked = !liked);
              },
            ),
            const SizedBox(height: 17),
            watchControl(
              Icons.monetization_on_outlined,
              'Earn',
              onTap: widget.onEarn,
            ),
          ],
),
    ),

    // VIDEO DESCRIPTION
if (widget.index == 0)
  Positioned(
    left: 18,
    right: 95,
    bottom: 105,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.amber,
              child: Icon(
                Icons.diamond,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 9),
            Text(
              'Mzansi Silver',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Discover Your Next Adventure',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Explore videos, discover something new, and watch for opportunities to earn Silver.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
      ],
    ),
  ),
],
);
}

Widget watchControl(
  IconData icon,
  String label, {
  required VoidCallback onTap,
  bool active = false,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Column(
children: [
Container(
width: 48,
height: 48,
decoration: BoxDecoration(
shape: BoxShape.circle,
color:
Colors.black.withValues(alpha: .55),
border: Border.all(
color: Colors.white12,
),
),
child: Icon(
icon,
color:
active ? Colors.redAccent : Colors.white,
size: 25,
),
),
const SizedBox(height: 4),
Text(
label,
style: const TextStyle(
fontSize: 9,
fontWeight: FontWeight.w600,
),
),
],
),
);
}
void showMoreMenu(BuildContext context) {
showModalBottomSheet(
context: context,
backgroundColor: const Color(0xFF151515),
shape: const RoundedRectangleBorder(
borderRadius: BorderRadius.vertical(
top: Radius.circular(28),
),
),
builder: (context) {
return SafeArea(
child: Padding(
padding: const EdgeInsets.fromLTRB(
20,
12,
20,
20,
),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Container(
width: 45,
height: 5,
decoration: BoxDecoration(
color: Colors.white24,
borderRadius:
BorderRadius.circular(10),
),
),
const SizedBox(height: 18),
const Text(
'More',
style: TextStyle(
fontSize: 22,
fontWeight: FontWeight.w900,
),
),
const SizedBox(height: 12),
ListTile(
leading: const Icon(
Icons.flag_outlined,
color: Colors.amber,
),
title: const Text('Report video'),
onTap: () {
Navigator.pop(context);
widget.onMessage(
'Report option selected.',
icon: Icons.flag_outlined,
);
},
),
ListTile(
leading: const Icon(
Icons.visibility_off_outlined,
color: Colors.amber,
),
title:
const Text('Not interested'),
onTap: () {
Navigator.pop(context);
widget.onMessage(
'We will show you fewer videos like this.',
icon: Icons.visibility_off_outlined,
);
},
),
ListTile(
leading: const Icon(
Icons.info_outline,
color: Colors.amber,
),
title:
const Text('About this video'),
onTap: () {
Navigator.pop(context);
widget.onMessage(
'More video information will be available later.',
icon: Icons.info_outline,
);
},
),
],
),
),
);
},
);
}
}
// 
//=======================================
//=====================
// REWARDS PAGE
// 
//=======================================
//=====================
class RewardsPage extends StatefulWidget {
final int silver;
final void Function(String, {IconData? icon}) onMessage;
final void Function(int) onReward;

const RewardsPage({
  super.key,
  required this.silver,
  required this.onMessage,
  required this.onReward,
});
@override
State<RewardsPage> createState() =>
_RewardsPageState();
}
class _RewardsPageState extends 
State<RewardsPage> {
bool wheelUsed = false;
bool isLoadingWheel = true;
@override
void initState() {
  super.initState();
  loadWheelStatus();
}

Future<void> loadWheelStatus() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    if (mounted) {
      setState(() {
        isLoadingWheel = false;
      });
    }
    return;
  }

  try {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final document = await userRef.get();

    if (!document.exists) {
      if (mounted) {
        setState(() {
          isLoadingWheel = false;
        });
      }
      return;
    }

    final data = document.data();

    final lastWheelDate =
        data?['lastWheelDate'] as String?;

    final today = todayDateKey();

    if (mounted) {
      setState(() {
        wheelUsed = lastWheelDate == today;
        isLoadingWheel = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        isLoadingWheel = false;
      });

      widget.onMessage(
        'Could not load your daily wheel status.',
        icon: Icons.error_outline,
      );
    }
  }
}
Future<void> spinWheel() async {
  if (isLoadingWheel || wheelUsed) {
    return;
  }

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    widget.onMessage(
      'You are not logged in.',
      icon: Icons.lock,
    );
    return;
  }

  try {
    setState(() {
      isLoadingWheel = true;
    });

    final reward = 200 + Random().nextInt(201);

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final transactionId =
        '${user.uid}wheel${DateTime.now().microsecondsSinceEpoch}';

    final transactionRef = FirebaseFirestore.instance
        .collection('silverTransactions')
        .doc(transactionId);

    await FirebaseFirestore.instance.runTransaction(
      (transaction) async {
        final userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists) {
          throw Exception('User data not found.');
        }

        final data =
            userSnapshot.data() as Map<String, dynamic>;

        int currentSilver =
            (data['silver'] ?? 0) as int;

        final lastWheelDate =
            data['lastWheelDate'];

        final today = todayDateKey();

        if (lastWheelDate == today) {
          throw Exception(
            'You have already spun the Treasure Wheel today.',
          );
        }

        final newSilver =
            currentSilver + reward;

        transaction.update(userRef, {
          'silver': newSilver,
          'lastWheelDate': today,
        });

        transaction.set(transactionRef, {
          'uid': user.uid,
          'type': 'wheel_reward',
          'reward': reward,
          'createdAt': FieldValue.serverTimestamp(),
        });
      },
    );

    if (!mounted) return;

    setState(() {
      wheelUsed = true;
      isLoadingWheel = false;
    });

    widget.onReward(reward);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('TREASURE FOUND! 🏴‍☠️'),
          content: Text(
            '+$reward SILVER',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('CLAIM'),
            ),
          ],
        );
      },
    );
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoadingWheel = false;
    });

    widget.onMessage(
      e.toString().replaceFirst('Exception: ', ''),
      icon: Icons.error_outline,
    );
  }
}
@override
Widget build(BuildContext context) {
return SafeArea(
child: ListView(
padding: const EdgeInsets.all(18),
children: [
const SizedBox(height: 10),
const Text(
'Rewards',
style: TextStyle(
fontSize: 30,
fontWeight: FontWeight.w900,
),
),
const SizedBox(height: 6),
const Text(
'Your treasure room.',
style: TextStyle(
  color:Colors.white54,
            ),
          ),

          const SizedBox(height: 25),

          Container(
            padding: const EdgeInsets.all(22),
            decoration: cardDecoration(),
            child: Column(
              children: [
                const Icon(
                  Icons.casino,
                  color: Colors.amber,
                  size: 55,
                ),

                const SizedBox(height: 15),

                const Text(
                  'DAILY TREASURE WHEEL',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Spin once every day and discover a Silver reward.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                   onPressed: (wheelUsed || isLoadingWheel)
    ? null
    : spinWheel,
                    style: amberButton(),
                    child: Text(
  isLoadingWheel
      ? 'LOADING...'
      : wheelUsed
          ? 'WHEEL USED TODAY'
          : 'SPIN THE WHEEL',
  style: const TextStyle(
    fontWeight: FontWeight.w900,
  ),
),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(22),
            decoration: cardDecoration(),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.amber,
                  size: 35,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CURRENT SILVER',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${widget.silver} Silver',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WALLET PAGE
// ============================================================

class WalletPage extends StatefulWidget {
  final int silver;
  final int cashOutTarget;
  final void Function(String, {IconData? icon}) onMessage;

  final Future<void> Function({
    required String payoutMethod,
    required Map<String, dynamic> payoutDetails,
  }) onCashOut;

  const WalletPage({
    super.key,
    required this.silver,
    required this.cashOutTarget,
    required this.onMessage,
    required this.onCashOut,
  });

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final TextEditingController accountHolderController =
      TextEditingController();

  final TextEditingController bankNameController =
      TextEditingController();

  final TextEditingController accountNumberController =
      TextEditingController();

  final TextEditingController walletProviderController =
      TextEditingController();

  final TextEditingController walletNumberController =
      TextEditingController();

  String selectedMethod = 'Bank / EFT';
  bool isSubmitting = false;

  @override
  void dispose() {
    accountHolderController.dispose();
    bankNameController.dispose();
    accountNumberController.dispose();
    walletProviderController.dispose();
    walletNumberController.dispose();
    super.dispose();
  }

  // ==========================================================
  // WITHDRAWAL HISTORY
  // ==========================================================

  Stream<QuerySnapshot> withdrawalHistoryStream() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('withdrawalRequests')
        .where('uid', isEqualTo: user.uid)
        .snapshots();
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.greenAccent;

      case 'processing':
        return Colors.lightBlueAccent;

      case 'rejected':
        return Colors.redAccent;

      default:
        return Colors.amber;
    }
  }

  String formatStatus(String status) {
    if (status.isEmpty) {
      return 'Pending';
    }

    return status[0].toUpperCase() +
        status.substring(1).toLowerCase();
  }

  // ==========================================================
  // CASH OUT CONFIRMATION
  // ==========================================================

  void showCashOutConfirmation(BuildContext context) {
    final remaining =
        (widget.cashOutTarget - widget.silver)
            .clamp(0, widget.cashOutTarget);

    if (widget.silver < widget.cashOutTarget) {
      widget.onMessage(
        'You need $remaining more Silver to cash out.',
        icon: Icons.lock,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151515),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  22,
                  12,
                  22,
                  24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Icon(
                      Icons.payments_outlined,
                      color: Colors.amber,
                      size: 50,
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'CASH OUT R20',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Choose your payout method and enter your details.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 22),

                    GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          selectedMethod = 'Bank / EFT';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: selectedMethod == 'Bank / EFT'
                              ? Colors.amber.withValues(alpha: .10)
                              : Colors.black26,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: selectedMethod == 'Bank / EFT'
                                ? Colors.amber
                                : Colors.white10,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_balance,
                              color:
                                  selectedMethod == 'Bank / EFT'
                                      ? Colors.amber
                                      : Colors.white54,
                              size: 28,
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bank / EFT',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Receive your payout through your bank.',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              selectedMethod == 'Bank / EFT'
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color:
                                  selectedMethod == 'Bank / EFT'
                                      ? Colors.amber
                                      : Colors.white38,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (selectedMethod == 'Bank / EFT') ...[
                      const SizedBox(height: 14),

                      _walletTextField(
                        controller: accountHolderController,
                        label: 'Account holder name',
                        hint: 'Enter account holder name',
                        icon: Icons.person_outline,
                        textCapitalization:
                            TextCapitalization.words,
                      ),

                      const SizedBox(height: 10),

                      _walletTextField(
                        controller: bankNameController,
                        label: 'Bank name',
                        hint: 'e.g. Capitec, FNB, Absa',
                        icon: Icons.account_balance_outlined,
                        textCapitalization:
                            TextCapitalization.words,
                      ),

                      const SizedBox(height: 10),

                      _walletTextField(
                        controller: accountNumberController,
                        label: 'Account number',
                        hint: 'Enter account number',
                        icon: Icons.numbers,
                        keyboardType: TextInputType.number,
                      ),
                    ],

                    const SizedBox(height: 14),

                    GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          selectedMethod = 'Mobile Wallet';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: selectedMethod == 'Mobile Wallet'
                              ? Colors.amber.withValues(alpha: .10)
                              : Colors.black26,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color:
                                selectedMethod == 'Mobile Wallet'
                                    ? Colors.amber
                                    : Colors.white10,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_android,
                              color:
                                  selectedMethod == 'Mobile Wallet'
                                      ? Colors.amber
                                      : Colors.white54,
                              size: 28,
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mobile Wallet',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Receive your payout on your mobile wallet.',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              selectedMethod == 'Mobile Wallet'
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color:
                                  selectedMethod == 'Mobile Wallet'
                                      ? Colors.amber
                                      : Colors.white38,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (selectedMethod == 'Mobile Wallet') ...[
                      const SizedBox(height: 14),

                      _walletTextField(
                        controller: walletProviderController,
                        label: 'Wallet provider',
                        hint: 'Enter wallet/provider name',
                        icon: Icons.wallet_outlined,
                        textCapitalization:
                            TextCapitalization.words,
                      ),

                      const SizedBox(height: 10),

                      _walletTextField(
                        controller: walletNumberController,
                        label: 'Mobile number',
                        hint: 'Enter mobile number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ],

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.diamond,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Silver used',
                              style: TextStyle(
                                color: Colors.white54,
                              ),
                            ),
                          ),
                          Text(
                            '${widget.cashOutTarget}',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final Map<String, dynamic>
                                    payoutDetails;

                                if (selectedMethod ==
                                    'Bank / EFT') {
                                  if (accountHolderController
                                          .text
                                          .trim()
                                          .isEmpty ||
                                      bankNameController.text
                                          .trim()
                                          .isEmpty ||
                                      accountNumberController
                                          .text
                                          .trim()
                                          .isEmpty) {
                                    widget.onMessage(
                                      'Please complete all bank details.',
                                      icon: Icons.error_outline,
                                    );
                                    return;
                                  }

                                  payoutDetails = {
                                    'accountHolder':
                                        accountHolderController
                                            .text
                                            .trim(),
                                    'bankName':
                                        bankNameController
                                            .text
                                            .trim(),
                                    'accountNumber':
                                        accountNumberController
                                            .text
                                            .trim(),
                                  };
                                } else {
                                  if (walletProviderController
                                          .text
                                          .trim()
                                          .isEmpty ||
                                      walletNumberController
                                          .text
                                          .trim()
                                          .isEmpty) {
                                    widget.onMessage(
                                      'Please complete all mobile wallet details.',
                                      icon: Icons.error_outline,
                                    );
                                    return;
                                  }

                                  payoutDetails = {
                                    'provider':
                                        walletProviderController
                                            .text
                                            .trim(),
                                    'mobileNumber':
                                        walletNumberController
                                            .text
                                            .trim(),
                                  };
                                }

                                setSheetState(() {
                                  isSubmitting = true;
                                });

                                try {
                                  Navigator.pop(sheetContext);

                                  await widget.onCashOut(
                                    payoutMethod:
                                        selectedMethod,
                                    payoutDetails:
                                        payoutDetails,
                                  );
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      isSubmitting = false;
                                    });
                                  }
                                }
                              },
                        style: amberButton(),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'SUBMIT WITHDRAWAL REQUEST',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextButton(
                      onPressed: isSubmitting
                          ? null
                          : () {
                              Navigator.pop(sheetContext);
                            },
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================
  // WALLET TEXT FIELD
  // ==========================================================

  Widget _walletTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization =
        TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: Colors.amber,
        ),
        labelStyle: const TextStyle(
          color: Colors.white54,
        ),
        hintStyle: const TextStyle(
          color: Colors.white24,
        ),
        filled: true,
        fillColor: Colors.black26,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.white10,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.amber,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final progress =
        (widget.silver / widget.cashOutTarget)
            .clamp(0.0, 1.0);

    final remaining =
        (widget.cashOutTarget - widget.silver)
            .clamp(0, widget.cashOutTarget);

    final canCashOut =
        widget.silver >= widget.cashOutTarget;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const SizedBox(height: 10),

          const Text(
            'Wallet',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Your Silver treasure chest.',
            style: TextStyle(
              color: Colors.white54,
            ),
          ),

          const SizedBox(height: 25),

          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF332500),
                  Color(0xFF151515),
                ],
              ),
              border: Border.all(
                color: Colors.amber,
                width: .5,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.amber,
                  size: 55,
                ),

                const SizedBox(height: 15),

                const Text(
                  'YOUR SILVER',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${widget.silver}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const Text(
                  'SILVER',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: cardDecoration(),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'CASH OUT PROGRESS',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${widget.silver} / ${widget.cashOutTarget}',
                      style: const TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white10,
                    valueColor:
                        const AlwaysStoppedAnimation(
                      Colors.amber,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  canCashOut
                      ? 'Your cash-out target has been reached.'
                      : '$remaining Silver remaining to reach the minimum cash out.',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        showCashOutConfirmation(context),
                    style: amberButton(),
                    child: Text(
                      canCashOut
                          ? 'CASH OUT R20'
                          : 'LOCKED',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: cardDecoration(),
            child: const Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'MINIMUM CASH OUT',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 6),

                Text(
                  '96,000 SILVER = R20',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                SizedBox(height: 10),

                Text(
                  'Cash-out requests are reviewed before payment is processed.',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          const Text(
            'WITHDRAWAL HISTORY',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: withdrawalHistoryStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: cardDecoration(),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.amber,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: cardDecoration(),
                  child: const Text(
                    'Unable to load withdrawal history.',
                    style: TextStyle(
                      color: Colors.white54,
                    ),
                  ),
                );
              }

              final requests =
                  snapshot.data?.docs.toList() ?? [];

              requests.sort((a, b) {
                final aData =
                    a.data() as Map<String, dynamic>;
                final bData =
                    b.data() as Map<String, dynamic>;

                final aTime =
                    aData['createdAt'] as Timestamp?;
                final bTime =
                    bData['createdAt'] as Timestamp?;

                if (aTime == null && bTime == null) {
                  return 0;
                }

                if (aTime == null) {
                  return 1;
                }

                if (bTime == null) {
                  return -1;
                }

                return bTime.compareTo(aTime);
              });

              if (requests.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(22),
                  decoration: cardDecoration(),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        color: Colors.white24,
                        size: 42,
                      ),

                      SizedBox(height: 10),

                      Text(
                        'No withdrawal requests yet.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 5),

                      Text(
                        'Your cash-out requests will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: requests.map((doc) {
                  final data =
                      doc.data() as Map<String, dynamic>;

                  final status =
                      (data['status'] ?? 'pending')
                          .toString();

                  final payoutMethod =
                      (data['payoutMethod'] ??
                              'Unknown')
                          .toString();

                  final cashAmount =
                      data['cashAmount'] ?? 20;

                  final silverAmount =
                      data['silverAmount'] ??
                          widget.cashOutTarget;

                  final createdAt =
                      data['createdAt'] as Timestamp?;

                  String dateText =
                      'Date unavailable';

                  if (createdAt != null) {
                    final date =
                        createdAt.toDate();

                    dateText =
                        '${date.day.toString().padLeft(2, '0')}/'
                        '${date.month.toString().padLeft(2, '0')}/'
                        '${date.year}';
                  }

                  return Container(
                    margin:
                        const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.all(18),
                    decoration: cardDecoration(),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              color: Colors.amber,
                              size: 32,
                            ),

                            const SizedBox(width: 12),

                            const Expanded(
                              child: Text(
                                'Withdrawal Request',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                            ),

                            Text(
                              'R$cashAmount',
                              style: const TextStyle(
                                color:
                                    Colors.greenAccent,
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        const Divider(
                          color: Colors.white10,
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Status',
                                style: TextStyle(
                                  color:
                                      Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            Text(
                              formatStatus(status),
                              style: TextStyle(
                                color:
                                    statusColor(status),
                                fontWeight:
                                    FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Payout method',
                                style: TextStyle(
                                  color:
                                      Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            Text(
                              payoutMethod,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Silver used',
                                style: TextStyle(
                                  color:
                                      Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            Text(
                              '$silverAmount',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Requested',
                                style: TextStyle(
                                  color:
                                      Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            Text(
                              dateText,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROFILE PAGE
// ============================================================

class ProfilePage extends StatelessWidget {
  final String username;
  final int silver;
  final int adsWatched;
  final int dailyLimit;
  final void Function(String, {IconData? icon}) onMessage;

const ProfilePage({
  super.key,
  required this.username,
  required this.silver,
    required this.adsWatched,
    required this.dailyLimit,
    required this.onMessage,
  });
Future<void> logoutUser(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const WelcomePage(),
      ),
      (route) => false,
    );
  } catch (e) {
    onMessage(
      'Could not log out. Please try again.',
      icon: Icons.error_outline,
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const SizedBox(height: 10),

          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 25),

          Container(
            padding: const EdgeInsets.all(22),
            decoration: cardDecoration(),
            child: Column(
              children: [
                Container(
                  width: 85,
                  height: 85,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.amber,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.black,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 15),

                Text(
  username,
  style: const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
  ),
),

                const SizedBox(height: 5),

                const Text(
                  'Your Silver journey has begun.',
                  style: TextStyle(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          profileStat(
            Icons.diamond,
            'Silver Balance',
            '$silver Silver',
          ),

          const SizedBox(height: 12),

          profileStat(
            Icons.play_circle_fill,
            'Videos / Ads Watched Today',
            '$adsWatched / $dailyLimit',
          ),

          const SizedBox(height: 20),

          Container(
            decoration: cardDecoration(),
            child: Column(
              children: [
                
                const Divider(
                  color: Colors.white10,
                  height: 1,
                ),

                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: Colors.amber,
                  ),
                  title: const Text(
                    'About Mzansi Silver',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white38,
                  ),
                  onTap: () {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('About Mzansi Silver'),
        content: const Text(
          'Every ad is another step towards your treasure.\n\n'
          'Watch. Discover. Earn Silver.\n\n'
          'Version 1.0.0',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      );
    },
  );
},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => logoutUser(context),
              icon: const Icon(Icons.logout),
              label: const Text(
                'LOG OUT',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(
                  color: Colors.redAccent,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget profileStat(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cardDecoration(),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.amber,
            size: 32,
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
Widget notificationRow(
  IconData icon,
  String title,
) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(
          icon,
          color: Colors.amber,
          size: 22,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Icon(
          Icons.check_circle,
          color: Colors.greenAccent,
          size: 20,
        ),
      ],
    ),
  );
}
// ============================================================
// SHARED UI HELPERS
// ============================================================

BoxDecoration cardDecoration() {
  return BoxDecoration(
    color: const Color(0xFF151515),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(
      color: Colors.white10,
    ),
  );
}

ButtonStyle amberButton() {
  return ElevatedButton.styleFrom(
    backgroundColor: Colors.amber,
    foregroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(
      vertical: 15,
      horizontal: 20,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  );
}

Widget silverLogo() {
  return Container(
    width: 38,
    height: 38,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.amber,
    ),
    child: const Icon(
      Icons.diamond,
      color: Colors.black,
      size: 22,
    ),
  );
}

Widget silverPill(int silver) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 7,
    ),
    decoration: BoxDecoration(
      color: Colors.amber.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.amber.withValues(alpha: .25),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.diamond,
          color: Colors.amber,
          size: 15,
        ),
        const SizedBox(width: 5),
        Text(
          '$silver',
          style: const TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}