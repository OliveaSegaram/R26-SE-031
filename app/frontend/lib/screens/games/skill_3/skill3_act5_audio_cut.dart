import 'package:flutter/material.dart';
import '../../../../models/curriculum_models.dart';

class Skill3Act5AudioCut extends StatefulWidget {
  final ActivityNode? activityNode;
  final bool isRemedial;
  
  const Skill3Act5AudioCut({super.key, this.activityNode, this.isRemedial = false});

  @override
  State<Skill3Act5AudioCut> createState() => _Skill3Act5AudioCutState();
}

class _Skill3Act5AudioCutState extends State<Skill3Act5AudioCut> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activityNode?.title ?? 'Activity 5'),
      ),
      body: const Center(
        child: Text(
          'Empty Activity',
          style: TextStyle(fontSize: 24, color: Colors.grey),
        ),
      ),
    );
  }
}
