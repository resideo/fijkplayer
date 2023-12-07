part of fijkplayer;

class ClipPlayerModel {
  final Widget? backwardIcon;
  final Widget? forwardIcon;
  final Widget? nextClipIcon;
  final Widget? previousClipIcon;
  final Widget? playClipIcon;
  final Widget? pauseClipIcon;
  final Widget? loaderView;
  final Widget? errorView;

  ClipPlayerModel({
    required this.backwardIcon,
    required this.forwardIcon,
    required this.nextClipIcon,
    required this.previousClipIcon,
    required this.playClipIcon,
    required this.pauseClipIcon,
    required this.loaderView,
    required this.errorView,
  });
}
