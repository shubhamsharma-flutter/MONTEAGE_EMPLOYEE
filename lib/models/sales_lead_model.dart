// Models for the Sales module (montcrm EducationCRM API). Every lead list
// endpoint (today/all visits, today/completed/next day/next week follow-ups)
// returns the same lead record, so they all share [SalesLead].

String _str(dynamic v) => v == null ? '' : v.toString().trim();

class SalesLead {
  final String leadsId;
  final String courseId;
  final String courseName;
  final String organizationName;
  final String contactName;
  final String mobile;
  final String alternateMobile;
  final String email;
  final String alternateEmail;
  final String orgAddress;
  final String currentAddress;
  final String latitude;
  final String longitude;
  final String followupDate;
  final String remarks;
  final String action;
  final String subStatus;
  final String createDate;
  final String updateDate;

  const SalesLead({
    required this.leadsId,
    required this.courseId,
    required this.courseName,
    required this.organizationName,
    required this.contactName,
    required this.mobile,
    required this.alternateMobile,
    required this.email,
    required this.alternateEmail,
    required this.orgAddress,
    required this.currentAddress,
    required this.latitude,
    required this.longitude,
    required this.followupDate,
    required this.remarks,
    required this.action,
    required this.subStatus,
    required this.createDate,
    required this.updateDate,
  });

  factory SalesLead.fromJson(Map<String, dynamic> json) {
    return SalesLead(
      leadsId: _str(json['LeadsId']),
      courseId: _str(json['CourseId']),
      courseName: _str(json['CourseName']),
      organizationName: _str(json['Organizationname']),
      contactName: _str(json['Contactname']),
      mobile: _str(json['LMobile']),
      alternateMobile: _str(json['AlternateMobile']),
      email: _str(json['LEmail']),
      alternateEmail: _str(json['AlternateEmail']),
      orgAddress: _str(json['OrgAddress']),
      currentAddress: _str(json['CurruntAddrs']),
      latitude: _str(json['Leadlatitude']),
      longitude: _str(json['Leadlongitude']),
      followupDate: _str(json['LFollowupdate']),
      remarks: _str(json['LRemarks']),
      action: _str(json['LAction']),
      subStatus: _str(json['LSubstatus']),
      createDate: _str(json['Createdate']),
      updateDate: _str(json['Updatedate']),
    );
  }

  bool get hasLocation =>
      double.tryParse(latitude) != null &&
      double.tryParse(longitude) != null &&
      double.parse(latitude) != 0;

  /// Text the list search matches against.
  String get searchText =>
      '$organizationName $contactName $mobile $alternateMobile $email $courseName'
          .toLowerCase();
}

/// One entry in a lead's follow-up history (GetCommunicateSales).
class SalesFollowupEntry {
  final String remarks;
  final String subStatus;
  final String followupDate;
  final String updateDate;

  const SalesFollowupEntry({
    required this.remarks,
    required this.subStatus,
    required this.followupDate,
    required this.updateDate,
  });

  factory SalesFollowupEntry.fromJson(Map<String, dynamic> json) {
    return SalesFollowupEntry(
      remarks: _str(json['CRemarks']),
      subStatus: _str(json['CSubstatus']),
      followupDate: _str(json['CFollowupdate']),
      updateDate: _str(json['CUpdateDate']),
    );
  }
}

/// Visit type option for Add Visit (SalesCourse).
class SalesVisitType {
  final String id;
  final String name;

  const SalesVisitType({required this.id, required this.name});

  factory SalesVisitType.fromJson(Map<String, dynamic> json) {
    return SalesVisitType(
      id: _str(json['CourseId']),
      name: _str(json['CourseName']),
    );
  }
}
