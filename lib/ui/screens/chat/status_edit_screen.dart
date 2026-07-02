import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../core/utils/helpers.dart';

class StatusEditScreen extends StatefulWidget {
  final String path;
  final String type;
  final Function(String caption, {String? newPath, String? newType}) onSend;

  const StatusEditScreen({
    super.key,
    required this.path,
    required this.type,
    required this.onSend,
  });

  @override
  State<StatusEditScreen> createState() => _StatusEditScreenState();
}

class _StatusEditScreenState extends State<StatusEditScreen>
    with TickerProviderStateMixin {
  late VideoPlayerController _controller;
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _captionFocusNode = FocusNode();

  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _sendAsDocument = false;
  double _rotationDeg = 0.0;
  List<String> _thumbnails = [];

  // ── Premium dark palette ────────────────────────────────────────────────────
  static const Color _waGreen      = Color(0xFF00CF9D);
  static const Color _waGreenDeep  = Color(0xFF00A87F);
  static const Color _bgDeep       = Color(0xFF0D1117);
  static const Color _bgCard       = Color(0xFF161B22);
  static const Color _bgInput      = Color(0xFF21262D);
  static const Color _borderColor  = Color(0xFF30363D);
  static const Color _textPrimary  = Color(0xFFE6EDF3);
  static const Color _textMuted    = Color(0xFF7D8590);
  static const Color _accentBlue   = Color(0xFF388BFD);

  late AnimationController _sendAnimCtrl;
  late Animation<double>   _sendScale;
  late AnimationController _playPulseCtrl;
  late Animation<double>   _playPulse;

  String? _activeToolLabel;
  int _selectedToolIndex = -1;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    _sendAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _sendScale = Tween<double>(begin: 1.0, end: 0.86).animate(
      CurvedAnimation(parent: _sendAnimCtrl, curve: Curves.easeInOut),
    );

    _playPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _playPulse = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _playPulseCtrl, curve: Curves.easeInOut),
    );

    _captionFocusNode.addListener(() { if (mounted) setState(() {}); });

    if (widget.type == 'video') {
      _controller = VideoPlayerController.file(File(widget.path))
        ..initialize().then((_) {
          if (mounted) {
            setState(() => _isInitialized = true);
            _generateThumbnails();
          }
        });
      _controller.addListener(() {
        if (mounted) setState(() => _isPlaying = _controller.value.isPlaying);
      });
    } else {
      _isInitialized = true;
    }
  }

  Future<void> _generateThumbnails() async {
    if (widget.type != 'video') return;
    try {
      final tempDir = (await getTemporaryDirectory()).path;
      final paths   = <String>[];
      final totalMs = _controller.value.duration.inMilliseconds.toDouble();
      for (int i = 0; i < 10; i++) {
        final ms   = ((i / 9) * totalMs).toInt();
        final path = await VideoThumbnail.thumbnailFile(
          video: widget.path,
          thumbnailPath: tempDir,
          imageFormat: ImageFormat.JPEG,
          timeMs: ms,
          quality: 35,
        );
        if (path != null) paths.add(path);
      }
      if (mounted) setState(() => _thumbnails = paths);
    } catch (e) {
      debugPrint('Thumbnail error: $e');
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (widget.type == 'video') _controller.dispose();
    _captionController.dispose();
    _captionFocusNode.dispose();
    _sendAnimCtrl.dispose();
    _playPulseCtrl.dispose();
    super.dispose();
  }

  // ── Actions ─────────────────────────────────────────────────────────────────

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _rotate() {
    setState(() => _rotationDeg = (_rotationDeg + 90) % 360);
    _flashTool('Rotate');
  }

  void _flashTool(String label) {
    setState(() => _activeToolLabel = label);
    Future.delayed(
      const Duration(milliseconds: 950),
          () { if (mounted) setState(() => _activeToolLabel = null); },
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(msg, style: const TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: _bgCard,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: const BorderSide(color: _borderColor),
        ),
        margin: EdgeInsets.only(bottom: 100.h, left: 16.w, right: 16.w),
      ),
    );
  }

  void _showSpeedDialog() {
    _flashTool('Speed');
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (_) => _SpeedSheet(
        waGreen: _waGreen,
        bgInput: _bgInput,
        textPrimary: _textPrimary,
        textMuted: _textMuted,
        onSpeedSelected: (speed) {
          Navigator.pop(context);
          _controller.setPlaybackSpeed(speed);
          _flashTool('${speed}x');
        },
      ),
    );
  }

  void _showTextOverlay() {
    _flashTool('Text');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (_) => _TextOverlaySheet(
        waGreen: _waGreen,
        bgInput: _bgInput,
        textPrimary: _textPrimary,
        textMuted: _textMuted,
        borderColor: _borderColor,
        onAdd: (text) {
          Navigator.pop(context);
          _snack('Text overlay added');
        },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: ThemeData.dark().copyWith(
          useMaterial3: true,
          scaffoldBackgroundColor: _bgDeep,
        ),
        child: Scaffold(
          backgroundColor: _bgDeep,
          resizeToAvoidBottomInset: true,
          body: Stack(
            children: [
              // ── Full-bleed media ──────────────────────────────────────────
              Positioned.fill(child: _buildMediaLayer()),

              // ── Vignette overlay ──────────────────────────────────────────
              Positioned.fill(child: _buildVignette()),

              // ── Top bar ───────────────────────────────────────────────────
              Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

              // ── Play button overlay (video only) ──────────────────────────
              if (widget.type == 'video' && _isInitialized && !_isPlaying)
                Center(child: _buildPlayButton()),

              // ── Active tool toast ─────────────────────────────────────────
              if (_activeToolLabel != null)
                Positioned(
                  top: 0, bottom: 0, left: 0, right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 11.h),
                        decoration: BoxDecoration(
                          color: _bgCard.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(30.r),
                          border: Border.all(color: _waGreen.withOpacity(0.4)),
                        ),
                        child: Text(
                          _activeToolLabel!,
                          style: TextStyle(
                            color: _waGreen,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── Bottom panel ──────────────────────────────────────────────
              Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomPanel()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Media layer ─────────────────────────────────────────────────────────────

  Widget _buildMediaLayer() {
    return GestureDetector(
      onTap: widget.type == 'video' ? _togglePlay : null,
      child: Container(
        color: Colors.black,
        child: Center(
          child: !_isInitialized
              ? CircularProgressIndicator(color: _waGreen, strokeWidth: 2.w)
              : Transform.rotate(
                  angle: _rotationDeg * (3.14159265 / 180),
                  child: widget.type == 'video'
                      ? AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        )
                      : (widget.type == 'image' || widget.type == 'sticker'
                          ? Image.file(
                              File(widget.path),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => _buildDocumentPreview(),
                            )
                          : _buildDocumentPreview()),
                ),
        ),
      ),
    );
  }

  Widget _buildDocumentPreview() {
    final fileName = widget.path.split('/').last;
    final extension = fileName.split('.').last.toUpperCase();
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.insert_drive_file, size: 80.sp, color: Colors.blue),
        SizedBox(height: 20.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Text(
            fileName,
            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: 8.h),
        FutureBuilder<FileStat>(
          future: File(widget.path).stat(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                "$extension • ${Helpers.formatFileSize(snapshot.data!.size)}",
                style: TextStyle(color: _textMuted, fontSize: 14.sp),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildVignette() {
    return IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [Color(0xBB000000), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: _togglePlay,
      child: ScaleTransition(
        scale: _playPulse,
        child: Container(
          width: 72.w,
          height: 72.w,
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white54, width: 1.5.w),
          ),
          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 40.sp),
        ),
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Row(
          children: [
            _circleBtn(Icons.close_rounded, () => Navigator.pop(context)),
            SizedBox(width: 8.w),
            _circleBtn(Icons.refresh_rounded, () => Navigator.pop(context, 'retake')),
            const Spacer(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.type == 'image')
                      _topPill(
                        _sendAsDocument ? Icons.description : Icons.image,
                        _sendAsDocument ? 'PDF' : 'Image',
                        () => setState(() => _sendAsDocument = !_sendAsDocument),
                        active: _sendAsDocument,
                      ),
                    SizedBox(width: 6.w),
                    _circleBtn(Icons.download_rounded, () => _snack('Saved to gallery')),
                    SizedBox(width: 6.w),
                    _circleBtn(Icons.hd_outlined, () => _snack('HD quality enabled')),
                    SizedBox(width: 6.w),
                    _circleBtn(Icons.emoji_emotions_outlined, () => _snack('Emoji')),
                    SizedBox(width: 6.w),
                    _circleBtn(Icons.title_rounded, () => _captionFocusNode.requestFocus()),
                    SizedBox(width: 6.w),
                    _circleBtn(Icons.edit_outlined, () => _snack('Draw mode enabled')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: Colors.black38,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20.sp),
      ),
    );
  }

  Widget _topPill(IconData icon, String label, VoidCallback onTap, {bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: active ? _waGreen.withOpacity(0.2) : Colors.black38,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: active ? _waGreen : Colors.white),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? _waGreen : Colors.white, size: 15.sp),
            SizedBox(width: 4.w),
            Text(label, style: TextStyle(color: active ? _waGreen : Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _exportBtn() {
    return GestureDetector(
      onTap: () => _snack('Export — coming soon'),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: _waGreen,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(color: _waGreen.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.upload_rounded, color: Colors.white, size: 15.sp),
            SizedBox(width: 5.w),
            Text('Export', style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ── Bottom Panel ─────────────────────────────────────────────────────────────

  Widget _buildBottomPanel() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: _bgDeep.withOpacity(0.85),
            border: Border(top: BorderSide(color: _borderColor.withOpacity(0.5))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 10.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.type == 'video' && _isInitialized) ...[
                    _buildTimeline(),
                    SizedBox(height: 12.h),
                    _buildDivider(),
                    SizedBox(height: 12.h),
                  ],
                  _buildToolsRow(),
                  SizedBox(height: 14.h),
                  _buildCaptionRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: _borderColor.withOpacity(0.5));
  }

  // ── Timeline ─────────────────────────────────────────────────────────────────

  Widget _buildTimeline() {
    final duration = _controller.value.duration;
    final position = _controller.value.position;
    final double maxMs =
    duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0;
    final double posMs =
    position.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Timeline',
              style: TextStyle(
                color: _textMuted,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: _bgInput,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                '${Helpers.formatDuration(position.inSeconds)} / ${Helpers.formatDuration(duration.inSeconds)}',
                style: TextStyle(color: _textPrimary, fontSize: 11.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // Thumbnail strip with rounded corners
        ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            height: 48.h,
            decoration: BoxDecoration(
              color: _bgInput,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: _thumbnails.isEmpty
                  ? List.generate(
                10,
                    (_) => Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                    color: _bgInput,
                    child: Icon(Icons.image_outlined, size: 13.sp, color: _textMuted),
                  ),
                ),
              )
                  : _thumbnails
                  .map(
                    (p) => Expanded(
                  child: Image.file(
                    File(p),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: _bgInput),
                  ),
                ),
              )
                  .toList(),
            ),
          ),
        ),
        SizedBox(height: 4.h),

        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.0,
            thumbColor: Colors.white,
            activeTrackColor: _waGreen,
            inactiveTrackColor: _borderColor,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.r),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 16.r),
            overlayColor: _waGreen.withOpacity(0.18),
          ),
          child: Slider(
            value: posMs,
            max: maxMs,
            onChanged: (v) => _controller.seekTo(Duration(milliseconds: v.toInt())),
          ),
        ),
      ],
    );
  }

  // ── Tools Row ────────────────────────────────────────────────────────────────

  Widget _buildToolsRow() {
    final tools = <_ToolItem>[
      if (widget.type == 'video') ...[
        _ToolItem(Iconsax.crop_copy,        'Crop',    () { _flashTool('Crop');    _snack('Crop — coming soon'); }),
        _ToolItem(Iconsax.rotate_left_copy, 'Rotate',  _rotate),
        _ToolItem(Iconsax.scissor_copy,     'Trim',    () { _flashTool('Trim');    _snack('Trim — coming soon'); }),
        _ToolItem(Iconsax.timer_1_copy,     'Speed',   _showSpeedDialog),
      ] else ...[
        _ToolItem(Iconsax.crop_copy,        'Crop',    () { _flashTool('Crop');    _snack('Crop — coming soon'); }),
        _ToolItem(Iconsax.rotate_left_copy, 'Rotate',  _rotate),
      ],
      _ToolItem(Iconsax.text_copy,          'Text',    _showTextOverlay),
      _ToolItem(Iconsax.emoji_happy_copy,   'Sticker', () { _flashTool('Sticker'); _snack('Sticker — coming soon'); }),
      _ToolItem(Iconsax.music_copy,         'Music',   () { _flashTool('Music');   _snack('Music — coming soon'); }),
      _ToolItem(Iconsax.filter_copy,        'Filter',  () { _flashTool('Filter');  _snack('Filter — coming soon'); }),
    ];

    return SizedBox(
      height: 72.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        itemCount: tools.length,
        separatorBuilder: (_, __) => SizedBox(width: 10.w),
        itemBuilder: (_, i) => _buildToolChip(tools[i], i),
      ),
    );
  }

  Widget _buildToolChip(_ToolItem tool, int index) {
    final bool isActive = _activeToolLabel == tool.label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedToolIndex = index);
        tool.onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        decoration: BoxDecoration(
          color: isActive ? _waGreen.withOpacity(0.15) : _bgCard,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isActive ? _waGreen : _borderColor,
            width: isActive ? 1.2 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tool.icon,
              color: isActive ? _waGreen : _textPrimary,
              size: 20.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              tool.label,
              style: TextStyle(
                color: isActive ? _waGreen : _textMuted,
                fontSize: 11.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Caption + Send ───────────────────────────────────────────────────────────

  Widget _buildCaptionRow() {
    final bool focused = _captionFocusNode.hasFocus;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Input box
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: _bgInput,
              borderRadius: BorderRadius.circular(26.r),
              border: Border.all(
                color: focused ? _waGreen.withOpacity(0.6) : _borderColor,
                width: focused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 14.w),
                GestureDetector(
                  onTap: () => _snack('Emoji picker — coming soon'),
                  child: Icon(Icons.emoji_emotions_outlined, color: _textMuted, size: 22.sp),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: _captionController,
                    focusNode: _captionFocusNode,
                    style: TextStyle(color: _textPrimary, fontSize: 14.sp),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _captionFocusNode.unfocus(),
                    decoration: InputDecoration(
                      hintText: 'Add a caption…',
                      hintStyle: TextStyle(color: _textMuted, fontSize: 14.sp),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _snack('Voice caption — coming soon'),
                  child: Icon(Icons.mic_none_rounded, color: _textMuted, size: 22.sp),
                ),
                SizedBox(width: 14.w),
              ],
            ),
          ),
        ),

        SizedBox(width: 10.w),

        // Send FAB
        GestureDetector(
          onTapDown: (_) => _sendAnimCtrl.forward(),
          onTapUp:   (_) => _sendAnimCtrl.reverse(),
          onTapCancel: ()  => _sendAnimCtrl.reverse(),
          onTap: () async {
            if (_sendAsDocument && widget.type == 'image') {
              final pdfPath = await _convertToPdf(widget.path);
              widget.onSend(_captionController.text, newPath: pdfPath, newType: 'document');
            } else {
              widget.onSend(_captionController.text);
            }
          },
          child: ScaleTransition(
            scale: _sendScale,
            child: Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: _waGreen,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _waGreen.withOpacity(0.40),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(Icons.send_rounded, color: Colors.white, size: 22.sp),
            ),
          ),
        ),
      ],
    );
  }

  Future<String> _convertToPdf(String imagePath) async {
    _flashTool('Generating PDF...');
    final pdf = pw.Document();
    final image = pw.MemoryImage(File(imagePath).readAsBytesSync());

    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Image(image),
        );
      },
    ));

    final output = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File("${output.path}/Image_$timestamp.pdf");
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}

// ── Tool item model ─────────────────────────────────────────────────────────────

class _ToolItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolItem(this.icon, this.label, this.onTap);
}

// ── Speed Bottom Sheet ──────────────────────────────────────────────────────────

class _SpeedSheet extends StatefulWidget {
  final Color waGreen, bgInput, textPrimary, textMuted;
  final Function(double) onSpeedSelected;

  const _SpeedSheet({
    required this.waGreen,
    required this.bgInput,
    required this.textPrimary,
    required this.textMuted,
    required this.onSpeedSelected,
  });

  @override
  State<_SpeedSheet> createState() => _SpeedSheetState();
}

class _SpeedSheetState extends State<_SpeedSheet> {
  double _selected = 1.0;
  static const speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 30.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.speed_rounded, color: widget.waGreen, size: 20.sp),
              SizedBox(width: 10.w),
              Text(
                'Playback Speed',
                style: TextStyle(color: widget.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: widget.waGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: widget.waGreen.withOpacity(0.4)),
                ),
                child: Text(
                  '${_selected}x',
                  style: TextStyle(color: widget.waGreen, fontSize: 13.sp, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: speeds.map((s) {
              final bool isSelected = s == _selected;
              return GestureDetector(
                onTap: () => setState(() => _selected = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 68.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: isSelected ? widget.waGreen : widget.bgInput,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isSelected ? widget.waGreen : Colors.white12,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${s}x',
                      style: TextStyle(
                        color: isSelected ? Colors.white : widget.textMuted,
                        fontSize: 13.sp,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onSpeedSelected(_selected),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.waGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: Text('Apply', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Text Overlay Sheet ──────────────────────────────────────────────────────────

class _TextOverlaySheet extends StatefulWidget {
  final Color waGreen, bgInput, textPrimary, textMuted, borderColor;
  final Function(String) onAdd;

  const _TextOverlaySheet({
    required this.waGreen,
    required this.bgInput,
    required this.textPrimary,
    required this.textMuted,
    required this.borderColor,
    required this.onAdd,
  });

  @override
  State<_TextOverlaySheet> createState() => _TextOverlaySheetState();
}

class _TextOverlaySheetState extends State<_TextOverlaySheet> {
  final _ctrl = TextEditingController();
  Color _selectedColor = Colors.white;
  double _fontSize = 24;

  static const _colors = [
    Colors.white, Colors.yellow, Colors.cyan, Colors.pink,
    Colors.orange, Colors.greenAccent,
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20.w,
        right: 20.w,
        top: 8.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.title_rounded, color: widget.waGreen, size: 20.sp),
              SizedBox(width: 10.w),
              Text(
                'Add Text',
                style: TextStyle(color: widget.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Preview
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: widget.borderColor),
            ),
            child: Center(
              child: Text(
                _ctrl.text.isEmpty ? 'Preview text' : _ctrl.text,
                style: TextStyle(
                  color: _selectedColor,
                  fontSize: _fontSize.sp,
                  fontWeight: FontWeight.w600,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: 14.h),

          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: widget.textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'Type something…',
              hintStyle: TextStyle(color: widget.textMuted),
              filled: true,
              fillColor: widget.bgInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
          SizedBox(height: 14.h),

          // Color picker
          Row(
            children: [
              Text('Color', style: TextStyle(color: widget.textMuted, fontSize: 12.sp)),
              SizedBox(width: 12.w),
              ..._colors.map((c) => GestureDetector(
                onTap: () => setState(() => _selectedColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 26.w,
                  height: 26.w,
                  margin: EdgeInsets.only(right: 8.w),
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == c ? widget.waGreen : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
              )),
            ],
          ),
          SizedBox(height: 12.h),

          // Font size slider
          Row(
            children: [
              Text('Size', style: TextStyle(color: widget.textMuted, fontSize: 12.sp)),
              SizedBox(width: 12.w),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    activeTrackColor: widget.waGreen,
                    inactiveTrackColor: widget.bgInput,
                    thumbColor: Colors.white,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 14.r),
                  ),
                  child: Slider(
                    value: _fontSize,
                    min: 14,
                    max: 48,
                    onChanged: (v) => setState(() => _fontSize = v),
                  ),
                ),
              ),
              Text(
                _fontSize.round().toString(),
                style: TextStyle(color: widget.textPrimary, fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _ctrl.text.trim().isEmpty ? null : () => widget.onAdd(_ctrl.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.waGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: widget.bgInput,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: Text('Add to Status', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}