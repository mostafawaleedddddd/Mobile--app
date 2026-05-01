import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

const _blue = Color(0xFF3B82F6);
const _bluePale = Color(0xFFF0F7FF);
const _textDark = Color(0xFF1E293B);
const _textGrey = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _white = Colors.white;

class MockInterviewRecorderScreen extends StatefulWidget {
  final String title;
  final String description;
  final Color color;

  const MockInterviewRecorderScreen({
    super.key,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  State<MockInterviewRecorderScreen> createState() => _MockInterviewRecorderScreenState();
}

class _MockInterviewRecorderScreenState extends State<MockInterviewRecorderScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _recordedFile;
  VideoPlayerController? _videoController;
  bool _isLoading = false;

  Future<void> _startRecording() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 10),
      );

      if (video == null) {
        return;
      }

      _recordedFile = File(video.path);
      await _initializeVideoController(_recordedFile!);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeVideoController(File file) async {
    await _videoController?.dispose();
    final controller = VideoPlayerController.file(file);
    _videoController = controller;
    await controller.initialize();
    controller.setLooping(false);
    setState(() {});
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasRecording = _recordedFile != null && _videoController?.value.isInitialized == true;

    return Scaffold(
      backgroundColor: _bluePale,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _textDark),
        title: Text(
          'Interview Recorder',
          style: const TextStyle(color: _textDark, fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.color.withOpacity(0.18), widget.color.withOpacity(0.06)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: widget.color.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.videocam_outlined, color: widget.color, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.description,
                                  style: const TextStyle(fontSize: 13, color: _textGrey, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Record yourself with video and review your last take. Use this flow to practice interview responses, body language, and presence.',
                            style: TextStyle(fontSize: 13.5, color: _textGrey, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Your recording',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textDark),
              ),
              const SizedBox(height: 12),
              if (hasRecording) ...[
                AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: VideoPlayer(_videoController!),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _togglePlayback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                      icon: Icon(
                        _videoController!.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 20,
                      ),
                      label: Text(_videoController!.value.isPlaying ? 'Pause' : 'Play'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _startRecording,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _blue,
                        side: BorderSide(color: _blue.withOpacity(0.8)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                      icon: const Icon(Icons.fiber_manual_record_rounded, size: 20),
                      label: const Text('Re-record'),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
                  decoration: BoxDecoration(
                    color: _white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'No recording yet',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _textDark),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap the button below to capture your first interview practice video.',
                        style: TextStyle(fontSize: 13, color: _textGrey, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startRecording,
                  icon: const Icon(Icons.videocam_rounded, size: 20),
                  label: Text(hasRecording ? 'Record a New Take' : 'Start Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 14),
                const Center(
                  child: CircularProgressIndicator(color: _blue),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
