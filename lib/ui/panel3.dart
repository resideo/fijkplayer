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
  final int duration = 4000,
  final bool doubleTap = true,
  final bool snapShot = false,
  final VoidCallback? onBack,
  final VoidCallback? onAlarmTapped,
  final VoidCallback? onRecordPressed,
  final VoidCallback? onPushToTalkStart,
  final VoidCallback? onPushToTalkEnd,
  final VoidCallback? onSnapShotTapped,
}) {
  return (FijkPlayer player, FijkData data, BuildContext context, Size viewSize,
      Rect texturePos) {
    return _FijkPanel3(
      key: key,
      player: player,
      data: data,
      onBack: onBack,
      onAlarmTapped: onAlarmTapped,
      onRecordPressed: onRecordPressed,
      onPushToTalkStart: onPushToTalkStart,
      onPushToTalkEnd: onPushToTalkEnd,
      onSnapShotTapped: onSnapShotTapped,
      viewSize: viewSize,
      texPos: texturePos,
      fill: fill,
      doubleTap: doubleTap,
      snapShot: snapShot,
      hideDuration: duration,
    );
  };
}

class _FijkPanel3 extends StatefulWidget {
  final FijkPlayer player;
  final FijkData data;
  final VoidCallback? onBack;
  final VoidCallback? onAlarmTapped;
  final VoidCallback? onPushToTalkStart;
  final VoidCallback? onPushToTalkEnd;
  final VoidCallback? onRecordPressed;
  final VoidCallback? onSnapShotTapped;
  final Size viewSize;
  final Rect texPos;
  final bool fill;
  final bool doubleTap;
  final bool snapShot;
  final int hideDuration;

  const _FijkPanel3(
      {Key? key,
      required this.player,
      required this.data,
      this.fill = false,
      this.onBack,
      this.onAlarmTapped,
      this.onRecordPressed,
      this.onPushToTalkStart,
      this.onPushToTalkEnd,
      this.onSnapShotTapped,
      required this.viewSize,
      this.hideDuration = 4000,
      this.doubleTap = false,
      this.snapShot = false,
      required this.texPos})
      : assert(hideDuration > 0 && hideDuration < 10000),
        super(key: key);

  @override
  __FijkPanel3State createState() => __FijkPanel3State();
}

class __FijkPanel3State extends State<_FijkPanel3> {
  FijkPlayer get player => widget.player;

  Timer? _statelessTimer;
  bool _prepared = false;
  bool _isPlaying = false;

  Duration _duration = Duration();

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
    _duration = player.value.duration;

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
    _statelessTimer?.cancel();
    _currentPosSubs?.cancel();
    _bufferPosSubs?.cancel();
    player.removeListener(_playerValueChanged);
  }

  void _playerValueChanged() {
    FijkValue value = player.value;

    if (value.duration != _duration) {
      _duration = value.duration;
    }
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

  Widget _buildAlarmButton() {
    Icon icon = Icon(Icons.doorbell);

    return IconButton(
      padding: EdgeInsets.all(0),
      color: Colors.black,
      icon: icon,
      onPressed: widget.onAlarmTapped,
    );
  }

  Widget _buildFullScreenButton() {
    Icon icon = player.value.fullScreen
        ? Icon(Icons.fullscreen_exit)
        : Icon(Icons.fullscreen);

    return IconButton(
      padding: EdgeInsets.all(0),
      color: Colors.white,
      icon: icon,
      onPressed: () {
        player.value.fullScreen
            ? player.exitFullScreen()
            : player.enterFullScreen();
      },
    );
  }

  Widget _buildBottom() {
    return Row(
      children: <Widget>[
        Expanded(child: Container()),
        _buildFullScreenButton(),
      ],
    );
  }

  Widget _buildPanel(BuildContext context) {
    double height = _panelHeight();

    bool fullScreen = player.value.fullScreen;
    Widget centerWidget = Container(
      color: Color(0xFFFFFFFF),
    );

    Widget centerChild = Container(
      color: Color(0xFFFFFFFF),
    );

    if (fullScreen) {
      centerWidget = Row(
        children: <Widget>[
          Expanded(child: centerChild),
          Padding(
            padding: EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                GestureDetector(
                  onLongPressStart: (LongPressStartDetails details) {
                    if (widget.onPushToTalkStart != null) {
                      widget.onPushToTalkStart!();
                    }
                  },
                  onLongPressEnd: (LongPressEndDetails details) =>
                      widget.onPushToTalkEnd!(),
                  child: Icon(Icons.mic, color: Colors.black),
                ),
                IconButton(
                  padding: EdgeInsets.all(0),
                  color: Colors.black,
                  icon:
                      Icon(Icons.record_voice_over_sharp, color: Colors.black),
                  onPressed: widget.onRecordPressed,
                ),
                IconButton(
                  padding: EdgeInsets.all(0),
                  color: Colors.black,
                  icon: Icon(Icons.camera),
                  onPressed: widget.onSnapShotTapped,
                ),
              ],
            ),
          )
        ],
      );
    }

    if (fullScreen) {
      return Container(
        padding: EdgeInsets.all(15),
        child: Row(
          children: [
            Column(
              children: [
                IconButton(
                  padding: EdgeInsets.all(0),
                  color: Colors.black,
                  icon: Icon(Icons.close),
                  onPressed: () {
                    player.exitFullScreen();
                  },
                ),
                Expanded(child: Container()),
                _buildAlarmButton()
              ],
            ),
            Expanded(child: centerWidget),
          ],
        ),
      );
    } else {
      return Stack(
        children: [
          if (_isPlaying)
            Positioned(
              right: 70,
              top: 10,
              child: _liveButton(),
            ),
          Positioned(
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: height > 80 ? 45 : height / 2,
              padding: EdgeInsets.only(left: 8, right: 8, bottom: 5),
              child: _buildBottom(),
            ),
          ),
        ],
      );
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

  double _panelHeight() {
    if (player.value.fullScreen || (true == widget.fill)) {
      return widget.viewSize.height;
    } else {
      return min(widget.viewSize.height, widget.texPos.bottom) -
          max(0.0, widget.texPos.top);
    }
  }

  Widget _buildBack(BuildContext context) {
    return IconButton(
      padding: EdgeInsets.only(left: 5),
      icon: Icon(
        Icons.arrow_back_ios,
        color: Color(0xDDFFFFFF),
      ),
      onPressed: widget.onBack,
    );
  }

  Widget _liveButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 0, horizontal: 4),
        color: Colors.black.withOpacity(0.6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(shape: BoxShape.circle, color: Colors.red),
            ),
            SizedBox(width: 4),
            Text(
              'Live',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStateless() {
    if (player.state == FijkState.asyncPreparing) {
      return Container(
        alignment: Alignment.center,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      );
    } else if (player.state == FijkState.error) {
      return Container(
        alignment: Alignment.center,
        child: Icon(
          Icons.error,
          size: 30,
          color: Color(0x99FFFFFF),
        ),
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    Rect rect = _panelRect();

    List ws = <Widget>[];

    if (_statelessTimer != null && _statelessTimer!.isActive) {
      ws.add(_buildStateless());
    } else if (player.state == FijkState.asyncPreparing) {
      ws.add(_buildStateless());
    } else if (player.state == FijkState.error) {
      ws.add(_buildStateless());
    }

    ws.add(_buildPanel(context));

    if (widget.onBack != null) {
      ws.add(_buildBack(context));
    }
    return Positioned.fromRect(
      rect: rect,
      child: Stack(children: ws as List<Widget>),
    );
  }
}
