import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'destination_folder.dart';
import 'package:file_selector/file_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _fromDir = '';
  final List<DestinationFolder> _destinations = [];

  @override
  void initState() {
    super.initState();
    loadFromPreferences();
  }

  Future<void> loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fromDir = prefs.getString('fromDir') ?? '';
      List<String> destinationPaths = prefs.getStringList('destinationPaths') ?? [];
      for (var path in destinationPaths){
        _destinations.add(DestinationFolder(path: path, enabled: false));
      }
    });
  }

  bool isFolderInstance(String folderPath) {
    if (RegExp(r"\.").hasMatch(folderPath)) {
      return false;
    }
    Directory dir = Directory(folderPath);
    try {
      dir.listSync(followLinks: false);
      return true;
    } on FileSystemException {
      return false;
    }
  }

  bool destinationExists(String folderPath) {
    for (var destination in _destinations) {
      if (destination.path == folderPath) {
        return true;
      }
    }
    return false;
  }

  void addFromDir() async {
    final file = await openFile();
    final prefs = await SharedPreferences.getInstance();
    if (file != null) {
      if (isFolderInstance(file.path) && !destinationExists(file.path)) {
        prefs.setString('fromDir', file.path);
        setState(() {
          _fromDir = file.path;
        });
      }
    }
  }

  void cacheDestinations() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('destinationPaths', _destinations.map((destination) => destination.path).toList());
  }

  void addDestination() async {
    resetProgress();
    final openedFiles = await openFiles();
    setState(() {
      for (var file in openedFiles) {
        if (isFolderInstance(file.path) && file.path != _fromDir && !destinationExists(file.path)) {
          _destinations.add(DestinationFolder(path: file.path, enabled: true));
        }
      }
    });
    cacheDestinations();
  }

  void resetProgress() {
    setState(() {
      for (var destination in _destinations) {
        destination.resetProgress();
      }
    });
  }

  void toggleEnabled(DestinationFolder destination, bool value){
    resetProgress();
    setState(() {
      destination.toggleEnabled(value);
    });
  }

  bool anyDisabled() {
    for (var destination in _destinations) {
      if (!destination.enabled) {
        return true;
      }
    }
    return false;
  }

  void activateAll() {
    setState(() {
      for (var destination in _destinations) {
        destination.toggleEnabled(true);
      }
    });
  }

  void deleteDestination(DestinationFolder folder) {
    resetProgress();
    setState(() {
      _destinations.remove(folder);
    });
    cacheDestinations();
  }

  String? getBaseName(parentPath, fullPath) {
    return RegExp("$parentPath(.*)").firstMatch(fullPath)![1];
  }

  void recursiveCopy(Directory from, String to) async {
    await for (var entity in from.list(followLinks: false)) {
      String? baseName = getBaseName(entity.parent.path, entity.path);
      if (baseName != null) {
        if (entity is File) {
          entity.copy("$to$baseName");
        } else if (entity is Directory) {
          Directory targetDir = await Directory("$to$baseName").create();
          recursiveCopy(entity, targetDir.path);
        }
      }
    }
  }

  void copyFiles(BuildContext context) async {
    resetProgress();
    Directory fromDirectory = Directory(_fromDir);
    for (var folder in _destinations) {
      if (folder.enabled) {
        setState(() {
          folder.startCopyProgress();
        });
        recursiveCopy(fromDirectory, folder.path);
        setState(() {
          folder.finishProgress();
        });
      }
    }
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Процесс копирования завершен'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть')
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Копирование содержимого $_fromDir'),
        trailing: GestureDetector(
          onTap: addFromDir,
          child: const Text('Выбрать', style: TextStyle(color: CupertinoColors.activeBlue)),
        ),
      ),
      child: SafeArea(child:
        Column(
          children: [
            Container(
              color: CupertinoColors.systemGroupedBackground,
              child: Row(
                children: [
                  const Text('Куда скопировать'),
                  CupertinoButton(
                    onPressed: (_fromDir != '') ? addDestination : null,
                    child: const Text('Добавить папки'),
                  ),
                ]
              ),
            ),
            if (_destinations.isEmpty) ...[
              const Expanded(child: Center(child: Text('Не выбрано, куда копировать файлы'),))
            ] else ...[
              if (anyDisabled())
                Align(
                  alignment: Alignment.centerLeft,
                  child: CupertinoButton(
                    onPressed: activateAll,
                    child: const Text('Активировать все'),
                  ),
                ),
              Expanded(
                child: ListView(
                  children:[
                    CupertinoListSection(children: [
                      for (var destination in _destinations)
                        DestinationRow(
                          destination: destination,
                          enabled: destination.enabled,
                          transferInProgress: destination.transferInProgress,
                          transferComplete: destination.transferComplete,
                          onEnabledToggle: (value) => toggleEnabled(destination, value),
                          onDeleteAction: deleteDestination
                        )
                    ])
                  ]
                )
              ),
            ],
            Container(
              color: CupertinoColors.systemGroupedBackground,
              child: Center(
                child: CupertinoButton.filled(
                  onPressed: (_fromDir != '' && _destinations.isNotEmpty) ? () => copyFiles(context) : null,
                  child: const Text('Запустить копирование'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
