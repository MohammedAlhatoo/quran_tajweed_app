import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/constants/firebase_collections.dart';
import 'package:quran_tajweed_app/features/courses/data/seed/curriculum_seed.dart';
import 'package:quran_tajweed_app/features/courses/data/seed/curriculum_seeder.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/course_level.dart';
import 'package:quran_tajweed_app/features/courses/domain/entities/tajweed_rule.dart';

class _MemorySeedStore implements SeedStore {
  final Map<String, Map<String, Map<String, dynamic>>> collections = {};

  @override
  Object get timestamp => 'now';

  Map<String, Map<String, dynamic>> docs(String collection) =>
      collections.putIfAbsent(collection, () => {});

  @override
  Future<Map<String, Map<String, dynamic>>> readAll(
    String collection,
  ) async => {
    for (final entry in docs(collection).entries) entry.key: {...entry.value},
  };

  @override
  Future<void> writeAll(
    String collection,
    Map<String, Map<String, Object?>> documents,
  ) async {
    for (final entry in documents.entries) {
      docs(collection).putIfAbsent(entry.key, () => {}).addAll(entry.value);
    }
  }
}

final _ruleIds = {for (final rule in tajweedRuleSeeds) rule.id};

Set<String> _idsOf(TajweedCategory category) => {
  for (final rule in tajweedRuleSeeds)
    if (rule.category == category) rule.id,
};

Set<String> _idsOfLevel(CourseLevel level) => {
  for (final rule in rulesOfLevel(level)) rule.id,
};

void main() {
  group('courses', () {
    test('are the four approved courses in order', () {
      expect(courseSeeds.map((course) => course.name), [
        'تمهيدية',
        'تأهيلية',
        'عليا',
        'السند',
      ]);
      expect(courseSeeds.map((course) => course.order), [1, 2, 3, 4]);
      expect(courseSeeds.map((course) => course.level), CourseLevel.values);
    });

    test('have no duplicate IDs', () {
      expect({for (final course in courseSeeds) course.id}, hasLength(4));
    });

    test('are read by the Course entity', () {
      for (final seed in courseSeeds) {
        final course = Course.fromMap(seed.id, seed.toMap())!;
        expect(course.level, seed.level);
        expect(course.name, seed.name);
        expect(course.description, isNotEmpty);
      }
    });

    test('write their objectives, which may be empty', () {
      for (final seed in courseSeeds) {
        expect(seed.objectives, hasLength(3));
        expect(seed.toMap()['objectives'], seed.objectives);
      }
      const seed = CourseSeed(
        CourseLevel.introductory,
        'تمهيدية',
        'وصف',
        objectives: ['هدف أول', 'هدف ثانٍ'],
      );

      final course = Course.fromMap(seed.id, seed.toMap())!;

      expect(course.objectives, ['هدف أول', 'هدف ثانٍ']);
    });
  });

  group('tajweed rules', () {
    test('form a wide taxonomy over every category', () {
      expect(tajweedRuleSeeds.length, greaterThan(200));
      for (final category in TajweedCategory.values) {
        expect(_idsOf(category), isNotEmpty, reason: category.label);
      }
    });

    test('have no duplicate IDs or names', () {
      expect(_ruleIds, hasLength(tajweedRuleSeeds.length));
      expect({
        for (final rule in tajweedRuleSeeds) rule.name,
      }, hasLength(tajweedRuleSeeds.length));
    });

    test('have a stable ID, a name and a description', () {
      final idPattern = RegExp(r'^[a-z]+(_[a-z]+)*$');
      for (final rule in tajweedRuleSeeds) {
        expect(idPattern.hasMatch(rule.id), isTrue, reason: rule.id);
        expect(rule.name.trim(), isNotEmpty, reason: rule.id);
        expect(rule.description.trim(), isNotEmpty, reason: rule.id);
      }
    });

    test('are read by the TajweedRule entity', () {
      for (final seed in tajweedRuleSeeds) {
        final rule = TajweedRule.fromMap(seed.id, seed.toMap())!;
        expect(rule.name, seed.name);
        expect(rule.description, seed.description);
        expect(rule.category, seed.category);
        expect(rule.kind, seed.kind);
        expect(rule.isActive, isTrue);
        expect(rule.isRecitation, seed.isRecitation);
      }
    });

    test('a document with only a name is an active recitation rule', () {
      final rule = TajweedRule.fromMap('old-rule', {'name': 'المد الطبيعي'})!;
      expect(rule.kind, TajweedRuleKind.recitation);
      expect(rule.category, isNull);
      expect(rule.description, isEmpty);
      expect(rule.isActive, isTrue);
    });

    test('a stopped rule is read as inactive', () {
      final rule = TajweedRule.fromMap('madd_tabii', {
        'name': 'المد الطبيعي',
        'isActive': false,
      })!;
      expect(rule.isActive, isFalse);
    });

    test('cover the articulation points', () {
      expect(
        _ruleIds,
        containsAll([
          'makhraj_jawf',
          'makhraj_halq',
          'makhraj_aqsa_halq',
          'makhraj_wasat_halq',
          'makhraj_adna_halq',
          'makhraj_lisan',
          'makhraj_aqsa_lisan',
          'makhraj_wasat_lisan',
          'makhraj_hafat_lisan',
          'makhraj_taraf_lisan',
          'makhraj_shafatan',
          'makhraj_khayshum',
          'makhraj_dad',
          'makhraj_ba_mim_waw',
        ]),
      );
      expect(_idsOf(TajweedCategory.makharij), hasLength(30));
    });

    test('cover the attributes that have opposites', () {
      expect(
        _ruleIds,
        containsAll([
          'sifah_hams',
          'sifah_jahr',
          'sifah_shiddah',
          'sifah_tawassut',
          'sifah_rakhawah',
          'sifah_istila',
          'sifah_istifal',
          'sifah_itbaq',
          'sifah_infitah',
          'sifah_idhlaq',
          'sifah_ismat',
        ]),
      );
    });

    test('cover the attributes that have no opposite', () {
      expect(
        _ruleIds,
        containsAll([
          'sifah_safir',
          'sifah_qalqalah',
          'sifah_lin',
          'sifah_inhiraf',
          'sifah_takrir',
          'sifah_tafashshi',
          'sifah_istitalah',
          'sifah_khafa',
          'sifah_ghunnah',
        ]),
      );
    });

    test('cover Nun Sakinah and Tanween', () {
      expect(
        _ruleIds,
        containsAll([
          'nun_izhar_halqi',
          'nun_idgham_bi_ghunnah',
          'nun_idgham_bila_ghunnah',
          'nun_idgham_naqis',
          'nun_idgham_kamil',
          'nun_iqlab',
          'nun_ikhfa_haqiqi',
          'nun_maratib_ikhfa',
        ]),
      );
    });

    test('cover Meem Sakinah', () {
      expect(_idsOf(TajweedCategory.mim), {
        'mim_izhar_shafawi',
        'mim_idgham_shafawi',
        'mim_ikhfa_shafawi',
      });
    });

    test('cover Ghunnah', () {
      expect(
        _ruleIds,
        containsAll([
          'ghunnah_nun_mushaddadah',
          'ghunnah_mim_mushaddadah',
          'ghunnah_miqdar',
          'ghunnah_maratib',
          'ghunnah_mawadi',
        ]),
      );
    });

    test('keep general Idgham apart from the Idgham of Nun', () {
      expect(
        _idsOf(TajweedCategory.idgham),
        containsAll([
          'idgham_mutamathilayn',
          'idgham_mutamathilayn_saghir',
          'idgham_mutajanisayn',
          'idgham_mutajanisayn_saghir',
          'idgham_mutaqaribayn',
          'idgham_mutaqaribayn_saghir',
          'idgham_mutabaidan',
        ]),
      );
      expect(
        _idsOf(TajweedCategory.idgham)
            .intersection(_idsOf(TajweedCategory.nun)),
        isEmpty,
      );
    });

    test('cover the Lams', () {
      expect(
        _ruleIds,
        containsAll([
          'lam_tarif',
          'lam_shamsiyyah',
          'lam_qamariyyah',
          'lam_fil',
          'lam_ism',
          'lam_harf',
          'lam_amr',
          'lam_jalalah_tafkhim',
          'lam_jalalah_tarqiq',
        ]),
      );
    });

    test('cover Tafkhim and Tarqiq', () {
      expect(
        _ruleIds,
        containsAll([
          'tafkhim_huruf_mufakhkhamah',
          'tarqiq_huruf_muraqqaqah',
          'tafkhim_alif',
          'ra_tafkhim',
          'ra_tarqiq',
          'ra_wajhan',
          'ra_tarqiq_awla',
          'ra_tafkhim_awla',
        ]),
      );
    });

    test('cover Qalqalah', () {
      expect(
        _ruleIds,
        containsAll([
          'qalqalah_huruf',
          'qalqalah_sughra',
          'qalqalah_kubra',
          'qalqalah_ada',
          'qalqalah_akhta',
        ]),
      );
    });

    test('cover the natural Madd and every main group of Madd', () {
      expect(
        _ruleIds,
        containsAll([
          'madd_tabii',
          'madd_huruf',
          'madd_muttasil',
          'madd_munfasil',
          'madd_badal',
          'madd_silah_kubra',
          'madd_silah_sughra',
          'madd_arid_lil_sukun',
          'madd_lin',
          'madd_lazim',
          'madd_lazim_kalimi_muthaqqal',
          'madd_lazim_kalimi_mukhaffaf',
          'madd_lazim_harfi_muthaqqal',
          'madd_lazim_harfi_mukhaffaf',
          'madd_maratib',
          'madd_ijtima_asbab',
          'madd_ijtima_maddayn',
        ]),
      );
    });

    test('cover Hamzat al-Wasl and al-Qat', () {
      expect(
        _ruleIds,
        containsAll([
          'hamzat_wasl',
          'hamzat_qat',
          'hamzat_wasl_afal',
          'hamzat_wasl_asma',
          'hamzat_wasl_huruf',
          'hamzat_wasl_bad',
          'hamzat_wasl_istifham',
        ]),
      );
    });

    test('cover Ha al-Kinayah', () {
      expect(_idsOf(TajweedCategory.haKinayah), {
        'ha_kinayah_tarif',
        'ha_kinayah_adam_silah',
        'ha_kinayah_hafs',
      });
    });

    test('cover stopping and starting', () {
      expect(
        _ruleIds,
        containsAll([
          'waqf_tarif',
          'ibtida_tarif',
          'waqf_qat_sakt_farq',
          'waqf_ikhtiyari',
          'waqf_idtirari',
          'waqf_intizari',
          'waqf_tamm',
          'waqf_kafi',
          'waqf_hasan',
          'waqf_qabih',
          'waqf_taalluq_lafzi',
          'waqf_taalluq_manawi',
          'waqf_alamat',
          'ibtida_mamnu',
          'ibtida_hasan',
          'ibtida_qabih',
        ]),
      );
    });

    test('cover Rawm and Ishmam', () {
      expect(
        _ruleIds,
        containsAll([
          'waqf_sukun_mahd',
          'waqf_rawm',
          'waqf_ishmam',
          'waqf_rawm_ishmam_farq',
          'waqf_rawm_mawadi',
          'waqf_ishmam_mawadi',
        ]),
      );
    });

    test('cover Sakt with exactly the six places of Hafs', () {
      for (final id in ['sakt_tarif', 'sakt_aqsam']) {
        final general = tajweedRuleSeeds.firstWhere((rule) => rule.id == id);
        expect(general.kind, TajweedRuleKind.theoretical, reason: id);
      }
      final places = {
        for (final rule in tajweedRuleSeeds)
          if (rule.category == TajweedCategory.sakt &&
              rule.kind == TajweedRuleKind.hafsSpecific)
            rule.id,
      };
      expect(places, {
        'sakt_iwaja',
        'sakt_marqadina',
        'sakt_man_raq',
        'sakt_bal_ran',
        'sakt_anfal_tawbah',
        'sakt_maliyah_halak',
      });
    });

    test('cover the meeting of two Sukuns', () {
      expect(_idsOf(TajweedCategory.iltiqaSakinayn), hasLength(5));
    });

    test('cover the separated and the joined words', () {
      expect(
        _ruleIds,
        containsAll([
          'maqtu_tarif',
          'mawsul_tarif',
          'maqtu_kalimat',
          'mawsul_kalimat',
          'maqtu_mawsul_mukhtalaf',
          'maqtu_mawsul_waqf',
        ]),
      );
    });

    test('cover omission and retention', () {
      expect(
        _ruleIds,
        containsAll([
          'hadhf_alif',
          'ithbat_alif',
          'hadhf_ya',
          'ithbat_ya',
          'hadhf_waw',
          'ithbat_waw',
          'hadhf_ithbat_khass',
        ]),
      );
    });

    test('hold rules particular to Hafs', () {
      expect(_idsOf(TajweedCategory.hafs), isNotEmpty);
      for (final rule in tajweedRuleSeeds) {
        if (rule.category == TajweedCategory.hafs) {
          expect(rule.kind, TajweedRuleKind.hafsSpecific, reason: rule.id);
        }
      }
    });

    test('name no narration other than Hafs', () {
      const others = [
        'ورش',
        'قالون',
        'شعبة',
        'قنبل',
        'البزي',
        'السوسي',
        'الدوري',
        'الكسائي',
        'خلاد',
        'ابن كثير',
        'أبو عمرو',
        'ابن عامر',
        'القراءات',
      ];
      for (final rule in tajweedRuleSeeds) {
        for (final other in others) {
          expect(rule.name.contains(other), isFalse, reason: rule.id);
          expect(rule.description.contains(other), isFalse, reason: rule.id);
        }
      }
    });

    test('keep theoretical knowledge out of the recitation rules', () {
      for (final rule in tajweedRuleSeeds) {
        if (rule.category == TajweedCategory.intro ||
            rule.id.startsWith('sajdah_')) {
          expect(rule.isRecitation, isFalse, reason: rule.id);
        }
      }
      expect(tajweedRuleSeeds.where((rule) => rule.isRecitation), isNotEmpty);
    });
  });

  group('course rules', () {
    final links = courseRuleSeeds;

    test('refer to an existing course and an existing rule', () {
      final levels = {for (final course in courseSeeds) course.level};
      for (final link in links) {
        expect(levels, contains(link.level));
        expect(_ruleIds, contains(link.ruleId));
      }
    });

    test('hold no duplicate relation', () {
      expect({
        for (final link in links) (link.level, link.ruleId),
      }, hasLength(links.length));
    });

    test('give every course rules, more at each level', () {
      final counts = [
        for (final level in CourseLevel.values) _idsOfLevel(level).length,
      ];
      expect(counts.first, greaterThan(0));
      for (var i = 1; i < counts.length; i++) {
        expect(counts[i], greaterThan(counts[i - 1]));
      }
    });

    test('have a weight of 1, 2 or 3', () {
      for (final link in links) {
        expect(link.weight, inInclusiveRange(1, 3), reason: link.ruleId);
      }
    });

    test('weigh a rule most in the level that introduces it', () {
      final rule = tajweedRuleSeeds.firstWhere((r) => r.id == 'madd_muttasil');
      expect(courseRuleWeight(rule, CourseLevel.qualifying), 3);
      expect(courseRuleWeight(rule, CourseLevel.advanced), 2);
      expect(courseRuleWeight(rule, CourseLevel.sanad), 1);

      final theory = tajweedRuleSeeds.firstWhere((r) => r.id == 'madd_huruf');
      expect(courseRuleWeight(theory, CourseLevel.introductory), 1);
    });

    test('keep advanced details out of the introductory course', () {
      final introductory = _idsOfLevel(CourseLevel.introductory);
      expect(
        introductory,
        containsAll([
          'nun_izhar_halqi',
          'nun_iqlab',
          'mim_ikhfa_shafawi',
          'madd_tabii',
          'lam_shamsiyyah',
          'qalqalah_sughra',
          'intro_basmalah',
        ]),
      );
      for (final id in [
        'waqf_rawm',
        'waqf_ishmam',
        'madd_muttasil',
        'hadhf_alif',
        'maqtu_tarif',
        'sakt_iwaja',
        'hafs_imalah',
      ]) {
        expect(introductory, isNot(contains(id)));
      }
    });

    test('each course covers all the rules of the course below it', () {
      for (var i = 1; i < CourseLevel.values.length; i++) {
        expect(
          _idsOfLevel(CourseLevel.values[i]),
          containsAll(_idsOfLevel(CourseLevel.values[i - 1])),
        );
      }
    });

    test('the sanad course covers every rule', () {
      expect(_idsOfLevel(CourseLevel.sanad), _ruleIds);
      expect(
        _idsOfLevel(CourseLevel.sanad),
        containsAll([
          'waqf_rawm',
          'waqf_ishmam',
          'waqf_tamm',
          'maqtu_mawsul_waqf',
          'hadhf_alif',
          'hamzat_wasl',
          'ha_kinayah_hafs',
          'sakt_maliyah_halak',
          'hafs_rasm_dabt',
          'hafs_daqaiq_ada',
        ]),
      );
    });
  });

  group('CurriculumSeeder', () {
    late _MemorySeedStore store;

    setUp(() => store = _MemorySeedStore());

    test('writes the courses, the rules and their links', () async {
      final result = await CurriculumSeeder(store).seed();

      expect(result.coursesCreated, 4);
      expect(result.rulesCreated, tajweedRuleSeeds.length);
      expect(result.courseRulesCreated, courseRuleSeeds.length);

      final courses = store.docs(FirebaseCollections.courses);
      final rules = store.docs(FirebaseCollections.tajweedRules);
      expect(courses.keys, CourseLevel.values.map((level) => level.value));
      expect(rules['madd_tabii'], {
        'name': 'المد الطبيعي',
        'description': isNotEmpty,
        'category': 'madd',
        'kind': 'recitation',
        'isActive': true,
        'createdAt': 'now',
        'updatedAt': 'now',
      });
      for (final link in store.docs(FirebaseCollections.courseRules).values) {
        expect(courses, contains(link['courseId']));
        expect(rules, contains(link['ruleId']));
        expect(link['weight'], isPositive);
      }
    });

    test('writes nothing when run again', () async {
      await CurriculumSeeder(store).seed();
      final counts = {
        for (final entry in store.collections.entries)
          entry.key: entry.value.length,
      };

      final result = await CurriculumSeeder(store).seed();

      expect(result.wroteNothing, isTrue);
      expect({
        for (final entry in store.collections.entries)
          entry.key: entry.value.length,
      }, counts);
    });

    test('reuses an existing course of the same level', () async {
      store.docs(FirebaseCollections.courses)['course-1'] = {
        'name': 'الدورة التمهيدية',
        'level': 'introductory',
        'isActive': false,
      };

      final result = await CurriculumSeeder(store).seed();

      final courses = store.docs(FirebaseCollections.courses);
      final seed = courseSeeds.first;
      expect(result.coursesCreated, 3);
      expect(result.coursesUpdated, 1);
      expect(courses, isNot(contains('introductory')));
      // Its definition is brought up to date; its isActive is kept.
      expect(courses['course-1'], {
        'name': seed.name,
        'description': seed.description,
        'level': 'introductory',
        'objectives': seed.objectives,
        'isActive': false,
        'updatedAt': 'now',
      });
      expect(result.documentIds[FirebaseCollections.courses], {
        'course-1',
        'qualifying',
        'advanced',
        'sanad',
      });
      expect(
        store
            .docs(FirebaseCollections.courseRules)
            .values
            .where((link) => link['courseId'] == 'course-1'),
        hasLength(rulesOfLevel(CourseLevel.introductory).length),
      );
    });

    test('reuses an existing rule that has the same name', () async {
      store.docs(FirebaseCollections.tajweedRules)['old-rule'] = {
        'name': 'المد الطبيعي',
      };

      final result = await CurriculumSeeder(store).seed();

      expect(result.rulesCreated, tajweedRuleSeeds.length - 1);
      expect(
        store.docs(FirebaseCollections.tajweedRules),
        isNot(contains('madd_tabii')),
      );
      expect(
        store.docs(FirebaseCollections.courseRules),
        contains('introductory_old-rule'),
      );
    });

    test('keeps a weight and an isActive changed by hand', () async {
      await CurriculumSeeder(store).seed();
      store.docs(
        FirebaseCollections.courseRules,
      )['introductory_madd_tabii']!['weight'] = 5;
      store.docs(FirebaseCollections.tajweedRules)['madd_tabii']!
        ..['isActive'] = false
        ..['description'] = 'قديم';

      final result = await CurriculumSeeder(store).seed();

      expect(result.rulesUpdated, 1);
      expect(
        store.docs(
          FirebaseCollections.courseRules,
        )['introductory_madd_tabii']!['weight'],
        5,
      );
      final rule = store.docs(FirebaseCollections.tajweedRules)['madd_tabii']!;
      expect(rule['isActive'], isFalse);
      expect(rule['description'], isNot('قديم'));
    });
  });
}
