import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../data/models/active_progress_model.dart';
import '../../../../providers/health_provider.dart';
import '../../../../../core/constants/app_constants.dart';
import '../../../../../data/models/daily_exercise_model.dart';
import 'dart:ui';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/theme/app_theme.dart';

class SessionOverviewScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final GuidedSessionModel? predefinedSession;

  const SessionOverviewScreen({super.key, required this.sessionId, this.predefinedSession});

  @override
  ConsumerState<SessionOverviewScreen> createState() => _SessionOverviewScreenState();
}

class _SessionOverviewScreenState extends ConsumerState<SessionOverviewScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _hasManuallySelectedStep = false;

  @override
  void initState() {
    super.initState();
    // Use full viewport for immersive screen
    _pageController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Trigger active progress fetch on load
    ref.watch(activeProgressProvider);
    
    // Listen to active progress to update the starting page if there is a saved session
    ref.listen<AsyncValue<ActiveProgressModel?>>(
      activeProgressProvider,
      (previous, next) {
        if (!next.isLoading && next.hasValue && next.value != null) {
          final progress = next.value!;
          if (progress.sessionId == widget.sessionId && !_hasManuallySelectedStep) {
            // Find 0-based index
            int savedIndex = (progress.currentStepIndex ?? 1) - 1;
            if (savedIndex < 0) savedIndex = 0;
            
            // Only jump if we have clients and the index has changed
            if (_pageController.hasClients && _currentPage != savedIndex) {
               // We don't know the exact length here synchronously without reading session details,
               // but jumping to a non-existent page will just clamp or throw, usually PageController handles it or we 
               // can just animate to it.
               setState(() {
                 _currentPage = savedIndex;
               });
               // Use addPostFrameCallback to ensure the list is built before jumping
               WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_pageController.hasClients) {
                    _pageController.jumpToPage(savedIndex);
                  }
               });
            }
          }
        }
      },
    );

    final sessionAsync = widget.predefinedSession != null 
        ? AsyncValue.data(widget.predefinedSession) 
        : ref.watch(sessionDetailsProvider(widget.sessionId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        title: const Text(
          AppStrings.sessionOverview,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.black45,
                blurRadius: 10.0,
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFA05E44))),
        error: (error, stackTrace) => Center(child: Text('${AppStrings.failedToLoadSession}$error')),
        data: (session) {
          if (session == null) {
            return const Center(child: Text(AppStrings.sessionNotFound));
          }

          final steps = session.steps ?? [];

          return Stack(
            children: [
              Positioned.fill(
                child: steps.isEmpty 
                    ? _buildSingleView(
                        title: session.title ?? AppStrings.guidedSession,
                        description: session.description,
                        duration: session.duration,
                        imageUrl: session.imageUrl,
                        purpose: session.purpose,
                        intensity: session.intensity,
                      )
                    : PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                            _hasManuallySelectedStep = true;
                          });
                        },
                        itemCount: steps.length,
                        itemBuilder: (context, index) {
                          final step = steps[index];
                          return _buildSingleView(
                            title: step.title ?? "${AppStrings.stepPrefix}${index + 1}",
                            description: step.description,
                            duration: step.duration,
                            // Step image if available and not empty, else session image
                            imageUrl: (step.imageUrl != null && step.imageUrl!.trim().isNotEmpty)
                                ? step.imageUrl
                                : session.imageUrl,
                            // Stats inherit purpose and intensity from session
                            purpose: session.purpose,
                            intensity: session.intensity,
                            stepIndex: index + 1,
                            totalSteps: steps.length,
                          );
                        },
                      ),
              ),

              // Bottom Button and Indicators Container
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  padding: const EdgeInsets.only(top: 120), // Extra top padding for seamless gradient
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.primaryDark.withValues(alpha: 0.8),
                        AppColors.primaryDark,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Carousel Page Indicators
                        if (steps.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                steps.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentPage == index ? 24 : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _currentPage == index 
                                        ? AppColors.primaryButtonColor 
                                        : Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        
                        // Bottom Button
                        Padding(
                          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    try {
                                      ActiveProgressModel? activeProgress;
                                      try {
                                        activeProgress = await ref.read(activeProgressProvider.future);
                                      } catch (e) {
                                        debugPrint('Error fetching active progress: $e');
                                        activeProgress = null;
                                      }
                                      
                                      int currentTimeInStep = 0;
                                      int stepIndexToSend = _currentPage + 1;
                                      
                                      if (activeProgress != null && 
                                          activeProgress.sessionId == widget.sessionId &&
                                          activeProgress.currentStepIndex == stepIndexToSend) {
                                        currentTimeInStep = activeProgress.currentTimeInStep ?? 0;
                                      } else if (activeProgress == null) {
                                        currentTimeInStep = 0;
                                        stepIndexToSend = _currentPage + 1;
                                      }

                                      if (activeProgress != null) {
                                        final progressData = {
                                          "currentStepIndex": stepIndexToSend,
                                          "currentTimeInStep": currentTimeInStep,
                                          "heartRate": 120,
                                        };

                                        await ref.read(syncSessionProgressProvider({
                                          'id': widget.sessionId,
                                          'data': progressData,
                                        }).future);
                                      }

                                      int? initialStep;
                                      if (_hasManuallySelectedStep) {
                                        initialStep = _currentPage;
                                      }
                                      
                                      if (context.mounted) {
                                        await context.push('/health/guided-session', extra: {
                                          'sessionId': widget.sessionId,
                                          'steps': session.steps,
                                          'initialStepIndex': initialStep,
                                        });
                                        ref.invalidate(activeProgressProvider);
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('${AppStrings.failedToSyncProgress}$e')),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryButtonColor,
                                    foregroundColor: Colors.white,
                                    shadowColor: AppColors.primaryDark.withValues(alpha: 0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                                      const SizedBox(width: 12),
                                      const Text(
                                        AppStrings.beginSession,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSingleView({
    required String title,
    String? description,
    int? duration,
    String? imageUrl,
    String? purpose,
    String? intensity,
    int? stepIndex,
    int? totalSteps,
  }) {
    final bool isCarousel = totalSteps != null && totalSteps > 1;

    return Stack(
      children: [
        // Full screen background image (ambient blur)
        Positioned.fill(
          child: Image.network(
            _formatImageUrl(imageUrl, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=1740&q=80'),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[800]),
          ),
        ),
        
        // Ambient blur overlay
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40.0, sigmaY: 40.0),
            child: Container(color: AppColors.primaryDark.withValues(alpha: 0.6)),
          ),
        ),
        
        // Foreground contained image to prevent overlapping with text
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(bottom: isCarousel ? 240.0 : 200.0), // Keep well above the text
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  _formatImageUrl(imageUrl, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=1740&q=80'),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),
          ),
        ),
        
        // Dark gradient overlay for text readability
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  AppColors.primaryDark.withValues(alpha: 0.9),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        
        // Content
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(left: 24.0, right: 24.0, bottom: isCarousel ? 180.0 : 140.0), // Give room for bottom button container
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCarousel)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      AppStrings.stepOf.replaceFirst('%s', '$stepIndex').replaceFirst('%s', '$totalSteps'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Inter',
                    height: 1.1,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 24),
                // Stats row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatChip(
                        icon: Icons.schedule_rounded,
                        label: "${duration != null ? (duration / 60).ceil() : 0} ${AppStrings.min}",
                      ),
                      if (purpose != null) ...[
                        const SizedBox(width: 12),
                        _buildStatChip(
                          icon: Icons.track_changes_rounded,
                          label: purpose,
                        ),
                      ],
                      if (intensity != null) ...[
                        const SizedBox(width: 12),
                        _buildStatChip(
                          icon: Icons.local_fire_department_rounded,
                          label: intensity,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatImageUrl(String? url, String fallback) {
    if (url == null || url.isEmpty) return fallback;
    if (url.startsWith('http')) return url;
    
    final uri = Uri.parse(ApiConstants.baseUrl);
    final baseDomain = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
    
    if (url.startsWith('/')) {
      return '$baseDomain$url';
    }
    return '$baseDomain/$url';
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
