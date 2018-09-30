// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:process/process.dart';

import '../application_package.dart';
import '../base/common.dart';
import '../base/process_manager.dart';
import '../base/process.dart';
import '../cache.dart';
import '../device.dart';
import '../globals.dart';
import '../runner/flutter_command.dart';

class LaunchCommand extends FlutterCommand {
  LaunchCommand() {
    requiresPubspecYaml();
  }

  @override
  final String name = 'launch';

  @override
  final String description = 'Launch a Flutter app on an attached device.';

  Device device;

  @override
  Future<Null> validateCommand() async {
    await super.validateCommand();
    device = await findTargetDevice();
    if (device == null) throwToolExit('No target device found');
  }

  @override
  Future<Null> runCommand() async {
    final ApplicationPackage package = await applicationPackages
        .getPackageForPlatform(await device.targetPlatform);

    Cache.releaseLockEarly();

    printStatus('Launching $package to $device...');

    if (!await launchApp(device, package)) throwToolExit('Launch failed');
  }
}

Future<bool> launchApp(Device device, ApplicationPackage package) async {
  if (package == null) return false;

  final cmd = <String>[
    '/usr/bin/xcrun',
    'simctl',
    'get_app_container',
    device.id,
    package.id,
  ];
  print(package.id);
  _traceCommand(cmd);
  final result = await LocalProcessManager().run(cmd);
  print(result.exitCode);
  final StringBuffer out = StringBuffer();
  if (result.stdout.isNotEmpty)
    out.writeln(result.stdout);
  if (result.stderr.isNotEmpty)
    out.writeln(result.stderr);
  print(out.toString().trimRight());

  // if (!await device.isAppInstalled(package)) {
  //   printError('Warning: the app is not installed');
  // }

  // return device.installApp(package);

  printStatus(device.toString());
  printStatus("done");
}

void _traceCommand(List<String> args) {
  final String argsText = args.join(' ');
  printTrace('executing: $argsText');
}
