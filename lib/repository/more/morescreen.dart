import 'package:chatapp/repository/chats/chatsscreen.dart';
import 'package:chatapp/repository/screens/onboarding/onboardingscreen.dart';
import 'package:chatapp/repository/screens/widgets/uihelper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../data/auth_service.dart';
import '../../data/user_service.dart';
import '../../domain/constants/appcolors.dart';
import '../../domain/models/user_model.dart';
import '../screens/bottomnav/bottomnavigationscreen.dart';
import '../screens/profile/profilescreen.dart';

class MoreScreen extends StatefulWidget {
  final String currentUserId;

  const MoreScreen({super.key, required this.currentUserId});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  UserModel? _currentUserModel;
  bool _isLoading = true;

  final List<Map<String, dynamic>> arrMore = [
    {"icon": Icons.person, "txt": "Account"},
    {"icon": CupertinoIcons.chat_bubble_fill, "txt": "Chats"},
    {"icon": Icons.logout, "txt": "LogOut"},
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userModel = await _userService.getUserProfile(user.uid);
      if (userModel != null) {
        setState(() {
          _currentUserModel = userModel;
          _isLoading = false;
        });
      }
    }
  }

  void _logout() async {
    await _authService.signOut();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Logout successfully"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OnBoardingScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.scaffolddark
              : AppColors.scaffoldlight,
          automaticallyImplyLeading: false,
          title: UiHelper.CustomText(
            text: "More",
            fontsize: 18,
            context: context,
            fontweight: FontWeight.bold,
            fontfamily: "bold",
          ),
        ),
        body: Column(
          children: [
            /// Profile Section
            ListTile(
              leading: Theme.of(context).brightness == Brightness.dark
                  ? UiHelper.CustomImage(imgurl: "darkprofile.png")
                  : UiHelper.CustomImage(imgurl: "lightprofile.png"),
              title: UiHelper.CustomText(
                text: _currentUserModel?.firstName ?? "User Name",
                fontsize: 14,
                context: context,
                fontfamily: "bold",
                fontweight: FontWeight.bold,
              ),
              subtitle: UiHelper.CustomText(
                text: _currentUserModel?.phone ?? "+62 0000 - 0000 - 0000",
                fontsize: 12,
                context: context,
              ),
              trailing: const Icon(CupertinoIcons.forward),
            ),

            const SizedBox(height: 20),

            /// Options List
            Expanded(
              child: ListView.builder(
                itemCount: arrMore.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(
                      arrMore[index]["icon"],
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.icondarkmode
                          : AppColors.iconlightmode,
                    ),
                    title: UiHelper.CustomText(
                      text: arrMore[index]["txt"],
                      fontsize: 14,
                      context: context,
                    ),
                    trailing: const Icon(CupertinoIcons.forward),

                      onTap: () {
                        /// Logout
                        if (arrMore[index]["txt"] == "LogOut") {
                          _logout();
                        }
                        /// Account/Profile
                        else if (arrMore[index]["txt"] == "Account") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProfileScreen(editEmail: false),
                            ),
                          ).then((_) => _loadCurrentUser());
                        }
                        /// Chats
                        else if (arrMore[index]["txt"] == "Chats") {
                          BottomNavScreen.changeTab(context, 1);
                        }
                      }
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
