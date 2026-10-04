import 'exam_segment_seed.dart';
import 'segments/juz_01_08_segments_seed.dart';
import 'segments/juz_09_16_segments_seed.dart';
import 'segments/juz_17_24_segments_seed.dart';
import 'segments/juz_25_30_segments_seed.dart';

/// Every examination segment of the project, in Mushaf order. Hafs 'an Asim
/// by the way of al-Shatibiyyah, Madinah Mushaf of 604 pages.
///
/// A segment is a run of whole ayahs of one surah on one page, of about five
/// to seven lines.
const examSegmentSeeds = <ExamSegmentSeed>[
  ...juz01To08Segments,
  ...juz09To16Segments,
  ...juz17To24Segments,
  ...juz25To30Segments,
];

/// The rules that keep a segment out of the courses below the one that
/// introduces them: their place is performed in a way of its own, so a
/// student who has not been taught it cannot read the segment correctly.
///
/// Besides them, only the question Hamza before the definite article does
/// so, at its six places, where Hamzat al-Wasl is read as a long Alif or
/// eased. Every other rule of a higher course leaves the segment open.
const levelRaisingRuleIds = <String>{
  'sakt_iwaja',
  'sakt_marqadina',
  'sakt_man_raq',
  'sakt_bal_ran',
  'sakt_maliyah_halak',
  'hafs_imalah',
  'hafs_tashil',
  'hafs_ishmam_rawm_wasl',
  'hafs_ayn_fawatih',
  'madd_lazim_harfi_muthaqqal',
  'madd_lazim_harfi_mukhaffaf',
};
