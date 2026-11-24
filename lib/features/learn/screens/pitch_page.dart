import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../api/api_client.dart';
import '../../../shared_widgets/app_nav.dart';
import '../../../theme/home_tokens.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';

void openPitchTask(
  BuildContext context, {
  String prompt = 'Record a 60-second elevator pitch for your target role.',
  String weekKey = '',
  ApiClient? api,
  VoidCallback? onDone,
}) {
  pushSlide(
    context,
    PitchTaskPage(prompt: prompt, weekKey: weekKey, api: api, onDone: onDone),
  );
}

class PitchTaskPage extends StatefulWidget {
  const PitchTaskPage({
    super.key,
    this.prompt = 'Record a 60-second elevator pitch for your target role.',
    this.weekKey = '',
    this.api,
    this.onDone,
  });

  final String prompt;
  final String weekKey;
  final ApiClient? api;
  final VoidCallback? onDone;

  @override
  State<PitchTaskPage> createState() => _PitchTaskPageState();
}

class _PitchTaskPageState extends State<PitchTaskPage> {
  bool _recording = false;
  bool _hasTake = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final t = HomeTokens.of(context);
    return AppPageScaffold(
      title: '60-second pitch',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Text(
            widget.prompt,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: t.ink,
              height: 1.4,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1A22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _recording
                      ? Icons.fiber_manual_record
                      : (_hasTake ? Icons.play_circle_outline : Icons.videocam_outlined),
                  size: 64,
                  color: _recording ? const Color(0xFFFF6B6B) : Colors.white70,
                ),
                const SizedBox(height: 12),
                Text(
                  _recording
                      ? 'Recording… look at the camera'
                      : (_hasTake
                          ? 'Take saved — retake or keep it'
                          : 'Front camera · 60 seconds'),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _recording = false;
                            _hasTake = false;
                          });
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: t.ink,
                    side: BorderSide(color: t.line),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Retake'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          HapticFeedback.selectionClick();
                          if (_hasTake) {
                            final api = widget.api;
                            final week = widget.weekKey;
                            if (api != null && week.isNotEmpty) {
                              setState(() => _saving = true);
                              try {
                                await api.completeChallenge(week);
                              } catch (_) {
                                if (!context.mounted) return;
                                setState(() => _saving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Could not mark the pitch complete. Try again.'),
                                    backgroundColor: t.ink,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              if (!mounted) return;
                              setState(() => _saving = false);
                            }
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Saved on this phone. We do not keep the video.'),
                                backgroundColor: t.teal,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            widget.onDone?.call();
                            Navigator.pop(context);
                            return;
                          }
                          final file = await ImagePicker().pickVideo(
                            source: ImageSource.camera,
                            preferredCameraDevice: CameraDevice.front,
                            maxDuration: const Duration(seconds: 60),
                          );
                          if (file == null || !mounted) return;
                          try {
                            await Gal.putVideo(file.path);
                          } catch (_) {}
                          if (!mounted) return;
                          setState(() => _hasTake = true);
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: t.teal,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(_saving ? 'Saving…' : (_hasTake ? 'Save' : 'Record')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
