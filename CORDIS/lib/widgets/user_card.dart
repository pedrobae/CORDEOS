import 'package:cordis/providers/user/my_auth_provider.dart';
import 'package:cordis/providers/navigation_provider.dart';
import 'package:cordis/screens/user/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserCard extends StatelessWidget {
  const UserCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer2<MyAuthProvider, NavigationProvider>(
      builder: (context, authProvider, navigationProvider, child) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop();

            navigationProvider.push(ProfileScreen(), showBottomNavBar: true);
          },
          child: Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              spacing: 8,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primary,
                  // photoURL, Initials fallback, Person Icon fallback
                  child: authProvider.photoURL != null
                      ? ClipOval(
                          child: Image.network(
                            authProvider.photoURL!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                      : (authProvider.userName != null &&
                            authProvider.userName!.isNotEmpty)
                      ? Text(
                          authProvider.userName!
                              .trim()
                              .split(' ')
                              .map((e) => e[0])
                              .take(2)
                              .join()
                              .toUpperCase(),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: colorScheme.surfaceContainerLowest,
                        ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authProvider.userName ?? 'Guest',
                        style: theme.textTheme.labelLarge,
                      ),
                      if (authProvider.userEmail != null)
                        Text(
                          authProvider.userEmail!,
                          style: theme.textTheme.bodySmall,
                          softWrap: false,
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        );
      },
    );
  }
}
