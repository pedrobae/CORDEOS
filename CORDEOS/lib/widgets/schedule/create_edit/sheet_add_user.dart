import 'package:collection/collection.dart';
import 'package:cordeos/l10n/app_localizations.dart';
import 'package:cordeos/models/domain/user.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/providers/user/user_provider.dart';
import 'package:cordeos/widgets/common/filled_text_button.dart';
import 'package:cordeos/widgets/common/labeled_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddUserSheet extends StatefulWidget {
  final int scheduleId;
  final int roleID;

  const AddUserSheet({
    super.key,
    required this.scheduleId,
    required this.roleID,
  });

  @override
  State<AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends State<AddUserSheet> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  List<User> _usernameFilteredUsers = [];
  List<User> _emailFilteredUsers = [];
  bool _showDropdown = false;
  int _resetDropdownOnNextChange = 0;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
    _emailController.addListener(_onEmailChanged());
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _emailController.removeListener(_onEmailChanged());
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    if (!mounted) return;
    if (_resetDropdownOnNextChange > 0) {
      debugPrint(_resetDropdownOnNextChange.toString());
      setState(() {
        _resetDropdownOnNextChange--;
      });
      return;
    }

    final userProvider = context.read<UserProvider>();

    final query = _usernameController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _usernameFilteredUsers = [];
        _showDropdown = false;
      } else {
        _usernameFilteredUsers = userProvider.knownUsers
            .where(
              (user) =>
                  user.username.toLowerCase().contains(query) &&
                  user.username.toLowerCase() != query,
            )
            .toList();
        _showDropdown = _usernameFilteredUsers.isNotEmpty;
      }
    });
  }

  VoidCallback _onEmailChanged() {
    return () async {
      if (_resetDropdownOnNextChange > 0) {
        debugPrint(_resetDropdownOnNextChange.toString());
        setState(() {
          _resetDropdownOnNextChange--;
        });
        return;
      }
      if (!mounted) return;
      final userProvider = context.read<UserProvider>();

      User? firestoreUser;
      if (_validateEmail(_emailController.text) == null) {
        final cloudUser = await userProvider.fetchUserDtoByEmail(
          _emailController.text,
        );
        if (cloudUser != null) {
          firestoreUser = cloudUser.toDomain();
        }
      }

      final query = _emailController.text.toLowerCase();
      setState(() {
        if (query.isEmpty) {
          _emailFilteredUsers = [];
          _showDropdown = false;
        } else {
          _emailFilteredUsers = userProvider.knownUsers
              .where(
                (user) =>
                    user.email.toLowerCase().contains(query) &&
                    user.email.toLowerCase() != query,
              )
              .toList();
          if (firestoreUser != null) {
            _emailFilteredUsers.add(firestoreUser);
          }
          _showDropdown = _emailFilteredUsers.isNotEmpty;
        }
      });
    };
  }

  void _selectUser(User user) {
    setState(() {
      _resetDropdownOnNextChange = 3;
      _usernameController.text = user.username;
      _emailController.text = user.email;
      _showDropdown = false;
      _usernameFilteredUsers = [];
    });
  }

  void _addUser(BuildContext context) async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();

    if (username.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseEnterNameAndEmail),
        ),
      );
      return;
    }

    final userProvider = context.read<UserProvider>();
    final scheduleProvider = context.read<LocalScheduleProvider>();

    // Check if user exists in known users
    User? user = userProvider.knownUsers.firstWhereOrNull(
      (user) => user.email.toLowerCase() == email.toLowerCase(),
    );

    if (user == null || user.firebaseId == null || user.firebaseId!.isEmpty) {
      user = (await userProvider.fetchUserDtoByEmail(email))?.toDomain();

      if (user != null) {
        // Upsert to local db if found in cloud
        await userProvider.upsertUser(user);
      }
    }
    user ??= await userProvider.createLocalUnknownUser(username, email);

    scheduleProvider.addUserToRole(widget.scheduleId, widget.roleID, user);

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe o e-mail';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'E-mail inválido';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer2<UserProvider, LocalScheduleProvider>(
      builder: (context, userProvider, scheduleProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.close),
                    ),
                  ],
                ),

                // NAME INPUT WITH DROPDOWN
                Column(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // EMAIL INPUT WITH DROPDOWN
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        LabeledTextField(
                          label: AppLocalizations.of(context)!.email,
                          controller: _emailController,
                          hint: AppLocalizations.of(context)!.enterEmailHint,
                        ),
                        if (_showDropdown && _emailFilteredUsers.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colorScheme.surfaceContainerLowest,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            constraints: BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _emailFilteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _emailFilteredUsers[index];
                                return ListTile(
                                  title: Text(user.email),
                                  subtitle: Text(user.username),
                                  onTap: () => _selectUser(user),
                                );
                              },
                            ),
                          ),
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        LabeledTextField(
                          label: AppLocalizations.of(context)!.name,
                          controller: _usernameController,
                          hint: AppLocalizations.of(context)!.enterNameHint,
                        ),
                        if (_showDropdown && _usernameFilteredUsers.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colorScheme.surfaceContainerLowest,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            constraints: BoxConstraints(maxHeight: 200),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _usernameFilteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _usernameFilteredUsers[index];
                                return ListTile(
                                  title: Text(user.username),
                                  subtitle: Text(user.email),
                                  onTap: () => _selectUser(user),
                                );
                              },
                            ),
                          ),
                      ],
                    ),

                    // ADD BUTTON
                    FilledTextButton(
                      onPressed: () => _addUser(context),
                      text: AppLocalizations.of(
                        context,
                      )!.addPlaceholder(AppLocalizations.of(context)!.member),
                      isDark: true,
                    ),
                    SizedBox(),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
