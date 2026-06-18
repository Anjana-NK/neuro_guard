class UserProfile {
  String role = 'I Need Support'; // 'I Need Support' or 'Caregiver'
  String name = '';
  String age = '';
  String autismStatus = 'No'; // 'Yes', 'No', 'Undiagnosed'
  
  bool isStudent = false;
  String studentHighest = 'Graduate'; // 10th, 12th, Graduate, Post Graduate, Diploma
  String studentStatus = 'College';   // Schooling, College, ITI, Not Enrolled
  String studentInstitution = '';     // e.g. CUSAT
  String studentCourse = 'B.Tech';    // B.Tech, M.Tech, IMSC, B.Sc, B.Com, BBA
  
  bool isEmployee = false;
  String employeeCompany = '';
  String employeeRole = '';
  String employeeSupportDesired = 'UNSURE'; // YES, NO, UNSURE
  
  String state = 'Kerala'; // Kerala, Tamil Nadu, Karnataka, Maharashtra, Delhi
  String pincode = '';
  
  String disabilityCertificate = 'Looking to apply'; // Obtained, Pending, Looking to apply
  String communicationMethod = 'Verbal'; // Verbal, Non-verbal/AAC devices, Gestures
  String sensorySensitivity = 'None'; // High, Moderate, None
  
  String incomeRange = 'Below \u20b92.5L'; // Below \u20b92.5L, \u20b92.5L - \u20b98L, Above \u20b98L
  String targetedPath = 'Academic grants'; // Neurodivergent-friendly corporate jobs, vocational training, academic grants
  bool insuranceNiramaya = false;
  String email = 'user@example.com';

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'name': name,
      'age': age,
      'autismStatus': autismStatus,
      'isStudent': isStudent,
      'studentHighest': studentHighest,
      'studentStatus': studentStatus,
      'studentInstitution': studentInstitution,
      'studentCourse': studentCourse,
      'isEmployee': isEmployee,
      'employeeCompany': employeeCompany,
      'employeeRole': employeeRole,
      'employeeSupportDesired': employeeSupportDesired,
      'state': state,
      'pincode': pincode,
      'disabilityCertificate': disabilityCertificate,
      'communicationMethod': communicationMethod,
      'sensorySensitivity': sensorySensitivity,
      'incomeRange': incomeRange,
      'targetedPath': targetedPath,
      'insuranceNiramaya': insuranceNiramaya,
      'email': email,
    };
  }
}
