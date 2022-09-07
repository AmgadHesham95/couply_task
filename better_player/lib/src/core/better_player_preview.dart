import 'dart:async';
import 'dart:math';

import 'package:better_player/better_player.dart';
import 'package:better_player/src/configuration/better_player_controller_event.dart';
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class BetterPlayerPreview extends StatefulWidget {
  const BetterPlayerPreview({
    Key? key,
    this.controller,
    this.videoThumbnailUrl,
    this.aspectRatio,
  }) : super(key: key);

  final BetterPlayerController? controller;
  final String? videoThumbnailUrl;

  final double? aspectRatio;

  @override
  _BetterPlayerPreviewState createState() => _BetterPlayerPreviewState();
}

class _BetterPlayerPreviewState extends State<BetterPlayerPreview> {
  final StreamController<bool> playerVisibilityStreamController = StreamController();

  bool _initialized = false;

  StreamSubscription? _controllerEventSubscription;

  @override
  void initState() {
    playerVisibilityStreamController.add(true);
    _controllerEventSubscription = widget.controller!.controllerEventStream.listen(_onControllerChanged);
    super.initState();
  }

  @override
  void didUpdateWidget(BetterPlayerPreview oldWidget) {
    if (oldWidget.controller != widget.controller) {
      _controllerEventSubscription?.cancel();
      _controllerEventSubscription = widget.controller!.controllerEventStream.listen(_onControllerChanged);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    playerVisibilityStreamController.close();
    _controllerEventSubscription?.cancel();
    super.dispose();
  }

  void _onControllerChanged(BetterPlayerControllerEvent event) {
    setState(() {
      if (!_initialized) {
        _initialized = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final BetterPlayerController betterPlayerController = widget.controller!;
    double? aspectRatio;
    if (betterPlayerController.isFullScreen) {
      if (betterPlayerController.betterPlayerConfiguration.autoDetectFullscreenDeviceOrientation ||
          betterPlayerController.betterPlayerConfiguration.autoDetectFullscreenAspectRatio) {
        aspectRatio = betterPlayerController.videoPlayerController?.value.aspectRatio ?? 1.0;
      } else {
        aspectRatio = betterPlayerController.betterPlayerConfiguration.fullScreenAspectRatio ??
            BetterPlayerUtils.calculateAspectRatio(context);
      }
    } else {
      aspectRatio = widget.aspectRatio;
    }

    aspectRatio ??= 16 / 9;
    final innerContainer = Container(
      width: double.infinity,
      color: betterPlayerController.betterPlayerConfiguration.controlsConfiguration.backgroundColor,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: _buildPlayerPreview(betterPlayerController, context),
      ),
    );

    if (betterPlayerController.betterPlayerConfiguration.expandToFill) {
      return Center(child: innerContainer);
    } else {
      return innerContainer;
    }
  }

  Widget _buildPlayerPreview(BetterPlayerController betterPlayerController, BuildContext context) {
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
    return Container(
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
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BetterPlayerController betterPlayerController) {
    return betterPlayerController.betterPlayerDataSource!.placeholder ??
        betterPlayerController.betterPlayerConfiguration.placeholder ??
        Container();
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
                        if (widget.videoThumbnailUrl != null)
                          CachedNetworkImage(
                            imageUrl: widget.videoThumbnailUrl!,
                          ),
                      ],
                    )
                  : SizedBox(
                      width: controller!.value.size?.width ?? 0,
                      height: controller!.value.size?.height ?? 0,
                      child: (controller!.value.isPlaying)
                          ? VideoPlayer(controller)
                          : FittedBox(
                              child: widget.videoThumbnailUrl != "" && widget.videoThumbnailUrl != null
                                  ? Image.network(widget.videoThumbnailUrl!)
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
