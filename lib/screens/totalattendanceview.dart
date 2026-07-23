import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:monteage_employee/models/totalattendanceview_model.dart';
import 'package:monteage_employee/controllers/totalattendanceview_controller.dart';

// ─────────────────────────────────────────────────────────────
//  ATTENDANCE LOGIC
// ─────────────────────────────────────────────────────────────
class _AttendanceLogic {
  static const int _onTimeMax     = 10 * 60 + 10;
  static const int _halfDayFrom   = 12 * 60;
  static const int _shortLeaveMax = 16 * 60;
  static const int _stdEnd        = 18 * 60 + 30;

  static int? _toMins(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parts = raw.trim().split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  static String _fmtOvertime(int mins) {
    final h = mins ~/ 60; final m = mins % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    return '${m}m';
  }

  static List<_Badge> getBadges(String? checkInTime, String? checkOutTime) {
    final inMins  = _toMins(checkInTime);
    final outMins = _toMins(checkOutTime);
    final badges  = <_Badge>[];
    if (inMins != null) {
      if (inMins <= _onTimeMax)       badges.add(_Badge.onTime());
      else if (inMins < _halfDayFrom) badges.add(_Badge.lateComing());
      else                            badges.add(_Badge.halfDay());
    }
    if (outMins != null) {
      if (outMins < _shortLeaveMax)  badges.add(_Badge.shortLeave());
      else if (outMins > _stdEnd)    badges.add(_Badge.overtime(_fmtOvertime(outMins - _stdEnd)));
    }
    return badges;
  }

  static String getCheckInStatus(String? t) {
    final m = _toMins(t);
    if (m == null) return '-';
    if (m <= _onTimeMax) return 'On Time';
    if (m < _halfDayFrom) return 'Late Coming';
    return 'Half Day';
  }

  static String getCheckOutStatus(String? t) {
    final m = _toMins(t);
    if (m == null) return '-';
    if (m < _shortLeaveMax) return 'Short Leave';
    if (m > _stdEnd) return 'Overtime: ${_fmtOvertime(m - _stdEnd)}';
    return 'Normal';
  }
}

// ─────────────────────────────────────────────────────────────
//  BADGE MODEL
// ─────────────────────────────────────────────────────────────
class _Badge {
  final String label; final Color bg, fg; final IconData icon;
  const _Badge({required this.label, required this.bg, required this.fg, required this.icon});
  factory _Badge.onTime()     => const _Badge(label: 'On Time',     bg: Color(0xFFE9F9EE), fg: Color(0xFF1E8E3E), icon: Icons.check_circle_outline);
  factory _Badge.lateComing() => const _Badge(label: 'Late Coming', bg: Color(0xFFFFF4E5), fg: Color(0xFFE67E22), icon: Icons.watch_later_outlined);
  factory _Badge.halfDay()    => const _Badge(label: 'Half Day',    bg: Color(0xFFFFEEEE), fg: Color(0xFFD93025), icon: Icons.timelapse);
  factory _Badge.shortLeave() => const _Badge(label: 'Short Leave', bg: Color(0xFFEEF2FF), fg: Color(0xFF3D5AFE), icon: Icons.logout);
  factory _Badge.overtime(String d) => _Badge(label: 'OT: $d', bg: const Color(0xFFE8F5E9), fg: const Color(0xFF2E7D32), icon: Icons.trending_up);
}

Widget _buildBadgeChip(_Badge badge) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
  decoration: BoxDecoration(
    color: badge.bg,
    borderRadius: BorderRadius.circular(30),
    border: Border.all(color: badge.fg.withValues(alpha: 0.25)),
  ),
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(badge.icon, size: 12, color: badge.fg),
    const SizedBox(width: 4),
    Text(badge.label, style: GoogleFonts.manrope(fontSize: 11, fontWeight: FontWeight.w700, color: badge.fg)),
  ]),
);

// ─────────────────────────────────────────────────────────────
//  SHARED HISTORY TILE (used by both the list and calendar views)
// ─────────────────────────────────────────────────────────────
String _formatDate(String? date) {
  if (date == null || date.trim().isEmpty) return 'N/A';
  try { return DateFormat('dd MMM yyyy').format(DateTime.parse(date)); }
  catch (_) { return date; }
}

Widget _buildStatusChip(String? status) {
  final n = (status ?? 'N/A').trim();
  final color = n.toLowerCase() == 'verified' ? Colors.green
      : n.toLowerCase() == 'pending'  ? Colors.orange
      : n.toLowerCase() == 'rejected' ? Colors.red
      : Colors.blueGrey;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(n, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

Widget _buildKeyValue(String label, String? value) => RichText(
  text: TextSpan(
    style: const TextStyle(color: Colors.black87, fontSize: 12),
    children: [
      TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
      TextSpan(text: (value == null || value.trim().isEmpty) ? 'N/A' : value),
    ],
  ),
);

Widget _imageBlock(String title, String? url, TotalAttendanceViewController controller) {
  final full = controller.fullImageUrl(url);
  if (full.isEmpty) return const SizedBox();
  return Padding(
    padding: EdgeInsets.only(top: 10.h),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.manrope(
        fontSize: 13.sp, fontWeight: FontWeight.w700,
        color: const Color(0xFF241917),
      )),
      SizedBox(height: 8.h),
      ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(full, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFF1F1F1), alignment: Alignment.center,
              child: Text('Image unavailable',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp, color: const Color(0xFF8B7D77),
                  )),
            ),
            loadingBuilder: (_, child, p) {
              if (p == null) return child;
              return Container(color: const Color(0xFFF1F1F1),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator());
            },
          ),
        ),
      ),
    ]),
  );
}

Widget _buildHistoryTile(AttendanceHistory item, TotalAttendanceViewController controller) {
  final badges = _AttendanceLogic.getBadges(item.checkInTime, item.checkOutTime);
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8, offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.calendar_today, size: 15, color: Colors.blueGrey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(_formatDate(item.date),
              style: GoogleFonts.manrope(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E1E),
              )),
        ),
        _buildStatusChip(item.status),
      ]),
      const SizedBox(height: 10),
      if (badges.isNotEmpty) ...[
        Wrap(spacing: 6, runSpacing: 6,
            children: badges.map(_buildBadgeChip).toList()),
        const SizedBox(height: 10),
      ],
      Wrap(spacing: 12, runSpacing: 6, children: [
        _buildKeyValue('Check in',        item.checkInTime),
        _buildKeyValue('Check out',       item.checkOutTime),
        _buildKeyValue('Total',           item.totalTime),
        _buildKeyValue('Checkout status', item.checkoutStatus),
      ]),
      _imageBlock('Check-in Photo',  item.imageUrl, controller),
      _imageBlock('Check-out Photo', item.checkoutImageUrl, controller),
      if ((item.isSuspicious ?? false) ||
          (item.suspiciousReason?.trim().isNotEmpty ?? false)) ...[
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.flag, size: 14, color: Colors.redAccent),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Flag: ${item.suspiciousReason?.trim().isNotEmpty == true ? item.suspiciousReason : 'Marked suspicious'}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ]),
      ],
      if (item.locationAddress?.trim().isNotEmpty ?? false) ...[
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Expanded(
            child: Text(item.locationAddress!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
        ]),
      ],
    ]),
  );
}

// ─────────────────────────────────────────────────────────────
//  HISTORY BODY — toggles between List and Calendar views
// ─────────────────────────────────────────────────────────────
class _HistoryBody extends StatefulWidget {
  final List<AttendanceHistory> history;
  final TotalAttendanceViewController controller;
  const _HistoryBody({required this.history, required this.controller});

  @override
  State<_HistoryBody> createState() => _HistoryBodyState();
}

class _HistoryBodyState extends State<_HistoryBody> {
  bool _showCalendar = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: _ViewToggle(
            showCalendar: _showCalendar,
            onChanged: (v) => setState(() => _showCalendar = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _showCalendar
              ? _AttendanceCalendarView(
                  history: widget.history, controller: widget.controller)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _buildHistoryTile(widget.history[i], widget.controller),
                ),
        ),
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final bool showCalendar;
  final ValueChanged<bool> onChanged;
  const _ViewToggle({required this.showCalendar, required this.onChanged});

  Widget _seg(String label, IconData icon, bool active, VoidCallback onTap) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF4361EE) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 15, color: active ? Colors.white : Colors.black54),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : Colors.black54,
                  )),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        _seg('Calendar', Icons.calendar_month_rounded, showCalendar,
            () => onChanged(true)),
        _seg('List', Icons.list_rounded, !showCalendar, () => onChanged(false)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CALENDAR VIEW — per-day P/A markers + tap-to-see-details
// ─────────────────────────────────────────────────────────────
class _AttendanceCalendarView extends StatefulWidget {
  final List<AttendanceHistory> history;
  final TotalAttendanceViewController controller;
  const _AttendanceCalendarView(
      {required this.history, required this.controller});

  @override
  State<_AttendanceCalendarView> createState() =>
      _AttendanceCalendarViewState();
}

class _AttendanceCalendarViewState extends State<_AttendanceCalendarView> {
  static const _blue = Color(0xFF4361EE);
  static const _present = Color(0xFF1E8E3E);
  static const _absent = Color(0xFFD93025);

  late final Map<DateTime, AttendanceHistory> _byDate;
  late DateTime _firstRecordDay;
  late DateTime _lastRecordDay;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _byDate = {};
    for (final r in widget.history) {
      final d = _parseDate(r.date);
      if (d != null) _byDate[_dateOnly(d)] = r;
    }
    final dates = _byDate.keys.toList()..sort();
    final today = _dateOnly(DateTime.now());
    _firstRecordDay = dates.isNotEmpty ? dates.first : today;
    _lastRecordDay = dates.isNotEmpty ? dates.last : today;
    _focusedDay = _lastRecordDay;
    _selectedDay = _byDate.containsKey(today) ? today : _lastRecordDay;
  }

  /// 'P' if a record exists, 'A' if the day is within the loaded history
  /// range and already past with no record, otherwise no marker.
  String? _markerFor(DateTime day) {
    final key = _dateOnly(day);
    if (_byDate.containsKey(key)) return 'P';
    if (key.isBefore(_firstRecordDay) || key.isAfter(_lastRecordDay)) {
      return null;
    }
    if (key.isAfter(_dateOnly(DateTime.now()))) return null;
    return 'A';
  }

  Widget _dayCell(DateTime day, {bool isToday = false, bool isSelected = false}) {
    final marker = _markerFor(day);
    Color bg = Colors.transparent;
    Color fg = const Color(0xFF1E1E1E);
    if (isSelected) {
      bg = _blue;
      fg = Colors.white;
    } else if (marker == 'P') {
      bg = _present.withValues(alpha: 0.12);
      fg = _present;
    } else if (marker == 'A') {
      bg = _absent.withValues(alpha: 0.12);
      fg = _absent;
    }

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: isToday && !isSelected
            ? Border.all(color: _blue, width: 1.4)
            : null,
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${day.day}',
              style: GoogleFonts.inter(
                  fontSize: 12.sp, fontWeight: FontWeight.w600, color: fg)),
          if (marker != null)
            Text(marker,
                style: GoogleFonts.manrope(
                    fontSize: 8.5.sp,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : fg)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedRecord =
        _selectedDay != null ? _byDate[_dateOnly(_selectedDay!)] : null;

    return Column(
      children: [
        TableCalendar<AttendanceHistory>(
          firstDay: DateTime(_firstRecordDay.year, _firstRecordDay.month - 1, 1),
          lastDay: DateTime(_lastRecordDay.year, _lastRecordDay.month + 1, 0),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) =>
              _selectedDay != null && isSameDay(_selectedDay, day),
          onDaySelected: (selected, focused) {
            setState(() {
              _selectedDay = selected;
              _focusedDay = focused;
            });
          },
          onPageChanged: (focused) => _focusedDay = focused,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: GoogleFonts.manrope(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E1E)),
            leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: _blue),
            rightChevronIcon:
                const Icon(Icons.chevron_right_rounded, color: _blue),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: GoogleFonts.inter(
                fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600),
            weekendStyle: GoogleFonts.inter(
                fontSize: 11, color: Colors.black45, fontWeight: FontWeight.w600),
          ),
          calendarStyle: const CalendarStyle(outsideDaysVisible: false),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) => _dayCell(day),
            todayBuilder: (context, day, focusedDay) =>
                _dayCell(day, isToday: true),
            selectedBuilder: (context, day, focusedDay) =>
                _dayCell(day, isSelected: true),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendDot(_present, 'Present'),
            const SizedBox(width: 16),
            _legendDot(_absent, 'Absent'),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: selectedRecord != null
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildHistoryTile(selectedRecord, widget.controller),
                )
              : Center(
                  child: Text(
                    _selectedDay == null
                        ? 'Select a day to view details'
                        : 'Absent — no attendance record for this day',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700)),
        ],
      );
}

// ─────────────────────────────────────────────────────────────
//  PDF GENERATOR
// ─────────────────────────────────────────────────────────────
class _PdfGenerator {
  static Future<Uint8List> generate({
    required String employeeName,
    required String username,
    required DateTime fromDate,
    required DateTime toDate,
    required List<AttendanceHistory> records,
  }) async {
    final doc     = pw.Document();
    final dateFmt = DateFormat('dd MMM yyyy');

    // Sort by date
    records.sort((a, b) => (a.date ?? '').compareTo(b.date ?? ''));

    // Counts
    int onTime = 0, late = 0, halfDay = 0, sl = 0, ot = 0;
    for (final r in records) {
      final ins  = _AttendanceLogic.getCheckInStatus(r.checkInTime);
      final outs = _AttendanceLogic.getCheckOutStatus(r.checkOutTime);
      if (ins == 'On Time') onTime++;
      if (ins == 'Late Coming') late++;
      if (ins == 'Half Day') halfDay++;
      if (outs == 'Short Leave') sl++;
      if (outs.startsWith('Overtime')) ot++;
    }

    doc.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(28),
        header: (_) => _header(
          name: employeeName, username: username,
          from: dateFmt.format(fromDate), to: dateFmt.format(toDate),
        ),
        footer: (ctx) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('Generated: ${dateFmt.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ]),
        ),
        build: (_) => [
          pw.SizedBox(height: 14),
          _summaryRow(records.length, onTime, late, halfDay, sl, ot),
          pw.SizedBox(height: 18),
          _table(records),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _header({
    required String name, required String username,
    required String from, required String to,
  }) => pw.Column(children: [
    pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColor.fromInt(0xFF4361EE), PdfColor.fromInt(0xFF7B2FBE)],
        ),
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),

      ),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('ATTENDANCE REPORT',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          pw.SizedBox(height: 3),
          pw.Text('$from  →  $to',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(name,
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          pw.SizedBox(height: 2),
          pw.Text('@$username',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
        ]),
      ]),
    ),
    pw.SizedBox(height: 6),
    pw.Divider(color: PdfColors.grey300),
  ]);

  static pw.Widget _summaryRow(int total, int onTime, int late, int halfDay, int sl, int ot) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFF4F6FF),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),

          border: pw.Border.all(color: const PdfColor.fromInt(0xFFDDE2F0)),
        ),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceAround, children: [
          _summaryBox('Total',       '$total',   PdfColors.blueAccent),
          _summaryBox('On Time',     '$onTime',  PdfColors.green700),
          _summaryBox('Late',        '$late',    PdfColors.orange),
          _summaryBox('Half Day',    '$halfDay', PdfColors.red),
          _summaryBox('Short Leave', '$sl',      PdfColors.indigo),
          _summaryBox('Overtime',    '$ot',      PdfColors.teal),
        ]),
      );

  static pw.Widget _summaryBox(String label, String value, PdfColor color) =>
      pw.Column(children: [
        pw.Container(
          width: 52, height: 36,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: color,
                   borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),

          ),
          child: pw.Text(value,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ]);

  static pw.Widget _table(List<AttendanceHistory> records) {
    const hStyle = pw.TextStyle(color: PdfColors.white, fontSize: 9);
    const cStyle = pw.TextStyle(fontSize: 8);
    const hBg    = PdfColor.fromInt(0xFF4361EE);

    String fmtDate(String? raw) {
      if (raw == null || raw.isEmpty) return '-';
      try { return DateFormat('dd MMM yy').format(DateTime.parse(raw)); }
      catch (_) { return raw.length > 10 ? raw.substring(0, 10) : raw; }
    }

    PdfColor inColor(String s) {
      if (s == 'On Time')     return PdfColors.green700;
      if (s == 'Late Coming') return PdfColors.orange;
      if (s == 'Half Day')    return PdfColors.red;
      return PdfColors.grey600;
    }

    PdfColor outColor(String s) {
      if (s == 'Short Leave')         return PdfColors.indigo;
      if (s.startsWith('Overtime'))   return PdfColors.teal;
      return PdfColors.grey600;
    }

    pw.Widget cell(String t, pw.TextStyle s) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 7),
      child: pw.Text(t, style: s, textAlign: pw.TextAlign.center),
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.8),
        5: const pw.FlexColumnWidth(2.0),
        6: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: hBg),
          children: [
            cell('Date',        hStyle), cell('Check In',   hStyle),
            cell('Check Out',   hStyle), cell('Total Time', hStyle),
            cell('In Status',   hStyle), cell('Out Status', hStyle),
            cell('Status',      hStyle),
          ],
        ),
        ...records.asMap().entries.map((e) {
          final i = e.key; final r = e.value;
          final bg   = i.isOdd ? const PdfColor.fromInt(0xFFF8F9FF) : PdfColors.white;
          final ins  = _AttendanceLogic.getCheckInStatus(r.checkInTime);
          final outs = _AttendanceLogic.getCheckOutStatus(r.checkOutTime);
          final outShort = outs.length > 15 ? '${outs.substring(0, 13)}..' : outs;

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              cell(fmtDate(r.date),         cStyle),
              cell(r.checkInTime  ?? '-',   cStyle),
              cell(r.checkOutTime ?? '-',   cStyle),
              cell(r.totalTime    ?? '-',   cStyle),
              cell(ins,      pw.TextStyle(fontSize: 8, color: inColor(ins),   fontWeight: pw.FontWeight.bold)),
              cell(outShort, pw.TextStyle(fontSize: 8, color: outColor(outs), fontWeight: pw.FontWeight.bold)),
              cell(r.status ?? '-',         cStyle),
            ],
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  DATE RANGE + PDF BOTTOM SHEET
// ─────────────────────────────────────────────────────────────
class _PdfSheet extends StatefulWidget {
  final Results employee;
  final TotalAttendanceViewController controller;
  const _PdfSheet({required this.employee, required this.controller});

  @override
  State<_PdfSheet> createState() => _PdfSheetState();
}

class _PdfSheetState extends State<_PdfSheet> {
  DateTime? _from;
  DateTime? _to;
  bool _generating = false;
  final _fmt = DateFormat('dd MMM yyyy');

  static const _blue   = Color(0xFF4361EE);
  static const _purple = Color(0xFF7B2FBE);

  Future<void> _pick({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_from ?? DateTime.now()) : (_to ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _blue, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) { _from = picked; if (_to != null && _to!.isBefore(picked)) _to = null; }
      else _to = picked;
    });
  }

  List<AttendanceHistory> get _filtered {
    if (_from == null || _to == null) return [];
    final all = widget.employee.attendanceHistory ?? [];
    return all.where((r) {
      try {
        final d    = DateTime.parse(r.date ?? '');
        final from = DateTime(_from!.year, _from!.month, _from!.day);
        final to   = DateTime(_to!.year,   _to!.month,   _to!.day, 23, 59);
        return !d.isBefore(from) && !d.isAfter(to);
      } catch (_) { return false; }
    }).toList();
  }

  Future<void> _generate() async {
    final records = _filtered;
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No records in selected range',
            style: GoogleFonts.manrope(fontSize: 13.sp)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      ));
      return;
    }
    setState(() => _generating = true);
    try {
      final bytes = await _PdfGenerator.generate(
        employeeName: widget.employee.fullName ?? 'Unknown',
        username:     widget.employee.username ?? '-',
        fromDate: _from!, toDate: _to!,
        records: records,
      );
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Attendance_${widget.employee.username}_${DateFormat('yyyyMMdd').format(_from!)}.pdf',
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e', style: GoogleFonts.manrope(fontSize: 12.sp)),
        backgroundColor: Colors.redAccent,
      ));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final canGen   = _from != null && _to != null && !_generating;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40.w, height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(height: 18.h),

          // Title row
          Row(children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_blue, _purple]),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20.sp),
            ),
            SizedBox(width: 12.w),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Export Attendance PDF',
                  style: GoogleFonts.manrope(
                    fontSize: 15.sp, fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1E1E),
                  )),
              Text(widget.employee.fullName ?? '',
                  style: GoogleFonts.manrope(fontSize: 12.sp, color: Colors.black38)),
            ]),
          ]),
          SizedBox(height: 22.h),

          // Date pickers
          Text('Select Date Range',
              style: GoogleFonts.manrope(
                fontSize: 13.sp, fontWeight: FontWeight.w700, color: const Color(0xFF333333),
              )),
          SizedBox(height: 12.h),
          Row(children: [
            Expanded(child: _dateTile('From', _from, () => _pick(isFrom: true))),
            SizedBox(width: 12.w),
            Expanded(child: _dateTile('To',   _to,   () => _pick(isFrom: false))),
          ]),
          SizedBox(height: 14.h),

          // Record count badge
          if (_from != null && _to != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: filtered.isEmpty ? const Color(0xFFFFEEF1) : const Color(0xFFEEF0FF),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: filtered.isEmpty
                      ? const Color(0xFFE8607A).withValues(alpha: 0.3)
                      : _blue.withValues(alpha: 0.3),
                ),
              ),
              child: Row(children: [
                Icon(
                  filtered.isEmpty ? Icons.info_outline_rounded : Icons.check_circle_outline_rounded,
                  size: 16.sp,
                  color: filtered.isEmpty ? const Color(0xFFE8607A) : _blue,
                ),
                SizedBox(width: 8.w),
                Text(
                  filtered.isEmpty
                      ? 'No records found in this range'
                      : '${filtered.length} record${filtered.length == 1 ? '' : 's'} found',
                  style: GoogleFonts.manrope(
                    fontSize: 12.sp, fontWeight: FontWeight.w600,
                    color: filtered.isEmpty ? const Color(0xFFE8607A) : _blue,
                  ),
                ),
              ]),
            ),

          SizedBox(height: 22.h),

          // Generate button
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: canGen ? _generate : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                disabledBackgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: _generating
                  ? SizedBox(
                      width: 20.w, height: 20.w,
                      child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.picture_as_pdf_rounded, size: 20),
                      SizedBox(width: 8.w),
                      Text('Generate & Preview PDF',
                          style: GoogleFonts.manrope(fontSize: 14.sp, fontWeight: FontWeight.w700)),
                    ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FF),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: date != null ? _blue.withValues(alpha: 0.4) : Colors.grey.shade200,
              width: date != null ? 1.5 : 1,
            ),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today_rounded, size: 16.sp,
                color: date != null ? _blue : Colors.grey),
            SizedBox(width: 8.w),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: GoogleFonts.manrope(
                    fontSize: 10.sp, color: Colors.black38, fontWeight: FontWeight.w600,
                  )),
              Text(
                date != null ? _fmt.format(date) : 'Select',
                style: GoogleFonts.manrope(
                  fontSize: 13.sp, fontWeight: FontWeight.w700,
                  color: date != null ? const Color(0xFF1E1E1E) : Colors.grey,
                ),
              ),
            ]),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
//  MAIN VIEW
// ─────────────────────────────────────────────────────────────
class Totalattendanceview extends GetView<TotalAttendanceViewController> {
  final TextEditingController searchController = TextEditingController();
  DateTimeRange? selectedDateRange;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Attendance History',
          style: GoogleFonts.manrope(
            fontSize: 20, fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value)        return _buildLoading();
        if (controller.errorMessage.isNotEmpty) return _buildError();
        return _buildAttendanceList(context);
      }),
    );
  }

  Widget _buildLoading() => const Center(child: CircularProgressIndicator());

  Widget _buildError() => Center(
    child: Text(controller.errorMessage.value,
        style: const TextStyle(color: Colors.red)),
  );

  // ── Employee List ─────────────────────────────────────────────
  Widget _buildAttendanceList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: controller.attendanceData.length,
      itemBuilder: (context, index) {
        final data = controller.attendanceData[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(
                      controller.fullImageUrl(data.profileImage ?? '')),
                  backgroundColor: const Color(0xFFEDEFF3),
                  onBackgroundImageError: (_, __) {},
                  child: Text(
                    _initials(data.fullName),
                    style: GoogleFonts.manrope(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A2A2A),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              data.fullName ?? 'No Name',
              style: GoogleFonts.manrope(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: const Color(0xFF1F1F1F),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.username ?? 'No Username',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7A7A7A))),
                const SizedBox(height: 4),
                // History count badge
                if ((data.attendanceHistory?.length ?? 0) > 0)
                  Row(children: [
                    Icon(Icons.event_note_rounded,
                        size: 12, color: const Color(0xFF4361EE).withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      '${data.attendanceHistory!.length} records',
                      style: GoogleFonts.manrope(
                        fontSize: 11, color: const Color(0xFF4361EE),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // PDF icon button
                GestureDetector(
                  onTap: () => _openPdfSheet(context, data),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF0FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded,
                        size: 18, color: Color(0xFF4361EE)),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.black54),
              ],
            ),
            onTap: () => _onTapEmployee(context, data),
          ),
        );
      },
    );
  }

  // ── Employee tap → show options ───────────────────────────────
  void _onTapEmployee(BuildContext context, Results data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w, height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(height: 18.h),
            // Employee info header
            Row(children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: const Color(0xFFEDEFF3),
                child: Text(_initials(data.fullName),
                    style: GoogleFonts.manrope(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A2A2A),
                    )),
              ),
              SizedBox(width: 12.w),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data.fullName ?? 'No Name',
                    style: GoogleFonts.manrope(
                      fontSize: 15, fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E1E1E),
                    )),
                Text(data.username ?? '',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.black38)),
              ]),
            ]),
            SizedBox(height: 20.h),
            // Option buttons
            _optionTile(
              icon: Icons.history_rounded,
              color: const Color(0xFF7B2FBE),
              bg: const Color(0xFFF3EEFF),
              label: 'View Attendance History',
              subtitle: '${data.attendanceHistory?.length ?? 0} records available',
              onTap: () {
                Navigator.pop(context);
                _showAttendanceHistory(context, data);
              },
            ),
            SizedBox(height: 10.h),
            _optionTile(
              icon: Icons.picture_as_pdf_rounded,
              color: const Color(0xFF4361EE),
              bg: const Color(0xFFEEF0FF),
              label: 'Export PDF Report',
              subtitle: 'Choose date range and generate PDF',
              onTap: () {
                Navigator.pop(context);
                _openPdfSheet(context, data);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required Color color,
    required Color bg,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.06),
                blurRadius: 12, offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12.r)),
              child: Icon(icon, color: color, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.manrope(
                  fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E1E1E),
                )),
                SizedBox(height: 2.h),
                Text(subtitle, style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.black38,
                )),
              ],
            )),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
          ]),
        ),
      );

  // ── Open PDF sheet ────────────────────────────────────────────
  void _openPdfSheet(BuildContext context, Results data) {
    final history = data.attendanceHistory ?? [];
    if (history.isEmpty) {
      Get.snackbar(
        'No Records',
        '${data.fullName ?? 'Employee'} has no attendance records to export.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _PdfSheet(employee: data, controller: controller),
      ),
    );
  }

  // ── Attendance History Bottom Sheet ───────────────────────────
  void _showAttendanceHistory(BuildContext context, Results employee) {
    final history = employee.attendanceHistory ?? [];
    if (history.isEmpty) {
      Get.snackbar(
        'No Attendance History',
        '${employee.fullName ?? 'Employee'} has no attendance entries.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.88,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(employee.fullName ?? 'Attendance History',
                          style: GoogleFonts.manrope(
                            fontSize: 18, fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1E1E),
                          )),
                      const SizedBox(height: 2),
                      Text(employee.username ?? '',
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
                    ]),
                  ),
                  // PDF button in history sheet header
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _openPdfSheet(context, employee);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF0FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        const Icon(Icons.picture_as_pdf_rounded,
                            size: 16, color: Color(0xFF4361EE)),
                        const SizedBox(width: 5),
                        Text('Export PDF',
                            style: GoogleFonts.manrope(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: const Color(0xFF4361EE),
                            )),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: _HistoryBody(history: history, controller: controller),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Search & Filter',
            style: GoogleFonts.manrope(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search by Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () async {
              selectedDateRange = await showDateRangePicker(
                context: context,
                initialDateRange: selectedDateRange,
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
            },
            child: const SizedBox.shrink(),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              controller.fetchattendance(
                startDate: selectedDateRange?.start.toString(),
                endDate:   selectedDateRange?.end.toString(),
                search:    searchController.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Apply Filters', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final p = name.trim().split(' ');
    return p.length == 1 ? p[0][0].toUpperCase() : '${p[0][0]}${p[1][0]}'.toUpperCase();
  }
}