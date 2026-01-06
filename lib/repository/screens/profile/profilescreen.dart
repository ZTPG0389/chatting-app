import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/repository/screens/bottomnav/bottomnavigationscreen.dart';
import 'package:chatapp/repository/screens/widgets/uihelper.dart';

import '../../../data/auth_service.dart';
import '../../../data/user_service.dart';
import '../../../domain/constants/appcolors.dart';
import '../../../domain/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final bool editEmail;

  const ProfileScreen({
    this.editEmail = true,
    super.key,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController firstnameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userModel = await _userService.getUserProfile(user.uid);
      if (userModel != null) {
        firstnameController.text = userModel.firstName;
        lastnameController.text = userModel.lastName;
        emailController.text = userModel.email;
      }
    }
  }

  @override
  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> onSaveProfile() async {
    if (firstnameController.text.isEmpty || lastnameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      UserModel userModel = UserModel(
        uid: user.uid,
        phone: user.phoneNumber ?? '',
        firstName: firstnameController.text.trim(),
        lastName: lastnameController.text.trim(),
        email: emailController.text.trim(),
        createdAt: DateTime.now(),
      );

      await _userService.saveUserProfile(userModel: userModel);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Profile saved successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(Duration(milliseconds: 500));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BottomNavScreen(currentUserId: user.uid),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving profile: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(CupertinoIcons.back),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.scaffolddark
            : AppColors.scaffoldlight,
        title: UiHelper.CustomText(
          text: "Your Profile",
          fontsize: 20,
          context: context,
          fontfamily: "bold",
          fontweight: FontWeight.bold,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              children: [
                Theme.of(context).brightness == Brightness.dark
                    ? UiHelper.CustomImage(imgurl: "darkprofile.png")
                    : UiHelper.CustomImage(imgurl: "lightprofile.png"),

                SizedBox(height: 30),

                UiHelper.CustomTextField(
                  controller: firstnameController,
                  text: "First Name",
                  context: context,
                  textinputtype: TextInputType.name,
                  icondata: Icons.person,
                ),

                SizedBox(height: 10),

                UiHelper.CustomTextField(
                  controller: lastnameController,
                  text: "Last Name",
                  context: context,
                  textinputtype: TextInputType.name,
                  icondata: CupertinoIcons.person_2,
                ),

                SizedBox(height: 10),

                UiHelper.CustomTextField(
                  controller: emailController,
                  text: "Email",
                  context: context,
                  textinputtype: TextInputType.emailAddress,
                  icondata: CupertinoIcons.mail,
                  enabled: widget.editEmail,
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _isLoading
          ? CircularProgressIndicator()
          : UiHelper.CustomButtom(buttonname: "Save", callback: onSaveProfile),
    );
  }
}
