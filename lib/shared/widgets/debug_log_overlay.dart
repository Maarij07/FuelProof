import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/app_logger.dart';

/// Floating debug overlay injected at the app root (via MaterialApp.builder).
/// The log viewer opens in-place — no Navigator push needed, so it works
/// from anywhere in the tree including above the Navigator.
class DebugLogOverlay extends StatefulWidget {
  const DebugLogOverlay({super.key});

  @override
  State<DebugLogOverlay> createState() => _DebugLogOverlayState();
}

class _DebugLogOverlayState extends State<DebugLogOverlay> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Floating trigger button ──────────────────────────────────────────
        Positioned(
          bottom: 80,
          right: 12,
          child: _LogBadge(
            onTap: () => setState(() => _open = true),
          ),
        ),

        // ── Full-screen log viewer ───────────────────────────────────────────
        if (_open)
          Positioned.fill(
            child: _LogViewerPanel(
              onClose: () => setState(() => _open = false),
            ),
          ),
      ],
    );
  }
}

// ── Floating badge ─────────────────────────────────────────────────────────────

class _LogBadge extends StatefulWidget {
  final VoidCallback onTap;
  const _LogBadge({required this.onTap});

  @override
  State<_LogBadge> createState() => _LogBadgeState();
}

class _LogBadgeState extends State<_LogBadge> {
  @override
  void initState() {
    super.initState();
    AppLogger.instance.addListener(_rebuild);
  }

  @override
  void dispose() {
    AppLogger.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final count = AppLogger.instance.entries.length;
    final hasErrors =
        AppLogger.instance.entries.any((e) => e.level == LogLevel.error);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: hasErrors
              ? Colors.red.shade700.withValues(alpha: 0.92)
              : Colors.black87.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bug_report, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              'LOG ($count)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full-screen log panel ──────────────────────────────────────────────────────

class _LogViewerPanel extends StatefulWidget {
  final VoidCallback onClose;
  const _LogViewerPanel({required this.onClose});

  @override
  State<_LogViewerPanel> createState() => _LogViewerPanelState();
}

class _LogViewerPanelState extends State<_LogViewerPanel> {
  final ScrollController _scroll = ScrollController();
  LogLevel _filter = LogLevel.debug;

  @override
  void initState() {
    super.initState();
    AppLogger.instance.addListener(_onLog);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    AppLogger.instance.removeListener(_onLog);
    _scroll.dispose();
    super.dispose();
  }

  void _onLog() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scroll.hasClients) {
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    }
  }

  List<LogEntry> get _filtered => AppLogger.instance.entries
      .where((e) => e.level.index >= _filter.index)
      .toList();

  Color _levelColor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey.shade400;
      case LogLevel.info:
        return Colors.lightBlue.shade300;
      case LogLevel.warning:
        return Colors.orange.shade300;
      case LogLevel.error:
        return Colors.red.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filtered;

    return Material(
      color: const Color(0xFF0D0D0D),
      child: SafeArea(
        child: Column(
          children: [
            // ── Toolbar ───────────────────────────────────────────────────────
            Container(
              color: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: widget.onClose,
                    tooltip: 'Close',
                  ),
                  const Text(
                    'Debug Logs',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Filter
                  DropdownButtonHideUnderline(
                    child: DropdownButton<LogLevel>(
                      value: _filter,
                      dropdownColor: const Color(0xFF1A1A1A),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                      onChanged: (v) => setState(() => _filter = v!),
                      items: LogLevel.values
                          .map(
                            (l) => DropdownMenuItem(
                              value: l,
                              child: Text(
                                l.name.toUpperCase(),
                                style: TextStyle(
                                    color: _levelColor(l), fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  // Copy
                  IconButton(
                    icon: const Icon(Icons.copy,
                        color: Colors.white70, size: 20),
                    tooltip: 'Copy all',
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                            text: AppLogger.instance.exportText()),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logs copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  // Clear
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.white70, size: 20),
                    tooltip: 'Clear',
                    onPressed: () {
                      AppLogger.instance.clear();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),

            // ── Log list ──────────────────────────────────────────────────────
            Expanded(
              child: entries.isEmpty
                  ? const Center(
                      child: Text(
                        'No logs yet.',
                        style: TextStyle(
                            color: Colors.white38,
                            fontFamily: 'monospace'),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(8),
                      itemCount: entries.length,
                      itemBuilder: (_, i) {
                        final e = entries[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(
                                  text: '${e.timeStr} ',
                                  style: const TextStyle(
                                      color: Colors.white38),
                                ),
                                TextSpan(
                                  text:
                                      '[${e.level.name.toUpperCase()}] ',
                                  style: TextStyle(
                                    color: _levelColor(e.level),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: '[${e.tag}] ',
                                  style: const TextStyle(
                                      color: Colors.white60),
                                ),
                                TextSpan(
                                  text: e.message,
                                  style: TextStyle(
                                      color: _levelColor(e.level)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
