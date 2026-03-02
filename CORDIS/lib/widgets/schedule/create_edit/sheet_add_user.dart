import 'package:collection/collection.dart';
import 'package:cordis/l10n/app_localizations.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/models/domain/user.dart';
import 'package:cordis/providers/schedule/local_schedule_provider.dart';
import 'package:cordis/providers/user/user_provider.dart';
import 'package:cordis/widgets/common/filled_text_button.dart';
import 'package:cordis/widgets/common/labeled_text_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddUserSheet extends StatefulWidget {
  final dynamic scheduleId;
  final dynamic role; // Role or RoleDTO object

  const AddUserSheet({super.key, required this.scheduleId, required this.role});

  @override
  State<AddUserSheet> createState() => _AddUserSheetState();
}

class _AddUserSheetState extends State<AddUserSheet> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  List<dynamic> _usernameFilteredUsers = [];
  List<dynamic> _emailFilteredUsers = [];
  bool _showUsernameDropdown = false;
  bool _showEmailDropdown = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onUsernameChanged);
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _emailController.removeListener(_onEmailChanged);
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    if (!mounted) return;
    final userProvider = context.read<UserProvider>();
    final List<User> members = (widget.role is Role)
        ? widget.role.users
        : widget.role.users.map((user) => user.toDomain()).toList();

    final query = _usernameController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _usernameFilteredUsers = [];
        _showUsernameDropdown = false;
      } else {
        _usernameFilteredUsers = userProvider.knownUsers
            .where(
              (user) =>
                  user.username.toLowerCase().contains(query) &&
                  user.username.toLowerCase() != query &&
                  !members.any((member) => member.id == user.id),
            )
            .toList();
        _showUsernameDropdown = _usernameFilteredUsers.isNotEmpty;
      }
    });
  }

  void _onEmailChanged() {
    if (!mounted) return;
    final userProvider = context.read<UserProvider>();
    final List<User> members = (widget.role is Role)
        ? widget.role.users
        : widget.role.users.map((user) => user.toDomain()).toList();

    final query = _emailController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _emailFilteredUsers = [];
        _showEmailDropdown = false;
      } else {
        _emailFilteredUsers = userProvider.knownUsers
            .where(
              (user) =>
                  user.email.toLowerCase().contains(query) &&
                  user.email.toLowerCase() != query &&
                  !members.any((member) => member.id == user.id),
            )
            .toList();
        _showEmailDropdown = _emailFilteredUsers.isNotEmpty;
      }
    });
  }

  void _selectUserByUsername(User user) {
    setState(() {
      _usernameController.text = user.username;
      _emailController.text = user.email;
      _showUsernameDropdown = false;
      _usernameFilteredUsers = [];
    });
  }

  void _selectUserByEmail(User user) {
    setState(() {
      _emailController.text = user.email;
      _usernameController.text = user.username;
      _showEmailDropdown = false;
      _emailFilteredUsers = [];
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
    dynamic user = userProvider.knownUsers.firstWhereOrNull(
      (user) => user.email.toLowerCase() == email.toLowerCase(),
    );

    if (widget.role is Role) {
      user ??= await userProvider.createLocalUnknownUser(username, email);

      scheduleProvider.addUserToRole(widget.scheduleId, widget.role.id, user);
    } else {
      // CLOUD - SKIP
    }
    if (context.mounted) {
      Navigator.of(context).pop();
    }
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        LabeledTextField(
                          label: AppLocalizations.of(context)!.name,
                          controller: _usernameController,
                          hint: AppLocalizations.of(context)!.enterNameHint,
                        ),
                        if (_showUsernameDropdown &&
                            _usernameFilteredUsers.isNotEmpty)
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
                                  onTap: () => _selectUserByUsername(user),
                                );
                              },
                            ),
                          ),
                      ],
                    ),

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
                        if (_showEmailDropdown &&
                            _emailFilteredUsers.isNotEmpty)
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
                                  onTap: () => _selectUserByEmail(user),
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
