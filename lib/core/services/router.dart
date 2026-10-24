import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentinel/src/groups/presention/views/sentinel_groups_view.dart';
import 'package:sentinel/src/hosts/presention/views/sentinel_hosts_view.dart';
import 'package:sentinel/src/more/presention/views/sentinel_more_view.dart';
import 'package:sentinel/src/sftp/presention/views/sentinel_sftp_view.dart';
import 'package:sentinel/src/splash_screen/presention/views/splash_screen.dart';
import 'package:sentinel/src/ssh/presention/view/sentinel_terminal_view.dart';

import '../../sentinel_shell_scaffold.dart';
import '../../src/home/presention/views/sentinel_home.dart';
import '../../src/hosts/presention/views/edit_host_view.dart';
import '../common/application/riverpod/current_theme_controller.dart';
import '../common/entities/host.dart';

part 'router.main.dart';
