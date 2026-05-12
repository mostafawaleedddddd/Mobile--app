import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:camera/camera.dart';

const _blue = Color(0xFF3B82F6);

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

  List<CameraDescription>? cameras;
  CameraController? controller;
  bool isRecording = false;
  String? tempVideoPath;

  bool get hasRecording => _recordedFile != null && _videoController?.value.isInitialized == true;

  String get _recordButtonText {
    if (isRecording) {
      return 'Stop Recording';
    }
    return Platform.isWindows
        ? (hasRecording ? 'Record a New Take' : 'Start Recording')
        : (hasRecording ? 'Record a New Take' : 'Start Recording');
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras!.isNotEmpty) {
        controller = CameraController(cameras![0], ResolutionPreset.medium);
        await controller!.initialize();
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _startRecording() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (Platform.isWindows) {
        try {
          // Prioritize camera recording
          if (isRecording) {
            final XFile file = await controller!.stopVideoRecording();
            tempVideoPath = file.path;
            _recordedFile = File(tempVideoPath!);
            await _initializeVideoController(_recordedFile!);
            setState(() {
              isRecording = false;
            });
          } else {
            await controller!.startVideoRecording();
            setState(() {
              isRecording = true;
            });
          }
        } catch (e) {
          // Fall back to file picker if camera fails
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.video,
          );
          if (result == null || result.files.single.path == null) {
            return;
          }
          _recordedFile = File(result.files.single.path!);
          await _initializeVideoController(_recordedFile!);
        }
      } else {
        final XFile? video = await _picker.pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 10),
        );
        if (video == null) {
          return;
        }
        _recordedFile = File(video.path);
        await _initializeVideoController(_recordedFile!);
      }
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
    controller?.dispose();
    if (_recordedFile != null && _recordedFile!.existsSync()) {
      _recordedFile!.deleteSync();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: theme.surface,
      appBar: AppBar(
        backgroundColor: theme.surfaceContainerHighest,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.onSurface),
        title: Text(
          'Interview Recorder',
          style: TextStyle(color: theme.onSurface, fontWeight: FontWeight.w700),
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
                  color: theme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.outline),
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
                          colors: [
                            widget.color.withOpacity(0.18),
                            widget.color.withOpacity(0.06)
                          ],
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: theme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.description,
                                  style: TextStyle(
                                    fontSize: 13, 
                                    color: theme.onSurfaceVariant, 
                                    height: 1.4
                                  ),
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
                        children: [
                          Text(
                            'Record yourself with video and review your last take. Use this flow to practice interview responses, body language, and presence.',
                            style: TextStyle(
                              fontSize: 13.5, 
                              color: theme.onSurfaceVariant, 
                              height: 1.5
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _startRecording,
                  icon: Icon(isRecording ? Icons.stop : Icons.videocam_rounded, size: 20),
                  label: Text(_recordButtonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
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