import 'package:chatapp/domain/constants/appcolors.dart';
import 'package:chatapp/repository/chats/chatsscreen.dart';
import 'package:chatapp/repository/contacts/contactsscreen.dart';
import 'package:chatapp/repository/more/morescreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BottomNavScreen extends StatefulWidget {
  final String currentUserId;

  const BottomNavScreen({super.key, required this.currentUserId});

  static void changeTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_BottomNavScreenState>();
    state?.setTab(index);
  }

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  int currentIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      ContactsScreen(currentUserId: widget.currentUserId),
      ChatsScreen(currentUserId: widget.currentUserId),
      MoreScreen(currentUserId: widget.currentUserId),
    ];
  }

  void setTab(int index) {
    setState(() => currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Android back press → app close
        return true;
      },
      child: Scaffold(
        body: IndexedStack(index: currentIndex, children: pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: setTab,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? AppColors.bottomdark
              : AppColors.bottomlight,
          selectedIconTheme: IconThemeData(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.icondarkmode
                : AppColors.iconlightmode,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person_2_alt),
              label: "Contacts",
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.chat_bubble_2_fill),
              label: "Chats",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: "More",
            ),
          ],
        ),
      ),
    );
  }
}
