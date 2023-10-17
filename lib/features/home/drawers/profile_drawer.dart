import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reddit_clone/features/auth/controller/auth_controller.dart';
import 'package:reddit_clone/theme/pallete.dart';

class ProfileDrawer extends ConsumerWidget {
  const ProfileDrawer({super.key});

  void logOut(WidgetRef ref) {
    ref.read(authControllerProvider.notifier).logOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider)!;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(user.profilePic),
              radius: 70,
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              "u/${user.name}",
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text(
                "My Profile",
              ),
              leading: const Icon(
                Icons.person,
              ),
              onTap: () {},
            ),
            ListTile(
              title: const Text(
                "Log Out",
              ),
              leading: Icon(
                Icons.logout,
                color: Pallete.redColor,
              ),
              onTap: () {
                logOut(ref);
              },
            ),
            Switch.adaptive(
              value: true,
              onChanged: (val) {},
            ),
          ],
        ),
      ),
    );
  }
}
