import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import '../../../../widgets/health/session_completed_sheet.dart';
import '../../../../widgets/health/session_paused_sheet.dart';
import '../../../../../data/models/daily_exercise_model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/health_provider.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_theme.dart';

class GuidedSessionScreen extends ConsumerStatefulWidget {
  final List<ExerciseStepModel>? steps;
  final String sessionId;
  final int? initialStepIndex;

  const GuidedSessionScreen({super.key, required this.sessionId, this.steps, this.initialStepIndex});

  @override
  ConsumerState<GuidedSessionScreen> createState() =>
      _GuidedSessionScreenState();
}

class _GuidedSessionScreenState extends ConsumerState<GuidedSessionScreen> {
  bool _isPlaying = false;
  bool _isSessionStarted = false;
  bool _isCompletingSession = false;
  bool _isMuted = false;
  int _currentStep = 0;
  Timer? _timer;
  
  final ValueNotifier<int> _elapsedTimeNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _videoPositionNotifier = ValueNotifier<int>(0);
  int _currentStepDuration = 0;
  int _replayCount = 0;
  
  void _replayCurrentStep() {
    setState(() {
      _replayCount++;
      _isPlaying = true;
    });
    _resetTimerForCurrentStep();
  }
  
  late PageController _pageController;

  late final List<Map<String, dynamic>> _sessionSteps;

  @override
  void initState() {
    super.initState();
    int initialPage = widget.initialStepIndex ?? 0;
    _pageController = PageController(initialPage: initialPage);
    _currentStep = initialPage;

    if (widget.steps != null && widget.steps!.isNotEmpty) {
      _sessionSteps = widget.steps!
          .map(
            (step) => {
              'title': step.title ?? AppStrings.exerciseStep,
              'instruction': step.description ?? '',
              'image': (step.videoUrl != null && step.videoUrl!.isNotEmpty)
                  ? step.videoUrl!
                  : (step.imageUrl ?? ''),
              'poster': step.imageUrl ?? '',
              'isVideo': (step.videoUrl != null && step.videoUrl!.isNotEmpty),
              'duration': step.duration ?? 30,
              'subtitles': step.subtitles ?? [],
              'order': step.order ?? 0,
            },
          )
          .toList();
    } else {
      _sessionSteps = [];
    }
    
    _resetTimerForCurrentStep();
    _checkActiveProgress();
  }

  Future<void> _checkActiveProgress() async {
    try {
      final progress = await ref.read(activeProgressProvider.future);
      if (progress != null &&
          progress.status == 'STARTED' &&
          progress.sessionId == widget.sessionId) {
        // We have an active session for THIS specific session ID
        setState(() {
          _isSessionStarted = true;
          _isPlaying = false;
          
          if (widget.initialStepIndex == null) {
            // 1. Find the correct step index by mapping 1-based API index to 0-based list
            int savedOrder = progress.currentStepIndex ?? 1;
            
            // Map directly 1-based API index to 0-based array index
            int foundIndex = savedOrder - 1;
            
            if (foundIndex < 0) foundIndex = 0;
            if (foundIndex >= _sessionSteps.length) foundIndex = _sessionSteps.length - 1;
            
            _currentStep = foundIndex;
            _resetTimerForCurrentStep();
            
            // 2. Set the elapsed time to the saved paused time
            int savedTime = progress.currentTimeInStep ?? 0;
            if (savedTime < 0) savedTime = 0;
            if (savedTime > _currentStepDuration) savedTime = _currentStepDuration;
            
            _elapsedTimeNotifier.value = savedTime;
            
            // Pass the exact time to the video player as well
            _videoPositionNotifier.value = savedTime;

            // Jump to correct page
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(_currentStep);
              }
            });
          }
        });
      }
    } catch (e) {
      debugPrint('${AppStrings.failedToLoadActiveProgress}$e');
    }
  }

  Future<void> _startSessionOnBackend() async {
    try {
      // Call the API to start the session immediately when the screen loads
      await ref.read(startSessionProvider(widget.sessionId).future);
      debugPrint(AppStrings.sessionStartedBackend);
    } catch (e) {
      debugPrint('${AppStrings.failedToStartBackend}$e');
      // We don't block the UI if this fails, we just log it
    }
  }

  void _syncProgress() {
    if (!_isSessionStarted) return;
    
    // Note: API expects 'currentStepIndex' 
    // We strictly map 0-based array index to 1-based API index
    final int stepOrder = _currentStep + 1;

    final data = {
      "currentStepIndex": stepOrder,
      "currentTimeInStep": _elapsedTimeNotifier.value,
      "heartRate": 120 // Static for now as requested or placeholder
    };
    
    ref.read(syncSessionProgressProvider({
      'id': widget.sessionId,
      'data': data,
    }).future).then((_) {
      debugPrint('${AppStrings.progressSyncedSuccessfully}$stepOrder');
    }).catchError((e) {
      if (e.toString().contains('404')) {
        // Suppress 404 if the backend route isn't deployed yet
        return;
      }
      debugPrint('${AppStrings.failedToSyncProgress}$e');
    });
  }

  void _onPlayPauseTapped() {
    if (!_isSessionStarted) {
      // First time play is tapped -> Start the session
      setState(() {
        _isSessionStarted = true;
        _isPlaying = true;
      });
      _startSessionOnBackend();
      _startTimer();
    } else {
      // Toggle play/pause
      setState(() {
        _isPlaying = !_isPlaying;
      });

      // Sync progress when pausing
      if (!_isPlaying) {
        _timer?.cancel();
        _syncProgress();
        _showPausedSheet();
      } else {
        _startTimer();
      }
    }
  }

  void _showPausedSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => SessionPausedSheet(
        timeString: _formatDuration(_elapsedTimeNotifier.value),
        heartRate: 128, // Static matching the design requirement
        onResume: () {
          Navigator.pop(context);
          setState(() {
            _isPlaying = true;
          });
          _startTimer();
        },
        onEnd: () {
          Navigator.pop(context);
          _endSession();
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _elapsedTimeNotifier.dispose();
    _videoPositionNotifier.dispose();
    super.dispose();
  }

  bool _isTransitioning = false;

  void _nextStep() {
    if (_isTransitioning) return;
    
    HapticFeedback.mediumImpact(); // Haptic feedback on step finish
    
    if (_currentStep < _sessionSteps.length - 1) {
      _isTransitioning = true;
      _resetTimerForCurrentStep();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        if (mounted) {
          setState(() {
            _isTransitioning = false;
          });
        }
      });
    } else {
      _endSession();
    }
  }

  Future<void> _endSession() async {
    setState(() {
      _isPlaying = false;
      _isCompletingSession = true;
    });

    try {
      final response = await ref.read(completeSessionProvider(widget.sessionId).future);
      
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SessionCompletedSheet(message: response?.message),
      );
    } catch (e) {
      if (!mounted) return;
      // If it fails, we fall back to popping the screen since the user wanted to end it anyway
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.failedToCompleteSession}$e')),
      );
      context.pop();
    } finally {
      if (mounted) {
        _timer?.cancel();
        setState(() {
          _isCompletingSession = false;
        });
      }
    }
  }

  void _onStepChanged(int index) {
    if (_isSessionStarted && index != _currentStep) {
      _syncProgress(); // Sync progress when changing steps manually
    }
    setState(() {
      _currentStep = index;
    });
    _resetTimerForCurrentStep();
  }

  void _resetTimerForCurrentStep() {
    _timer?.cancel();
    
    // Safety check just in case
    if (_sessionSteps.isEmpty || _currentStep >= _sessionSteps.length) {
      return;
    }
    
    _currentStepDuration = _sessionSteps[_currentStep]['duration'] ?? 30;
    _elapsedTimeNotifier.value = 0; // Reset progress tracker
    _videoPositionNotifier.value = 0; // Reset video position to match progress tracker and avoid mis-syncs
    
    if (_isPlaying) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_elapsedTimeNotifier.value < _currentStepDuration) {
        _elapsedTimeNotifier.value++;
      } else {
        // Auto-advance to next step when timer reaches duration
        timer.cancel();
        _nextStep();
      }
    });
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Map<String, String> _getCurrentSubtitleData(Map<String, dynamic> stepData, int currentElapsed) {
    final List<dynamic>? subtitles = stepData['subtitles'];
    final defaultTitle = stepData['title'] as String;
    final defaultDesc = stepData['instruction'] as String? ?? stepData['description'] as String? ?? '';

    if (subtitles == null || subtitles.isEmpty) {
      return {'title': defaultTitle, 'description': defaultDesc};
    }

    List<Map<String, dynamic>> parsedSubs = [];
    for (var sub in subtitles) {
      try {
        if (sub is Map) {
          parsedSubs.add({
            'startTime': sub['startTime'] as int? ?? 0,
            'endTime': sub['endTime'] as int?,
            'title': sub['subtitle'] as String? ?? defaultTitle,
            'description': sub['description'] as String? ?? defaultDesc,
          });
        } else {
          // SubtitleModel
          parsedSubs.add({
            'startTime': sub.startTime as int? ?? 0,
            'endTime': sub.endTime as int?,
            'title': sub.subtitle as String? ?? defaultTitle,
            'description': sub.description as String? ?? defaultDesc,
          });
        }
      } catch (e) {
        debugPrint('Error parsing subtitle type: $e');
      }
    }

    // Sort by chronological order
    parsedSubs.sort((a, b) => (a['startTime'] as int).compareTo(b['startTime'] as int));

    Map<String, dynamic>? activeSub;
    
    // Find matching subtitle by interval checks
    for (int i = 0; i < parsedSubs.length; i++) {
        final sub = parsedSubs[i];
        final start = sub['startTime'] as int;
        final end = sub['endTime'] as int?;
        
        if (end != null) {
            // Explicit end time dictates limits
            if (currentElapsed >= start && currentElapsed <= end) {
                activeSub = sub;
            }
        } else {
            // Infer end time from the subsequent subtitle (or infinity if it's the last one)
            final nextStart = (i + 1 < parsedSubs.length) ? parsedSubs[i+1]['startTime'] as int : double.maxFinite.toInt();
            if (currentElapsed >= start && currentElapsed < nextStart) {
                activeSub = sub;
            }
        }
    }

    if (activeSub != null) {
        return {
          'title': activeSub['title'] as String,
          'description': activeSub['description'] as String,
        };
    }

    // Default if out of bounds entirely
    return {'title': defaultTitle, 'description': defaultDesc};
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionSteps.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF5D4037)),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            AppStrings.guidedSession,
            style: TextStyle(
              color: Color(0xFF5D4037),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            AppStrings.noSessionSteps,
            style: TextStyle(
              color: Color(0xFF5D4037),
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final currentStepData = _sessionSteps[_currentStep];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: _isSessionStarted 
            ? ValueListenableBuilder<int>(
                valueListenable: _elapsedTimeNotifier,
                builder: (context, elapsed, child) {
                  final remaining = (_currentStepDuration - elapsed).clamp(0, _currentStepDuration);
                  return Text(
                    _formatDuration(remaining),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  );
                },
              )
            : const Text(
                AppStrings.guidedSession,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isMuted = !_isMuted;
                });
                HapticFeedback.selectionClick();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Ambient Blurred Background
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Container(
                key: ValueKey(_currentStep),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(currentStepData['poster'] ?? currentStepData['image'] ?? ''),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                color: AppColors.primaryDark.withValues(alpha: 0.6), // Dim to ensure text readability
              ),
            ),
          ),

          // 2. Foreground Content
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Row(
                    children: List.generate(
                      _sessionSteps.length,
                      (index) => Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? AppColors.primaryButtonColor
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Video Area
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onStepChanged,
                          itemCount: _sessionSteps.length,
                          physics: const NeverScrollableScrollPhysics(), // Only navigate via next/prev buttons
                          itemBuilder: (context, index) {
                            final step = _sessionSteps[index];
                            return _StepMediaWidget(
                              url: step['image'],
                              posterUrl: step['poster'],
                              isVideo: step['isVideo'] ?? false,
                              isPlaying: _isPlaying && index == _currentStep,
                              isMuted: _isMuted,
                              positionNotifier: index == _currentStep ? _videoPositionNotifier : null,
                              replayCount: index == _currentStep ? _replayCount : 0,
                              initialPosition: index == _currentStep && _isSessionStarted && !_isPlaying 
                                  ? _elapsedTimeNotifier.value 
                                  : 0,
                            );
                          },
                        ),
                      ),
                    ]
                  ),
                ),

                // 3. Unified Bottom Controls
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.primaryButtonColor.withValues(alpha: 0.3)),
                          ),
                          child: ValueListenableBuilder<int>(
                            valueListenable: currentStepData['isVideo'] ? _videoPositionNotifier : _elapsedTimeNotifier,
                            builder: (context, elapsed, child) {
                              final activeSubtitle = _getCurrentSubtitleData(currentStepData, elapsed);
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Row 1: Instruction Text & End Session
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              activeSubtitle['title']!,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (activeSubtitle['description']!.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                activeSubtitle['description']!,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white.withValues(alpha: 0.7),
                                                  fontSize: 14,
                                                  height: 1.4,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Row 2: Playback Controls
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Skip Previous
                                      _buildCircleButton(
                                        icon: Icons.skip_previous_rounded,
                                        onTap: () {
                                          if (_currentStep > 0) {
                                            HapticFeedback.selectionClick();
                                            _syncProgress();
                                            _pageController.previousPage(
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                            );
                                          }
                                        },
                                        size: 48,
                                        iconColor: _currentStep > 0 ? Colors.white : Colors.white.withValues(alpha: 0.3),
                                        backgroundColor: Colors.transparent,
                                      ),
                                      const SizedBox(width: 24),
                                      
                                      // Replay (when paused)
                                      if (!_isPlaying) ...[
                                        _buildCircleButton(
                                          icon: Icons.replay_rounded,
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            _replayCurrentStep();
                                          },
                                          size: 48,
                                          iconColor: Colors.white,
                                          backgroundColor: Colors.transparent,
                                        ),
                                        const SizedBox(width: 24),
                                      ],
                                      
                                      // Play/Pause
                                      _buildCircleButton(
                                        icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        onTap: () {
                                           HapticFeedback.lightImpact();
                                           _onPlayPauseTapped();
                                        },
                                        size: 64,
                                        iconColor: Colors.white,
                                        backgroundColor: AppColors.primaryButtonColor,
                                        hasShadow: true,
                                      ),
                                      const SizedBox(width: 24),
                                      
                                      // Skip Next
                                      _buildCircleButton(
                                        icon: Icons.skip_next_rounded,
                                        onTap: () {
                                          if (_currentStep < _sessionSteps.length - 1) {
                                            HapticFeedback.selectionClick();
                                            _syncProgress();
                                            _nextStep();
                                          }
                                        },
                                        size: 48,
                                        iconColor: _currentStep < _sessionSteps.length - 1 ? Colors.white : Colors.white.withValues(alpha: 0.3),
                                        backgroundColor: Colors.transparent,
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            }
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    required double size,
    required Color iconColor,
    required Color backgroundColor,
    bool hasShadow = false,
    BoxBorder? border,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: border,
          boxShadow: hasShadow
              ? [
                  BoxShadow(
                    color: const Color(0xFFA35940).withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Icon(icon, color: iconColor, size: size * 0.4),
      ),
    );
  }
}

class _StepMediaWidget extends StatefulWidget {
  final String url;
  final String? posterUrl;
  final bool isVideo;
  final bool isPlaying;
  final bool isMuted;
  final ValueNotifier<int>? positionNotifier;
  final int replayCount;
  final int initialPosition;

  const _StepMediaWidget({
    required this.url,
    this.posterUrl,
    required this.isVideo,
    required this.isPlaying,
    required this.isMuted,
    this.positionNotifier,
    this.replayCount = 0,
    this.initialPosition = 0,
  });

  @override
  State<_StepMediaWidget> createState() => _StepMediaWidgetState();
}

class _StepMediaWidgetState extends State<_StepMediaWidget> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initMedia();
  }

  void _videoListener() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      final position = _videoController!.value.position.inSeconds;
      if (widget.positionNotifier != null && widget.positionNotifier!.value != position) {
        // Safe update
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && widget.positionNotifier != null && widget.isPlaying) {
            widget.positionNotifier!.value = position;
          }
        });
      }
    }
  }

  void _initMedia() {
    if (widget.isVideo) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..addListener(_videoListener)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isInitialized = true;
              _hasError = false;
            });
            
            // If we have an initial saved position, seek to it immediately
            if (widget.initialPosition > 0) {
               _videoController!.seekTo(Duration(seconds: widget.initialPosition)).then((_) {
                 if (mounted && widget.isPlaying) {
                   _updatePlaybackState();
                 }
               });
            } else {
               _updatePlaybackState();
            }
          }
        }).catchError((error) {
          debugPrint('Video Player error: $error URL: ${widget.url}');
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        });
      _videoController?.setLooping(true);
    }
  }

  @override
  void didUpdateWidget(_StepMediaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.isVideo != widget.isVideo) {
      _videoController?.dispose();
      _videoController = null;
      _isInitialized = false;
      _hasError = false;
      _initMedia();
    } else {
      if (oldWidget.replayCount != widget.replayCount && _videoController != null) {
        _videoController!.seekTo(Duration.zero);
      }

      _updatePlaybackState();
      
      if (oldWidget.isMuted != widget.isMuted && _videoController != null) {
        _videoController!.setVolume(widget.isMuted ? 0.0 : 1.0);
      }
    }
  }

  void _updatePlaybackState() {
    if (_videoController != null && _isInitialized) {
      _videoController!.setVolume(widget.isMuted ? 0.0 : 1.0);
      if (widget.isPlaying) {
        _videoController!.play();
      } else {
        _videoController!.pause();
      }
    }
  }

  @override
  void dispose() {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVideo) {
      return Image.network(
        widget.url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.error_outline, color: Colors.grey),
          ),
        ),
      );
    }

    if (_hasError) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image, color: Colors.white54, size: 48),
              SizedBox(height: 8),
              Text(
                'Video unavailable',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_videoController == null || !_isInitialized) {
      return Container(
        decoration: widget.posterUrl != null && widget.posterUrl!.isNotEmpty
            ? BoxDecoration(
                color: Colors.black,
                image: DecorationImage(
                  image: NetworkImage(widget.posterUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.5), BlendMode.darken),
                ),
              )
            : const BoxDecoration(color: Colors.black),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: _videoController!.value.size.width,
          height: _videoController!.value.size.height,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }
}
