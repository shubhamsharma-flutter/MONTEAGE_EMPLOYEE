import 'package:flutter/material.dart';

// One detail row on a card, e.g. a phone icon next to a phone number.
class CrmDetailLine {
  final IconData icon;
  final String text;
  const CrmDetailLine(this.icon, this.text);
}

// One card in an Opportunities / Visits list.
class CrmListItem {
  final String title;
  final List<CrmDetailLine> lines;
  const CrmListItem({required this.title, required this.lines});
}
