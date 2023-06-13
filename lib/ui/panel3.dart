//MIT License
//
//Copyright (c) [2020] [Befovy]
//
//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:
//
//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.
//
//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//SOFTWARE.

part of fijkplayer;

FijkPanelWidgetBuilder fijkPanel3Builder({
  Key? key,
  final bool fill = false,
  final bool doubleTap = true,
  final bool snapShot = false,
  final VoidCallback? onBack,
  final Widget? liveLabel,
  final Widget? alarmIcon,
  final Widget? pushToTalkIcon,
  final Widget? recordIcon,
  final Widget? snapshotIcon,
  final bool shouldShowLoader = false,
  final Widget? loaderView,
  final bool hasLiveStreamEnded = false,
  final Widget? liveStreamEndedView,
  final Widget? liveStreamErrorView,
}) {
  return (FijkPlayer player, FijkData data, BuildContext context, Size viewSize,
      Rect texturePos) {
    return _FijkPanel3(
      key: key,
      player: player,
      data: data,
      onBack: onBack,
      liveLabel: liveLabel,
      alarmIcon: alarmIcon,
      recordIcon: recordIcon,
      snapshotIcon: snapshotIcon,
      pushToTalkIcon: pushToTalkIcon,
      shouldShowLoader: shouldShowLoader,
      loaderView: loaderView,
      hasLiveStreamEnded: hasLiveStreamEnded,
      liveStreamEndedView: liveStreamEndedView,
      liveStreamErrorView: liveStreamErrorView,
      viewSize: viewSize,
      texPos: texturePos,
      fill: fill,
      doubleTap: doubleTap,
      snapShot: snapShot,
    );
  };
}

class _FijkPanel3 extends StatefulWidget {
  final FijkPlayer player;
  final FijkData data;
  final VoidCallback? onBack;
  final Widget? liveLabel;
  final Widget? alarmIcon;
  final Widget? pushToTalkIcon;
  final Widget? recordIcon;
  final Widget? snapshotIcon;
  final bool shouldShowLoader;
  final Widget? loaderView;
  final bool hasLiveStreamEnded;
  final Widget? liveStreamEndedView;
  final Widget? liveStreamErrorView;
  final Size viewSize;
  final Rect texPos;
  final bool fill;
  final bool doubleTap;
  final bool snapShot;

  const _FijkPanel3(
      {Key? key,
      required this.player,
      required this.data,
      this.fill = false,
      this.onBack,
      this.liveLabel,
      this.alarmIcon,
      this.pushToTalkIcon,
      this.recordIcon,
      this.snapshotIcon,
      this.shouldShowLoader = false,
      this.loaderView,
      this.hasLiveStreamEnded = false,
      this.liveStreamEndedView,
      this.liveStreamErrorView,
      required this.viewSize,
      this.doubleTap = false,
      this.snapShot = false,
      required this.texPos})
      : super(key: key);

  @override
  __FijkPanel3State createState() => __FijkPanel3State();
}

class __FijkPanel3State extends State<_FijkPanel3> {
  FijkPlayer get player => widget.player;

  bool _prepared = false;
  bool _isPlaying = false;

  StreamSubscription? _currentPosSubs;
  StreamSubscription? _bufferPosSubs;

  late StreamController<double> _valController;

  // Is it needed to clear seek data in FijkData (widget.data)
  bool _needClearSeekData = true;

  @override
  void initState() {
    super.initState();

    _valController = StreamController.broadcast();
    _prepared = player.state.index >= FijkState.prepared.index;
    _isPlaying = player.state == FijkState.started;

    _currentPosSubs = player.onCurrentPosUpdate.listen((v) {
      if (_needClearSeekData) {
        widget.data.clearValue(FijkData._fijkViewPanelSeekto);
      }
      _needClearSeekData = false;
    });

    _bufferPosSubs = player.onBufferPosUpdate.listen((v) {});

    player.addListener(_playerValueChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _valController.close();
    _currentPosSubs?.cancel();
    _bufferPosSubs?.cancel();
    player.removeListener(_playerValueChanged);
  }

  void _playerValueChanged() {
    FijkValue value = player.value;
    bool playing = (value.state == FijkState.started);
    bool prepared = value.prepared;

    if (playing != _isPlaying ||
        prepared != _prepared ||
        value.state == FijkState.asyncPreparing) {
      setState(() {
        _isPlaying = playing;
        _prepared = prepared;
      });
    }
  }

  Widget _buildPanel(BuildContext context) {
    bool fullScreen = player.value.fullScreen;

    if (widget.shouldShowLoader) {
      return _buildLoader();
    } else if (widget.hasLiveStreamEnded) {
      return _buildCustomWidgetsFor(
        view: widget.liveStreamEndedView != null
            ? widget.liveStreamEndedView!
            : SizedBox(),
      );
    } else if (_isPlaying) {
      if (fullScreen) {
        return Stack(
          children: [
            _buildCloseButton(),
            _buildFullScreenControls(),
          ],
        );
      } else {
        return Stack(
          children: [
            if (_isPlaying && widget.liveLabel != null)
              Positioned(left: 10, bottom: 10, child: widget.liveLabel!),
            _buildFullScreenButton(),
          ],
        );
      }
    } else {
      return Container();
    }
  }

  Rect _panelRect() {
    Rect rect = player.value.fullScreen || (true == widget.fill)
        ? Rect.fromLTWH(0, 0, widget.viewSize.width, widget.viewSize.height)
        : Rect.fromLTRB(
            max(0.0, widget.texPos.left),
            max(0.0, widget.texPos.top),
            min(widget.viewSize.width, widget.texPos.right),
            min(widget.viewSize.height, widget.texPos.bottom));
    return rect;
  }

  Widget _buildCloseButton({bool isDarkTheme = true}) {
    return Positioned(
      left: 10,
      top: 10,
      child: _roundIconButton(
        icon: Icon(
          Icons.close,
          color: isDarkTheme ? Colors.white : Colors.black,
        ),
        onPressed: () => player.exitFullScreen(),
        isDarkTheme: isDarkTheme,
      ),
    );
  }

  Widget _buildFullScreenButton() {
    Icon icon = Icon(Icons.fullscreen);

    return Positioned(
      right: 8,
      bottom: 4,
      child: IconButton(
        padding: EdgeInsets.all(0),
        color: Colors.white,
        icon: icon,
        onPressed: () => player.enterFullScreen(),
      ),
    );
  }

  Widget _buildFullScreenControls() {
    return Positioned(
      right: 20,
      bottom: 20,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          if (widget.pushToTalkIcon != null) widget.pushToTalkIcon!,
          if (widget.recordIcon != null) widget.recordIcon!,
          if (widget.snapshotIcon != null) widget.snapshotIcon!,
          if (widget.alarmIcon != null) widget.alarmIcon!,
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return (widget.loaderView != null)
        ? widget.loaderView!
        : Container(
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(
                Color(0xFF7DAAF7),
              ),
            ),
          );
  }

  Widget _buildCustomWidgetsFor({required Widget view}) {
    bool fullScreen = player.value.fullScreen;

    if (fullScreen) {
      return Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            child: view,
          ),
          _buildCloseButton(isDarkTheme: false)
        ],
      );
    } else {
      return Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            child: view,
          ),
          _buildFullScreenButton()
        ],
      );
    }
  }

  Widget _buildErrorWidget() {
    if (widget.liveStreamErrorView != null) {
      return _buildCustomWidgetsFor(view: widget.liveStreamErrorView!);
    } else {
      return Container(
        alignment: Alignment.center,
        child: Icon(
          Icons.error,
          size: 30,
          color: Color(0x99FFFFFF),
        ),
      );
    }
  }

  Widget _roundIconButton({
    required Widget icon,
    required VoidCallback? onPressed,
    bool isDarkTheme = true,
  }) {
    final shadowColor = isDarkTheme ? Colors.black : Colors.white;
    final backgroundColor =
        isDarkTheme ? Colors.black.withOpacity(0.4) : Colors.white;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          shadowColor: shadowColor,
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.all(16),
        ),
        onPressed: onPressed,
        child: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Rect rect = _panelRect();

    List ws = <Widget>[];

    if (player.state == FijkState.asyncPreparing) {
      ws.add(_buildLoader());
    } else if (player.state == FijkState.error) {
      ws.add(_buildErrorWidget());
    }

    ws.add(_buildPanel(context));

    return Positioned.fromRect(
      rect: rect,
      child: Stack(children: ws as List<Widget>),
    );
  }
}
