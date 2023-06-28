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

FijkPanelWidgetBuilder fijkPanel4Builder({
  Key? key,
  final bool fill = false,
  final int duration = 4000,
  final int forwardBackwardDuration = 5000,
  final VoidCallback? handleCasting,
}) {
  return (FijkPlayer player, FijkData data, BuildContext context, Size viewSize,
      Rect texturePos) {
    return _FijkPanel4(
      key: key,
      player: player,
      data: data,
      viewSize: viewSize,
      texPos: texturePos,
      fill: fill,
      hideDuration: duration,
      forwardBackwardDuration: forwardBackwardDuration,
      handleCasting: handleCasting,
    );
  };
}

class _FijkPanel4 extends StatefulWidget {
  final FijkPlayer player;
  final FijkData data;

  final Size viewSize;
  final Rect texPos;
  final bool fill;
  final int hideDuration;
  final int forwardBackwardDuration;
  final VoidCallback? handleCasting;

  const _FijkPanel4({
    Key? key,
    required this.player,
    required this.data,
    this.fill = false,
    required this.viewSize,
    this.hideDuration = 4000,
    required this.texPos,
    required this.forwardBackwardDuration,
    required this.handleCasting,
  })  : assert(hideDuration > 0 && hideDuration < 10000),
        super(key: key);

  @override
  __FijkPanel4State createState() => __FijkPanel4State();
}

class __FijkPanel4State extends State<_FijkPanel4> {
  FijkPlayer get player => widget.player;

  Timer? _hideTimer;
  bool _hideStuff = true;

  Timer? _statelessTimer;
  bool _prepared = false;
  bool _playing = false;

  double _seekPos = -1.0;
  Duration _duration = Duration();
  Duration _currentPos = Duration();
  Duration _bufferPos = Duration();

  StreamSubscription? _currentPosSubs;
  StreamSubscription? _bufferPosSubs;

  late StreamController<double> _valController;

  // Is it needed to clear seek data in FijkData (widget.data)
  bool _needClearSeekData = true;

  static const FijkSliderColors sliderColors = FijkSliderColors(
      cursorColor: Colors.white,
      playedColor: Colors.white,
      baselineColor: Color.fromARGB(180, 200, 200, 200),
      bufferedColor: Color.fromARGB(180, 200, 200, 200));

  @override
  void initState() {
    super.initState();

    _valController = StreamController.broadcast();
    _prepared = player.state.index >= FijkState.prepared.index;
    _playing = player.state == FijkState.started;
    _duration = player.value.duration;
    _currentPos = player.currentPos;
    _bufferPos = player.bufferPos;

    _currentPosSubs = player.onCurrentPosUpdate.listen((v) {
      if (_hideStuff == false) {
        setState(() {
          _currentPos = v;
        });
      } else {
        _currentPos = v;
      }
      if (_needClearSeekData) {
        widget.data.clearValue(FijkData._fijkViewPanelSeekto);
      }
      _needClearSeekData = false;
    });

    if (widget.data.contains(FijkData._fijkViewPanelSeekto)) {
      var pos = widget.data.getValue(FijkData._fijkViewPanelSeekto) as double;
      _currentPos = Duration(milliseconds: pos.toInt());
    }

    _bufferPosSubs = player.onBufferPosUpdate.listen((v) {
      if (_hideStuff == false) {
        setState(() {
          _bufferPos = v;
        });
      } else {
        _bufferPos = v;
      }
    });

    player.addListener(_playerValueChanged);
  }

  @override
  void dispose() {
    super.dispose();
    _valController.close();
    _hideTimer?.cancel();
    _statelessTimer?.cancel();
    _currentPosSubs?.cancel();
    _bufferPosSubs?.cancel();
    player.removeListener(_playerValueChanged);
  }

  double dura2double(Duration d) {
    return d.inMilliseconds.toDouble();
  }

  void _playerValueChanged() {
    FijkValue value = player.value;

    if (value.duration != _duration) {
      if (_hideStuff == false) {
        setState(() {
          _duration = value.duration;
        });
      } else {
        _duration = value.duration;
      }
    }
    bool playing = (value.state == FijkState.started);
    bool prepared = value.prepared;
    if (playing != _playing ||
        prepared != _prepared ||
        value.state == FijkState.asyncPreparing) {
      showHiddenControls();
      setState(() {
        _playing = playing;
        _prepared = prepared;
      });
    }
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(milliseconds: widget.hideDuration), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void showHiddenControls() {
    if (_hideStuff == true) {
      _restartHideTimer();
    }
    setState(() {
      _hideStuff = !_hideStuff;
    });
  }

  void playOrPause() {
    if (player.isPlayable() || player.state == FijkState.asyncPreparing) {
      if (player.state == FijkState.started) {
        player.pause();
      } else {
        player.start();
      }
    } else if (player.state == FijkState.initialized) {
      player.start();
    } else {
      FijkLog.w("Invalid state ${player.state} ,can't perform play or pause");
    }
  }

  Widget buildPlayButton(BuildContext context, double height) {
    Icon icon = (player.state == FijkState.started)
        ? Icon(Icons.pause)
        : Icon(Icons.play_arrow);

    return IconButton(
      padding: EdgeInsets.all(0),
      iconSize: height * 0.8,
      color: Color(0xFFFFFFFF),
      icon: icon,
      onPressed: playOrPause,
    );
  }

  Widget buildAirplayButton(BuildContext context, double height) {
    return IconButton(
      padding: EdgeInsets.all(0),
      iconSize: height * 0.6,
      color: Color(0xFFFFFFFF),
      icon: Icon(
        Icons.airplay_rounded,
      ),
      onPressed: widget.handleCasting,
    );
  }

  Widget buildTotalDurationTimeText(BuildContext context, double height) {
    String text = "${_duration2String(_duration)}";
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Color.fromARGB(255, 183, 179, 179),
      ),
    );
  }

  Widget buildCurrentPositionText(BuildContext context, double height) {
    String text = "${_duration2String(_currentPos)}";
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Color.fromARGB(255, 183, 179, 179),
      ),
    );
  }

  Widget buildSlider(BuildContext context) {
    double duration = dura2double(_duration);

    double currentValue = _seekPos > 0 ? _seekPos : dura2double(_currentPos);
    currentValue = currentValue.clamp(0.0, duration);

    double bufferPos = dura2double(_bufferPos);
    bufferPos = bufferPos.clamp(0.0, duration);

    return Padding(
      padding: EdgeInsets.only(left: 3, right: 3),
      child: FijkSlider(
        colors: sliderColors,
        value: currentValue,
        cacheValue: bufferPos,
        min: 0.0,
        max: duration,
        onChanged: (v) {
          _restartHideTimer();
          setState(() {
            _seekPos = v;
          });
        },
        onChangeEnd: (v) {
          setState(() {
            player.seekTo(v.toInt());
            _currentPos = Duration(milliseconds: _seekPos.toInt());
            widget.data.setValue(FijkData._fijkViewPanelSeekto, _seekPos);
            _needClearSeekData = true;
            _seekPos = -1.0;
          });
        },
      ),
    );
  }

  Widget buildBottom(BuildContext context, double height) {
    if (_duration.inMilliseconds > 0) {
      return Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(
            0,
            0,
            0,
            0.3,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            buildPlayButton(context, height),
            buildCurrentPositionText(context, height),
            Expanded(child: buildSlider(context)),
            buildTotalDurationTimeText(context, height),
            buildAirplayButton(context, height)
          ],
        ),
      );
    } else {
      return Row(
        children: <Widget>[
          buildPlayButton(context, height),
          Expanded(child: Container()),
        ],
      );
    }
  }

  Widget buildFullScreenButton(BuildContext context, double height) {
    Icon icon = player.value.fullScreen
        ? Icon(Icons.fullscreen_exit)
        : Icon(Icons.fullscreen);
    bool fullScreen = player.value.fullScreen;
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: EdgeInsets.all(fullScreen ? 10 : 5),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.fromRGBO(
              0,
              0,
              0,
              0.3,
            ),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(
              height: 35,
              width: 35,
            ),
            color: Color(0xFFFFFFFF),
            icon: icon,
            onPressed: () {
              player.value.fullScreen
                  ? player.exitFullScreen()
                  : player.enterFullScreen();
            },
          ),
        ),
      ),
    );
  }

  Widget buildPanel(BuildContext context) {
    double height = panelHeight();

    Widget centerWidget = Container(
      color: Color(0x00000000),
    );

    if (!_hideStuff) {
      centerWidget = buildCenterControls();
    }
    return InkWell(
      onTap: () {
        showHiddenControls();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Stack(
            children: [
              Container(
                height: height > 80 ? 80 : height / 2,
              ),
              if (!_hideStuff) buildFullScreenButton(context, height)
            ],
          ),
          Expanded(
            child: centerWidget,
          ),
          Container(
            height: height > 80 ? 80 : height / 2,
            alignment: Alignment.bottomCenter,
            child: _hideStuff
                ? Container()
                : Container(
                    height: height > 80 ? 45 : height / 2,
                    padding: EdgeInsets.only(left: 8, right: 8, bottom: 5),
                    child: buildBottom(context, height > 80 ? 40 : height / 2),
                  ),
          )
        ],
      ),
    );
  }

  Rect panelRect() {
    Rect rect = player.value.fullScreen || (true == widget.fill)
        ? Rect.fromLTWH(0, 0, widget.viewSize.width, widget.viewSize.height)
        : Rect.fromLTRB(
            max(0.0, widget.texPos.left),
            max(0.0, widget.texPos.top),
            min(widget.viewSize.width, widget.texPos.right),
            min(widget.viewSize.height, widget.texPos.bottom));
    return rect;
  }

  double panelHeight() {
    if (player.value.fullScreen || (true == widget.fill)) {
      return widget.viewSize.height;
    } else {
      return min(widget.viewSize.height, widget.texPos.bottom) -
          max(0.0, widget.texPos.top);
    }
  }

  double panelWidth() {
    if (player.value.fullScreen || (true == widget.fill)) {
      return widget.viewSize.width;
    } else {
      return min(widget.viewSize.width, widget.texPos.right) -
          max(0.0, widget.texPos.left);
    }
  }

  Widget buildStateless() {
    if (player.state == FijkState.asyncPreparing) {
      return Container(
        alignment: Alignment.center,
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(
              Color(0xFF7DAAF7),
            ),
          ),
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

  Widget buildCenterControls() {
    return _hideStuff
        ? Container()
        : Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildBackwardButton(context, 50),
                buildPlayButton(context, 50),
                buildForwardButton(context, 50),
              ],
            ),
          );
  }

  Widget buildForwardButton(BuildContext context, double height) {
    return IconButton(
      padding: EdgeInsets.all(0),
      iconSize: height * 0.6,
      color: Color(0xFFFFFFFF),
      icon: Icon(
        Icons.forward_10_rounded,
      ),
      onPressed: () {
        player.seekTo(
          _currentPos.inMilliseconds + widget.forwardBackwardDuration,
        );
      },
    );
  }

  Widget buildBackwardButton(BuildContext context, double height) {
    return IconButton(
      padding: EdgeInsets.all(0),
      iconSize: height * 0.6,
      color: Color(0xFFFFFFFF),
      icon: Icon(
        Icons.replay_10_rounded,
      ),
      onPressed: () {
        player.seekTo(
          _currentPos.inMilliseconds - widget.forwardBackwardDuration,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Rect rect = panelRect();
    List ws = <Widget>[];

    if (_statelessTimer != null && _statelessTimer!.isActive) {
      ws.add(buildStateless());
    } else if (player.state == FijkState.asyncPreparing) {
      ws.add(buildStateless());
    } else if (player.state == FijkState.error) {
      ws.add(buildStateless());
    }
    ws.add(buildPanel(context));

    return Positioned.fromRect(
      rect: rect,
      child: Stack(children: ws as List<Widget>),
    );
  }
}
