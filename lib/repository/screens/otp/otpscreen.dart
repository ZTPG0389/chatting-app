import 'package:chatapp/domain/constants/appcolors.dart';
import 'package:chatapp/repository/screens/profile/profilescreen.dart';
import 'package:chatapp/repository/screens/widgets/uihelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import '../../../data/auth_service.dart';
import '../bottomnav/bottomnavigationscreen.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OTPScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController otpController = TextEditingController();
  final AuthService _authService = AuthService();

  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: TextStyle(
        fontSize: 20,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(7)),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.otpdarkmode
          : AppColors.otplightmode,
      borderRadius: BorderRadius.circular(7),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.otpdarkmode
            : AppColors.otplightmode,
      ),
    );

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UiHelper.CustomText(
              text: "Enter Code",
              fontsize: 24,
              context: context,
              fontfamily: "bold",
              fontweight: FontWeight.bold,
            ),
            SizedBox(height: 5),
            UiHelper.CustomText(
              text: "We have sent you an SMS with the code",
              fontsize: 14,
              context: context,
            ),
            UiHelper.CustomText(
              text: "to ${widget.phoneNumber}",
              fontsize: 14,
              context: context,
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Pinput(
                onCompleted: (otp) async {
                  try {
                    await _authService.verifyOTP(
                      verificationId: _verificationId,
                      smsCode: otp,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("OTP verified successfully"),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );

                    await Future.delayed(const Duration(seconds: 2));
                    final uid = FirebaseAuth.instance.currentUser!.uid;

                    final isComplete = await _authService.isProfileComplete(uid);

                    if (!mounted) return;

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        isComplete ? BottomNavScreen(currentUserId: uid) : ProfileScreen(),
                      ),
                    );
                  }  catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Invalid OTP"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                length: 6,
                autofocus: true,
                controller: otpController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                submittedPinTheme: submittedPinTheme,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: TextButton(
        onPressed: () async {
          await _authService.verifyPhoneNumber(
            phoneNumber: widget.phoneNumber,
            onVerificationFailed: (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
            },
            onCodeSent: (newVerificationId) {
              setState(() {
                _verificationId = newVerificationId;
              });
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("OTP resent")));
            },
          );
        },
        child: Text(
          "Resend OTP",
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.otptextdarkmode
                : AppColors.otptextlightmode,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
