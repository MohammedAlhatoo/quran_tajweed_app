import '../../../../courses/domain/entities/course_level.dart';
import '../exam_segment_seed.dart';

typedef _S = ExamSegmentSeed;

const _l2 = CourseLevel.qualifying;
const _l3 = CourseLevel.advanced;

// dart format off
/// The segments of Juz 25 to 30, in Mushaf order.
const juz25To30Segments = <ExamSegmentSeed>[
  // الشورى
  _S(42, 16, 19, 485, 1.57, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_iqlab', 'nun_ikhfa_haqiqi',
    'nun_idgham_naqis', 'mim_izhar_shafawi', 'ghunnah_nun_mushaddadah',
    'lam_shamsiyyah', 'lam_qamariyyah', 'lam_jalalah_tafkhim',
    'lam_jalalah_tarqiq', 'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra',
    'qalqalah_kubra', 'madd_tabii', 'madd_muttasil', 'madd_munfasil',
    'madd_badal', 'madd_silah_sughra', 'madd_arid_lil_sukun', 'madd_lazim',
    'madd_lazim_kalimi_muthaqqal', 'hamzat_wasl', 'hamzat_qat',
  ]),
  // الزخرف
  _S(43, 1, 9, 489, 1.6, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_idgham_shafawi', 'mim_ikhfa_shafawi',
    'ghunnah_nun_mushaddadah', 'ghunnah_mim_mushaddadah', 'lam_shamsiyyah',
    'lam_qamariyyah', 'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra',
    'madd_tabii', 'madd_munfasil', 'madd_badal', 'madd_silah_sughra',
    'madd_arid_lil_sukun', 'madd_lazim', 'madd_lazim_harfi_mukhaffaf',
    'hamzat_wasl', 'hamzat_qat',
  ], from: _l3),
  _S(43, 28, 32, 491, 1.45, [
    'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah', 'nun_iqlab',
    'nun_ikhfa_haqiqi', 'nun_izhar_mutlaq', 'nun_idgham_naqis',
    'nun_idgham_kamil', 'mim_izhar_shafawi', 'mim_idgham_shafawi',
    'mim_ikhfa_shafawi', 'ghunnah_nun_mushaddadah', 'ghunnah_mim_mushaddadah',
    'lam_shamsiyyah', 'lam_qamariyyah', 'lam_harf', 'ra_tafkhim', 'ra_tarqiq',
    'qalqalah_sughra', 'madd_tabii', 'madd_muttasil', 'madd_badal',
    'madd_silah_sughra', 'madd_arid_lil_sukun', 'hamzat_wasl', 'hamzat_qat',
  ]),
  _S(43, 54, 60, 493, 1.59, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_iqlab', 'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_idgham_shafawi', 'ghunnah_nun_mushaddadah',
    'ghunnah_mim_mushaddadah', 'lam_qamariyyah', 'lam_harf', 'ra_tafkhim',
    'ra_tarqiq', 'qalqalah_sughra', 'madd_tabii', 'madd_muttasil',
    'madd_munfasil', 'madd_badal', 'madd_silah_sughra', 'madd_arid_lil_sukun',
    'hamzat_wasl', 'hamzat_qat',
  ]),
  // الدخان
  _S(44, 1, 10, 496, 1.79, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_idgham_shafawi', 'ghunnah_nun_mushaddadah',
    'lam_shamsiyyah', 'lam_qamariyyah', 'lam_harf', 'ra_tafkhim', 'ra_tarqiq',
    'qalqalah_sughra', 'madd_tabii', 'madd_muttasil', 'madd_munfasil',
    'madd_badal', 'madd_silah_sughra', 'madd_arid_lil_sukun', 'madd_lazim',
    'madd_lazim_harfi_mukhaffaf', 'hamzat_wasl', 'hamzat_qat',
  ], from: _l3),
  // الجاثية
  _S(45, 4, 8, 499, 1.47, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_iqlab', 'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'ghunnah_nun_mushaddadah', 'ghunnah_mim_mushaddadah',
    'lam_shamsiyyah', 'lam_qamariyyah', 'lam_jalalah_tafkhim',
    'lam_jalalah_tarqiq', 'ra_tafkhim', 'ra_tarqiq', 'madd_tabii',
    'madd_muttasil', 'madd_munfasil', 'madd_badal', 'madd_silah_sughra',
    'madd_arid_lil_sukun', 'madd_lazim', 'madd_lazim_kalimi_muthaqqal',
    'hamzat_wasl', 'hamzat_qat',
  ]),
  // الأحقاف
  _S(46, 10, 12, 503, 1.51, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_iqlab', 'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_ikhfa_shafawi', 'ghunnah_nun_mushaddadah',
    'lam_shamsiyyah', 'lam_qamariyyah', 'lam_jalalah_tafkhim',
    'lam_jalalah_tarqiq', 'lam_fil', 'ra_tafkhim', 'qalqalah_sughra',
    'madd_tabii', 'madd_muttasil', 'madd_munfasil', 'madd_badal',
    'madd_silah_sughra', 'madd_arid_lil_sukun', 'hamzat_wasl', 'hamzat_qat',
  ]),
  _S(46, 22, 25, 505, 1.7, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_iqlab', 'nun_ikhfa_haqiqi',
    'nun_idgham_kamil', 'mim_izhar_shafawi', 'mim_idgham_shafawi',
    'mim_ikhfa_shafawi', 'ghunnah_nun_mushaddadah', 'ghunnah_mim_mushaddadah',
    'lam_shamsiyyah', 'lam_qamariyyah', 'lam_jalalah_tafkhim', 'lam_harf',
    'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra', 'madd_tabii', 'madd_munfasil',
    'madd_badal', 'madd_silah_sughra', 'madd_arid_lil_sukun', 'hamzat_wasl',
    'hamzat_qat',
  ]),
  // محمد
  _S(47, 21, 25, 509, 1.5, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_iqlab', 'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_idgham_shafawi', 'ghunnah_nun_mushaddadah',
    'ghunnah_mim_mushaddadah', 'lam_shamsiyyah', 'lam_qamariyyah',
    'lam_jalalah_tafkhim', 'lam_harf', 'ra_tafkhim', 'ra_tarqiq',
    'qalqalah_sughra', 'madd_tabii', 'madd_muttasil', 'madd_munfasil',
    'madd_badal', 'hamzat_wasl', 'hamzat_qat',
  ]),
  // الفتح
  _S(48, 13, 15, 512, 1.69, [
    'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah', 'nun_iqlab',
    'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'ghunnah_nun_mushaddadah', 'lam_shamsiyyah',
    'lam_qamariyyah', 'lam_jalalah_tafkhim', 'lam_jalalah_tarqiq', 'lam_fil',
    'lam_harf', 'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra', 'madd_tabii',
    'madd_iwad', 'madd_muttasil', 'madd_munfasil', 'madd_silah_sughra',
    'hamzat_wasl', 'hamzat_qat',
  ]),
  _S(48, 29, 29, 515, 1.8, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_idgham_shafawi', 'ghunnah_mim_mushaddadah',
    'lam_shamsiyyah', 'lam_qamariyyah', 'lam_jalalah_tafkhim', 'ra_tafkhim',
    'ra_tarqiq', 'qalqalah_sughra', 'madd_tabii', 'madd_iwad', 'madd_muttasil',
    'madd_badal', 'madd_silah_kubra', 'madd_silah_sughra', 'hamzat_wasl',
    'hamzat_qat',
  ]),
  // الحجرات
  _S(49, 13, 14, 517, 2.02, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_idgham_shafawi', 'ghunnah_nun_mushaddadah',
    'ghunnah_mim_mushaddadah', 'lam_shamsiyyah', 'lam_qamariyyah',
    'lam_jalalah_tafkhim', 'lam_fil', 'ra_tafkhim', 'ra_tarqiq',
    'qalqalah_sughra', 'madd_tabii', 'madd_muttasil', 'madd_munfasil',
    'madd_badal', 'madd_silah_sughra', 'madd_arid_lil_sukun', 'hamzat_wasl',
    'hamzat_qat',
  ]),
  // الذاريات
  _S(51, 9, 20, 521, 1.71, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_ikhfa_shafawi', 'ghunnah_nun_mushaddadah',
    'lam_shamsiyyah', 'lam_qamariyyah', 'ra_tafkhim', 'ra_tarqiq',
    'qalqalah_sughra', 'madd_tabii', 'madd_muttasil', 'madd_munfasil',
    'madd_badal', 'madd_silah_sughra', 'madd_arid_lil_sukun', 'hamzat_wasl',
    'hamzat_qat',
  ]),
  // الطور
  _S(52, 21, 27, 524, 1.58, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_iqlab', 'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_idgham_shafawi', 'mim_ikhfa_shafawi',
    'ghunnah_nun_mushaddadah', 'ghunnah_mim_mushaddadah', 'lam_shamsiyyah',
    'lam_jalalah_tafkhim', 'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra',
    'madd_tabii', 'madd_muttasil', 'madd_munfasil', 'madd_badal',
    'madd_arid_lil_sukun', 'hamzat_wasl', 'hamzat_qat',
  ]),
  // النجم
  _S(53, 23, 26, 526, 1.56, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_iqlab', 'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_idgham_shafawi', 'ghunnah_nun_mushaddadah',
    'ghunnah_mim_mushaddadah', 'lam_shamsiyyah', 'lam_qamariyyah',
    'lam_jalalah_tafkhim', 'lam_jalalah_tarqiq', 'ra_tafkhim',
    'qalqalah_sughra', 'madd_tabii', 'madd_muttasil', 'madd_munfasil',
    'madd_badal', 'hamzat_wasl', 'hamzat_qat',
  ]),
  // القمر
  _S(54, 8, 15, 529, 1.72, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'ghunnah_nun_mushaddadah',
    'idgham_mutajanisayn_saghir', 'lam_shamsiyyah', 'lam_qamariyyah',
    'lam_harf', 'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra', 'madd_tabii',
    'madd_muttasil', 'madd_munfasil', 'madd_badal', 'madd_silah_kubra',
    'hamzat_wasl', 'hamzat_qat',
  ]),
  // الرحمن
  _S(55, 33, 39, 532, 1.74, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_iqlab', 'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'ghunnah_nun_mushaddadah', 'lam_shamsiyyah',
    'lam_qamariyyah', 'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra',
    'madd_tabii', 'madd_muttasil', 'madd_badal', 'madd_silah_kubra',
    'madd_arid_lil_sukun', 'madd_lazim', 'madd_lazim_kalimi_muthaqqal',
    'hamzat_wasl', 'hamzat_qat',
  ]),
  // الواقعة
  _S(56, 21, 40, 535, 1.97, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_iqlab', 'nun_ikhfa_haqiqi',
    'nun_idgham_naqis', 'nun_idgham_kamil', 'mim_izhar_shafawi',
    'ghunnah_nun_mushaddadah', 'ghunnah_mim_mushaddadah', 'lam_shamsiyyah',
    'lam_qamariyyah', 'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra',
    'qalqalah_kubra', 'madd_tabii', 'madd_iwad', 'madd_muttasil',
    'madd_munfasil', 'madd_badal', 'madd_arid_lil_sukun', 'hamzat_wasl',
    'hamzat_qat',
  ]),
  // الحديد
  _S(57, 19, 20, 540, 2.03, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_iqlab', 'nun_ikhfa_haqiqi',
    'nun_izhar_mutlaq', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'ghunnah_nun_mushaddadah', 'ghunnah_mim_mushaddadah',
    'lam_shamsiyyah', 'lam_qamariyyah', 'lam_jalalah_tafkhim',
    'lam_jalalah_tarqiq', 'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra',
    'madd_tabii', 'madd_muttasil', 'madd_munfasil', 'madd_badal',
    'madd_silah_kubra', 'madd_silah_sughra', 'madd_arid_lil_sukun',
    'hamzat_wasl', 'hamzat_qat',
  ]),
  // المجادلة
  _S(58, 4, 6, 542, 1.49, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_iqlab', 'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_ikhfa_shafawi', 'ghunnah_nun_mushaddadah',
    'lam_jalalah_tafkhim', 'lam_jalalah_tarqiq', 'ra_tafkhim', 'ra_tarqiq',
    'qalqalah_sughra', 'qalqalah_kubra', 'madd_tabii', 'madd_munfasil',
    'madd_badal', 'madd_silah_sughra', 'madd_arid_lil_sukun', 'madd_lazim',
    'madd_lazim_kalimi_muthaqqal', 'hamzat_wasl', 'hamzat_qat',
  ]),
  // الحشر
  _S(59, 7, 8, 546, 2.0, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_iqlab', 'nun_ikhfa_haqiqi',
    'nun_idgham_naqis', 'nun_idgham_kamil', 'mim_izhar_shafawi',
    'ghunnah_nun_mushaddadah', 'lam_shamsiyyah', 'lam_qamariyyah',
    'lam_jalalah_tafkhim', 'lam_jalalah_tarqiq', 'ra_tafkhim', 'ra_tarqiq',
    'qalqalah_sughra', 'qalqalah_kubra', 'madd_tabii', 'madd_muttasil',
    'madd_munfasil', 'madd_badal', 'madd_silah_kubra', 'madd_silah_sughra',
    'madd_arid_lil_sukun', 'hamzat_wasl', 'hamzat_qat',
  ]),
  _S(59, 20, 23, 548, 1.87, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_ikhfa_haqiqi', 'nun_idgham_kamil', 'mim_izhar_shafawi',
    'ghunnah_nun_mushaddadah', 'ghunnah_mim_mushaddadah', 'lam_shamsiyyah',
    'lam_qamariyyah', 'lam_jalalah_tafkhim', 'lam_jalalah_tarqiq', 'ra_tafkhim',
    'ra_tarqiq', 'qalqalah_sughra', 'madd_tabii', 'madd_muttasil',
    'madd_munfasil', 'madd_badal', 'madd_silah_sughra', 'madd_arid_lil_sukun',
    'hamzat_wasl', 'hamzat_qat',
  ]),
  // الصف
  _S(61, 6, 8, 552, 1.66, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_iqlab', 'nun_idgham_naqis', 'nun_idgham_kamil', 'mim_izhar_shafawi',
    'mim_idgham_shafawi', 'mim_ikhfa_shafawi', 'ghunnah_nun_mushaddadah',
    'ghunnah_mim_mushaddadah', 'lam_shamsiyyah', 'lam_qamariyyah',
    'lam_jalalah_tafkhim', 'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra',
    'madd_tabii', 'madd_muttasil', 'madd_munfasil', 'madd_badal',
    'madd_silah_kubra', 'madd_silah_sughra', 'madd_arid_lil_sukun',
    'hamzat_wasl', 'hamzat_qat',
  ]),
  // المنافقون
  _S(63, 8, 10, 555, 1.65, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_idgham_shafawi', 'ghunnah_nun_mushaddadah',
    'lam_shamsiyyah', 'lam_qamariyyah', 'lam_jalalah_tarqiq', 'ra_tafkhim',
    'ra_tarqiq', 'qalqalah_sughra', 'madd_tabii', 'madd_muttasil',
    'madd_munfasil', 'madd_badal', 'madd_silah_sughra', 'madd_arid_lil_sukun',
    'hamzat_wasl', 'hamzat_qat',
  ]),
  // التغابن
  _S(64, 6, 8, 556, 1.68, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_ikhfa_shafawi', 'ghunnah_nun_mushaddadah',
    'ghunnah_mim_mushaddadah', 'lam_shamsiyyah', 'lam_qamariyyah',
    'lam_jalalah_tafkhim', 'lam_jalalah_tarqiq', 'lam_fil', 'ra_tafkhim',
    'ra_tarqiq', 'qalqalah_sughra', 'qalqalah_kubra', 'madd_tabii',
    'madd_munfasil', 'madd_badal', 'madd_silah_sughra', 'madd_arid_lil_sukun',
    'hamzat_wasl', 'hamzat_qat',
  ]),
  // الطلاق
  _S(65, 6, 7, 559, 1.51, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_ikhfa_haqiqi',
    'nun_idgham_naqis', 'nun_idgham_kamil', 'mim_izhar_shafawi',
    'mim_idgham_shafawi', 'mim_ikhfa_shafawi', 'ghunnah_nun_mushaddadah',
    'ghunnah_mim_mushaddadah', 'lam_jalalah_tafkhim', 'ra_tafkhim', 'ra_tarqiq',
    'qalqalah_sughra', 'madd_tabii', 'madd_iwad', 'madd_munfasil', 'madd_badal',
    'madd_silah_kubra', 'madd_silah_sughra', 'madd_lazim',
    'madd_lazim_kalimi_muthaqqal', 'hamzat_wasl', 'hamzat_qat',
  ]),
  // الملك
  _S(67, 19, 22, 563, 1.74, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_iqlab', 'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_idgham_shafawi', 'ghunnah_nun_mushaddadah',
    'ghunnah_mim_mushaddadah', 'lam_shamsiyyah', 'lam_qamariyyah', 'lam_harf',
    'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra', 'madd_tabii', 'madd_munfasil',
    'madd_silah_kubra', 'madd_silah_sughra', 'madd_arid_lil_sukun',
    'madd_lazim', 'madd_lazim_kalimi_muthaqqal', 'hamzat_wasl', 'hamzat_qat',
  ]),
  // الحاقة
  _S(69, 21, 33, 567, 1.56, [
    'nun_izhar_halqi', 'nun_idgham_bila_ghunnah', 'nun_iqlab',
    'nun_ikhfa_haqiqi', 'nun_idgham_kamil', 'mim_izhar_shafawi',
    'ghunnah_nun_mushaddadah', 'ghunnah_mim_mushaddadah', 'lam_qamariyyah',
    'lam_jalalah_tarqiq', 'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra',
    'madd_tabii', 'madd_muttasil', 'madd_munfasil', 'madd_badal',
    'madd_silah_sughra', 'madd_arid_lil_sukun', 'hamzat_wasl', 'hamzat_qat',
    'sakt_maliyah_halak',
  ], from: _l3),
  // المعارج
  _S(70, 11, 25, 569, 1.51, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_iqlab', 'nun_ikhfa_haqiqi', 'nun_idgham_kamil', 'mim_izhar_shafawi',
    'ghunnah_nun_mushaddadah', 'ghunnah_mim_mushaddadah', 'lam_shamsiyyah',
    'lam_qamariyyah', 'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra',
    'madd_tabii', 'madd_iwad', 'madd_muttasil', 'madd_munfasil',
    'madd_silah_sughra', 'madd_arid_lil_sukun', 'hamzat_wasl', 'hamzat_qat',
  ]),
  // نوح
  _S(71, 19, 25, 571, 1.72, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_idgham_shafawi', 'ghunnah_nun_mushaddadah',
    'ghunnah_mim_mushaddadah', 'lam_shamsiyyah', 'lam_qamariyyah',
    'lam_jalalah_tafkhim', 'lam_jalalah_tarqiq', 'ra_tafkhim', 'ra_tarqiq',
    'qalqalah_sughra', 'madd_tabii', 'madd_iwad', 'madd_muttasil', 'madd_badal',
    'madd_silah_kubra', 'madd_silah_sughra', 'hamzat_wasl', 'hamzat_qat',
  ]),
  // المدثر
  _S(74, 5, 16, 575, 1.66, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_ikhfa_haqiqi',
    'nun_idgham_naqis', 'nun_idgham_kamil', 'mim_izhar_shafawi',
    'ghunnah_nun_mushaddadah', 'ghunnah_mim_mushaddadah',
    'idgham_mutajanisayn_saghir', 'lam_shamsiyyah', 'lam_qamariyyah',
    'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra', 'qalqalah_kubra',
    'madd_tabii', 'madd_iwad', 'madd_munfasil', 'madd_badal',
    'madd_silah_sughra', 'madd_arid_lil_sukun', 'hamzat_wasl', 'hamzat_qat',
  ]),
  // القيامة
  _S(75, 27, 40, 578, 1.3, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_ikhfa_haqiqi',
    'nun_idgham_naqis', 'nun_idgham_kamil', 'mim_izhar_shafawi',
    'ghunnah_nun_mushaddadah', 'ghunnah_mim_mushaddadah', 'lam_shamsiyyah',
    'lam_qamariyyah', 'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra',
    'qalqalah_kubra', 'madd_tabii', 'madd_iwad', 'madd_munfasil',
    'madd_silah_sughra', 'madd_arid_lil_sukun', 'hamzat_wasl', 'hamzat_qat',
    'sakt_man_raq',
  ], from: _l2),
  // المرسلات
  _S(77, 20, 32, 581, 1.64, [
    'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah', 'nun_ikhfa_haqiqi',
    'nun_idgham_naqis', 'nun_idgham_kamil', 'mim_izhar_shafawi',
    'mim_idgham_shafawi', 'mim_ikhfa_shafawi', 'ghunnah_nun_mushaddadah',
    'idgham_mutaqaribayn_saghir', 'lam_shamsiyyah', 'lam_qamariyyah',
    'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra', 'qalqalah_kubra',
    'madd_tabii', 'madd_iwad', 'madd_muttasil', 'madd_munfasil',
    'madd_silah_sughra', 'madd_arid_lil_sukun', 'hamzat_wasl', 'hamzat_qat',
  ]),
  // عبس
  _S(80, 20, 34, 585, 1.57, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_iqlab', 'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'ghunnah_nun_mushaddadah', 'ghunnah_mim_mushaddadah',
    'lam_shamsiyyah', 'lam_qamariyyah', 'ra_tafkhim', 'ra_tarqiq',
    'qalqalah_sughra', 'madd_tabii', 'madd_iwad', 'madd_muttasil',
    'madd_munfasil', 'madd_silah_sughra', 'madd_arid_lil_sukun', 'madd_lazim',
    'madd_lazim_kalimi_muthaqqal', 'hamzat_wasl', 'hamzat_qat',
  ]),
  // المطففين
  _S(83, 10, 21, 588, 1.57, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_idgham_shafawi', 'mim_ikhfa_shafawi',
    'ghunnah_nun_mushaddadah', 'ghunnah_mim_mushaddadah', 'lam_shamsiyyah',
    'lam_qamariyyah', 'lam_harf', 'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra',
    'madd_tabii', 'madd_munfasil', 'madd_badal', 'madd_silah_kubra',
    'madd_silah_sughra', 'madd_arid_lil_sukun', 'hamzat_wasl', 'hamzat_qat',
    'sakt_bal_ran',
  ], from: _l2),
  // البروج
  _S(85, 10, 20, 590, 1.9, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah',
    'nun_ikhfa_haqiqi', 'nun_idgham_naqis', 'nun_idgham_kamil',
    'mim_izhar_shafawi', 'mim_idgham_shafawi', 'ghunnah_nun_mushaddadah',
    'ghunnah_mim_mushaddadah', 'lam_shamsiyyah', 'lam_qamariyyah',
    'lam_jalalah_tafkhim', 'lam_harf', 'ra_tafkhim', 'ra_tarqiq',
    'qalqalah_sughra', 'qalqalah_kubra', 'madd_tabii', 'madd_muttasil',
    'madd_badal', 'madd_silah_sughra', 'madd_arid_lil_sukun', 'hamzat_wasl',
    'hamzat_qat',
  ]),
  // البلد
  _S(90, 6, 18, 594, 1.53, [
    'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah', 'nun_ikhfa_haqiqi',
    'nun_idgham_naqis', 'nun_idgham_kamil', 'mim_izhar_shafawi',
    'ghunnah_nun_mushaddadah', 'ghunnah_mim_mushaddadah', 'lam_shamsiyyah',
    'lam_qamariyyah', 'ra_tafkhim', 'ra_tarqiq', 'qalqalah_sughra',
    'qalqalah_kubra', 'madd_tabii', 'madd_iwad', 'madd_muttasil',
    'madd_munfasil', 'madd_badal', 'madd_silah_kubra', 'madd_silah_sughra',
    'madd_lin', 'hamzat_wasl', 'hamzat_qat',
  ]),
  // العلق
  _S(96, 1, 12, 597, 1.58, [
    'nun_izhar_halqi', 'nun_idgham_bila_ghunnah', 'nun_ikhfa_haqiqi',
    'nun_idgham_kamil', 'mim_izhar_shafawi', 'ghunnah_nun_mushaddadah',
    'lam_shamsiyyah', 'lam_qamariyyah', 'ra_tafkhim', 'qalqalah_sughra',
    'qalqalah_kubra', 'madd_tabii', 'madd_munfasil', 'madd_badal',
    'hamzat_wasl', 'hamzat_qat',
  ]),
  // البينة
  _S(98, 1, 5, 598, 1.52, [
    'nun_izhar_halqi', 'nun_idgham_bi_ghunnah', 'nun_iqlab', 'nun_ikhfa_haqiqi',
    'nun_idgham_kamil', 'mim_izhar_shafawi', 'lam_shamsiyyah', 'lam_qamariyyah',
    'lam_jalalah_tafkhim', 'ra_tafkhim', 'ra_tarqiq', 'madd_tabii',
    'madd_muttasil', 'madd_munfasil', 'madd_badal', 'hamzat_wasl', 'hamzat_qat',
  ]),
  // الهمزة
  _S(104, 1, 9, 601, 1.15, [
    'nun_idgham_bi_ghunnah', 'nun_idgham_bila_ghunnah', 'nun_iqlab',
    'nun_idgham_naqis', 'nun_idgham_kamil', 'mim_idgham_shafawi',
    'ghunnah_nun_mushaddadah', 'lam_qamariyyah', 'lam_jalalah_tafkhim',
    'ra_tafkhim', 'qalqalah_sughra', 'madd_tabii', 'madd_munfasil',
    'madd_silah_kubra', 'hamzat_wasl', 'hamzat_qat',
  ]),
];
// dart format on
