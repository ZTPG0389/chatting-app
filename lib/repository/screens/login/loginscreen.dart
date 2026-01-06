import 'package:chatapp/repository/screens/otp/otpscreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/repository/screens/widgets/uihelper.dart';

import '../../../data/auth_service.dart';
import '../../../domain/constants/appcolors.dart' show AppColors;
import '../profile/profilescreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController phoneController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.scaffolddark
            : AppColors.scaffoldlight,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(CupertinoIcons.back),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UiHelper.CustomText(
              text: "Enter Your Phone Number",
              fontsize: 24,
              context: context,
              fontweight: FontWeight.bold,
              fontfamily: "bold",
            ),
            SizedBox(height: 10),
            UiHelper.CustomText(
              text: "Please confirm your country code and enter",
              fontsize: 14,
              context: context,
            ),
            UiHelper.CustomText(
              text: "your phone number",
              fontsize: 14,
              context: context,
            ),
            SizedBox(height: 20),
            UiHelper.CustomTextField(
              controller: phoneController,
              text: "Phone Number",
              context: context,
              textinputtype: TextInputType.number,
              icondata: Icons.phone,
            ),
          ],
        ),
      ),
      floatingActionButton: _isLoading
          ? const CircularProgressIndicator()
          : UiHelper.CustomButtom(
              buttonname: "Continue",
              callback: () async {
                setState(() {
                  _isLoading = true;
                });

                String phone = phoneController.text.trim();

                if (phone.isEmpty) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter phone number")),
                  );
                  return;
                }

                if (!phone.startsWith('+')) {
                  phone = '+91$phone';
                }

                await _authService.verifyPhoneNumber(
                  phoneNumber: phone,

                  onVerificationFailed: (e) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.message ?? "Verification failed"),
                      ),
                    );
                  },

                  onCodeSent: (verificationId) {
                    setState(() => _isLoading = false);
                    print("✅ OTP SENT");

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OTPScreen(
                          verificationId: verificationId,
                          phoneNumber: phone,
                        ),
                      ),
                    );
                  },

                  onVerificationCompleted: (userCredential) {
                    setState(() => _isLoading = false);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => ProfileScreen()),
                      (route) => false,
                    );
                  },
                );
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
