import 'package:flutter/cupertino.dart';

class DestinationFolder {
  DestinationFolder({
    required this.path,
    this.enabled = false,
    this.transferInProgress = false,
    this.transferComplete = false,
  });

  String path;
  bool enabled;
  bool transferInProgress;
  bool transferComplete;

  void toggleEnabled(value) {
    enabled = value;
  }

  void startCopyProgress() {
    transferInProgress = true;
  }

  void finishProgress() {
    transferInProgress = false;
    transferComplete = true;
  }

  void resetProgress() {
    transferComplete = false;
  }
}

class DestinationRow extends StatefulWidget {
  const DestinationRow({
    super.key,
    required this.destination,
    required this.enabled,
    required this.transferInProgress,
    required this.transferComplete,
    required this.onEnabledToggle,
    required this.onDeleteAction,
  });

  final DestinationFolder destination;
  final bool enabled;
  final bool transferInProgress;
  final bool transferComplete;
  final Function onEnabledToggle;
  final Function onDeleteAction;

  @override
  State<DestinationRow> createState() => _DestinationRowState();
}

class _DestinationRowState extends State<DestinationRow> {
  // void toggleEnagled(bool value){
  //   print(widget.enabled);
  //   print(widget.destination.enabled);
  //   setState(() {
  //     widget.destination.toggleEnabled(value);
  //   });
  // }

  Color getTextStyle() {
    if (widget.enabled) {
      return CupertinoColors.activeBlue;
    } else {
      return CupertinoColors.inactiveGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
      leading: CupertinoSwitch(value: widget.enabled, onChanged: (value) => {widget.onEnabledToggle(value)},),
      title: Row(
        children: [
          Text(widget.destination.path, style: TextStyle(color: getTextStyle()),),
          if (widget.transferComplete)
            const Icon(CupertinoIcons.check_mark_circled),
        ],
      ),
      trailing: (!widget.transferInProgress) ? CupertinoButton(onPressed: () => widget.onDeleteAction(widget.destination), child: const Text('Удалить путь')) : null,
    );
  }
}
