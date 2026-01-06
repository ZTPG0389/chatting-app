import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/chat_service.dart';
import '../../data/user_service.dart';
import '../../domain/constants/appcolors.dart';
import '../../domain/models/user_model.dart';
import '../chats/chatdetailscreen.dart';
import '../screens/widgets/uihelper.dart';

class ContactsScreen extends StatefulWidget {
  final String currentUserId;

  const ContactsScreen({super.key, required this.currentUserId});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController searchController = TextEditingController();
  final UserService _userService = UserService();
  final ChatService chatService = ChatService();

  String searchText = "";

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      setState(() {
        searchText = searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Initials helper
  String getInitials(String firstName, String lastName) {
    String first = firstName.isNotEmpty ? firstName[0] : '';
    String last = lastName.isNotEmpty ? lastName[0] : '';
    return (first + last).toUpperCase();
  }

  // Avatar color helper
  Color getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.red,
    ];
    return colors[name.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.scaffolddark
            : AppColors.scaffoldlight,
        automaticallyImplyLeading: false,
        title: UiHelper.CustomText(
          text: "Contacts",
          fontsize: 18,
          context: context,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          /// Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: UiHelper.CustomTextField(
              controller: searchController,
              text: "Search",
              context: context,
              textinputtype: TextInputType.name,
              icondata: Icons.search,
            ),
          ),

          const SizedBox(height: 10),

          /// Contacts List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _userService.getAllUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No contacts found"));
                }

                final allUsers = snapshot.data!;

                /// FILTER LOGIC
                final filteredUsers = allUsers.where((user) {
                  final fullName = "${user.firstName} ${user.lastName}"
                      .toLowerCase();
                  return fullName.contains(searchText);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return const Center(child: Text("No matching contacts"));
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: getAvatarColor(user.firstName),
                        child: Text(
                          getInitials(user.firstName, user.lastName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      title: UiHelper.CustomText(
                        text: "${user.firstName} ${user.lastName}",
                        fontsize: 14,
                        context: context,
                        fontweight: FontWeight.w600,
                      ),
                      subtitle: UiHelper.CustomText(
                        text: user.phone,
                        fontsize: 12,
                        context: context,
                        color: const Color(0XFFADB5BD),
                      ),
                      onTap: () async {
                        await chatService.ensureChatExists(
                          widget.currentUserId,
                          user.uid,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              currentUserId: widget.currentUserId,
                              receiverId: user.uid,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
