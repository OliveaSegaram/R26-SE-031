class ComprehensiveQuestion {
  final String text;
  
  const ComprehensiveQuestion({required this.text});
}

class ComprehensiveAssessmentData {
  static const List<ComprehensiveQuestion> basicAssessment = [
    ComprehensiveQuestion(text: 'ඔබේ දරුවාට වම සහ දකුණ හඳුනාගැනීමට අපහසුද?'),
    ComprehensiveQuestion(text: 'කියවීමේදී ඔබේ දරුවා ඉක්මනින්ම මහන්සි වනවාද?'),
    ComprehensiveQuestion(text: 'කියවීමේදී ඔබේ දරුවාගේ අවධානය නිතර වෙනත් දේවල් වෙත යොමුවනවාද?'),
    ComprehensiveQuestion(text: 'කියවීමේදී ඔබේ දරුවා නිතර වැරදි කරනවාද?'),
    ComprehensiveQuestion(text: 'එක කාර්යයක් කෙරෙහි දිගු වේලාවක් අවධානය පවත්වා ගැනීමට ඔබේ දරුවාට අපහසුද?'),
    ComprehensiveQuestion(text: 'පුද්ගලයන්ගේ නම් මතක තබා ගැනීමට ඔබේ දරුවාට අපහසුද?'),
    ComprehensiveQuestion(text: 'කතා කරන විට වචන නිවැරදිව උච්චාරණය කිරීමට ඔබේ දරුවාට අපහසුද?'),
    ComprehensiveQuestion(text: 'දන්නා කෙටි වචන ලියන ආකාරය සමහර විට ඔබේ දරුවාට අමතක වනවාද?'),
    ComprehensiveQuestion(text: 'කලින් නොදුටු වචන නිවැරදිව ලිවීමට ඔබේ දරුවාට අපහසුද?'),
    ComprehensiveQuestion(text: 'කලින් නොකියවූ වචන කියවීමට ඔබේ දරුවාට අපහසුද?'),
    ComprehensiveQuestion(text: 'වචනයක තේරුම දැන සිටියත් එය ලිවීමට ඔබේ දරුවාට අපහසුද?'),
    ComprehensiveQuestion(text: 'කියවීමේදී සමහර වචන ළඟ නතර වී නැවත උත්සාහ කිරීමට ඔබේ දරුවාට සිදුවනවාද?'),
    ComprehensiveQuestion(text: 'කියවීමේදී ඔබේ දරුවාගේ ඇස් හොඳින් එකට ක්‍රියා නොකරන බවක් පෙනෙනවාද?'),
    ComprehensiveQuestion(text: 'කියවීමේදී වචන හෙලවෙනවා, බොඳව පෙනෙනවා හෝ අවධානය යොමු කිරීමට අපහසු බව ඔබේ දරුවා පවසනවාද?'),
  ];

  static const List<ComprehensiveQuestion> readingAssessment = [
    ComprehensiveQuestion(text: 'කුඩා කාලයේ සිට අකුරු හා ශබ්ද අතර සම්බන්ධතාවය (Phonics) ඉගෙන ගැනීමට ඔබේ දරුවාට අපහසුතා තිබුණාද?'),
    ComprehensiveQuestion(text: 'ශබ්ද නඟා කියවීමේදී ඔබේ දරුවා නිතර වැරදි කරනවාද?'),
    ComprehensiveQuestion(text: 'ලියා ඇති දේ නැවත නැවත කියවීමකින් තොරව තේරුම් ගැනීමට ඔබේ දරුවාට අපහසුද?'),
    ComprehensiveQuestion(text: 'ඔබේ දරුවාගේ කියවීමේ වේගය මන්දගාමීද?'),
    ComprehensiveQuestion(text: 'කියවීමේදී වචන අතහැර යාම හෝ වැරදි ලෙස කියවීම සිදුවනවාද?'),
    ComprehensiveQuestion(text: 'කියවීමේදී කියවමින් සිටි ස්ථානය අහිමි කරගැනීම ඔබේ දරුවාට සිදුවනවාද?'),
    ComprehensiveQuestion(text: 'ලිපියක් ඉක්මනින් පිරික්සා අවශ්‍ය තොරතුරු සොයා ගැනීමට ඔබේ දරුවාට අපහසුද?'),
    ComprehensiveQuestion(text: 'කියවීමේදී ඔබේ දරුවා ඉක්මනින් අවධානය වෙනතකට යොමුවනවාද?'),
    ComprehensiveQuestion(text: 'කියවීමේදී වචන හෙලවෙනවා, එකට මිශ්‍ර වනවා හෝ වෙනස් ලෙස පෙනෙනවා කියා ඔබේ දරුවා පවසනවාද?'),
    ComprehensiveQuestion(text: 'සුදු කඩදාසියක් හෝ සුදු පුවරුවක් දෙස බලන විට ඇස්වල අපහසුතාවයක් ඔබේ දරුවාට දැනෙනවාද?'),
  ];

  static const List<ComprehensiveQuestion> writingAssessment = [
    ComprehensiveQuestion(text: 'ඔබේ දරුවාට වචන නිවැරදිව අක්ෂර වින්‍යාස කිරීම දිගින් දිගටම අපහසුද?'),
    ComprehensiveQuestion(text: 'සමාන කෙටි වචන එකිනෙකට පටලවා ගැනීම ඔබේ දරුවාට සිදුවනවාද?'),
    ComprehensiveQuestion(text: 'ලියන විට, විශේෂයෙන් පීඩනයක් යටතේ, වචන අතහැර යාම සිදුවනවාද?'),
    ComprehensiveQuestion(text: 'ඔබේ දරුවාගේ අත් අකුරු පැහැදිලි නොවීම හෝ ලිවීමේ වේගය මන්දගාමී වීම පෙනෙනවාද?'),
    ComprehensiveQuestion(text: 'කතා කිරීමේ හැකියාවට සාපේක්ෂව ලිවීමේ හැකියාව අඩු බව පෙනෙනවාද?'),
    ComprehensiveQuestion(text: 'කතා කිරීමේදී තම අදහස් හොඳින් ප්‍රකාශ කළද, එම අදහස් ලිවීමේදී ප්‍රකාශ කිරීමට ඔබේ දරුවාට අපහසුද?'),
  ];

  static const List<ComprehensiveQuestion> otherAssessment = [
    ComprehensiveQuestion(text: 'කුඩා කාලයේදී කථන හෝ භාෂා සංවර්ධනයේ ප්‍රමාදයක් තිබුණාද?'),
    ComprehensiveQuestion(text: 'කුඩා කාලයේදී මැද කනේ ආසාදන (Glue Ear / Otitis Media) ඇති වී තිබුණාද?'),
    ComprehensiveQuestion(text: 'ඇදුම, එක්සීමා වැනි ප්‍රතිශක්තිකරණ පද්ධතියට සම්බන්ධ රෝග තිබුණාද?'),
    ComprehensiveQuestion(text: 'හොඳින් කතා කළද, අදහස් පිළිවෙළකට ප්‍රකාශ කිරීමට ඔබේ දරුවාට අපහසුද?'),
    ComprehensiveQuestion(text: 'අවශ්‍ය වචනය මතකයට ගන්නා විට ප්‍රමාද වීම හෝ වචන වැරදි ලෙස උච්චාරණය කිරීම සිදුවනවාද?'),
    ComprehensiveQuestion(text: 'ප්‍රශ්නයක් ඇසූ විට, එය තේරුම් ගෙන පිළිතුරු දීමට සාමාන්‍යයෙන් වඩා වැඩි කාලයක් ගන්නවාද?'),
    ComprehensiveQuestion(text: 'ඔබේ දරුවාට මතක තබා ගැනීමේ අපහසුතා තිබෙනවාද?'),
    ComprehensiveQuestion(text: 'ගණිත ගණනය කිරීම්, සංඛ්‍යා පිටපත් කිරීම හෝ ගුණක වගු මතක තබා ගැනීමේ අපහසුතා තිබෙනවාද?'),
    ComprehensiveQuestion(text: 'ADHD හෝ Dyspraxia වැනි වෙනත් සංවර්ධන සම්බන්ධ තත්ත්වයක් හඳුනාගෙන තිබෙනවාද?'),
    ComprehensiveQuestion(text: 'තමන්ට අපහසු තත්ත්වයන්ට මුහුණ දෙන විට අධික කනස්සල්ලක් හෝ භීතියක් පෙන්වනවාද?'),
    ComprehensiveQuestion(text: 'කාලය කළමනාකරණය කිරීම, පිළිවෙළට වැඩ කිරීම, හෝ අවකාශය පිළිබඳ අවබෝධය සම්බන්ධ අපහසුතා තිබෙනවාද?'),
    ComprehensiveQuestion(text: 'සාමාන්‍ය බුද්ධිමය හැකියාව තිබුණද, විශේෂයෙන් කියවීම හා ලිවීම සම්බන්ධ පාසල් කාර්යසාධනය බලාපොරොත්තු වූ මට්ටමට නොපැමිණෙන බව පෙනෙනවාද?'),
  ];

  static List<ComprehensiveQuestion> getQuestionsByCategory(String category) {
    switch (category) {
      case 'basic': return basicAssessment;
      case 'reading': return readingAssessment;
      case 'writing': return writingAssessment;
      case 'other': return otherAssessment;
      default: return [];
    }
  }

  static String getCategoryTitle(String category) {
    switch (category) {
      case 'basic': return 'මූලික ඩිස්ලෙක්සියා පරීක්ෂණය';
      case 'reading': return 'කියවීම හා දෘශ්‍ය සංජානන සම්බන්ධ අපහසුතා';
      case 'writing': return 'ලිවීම සම්බන්ධ අපහසුතා';
      case 'other': return 'වෙනත් සම්බන්ධ අපහසුතා';
      default: return '';
    }
  }
}
