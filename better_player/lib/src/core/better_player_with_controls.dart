import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/better_player_controller_event.dart';
import 'package:better_player/src/controls/better_player_cupertino_controls.dart';
import 'package:better_player/src/controls/better_player_material_controls.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/subtitles/better_player_subtitles_drawer.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BetterPlayerWithControls extends StatefulWidget {
  const BetterPlayerWithControls({
    Key? key,
    required this.controller,
    this.videoThumbnailUrl,
    this.fillHeight = false,
    this.onLongPress,
    this.onHorizontalDragEnd,
    this.onVerticalDragEnd,
  }) : super(key: key);

  final BetterPlayerController controller;
  final String? videoThumbnailUrl;
  final bool fillHeight;
  final VoidCallback? onLongPress;
  final ValueChanged<DragEndDetails>? onHorizontalDragEnd;
  final ValueChanged<DragEndDetails>? onVerticalDragEnd;

  @override
  _BetterPlayerWithControlsState createState() => _BetterPlayerWithControlsState();
}

class _BetterPlayerWithControlsState extends State<BetterPlayerWithControls> {
  BetterPlayerSubtitlesConfiguration get subtitlesConfiguration {
    return widget.controller.betterPlayerConfiguration.subtitlesConfiguration;
  }

  BetterPlayerControlsConfiguration get controlsConfiguration {
    return widget.controller.betterPlayerConfiguration.controlsConfiguration;
  }

  final StreamController<bool> playerVisibilityStreamController = StreamController();

  bool _initialized = false;

  StreamSubscription? _controllerEventSubscription;

  @override
  void initState() {
    super.initState();
    playerVisibilityStreamController.add(true);
    _controllerEventSubscription = widget.controller.controllerEventStream.listen(_onControllerChanged);
  }

  @override
  void didUpdateWidget(BetterPlayerWithControls oldWidget) {
    if (oldWidget.controller != widget.controller) {
      _controllerEventSubscription?.cancel();
      _controllerEventSubscription = widget.controller.controllerEventStream.listen(_onControllerChanged);
    }
    super.didUpdateWidget(oldWidget);
  }

  void _onControllerChanged(BetterPlayerControllerEvent event) {
    setState(() {
      if (!_initialized) {
        _initialized = true;
      }
    });
  }

  @override
  void dispose() {
    playerVisibilityStreamController.close();
    _controllerEventSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double? aspectRatio;
    if (widget.controller.isFullScreen) {
      if (widget.controller.betterPlayerConfiguration.autoDetectFullscreenDeviceOrientation ||
          widget.controller.betterPlayerConfiguration.autoDetectFullscreenAspectRatio) {
        aspectRatio = widget.controller.videoPlayerController?.value.aspectRatio ?? 1.0;
      } else {
        aspectRatio = widget.controller.betterPlayerConfiguration.fullScreenAspectRatio ??
            BetterPlayerUtils.calculateAspectRatio(context);
      }
    } else {
      aspectRatio = widget.controller.getAspectRatio();
    }

    aspectRatio ??= 16 / 9;
    final innerContainer = Container(
      height: widget.fillHeight ? double.infinity : null,
      color: widget.controller.betterPlayerConfiguration.controlsConfiguration.backgroundColor,
      child: _buildPlayerWithControls(widget.controller, context),
    );

    if (widget.controller.betterPlayerConfiguration.expandToFill) {
      return Center(child: innerContainer);
    } else {
      return innerContainer;
    }
  }

  Widget _buildPlayerWithControls(BetterPlayerController betterPlayerController, BuildContext context) {
    final configuration = betterPlayerController.betterPlayerConfiguration;
    var rotation = configuration.rotation;

    if (!(rotation <= 360 && rotation % 90 == 0)) {
      BetterPlayerUtils.log("Invalid rotation provided. Using rotation = 0");
      rotation = 0;
    }
    if (betterPlayerController.betterPlayerDataSource == null) {
      return Container();
    }
    _initialized = true;

    final bool placeholderOnTop = betterPlayerController.betterPlayerConfiguration.placeholderOnTop;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragEnd: widget.onVerticalDragEnd,
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          if (placeholderOnTop) _buildPlaceholder(betterPlayerController),
          Transform.rotate(
            angle: rotation * pi / 180,
            child: _BetterPlayerVideoFitWidget(
              betterPlayerController,
              betterPlayerController.betterPlayerConfiguration.fit,
              videoThumbnailUrl: widget.videoThumbnailUrl,
            ),
          ),
          betterPlayerController.betterPlayerConfiguration.overlay ?? const SizedBox.shrink(),
          BetterPlayerSubtitlesDrawer(
            betterPlayerController: betterPlayerController,
            betterPlayerSubtitlesConfiguration: subtitlesConfiguration,
            subtitles: betterPlayerController.subtitlesLines,
            playerVisibilityStream: playerVisibilityStreamController.stream,
          ),
          if (!placeholderOnTop) _buildPlaceholder(betterPlayerController),
          _buildControls(context, betterPlayerController),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BetterPlayerController betterPlayerController) {
    return betterPlayerController.betterPlayerDataSource!.placeholder ??
        betterPlayerController.betterPlayerConfiguration.placeholder ??
        Container();
  }

  Widget _buildControls(
    BuildContext context,
    BetterPlayerController betterPlayerController,
  ) {
    if (controlsConfiguration.showControls) {
      BetterPlayerTheme? playerTheme = controlsConfiguration.playerTheme;

      if (playerTheme == null) {
        if (kIsWeb) {
          playerTheme = BetterPlayerTheme.material;
        } else if (Platform.isAndroid) {
          playerTheme = BetterPlayerTheme.material;
        } else {
          playerTheme = BetterPlayerTheme.cupertino;
        }
      }

      if (controlsConfiguration.customControlsBuilder != null && playerTheme == BetterPlayerTheme.custom) {
        return controlsConfiguration.customControlsBuilder!(betterPlayerController, onControlsVisibilityChanged);
      } else if (playerTheme == BetterPlayerTheme.material) {
        return _buildMaterialControl();
      } else if (playerTheme == BetterPlayerTheme.cupertino) {
        return _buildCupertinoControl();
      }
    }

    return const SizedBox();
  }

  Widget _buildMaterialControl() {
    return BetterPlayerMaterialControls(
      onControlsVisibilityChanged: onControlsVisibilityChanged,
      controlsConfiguration: controlsConfiguration,
      onLongPress: widget.onLongPress,
      onHorizontalDragEnd: widget.onHorizontalDragEnd,
    );
  }

  Widget _buildCupertinoControl() {
    return BetterPlayerCupertinoControls(
      onControlsVisibilityChanged: onControlsVisibilityChanged,
      controlsConfiguration: controlsConfiguration,
      onLongPress: widget.onLongPress,
      onHorizontalDragEnd: widget.onHorizontalDragEnd,
    );
  }

  void onControlsVisibilityChanged(bool state) {
    playerVisibilityStreamController.add(state);
  }
}

///Widget used to set the proper box fit of the video. Default fit is 'fill'.
class _BetterPlayerVideoFitWidget extends StatefulWidget {
  final String? videoThumbnailUrl;

  const _BetterPlayerVideoFitWidget(
    this.betterPlayerController,
    this.boxFit, {
    Key? key,
    this.videoThumbnailUrl,
  }) : super(key: key);

  final BetterPlayerController betterPlayerController;
  final BoxFit boxFit;

  @override
  _BetterPlayerVideoFitWidgetState createState() => _BetterPlayerVideoFitWidgetState();
}

class _BetterPlayerVideoFitWidgetState extends State<_BetterPlayerVideoFitWidget> {
  VideoPlayerController? get controller => widget.betterPlayerController.videoPlayerController;

  bool _initialized = false;

  VoidCallback? _initializedListener;

  bool _started = false;

  StreamSubscription? _controllerEventSubscription;

  @override
  void initState() {
    super.initState();
    if (!widget.betterPlayerController.betterPlayerConfiguration.showPlaceholderUntilPlay) {
      _started = true;
    } else {
      _started = widget.betterPlayerController.hasCurrentDataSourceStarted;
    }

    _initialize();
  }

  @override
  void didUpdateWidget(_BetterPlayerVideoFitWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.betterPlayerController.videoPlayerController != controller) {
      if (_initializedListener != null) {
        oldWidget.betterPlayerController.videoPlayerController!.removeListener(_initializedListener!);
      }
      _initialized = false;
      _initialize();
    }
  }

  void _initialize() {
    if (controller?.value.initialized == false) {
      _initializedListener = () {
        if (!mounted) {
          return;
        }

        if (_initialized != controller!.value.initialized) {
          _initialized = controller!.value.initialized;
          setState(() {});
        }
      };
      controller!.addListener(_initializedListener!);
    } else {
      _initialized = true;
    }

    _controllerEventSubscription = widget.betterPlayerController.controllerEventStream.listen((event) {
      if (event == BetterPlayerControllerEvent.play) {
        if (!_started) {
          setState(() {
            _started = widget.betterPlayerController.hasCurrentDataSourceStarted;
          });
        }
      }
      if (event == BetterPlayerControllerEvent.setupDataSource) {
        setState(() {
          _started = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized && _started) {
      return Center(
        child: ClipRect(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: FittedBox(
              fit: widget.boxFit,
              child: (controller!.dataSource!.url.contains('.mp3'))
                  ? Row(
                      children: [
                        if (widget.videoThumbnailUrl != null) Image.network(widget.videoThumbnailUrl!),
                      ],
                    )
                  : SizedBox(
                      width: controller!.value.size?.width ?? 0,
                      height: controller!.value.size?.height ?? 0,
                      child: (controller!.value.isPlaying)
                          ? VideoPlayer(controller)
                          : FittedBox(
                              child: widget.videoThumbnailUrl != "" && widget.videoThumbnailUrl != null
                                  ? Image.network(
                                      widget.videoThumbnailUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : SizedBox(),
                              fit: BoxFit.fill,
                            )),
            ),
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  void dispose() {
    if (_initializedListener != null) {
      widget.betterPlayerController.videoPlayerController!.removeListener(_initializedListener!);
    }
    _controllerEventSubscription?.cancel();
    super.dispose();
  }
}
