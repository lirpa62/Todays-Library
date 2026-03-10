import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:excel/excel.dart' as ex hide TextSpan;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:window_manager/window_manager.dart'; // 창 제어 패키지

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _registerAdditionalLicenses();

  // 데스크톱 환경 설정 (SQLite 및 Window Manager)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    await windowManager.ensureInitialized();

    // 저장된 창 크기 불러오기 (처음 실행해서 값이 없으면 기본값 800, 700 세팅)
    final prefs = await SharedPreferences.getInstance();
    final double width = prefs.getDouble('window_width') ?? 800.0;
    final double height = prefs.getDouble('window_height') ?? 700.0;

    // 저장된 모드 불러오기 (없으면 일반 모드 false)
    final bool isCompact = prefs.getBool('is_compact_mode') ?? false;

    WindowOptions windowOptions = WindowOptions(
      size: Size(width, height),
      // 모드에 따라 최소 크기 제한을 다르게 설정하여 실행
      minimumSize: isCompact ? const Size(400, 650) : const Size(650, 650),
      center: true,
      title: '오늘의 도서관',
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // 앱 실행 전 DB에서 운영 시간 설정을 불러옵니다.
  await DatabaseHelper.instance.database;
  await LibrarySchedule.loadSchedule();

  runApp(const TodaysLibraryApp());
}

void _registerAdditionalLicenses() {
  _registerLicenseFromAsset(
    packages: const ['Pretendard'],
    assetPath: 'assets/licenses/Pretendard-LICENSE.txt',
  );
  _registerLicenseFromAsset(
    packages: const ['Material Icons (Google)'],
    assetPath: 'assets/licenses/Material-Icons-LICENSE.txt',
  );
}

void _registerLicenseFromAsset({
  required List<String> packages,
  required String assetPath,
}) {
  LicenseRegistry.addLicense(() async* {
    final String licenseText = await rootBundle.loadString(assetPath);
    yield LicenseEntryWithLineBreaks(
      packages,
      licenseText.replaceAll('\r\n', '\n') // 1. 윈도우 줄바꿈 통일
          .replaceAll('\n\n', '\n') // 2. 중복 줄바꿈 정리
          .replaceAll('\n', '\n\n'), // 3. 플러터가 인식하도록 모든 엔터를 두 번으로 뻥튀기
    );
  });
}

// -----------------------------------------------------------------------------
// 앱 메인 및 테마 설정
// -----------------------------------------------------------------------------
class TodaysLibraryApp extends StatefulWidget {
  const TodaysLibraryApp({super.key});

  @override
  State<TodaysLibraryApp> createState() => _TodaysLibraryAppState();
}

class _TodaysLibraryAppState extends State<TodaysLibraryApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this); // 리스너 등록
  }

  @override
  void dispose() {
    windowManager.removeListener(this); // 리스너 해제
    super.dispose();
  }

  // 창 크기가 조절될 때마다 자동으로 실행되는 함수
  @override
  void onWindowResized() async {
    final size = await windowManager.getSize();
    final prefs = await SharedPreferences.getInstance();

    // 조절된 새로운 가로, 세로 값을 저장소에 덮어씁니다.
    await prefs.setDouble('window_width', size.width);
    await prefs.setDouble('window_height', size.height);
  }

  @override
  Widget build(BuildContext context) {
    // 커스텀 색상 정의
    const Color primaryColor = Color(0xFF2A5982);
    const Color secondaryColor = Color(0xFF4EA699);
    const Color tertiaryColor = Color(0xFFE59F4A);
    const Color fontColor = Color(0xFF2C3E50);
    const Color neutralColor = Color(0xFFFFFFFF);
    const Color backgroundColor = Color(0xFFF4F6F8);

    return MaterialApp(
      title: '오늘의 도서관',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'), // 한국어 설정
      ],
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: primaryColor,
          onPrimary: Colors.white,
          secondary: secondaryColor,
          onSecondary: Colors.white,
          tertiary: tertiaryColor,
          onTertiary: Colors.white,
          surface: neutralColor,
          onSurface: fontColor,
          error: Colors.redAccent,
          onError: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: fontColor),
          bodyMedium: TextStyle(color: fontColor),
          titleLarge: TextStyle(color: fontColor, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
        // 모든 버튼에 마우스 오버 시 손가락 커서 일괄 적용
        iconButtonTheme: const IconButtonThemeData(
          style: ButtonStyle(mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click)),
        ),
        textButtonTheme: const TextButtonThemeData(
          style: ButtonStyle(mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click)),
        ),
        filledButtonTheme: const FilledButtonThemeData(
          style: ButtonStyle(mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click)),
        ),
        outlinedButtonTheme: const OutlinedButtonThemeData(
          style: ButtonStyle(mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click)),
        ),
        segmentedButtonTheme: const SegmentedButtonThemeData(
          style: ButtonStyle(mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// 데이터베이스 헬퍼 클래스
// -----------------------------------------------------------------------------
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todays_library_db.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            time_slot TEXT NOT NULL,
            adult INTEGER DEFAULT 0,
            child INTEGER DEFAULT 0,
            infant INTEGER DEFAULT 0,
            UNIQUE(date, time_slot)
          )
        ''');
        await _createScheduleTable(db);
      },
      // db 버전 업데이트 시 사용
      // onUpgrade: (db, oldVersion, newVersion) async {
      //   if (oldVersion < 2) {
      //     await _createScheduleTable(db);
      //   }
      // },
    );
  }

  // 요일별 운영시간 저장용 테이블 생성 및 초기화 함수
  Future<void> _createScheduleTable(Database db) async {
    // 1. IF NOT EXISTS를 추가하여, 이미 테이블이 있다면 덮어쓰지 않고 에러도 내지 않게 방어합니다.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS schedule (
        weekday INTEGER PRIMARY KEY,
        start_time INTEGER NOT NULL,
        end_time INTEGER NOT NULL,
        is_closed INTEGER NOT NULL
      )
    ''');

    // 2. 이미 데이터가 들어있는지 확인합니다.
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM schedule');
    final count = result.first['count'] as int;

    // 3. 데이터가 텅텅 비어있을 때만 기본값(10시~20시)을 밀어 넣습니다.
    if (count == 0) {
      for (int i = 1; i <= 7; i++) {
        await db.insert('schedule', {
          'weekday': i,
          'start_time': 10,
          'end_time': 20,
          'is_closed': 0
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> getRecordsByDate(String date) async {
    final db = await instance.database;
    return await db.query('records', where: 'date = ?', whereArgs: [date]);
  }

  Future<void> updateCount(String date, String timeSlot, String category, int change) async {
    final db = await instance.database;
    final result = await db.query('records', where: 'date = ? AND time_slot = ?', whereArgs: [date, timeSlot]);

    if (result.isEmpty) {
      int val = change < 0 ? 0 : change;
      await db.insert('records', {
        'date': date,
        'time_slot': timeSlot,
        'adult': category == '성인' ? val : 0,
        'child': category == '아동' ? val : 0,
        'infant': category == '유아' ? val : 0,
      });
    } else {
      Map<String, dynamic> row = Map.from(result.first);
      String col = category == '성인' ? 'adult' : (category == '아동' ? 'child' : 'infant');
      int newVal = (row[col] as int) + change;
      if (newVal < 0) newVal = 0;
      await db.update('records', {col: newVal}, where: 'id = ?', whereArgs: [row['id']]);
    }
  }

  Future<void> resetCount(String date, String timeSlot, String category) async {
    final db = await instance.database;
    if (category == '전체') {
      await db.update('records', {'adult': 0, 'child': 0, 'infant': 0}, where: 'date = ? AND time_slot = ?', whereArgs: [date, timeSlot]);
    } else {
      String col = category == '성인' ? 'adult' : (category == '아동' ? 'child' : 'infant');
      await db.update('records', {col: 0}, where: 'date = ? AND time_slot = ?', whereArgs: [date, timeSlot]);
    }
  }

  Future<List<Map<String, dynamic>>> getAllRecords() async {
    final db = await instance.database;
    return await db.query('records', orderBy: 'date ASC, time_slot ASC');
  }

  // 공장 초기화 로직 (모든 데이터 영구 삭제)
  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.delete('records'); // 모든 방문자 기록 삭제
    await db.delete('schedule'); // 스케줄 삭제
    await _createScheduleTable(db); // 스케줄 테이블 기본값(10-20시)으로 다시 세팅
  }

  // DB에 기록된 모든 연도를 중복 없이 가져오기
  Future<List<int>> getAvailableYears() async {
    final db = await instance.database;
    final result = await db.rawQuery('SELECT DISTINCT SUBSTR(date, 1, 4) as year FROM records ORDER BY year DESC');
    if (result.isEmpty) return [DateTime.now().year];
    return result.map((row) => int.parse(row['year'] as String)).toList();
  }
}

// -----------------------------------------------------------------------------
// 메인 네비게이션 화면 (글로벌 앱바 + 항상 위 기능)
// -----------------------------------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _isAlwaysOnTop = false; // 창 항상 위 고정 상태
  int _scheduleVersion = 0;

  // 콤팩트 모드용 변수
  bool _isCompactMode = false;
  double _normalWidth = 800.0;

  @override
  void initState() {
    super.initState();
    _loadInitialMode(); // 초기 모드 불러오기 실행
  }

  // 저장된 모드 상태를 UI 변수에 반영
  void _loadInitialMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCompactMode = prefs.getBool('is_compact_mode') ?? false;
      _normalWidth = prefs.getDouble('normal_width') ?? 800.0;
    });
  }

  // 콤팩트 모드 토글 함수
  void _toggleCompactMode() async {
    Size currentSize = await windowManager.getSize();
    final prefs = await SharedPreferences.getInstance(); // 저장소 인스턴스

    if (!_isCompactMode) {
      _normalWidth = currentSize.width; // 원래 가로 크기 기억
      await prefs.setDouble('normal_width', _normalWidth); // 기본 모드 너비를 영속 저장
      await windowManager.setMinimumSize(const Size(400, 650)); // 최소 너비 제한 해제
      await windowManager.setSize(Size(400, currentSize.height)); // 창 축소
      // onWindowResized 콜백의 비동기 타이밍에 의존하지 않고 직접 저장
      await prefs.setDouble('window_width', 400);
    } else {
      await windowManager.setSize(Size(_normalWidth, currentSize.height)); // 원래 크기로 복구
      await windowManager.setMinimumSize(const Size(650, 650)); // 최소 너비 제한 복구
      await prefs.setDouble('window_width', _normalWidth); // 직접 저장
    }

    setState(() {
      _isCompactMode = !_isCompactMode;
    });

    // 변경된 모드 상태를 즉시 저장
    await prefs.setBool('is_compact_mode', _isCompactMode);
  }

  void _toggleAlwaysOnTop() async {
    bool isTop = await windowManager.isAlwaysOnTop();
    await windowManager.setAlwaysOnTop(!isTop);
    setState(() {
      _isAlwaysOnTop = !isTop;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 콤팩트 모드일 때 타이틀 간소화
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: _isCompactMode
              ? const Text('집계 모드', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
              : Text(
              _selectedIndex == 0
                  ? '오늘의 도서관 (방문자 집계)'
                  : '오늘의 도서관 (방문자 통계)',
              style: const TextStyle(fontWeight: FontWeight.bold)),),
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0, // 스크롤 시 앱바 색상 변함 방지
        actions: [
          // 콤팩트 모드가 아닐 때만 탭(세그먼트 버튼) 표시
          if (!_isCompactMode) ...[
            // 상단 분할 버튼(SegmentedButton)으로 메뉴 구현
            Flexible(child: SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                    value: 0,
                    icon: Icon(Icons.touch_app),
                    label: Text('방문자 집계')
                ),
                ButtonSegment<int>(
                    value: 1,
                    icon: Icon(Icons.bar_chart),
                    label: Text('방문자 통계')
                ),
              ],
              selected: {_selectedIndex},
              onSelectionChanged: (Set<int> newSelection) async {
                int newIndex = newSelection.first;
                setState(() {
                  _selectedIndex = newIndex;
                });

                // 탭에 따라 윈도우 창 타이틀 동적 변경
                if (newIndex == 0) {
                  await windowManager.setTitle('오늘의 도서관 (방문자 집계)');
                } else {
                  await windowManager.setTitle('오늘의 도서관 (방문자 통계)');
                }
              },
            )),
            const SizedBox(width: 24), // 메뉴와 핀셋 사이 간격
          ],
          // 콤팩트 모드 전환 버튼 (집계 화면에서만 표시)
          if (_selectedIndex == 0)
            Tooltip(
              message: _isCompactMode ? '크게 보기' : '콤팩트 모드 (작게 보기)',
              child: IconButton(
                icon: Icon(_isCompactMode ? Icons.open_in_full : Icons.close_fullscreen),
                onPressed: _toggleCompactMode,
              ),
            ),

          // 항상 위 고정 아이콘 (메뉴 버튼 우측에 위치)
          Tooltip(
            message: _isAlwaysOnTop ? '항상 위 고정 해제' : '창을 항상 위에 고정',
            child: IconButton(
              icon: Icon(_isAlwaysOnTop ? Icons.push_pin : Icons.push_pin_outlined,
                  color: _isAlwaysOnTop ? Theme.of(context).colorScheme.primary : null),
              onPressed: _toggleAlwaysOnTop,
            ),
          ),
          // 콤팩트 모드가 아닐 때만 설정/정보 버튼 표시
          if (!_isCompactMode) ...[
            // '운영 시간 설정' 버튼
            Tooltip(
              message: '요일별 운영 시간 설정',
              child: IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () async {
                  // 설정 팝업창 띄우기
                  await showDialog(
                    context: context,
                    builder: (context) => const ScheduleSettingsDialog(),
                  );
                  // 팝업이 닫히면 카운터 화면을 강제로 새로고침하여 변경된 시간표 적용
                  setState(() {
                    _scheduleVersion++;
                  });
                },
              ),
            ),
            // '앱 정보 및 라이선스' 버튼
            Tooltip(
              message: '앱 정보 및 오픈소스 라이선스',
              child: IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  showLicensePage(
                    context: context,
                    applicationName: '오늘의 도서관',
                    applicationVersion: '1.0.0',
                    applicationIcon: Padding(
                      padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                      child: Image.asset('assets/icon/app_icon.png', width: 64, height: 64),
                    ),
                    applicationLegalese: 'Copyright (c) 2026. Lirpa',
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
          ] else ...[
            const SizedBox(width: 8), // 콤팩트 모드일 때 약간의 우측 여백
          ]
        ],
      ),
      // Row와 VerticalDivider 등을 모두 지우고 본문만 꽉 차게 배치
      // ValueKey를 부여하여, 설정이 바뀌면 CounterPage가 완전히 새로 시작되도록 함
      body: _selectedIndex == 0
          ? CounterPage(
          key: ValueKey('counter_$_scheduleVersion'),
          isCompactMode: _isCompactMode
      )
          : const StatisticsPage(),
    );
  }
}

// -----------------------------------------------------------------------------
// 도서관 운영 시간 중앙 관리 시스템 (DB 연동)
// -----------------------------------------------------------------------------
class LibrarySchedule {
  static Map<int, Map<String, int>> hours = {};

  // DB에서 스케줄 불러오기
  static Future<void> loadSchedule() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('schedule');

    for (var map in maps) {
      hours[map['weekday'] as int] = {
        'start': map['start_time'] as int,
        'end': map['end_time'] as int,
        'closed': map['is_closed'] as int,
      };
    }
  }

  // 특정 요일의 스케줄 업데이트
  static Future<void> updateSchedule(int weekday, int start, int end, int isClosed) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'schedule',
      {'start_time': start, 'end_time': end, 'is_closed': isClosed},
      where: 'weekday = ?',
      whereArgs: [weekday],
    );
    await loadSchedule(); // 메모리 데이터 즉시 갱신
  }

  // 특정 날짜가 휴관일인지 확인
  static bool isClosed(DateTime date) {
    if (hours.isEmpty) return false;
    return hours[date.weekday]!['closed'] == 1;
  }

  // 특정 날짜의 운영 시간대 리스트 자동 생성
  static List<String> getTimeSlots(DateTime date) {
    if (isClosed(date) || hours.isEmpty) return [];

    int start = hours[date.weekday]!['start']!;
    int end = hours[date.weekday]!['end']!;

    List<String> slots = [];
    for (int i = start; i < end; i++) {
      slots.add('${i.toString().padLeft(2, '0')}:00 - ${(i + 1).toString().padLeft(2, '0')}:00');
    }
    return slots;
  }
}

// -----------------------------------------------------------------------------
// 카운터 화면
// -----------------------------------------------------------------------------
class CounterPage extends StatefulWidget {
  final bool isCompactMode;
  const CounterPage({super.key, this.isCompactMode = false});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  List<String> timeSlots = [];
  late String selectedSlot;
  Map<String, Map<String, int>> todayData = {};
  String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  Timer? _timer;

  // 오늘이 휴관일인지 추적하는 변수
  bool isClosedToday = false;

  @override
  void initState() {
    super.initState();

    DateTime now = DateTime.now();
    isClosedToday = LibrarySchedule.isClosed(now); // 오늘 휴관 여부 확인

    if (!isClosedToday) {
      // 오늘 요일에 맞는 시간대 리스트 자동 생성
      timeSlots = LibrarySchedule.getTimeSlots(now);
      selectedSlot = _getRealTimeSlot() ?? timeSlots.first;
      _loadTodayData();
      _startTimer(); // 시간 감시 타이머 시작
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // 페이지 종료 시 타이머 중지
    super.dispose();
  }

  // 실제 운영 시간에만 슬롯을 반환
  String? _getRealTimeSlot() {
    if (isClosedToday) return null;

    final now = DateTime.now();
    final hour = now.hour;
    final schedule = LibrarySchedule.hours[now.weekday]!;

    // 도서관 운영 시간이 아니면 null 반환
    if (hour < schedule['start']! || hour >= schedule['end']!) return null;

    String prefix = '${hour.toString().padLeft(2, '0')}:';
    return timeSlots.firstWhere(
          (slot) => slot.startsWith(prefix),
      orElse: () => timeSlots.first,
    );
  }

  void _startTimer() {
    // 1분마다 현재 시간을 체크하여 시간대가 바뀌었으면 자동 변경
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (isClosedToday) return; // 휴관일이면 무시

      final newSlot = _getRealTimeSlot();
      // 운영 시간 중이며, 시간이 넘어가서 슬롯이 바뀌었을 때만 화면 전환
      if (newSlot != null && newSlot != selectedSlot) {
        setState(() {
          selectedSlot = newSlot;
        });
      }
    });
  }

  Future<void> _loadTodayData() async {
    for (var slot in timeSlots) {
      todayData[slot] = {'adult': 0, 'child': 0, 'infant': 0};
    }
    final records = await DatabaseHelper.instance.getRecordsByDate(todayStr);
    for (var row in records) {
      String slot = row['time_slot'];
      if (todayData.containsKey(slot)) {
        todayData[slot]!['adult'] = row['adult'];
        todayData[slot]!['child'] = row['child'];
        todayData[slot]!['infant'] = row['infant'];
      }
    }
    setState(() {});
  }

  // 오늘 항목별 총 합계 계산 함수
  Map<String, int> _getTodayTotal() {
    int a = 0, c = 0, i = 0;
    todayData.forEach((_, val) {
      a += val['adult']!;
      c += val['child']!;
      i += val['infant']!;
    });
    return {'adult': a, 'child': c, 'infant': i};
  }

  Future<void> _updateCount(String category, int change) async {
    await DatabaseHelper.instance.updateCount(todayStr, selectedSlot, category, change);
    _loadTodayData();
  }

  Future<void> _resetCount(String category) async {
    await DatabaseHelper.instance.resetCount(todayStr, selectedSlot, category);
    _loadTodayData();
  }

  @override
  Widget build(BuildContext context) {
    // 휴관일일 경우 아주 깔끔한 안내 화면 표시
    if (isClosedToday) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              '오늘은 도서관 휴관일입니다.',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Text(
              '법정공휴일은 운영하지 않습니다.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    if (todayData.isEmpty) return const Center(child: CircularProgressIndicator());
    final colorScheme = Theme.of(context).colorScheme;
    final totals = _getTodayTotal();

    // 콤팩트 모드용 직전 시간대 합계 계산
    String? prevSlotLabel;
    int prevTotal = 0;
    int currentIndex = timeSlots.indexOf(selectedSlot);
    if (currentIndex > 0) {
      String pSlot = timeSlots[currentIndex - 1]; // 이전 슬롯 (예: "13:00 - 14:00")
      int pAdult = todayData[pSlot]?['adult'] ?? 0;
      int pChild = todayData[pSlot]?['child'] ?? 0;
      int pInfant = todayData[pSlot]?['infant'] ?? 0;
      prevTotal = pAdult + pChild + pInfant;
      prevSlotLabel = '직전 시간대 [$pSlot]';
    }

    return Row(
      children: [
        // 콤팩트 모드가 아닐 때만 왼쪽 시간대 영역 렌더링
        if (!widget.isCompactMode) ...[
          SizedBox(
            width: 150,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: timeSlots.length,
                    itemBuilder: (context, index) {
                      final slot = timeSlots[index];
                      int total = (todayData[slot]?['adult'] ?? 0) + (todayData[slot]?['child'] ?? 0) + (todayData[slot]?['infant'] ?? 0);
                      bool isSelected = selectedSlot == slot;
                      return ListTile(
                        title: Text(slot, style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text('합계: $total명'),
                        selected: isSelected,
                        selectedTileColor: colorScheme.primary.withValues(alpha: 0.1),
                        onTap: () => setState(() => selectedSlot = slot),
                      );
                    },
                  ),
                ),
                // 좌측 하단 오늘 총 합계 표시
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: Border(top: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('오늘 총 방문자', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      _smallTotalRow('성인', totals['adult']!, colorScheme.primary),
                      _smallTotalRow('아동', totals['child']!, colorScheme.secondary),
                      _smallTotalRow('유아', totals['infant']!, colorScheme.tertiary),
                    ],
                  ),
                )
              ],
            ),
          ),
          const VerticalDivider(width: 1),
        ],
        // 오른쪽 메인 영역
        Expanded(
          child: Padding(
            // 콤팩트 모드일 때는 여백을 줄여서 공간 확보 (32.0 -> 16.0)
            padding: EdgeInsets.all(widget.isCompactMode ? 16.0 : 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  // 현재 날짜와 1초마다 업데이트되는 실시간 시계
                  child: StreamBuilder<DateTime>(
                      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                      builder: (context, snapshot) {
                        final now = snapshot.data ?? DateTime.now();
                        const weekdays = ['월', '화', '수', '목', '금', '토', '일'];

                        final dateStr = DateFormat('yyyy년 MM월 dd일').format(now);
                        final weekStr = weekdays[now.weekday - 1];
                        final timeStr = DateFormat('HH:mm:ss').format(now);

                        return Text(
                          '$dateStr ($weekStr)  $timeStr',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2, // 숫자 간격을 살짝 넓혀서 깔끔하게
                          ),
                        );
                      }
                  ),
                ),
                const SizedBox(height: 8), // 시계와 시간대 사이의 간격
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12.0,
                  children: [
                    Text('시간대: $selectedSlot', style: TextStyle(fontSize: widget.isCompactMode ? 22 : 28, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    // null이 아니면서, 현재 선택된 슬롯이 실제 시간과 일치할 때만 실시간 배지 표시
                    if (_getRealTimeSlot() != null && selectedSlot == _getRealTimeSlot())
                      const Badge(label: Text('실시간'), backgroundColor: Colors.red),
                    // 콤팩트 모드일 때만 직전 시간대 힌트 표시
                    if (widget.isCompactMode && prevSlotLabel != null)
                      Text(
                        '($prevSlotLabel : $prevTotal명)',
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildCounterRow('성인', todayData[selectedSlot]!['adult']!, colorScheme.primary),
                const SizedBox(height: 16),
                _buildCounterRow('아동', todayData[selectedSlot]!['child']!, colorScheme.secondary),
                const SizedBox(height: 16),
                _buildCounterRow('유아', todayData[selectedSlot]!['infant']!, colorScheme.tertiary),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red.withAlpha(25)),
                    onPressed: () async {
                      bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('초기화 확인', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                          content: const Text('현재 시간대의 방문자 기록(성인/아동/유아)을\n모두 0으로 초기화하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                            FilledButton(
                                style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('초기화')
                            ),
                          ],
                        ),
                      );
                      // 팝업에서 '초기화'를 눌렀을 때만 실행
                      if (confirm == true) {
                        _resetCount('전체');
                      }
                    },
                    icon: const Icon(Icons.refresh, color: Colors.redAccent),
                    label: const Text('현재 시간대 전체 초기화', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _smallTotalRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold)),
          Text('$count명', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCounterRow(String label, int count, Color brandColor) {
    // 콤팩트 모드 여부에 따라 여백과 글씨 크기를 유동적으로 바꿉니다.
    final bool isCompact = widget.isCompactMode;
    final double horizontalPadding = isCompact ? 12.0 : 24.0;
    final double labelFontSize = isCompact ? 20.0 : 24.0;
    final double countFontSize = isCompact ? 32.0 : 40.0;
    final double iconSize = isCompact ? 32.0 : 40.0;
    final double numberBoxWidth = isCompact ? 60.0 : 90.0;
    final double spacing = isCompact ? 8.0 : 24.0;

    // 오른쪽 조작 영역을 미리 위젯 변수로 만들어 둡니다.
    Widget rightControls = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
            icon: Icon(Icons.remove_circle_outline, size: iconSize),
            color: brandColor.withValues(alpha: 0.7),
            onPressed: () => _updateCount(label, -1)
        ),
        SizedBox(
          width: numberBoxWidth,
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(fontSize: countFontSize, fontWeight: FontWeight.bold, color: brandColor),
              // 숫자가 너무 커질 경우를 대비해 콤팩트 모드에서만 말줄임표 처리
              overflow: isCompact ? TextOverflow.ellipsis : null,
            ),
          ),
        ),
        IconButton(
            icon: Icon(Icons.add_circle, size: iconSize),
            color: brandColor,
            onPressed: () => _updateCount(label, 1)
        ),
        SizedBox(width: spacing),
        TextButton(
            onPressed: () => _resetCount(label),
            child: Text(
              '초기화',
              style: const TextStyle(color: Colors.grey),
              overflow: isCompact ? TextOverflow.ellipsis : null,
            )
        )
      ],
    );

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // --- 1. 왼쪽 라벨 영역 ---
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 20, height: 20, decoration: BoxDecoration(color: brandColor, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Text(label, style: TextStyle(fontSize: labelFontSize, fontWeight: FontWeight.bold)),
              ],
            ),

            // --- 2. 오른쪽 조작 영역 ---
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: rightControls,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 통계용 데이터 모델
// -----------------------------------------------------------------------------
class ChartData {
  final String label; // x축 라벨 (예: 10시, 3일, 5월, 2026년)
  int adult;
  int child;
  int infant;

  ChartData(this.label, {this.adult = 0, this.child = 0, this.infant = 0});

  int get total => adult + child + infant;
}

// -----------------------------------------------------------------------------
// 통계 및 추출 화면
// -----------------------------------------------------------------------------
class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  List<ChartData> chartDataList = [];
  String viewMode = '일별';
  DateTime selectedDate = DateTime.now();
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  // 차트 형태를 기억할 변수 ('막대' 또는 '선')
  String chartType = '막대';

  List<int> availableYears = []; // 동적 연도 리스트로 변경
  final List<int> availableMonths = List.generate(12, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    _initFilters();
  }

  // 초기 필터 설정 (연도 불러오기)
  Future<void> _initFilters() async {
    final years = await DatabaseHelper.instance.getAvailableYears();
    setState(() {
      availableYears = years;
      if (!availableYears.contains(selectedYear)) {
        selectedYear = availableYears.first;
      }
    });
    _loadAndProcessData();
  }

  // 현재 차트에 표시된 데이터의 총 합계 계산 함수
  Map<String, int> _getChartTotal() {
    int a = 0, c = 0, i = 0;
    for (var d in chartDataList) {
      a += d.adult;
      c += d.child;
      i += d.infant;
    }
    return {'adult': a, 'child': c, 'infant': i};
  }

  // DB에서 전체 데이터를 불러와 선택한 기준에 맞게 그룹화합니다.
  Future<void> _loadAndProcessData() async {
    final records = await DatabaseHelper.instance.getAllRecords();
    List<ChartData> tempList = [];

    if (viewMode == '일별') {
      String targetDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final filtered = records.where((r) => r['date'] == targetDate).toList();

      // 선택한 날짜에 맞는 유동적인 시간대 목록을 불러옴 (휴관일이면 빈 리스트 반환)
      final slots = LibrarySchedule.getTimeSlots(selectedDate);

      for (var slot in slots) {
        var row = filtered.firstWhere((r) => r['time_slot'] == slot,
            orElse: () => {'adult': 0, 'child': 0, 'infant': 0});
        tempList.add(ChartData('${slot.split(':')[0]}시',
            adult: row['adult'], child: row['child'], infant: row['infant']));
      }
    }
    else if (viewMode == '월별') {
      String targetPrefix = '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';
      final filtered = records.where((r) => (r['date'] as String).startsWith(targetPrefix)).toList();

      int daysInMonth = DateUtils.getDaysInMonth(selectedYear, selectedMonth);
      Map<int, ChartData> dayMap = {for (int i = 1; i <= daysInMonth; i++) i: ChartData('$i일')};

      for (var row in filtered) {
        int day = int.parse((row['date'] as String).split('-')[2]);
        dayMap[day]!.adult += row['adult'] as int;
        dayMap[day]!.child += row['child'] as int;
        dayMap[day]!.infant += row['infant'] as int;
      }
      tempList = dayMap.values.toList();
    }
    else if (viewMode == '연도별') {
      String targetPrefix = '$selectedYear-';
      final filtered = records.where((r) => (r['date'] as String).startsWith(targetPrefix)).toList();

      Map<int, ChartData> monthMap = {for (int i = 1; i <= 12; i++) i: ChartData('$i월')};

      for (var row in filtered) {
        int month = int.parse((row['date'] as String).split('-')[1]);
        monthMap[month]!.adult += row['adult'] as int;
        monthMap[month]!.child += row['child'] as int;
        monthMap[month]!.infant += row['infant'] as int;
      }
      tempList = monthMap.values.toList();
    }
    else if (viewMode == '전체') {
      Map<String, ChartData> yearMap = {};
      for (var row in records) {
        String year = (row['date'] as String).split('-')[0];
        if (!yearMap.containsKey(year)) yearMap[year] = ChartData('$year년');
        yearMap[year]!.adult += row['adult'] as int;
        yearMap[year]!.child += row['child'] as int;
        yearMap[year]!.infant += row['infant'] as int;
      }
      var sortedKeys = yearMap.keys.toList()..sort();
      tempList = sortedKeys.map((k) => yearMap[k]!).toList();
    }

    setState(() {
      chartDataList = tempList;
    });
  }

// 엑셀 추출 함수 (상세, 일별, 월별, 연도별 통계 분리 및 배경색/교차 서식 적용)
  Future<void> _exportToExcel() async {
    try {
      final records = await DatabaseHelper.instance.getAllRecords();
      if (records.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장된 데이터가 없습니다.')));
        return;
      }

      var excel = Excel.createExcel();

      // ==========================================
      // [스타일 정의] (맑은 고딕 공통 및 배경색 추가)
      // ==========================================
      final CellStyle defaultStyle = CellStyle(fontFamily: '맑은 고딕', fontSize: 16);

      // 번갈아가며 칠할 밝은 Secondary Color 배경색 (기존 #4EA699를 매우 밝게)
      final CellStyle altStyle = CellStyle(
        fontFamily: '맑은 고딕',
        fontSize: 16,
        backgroundColorHex: ExcelColor.fromHexString('#E0F0EE'),
      );

      // 1행 헤더용 밝은 Primary Color 배경색 (기존 #2A5982를 밝고 부드럽게)
      final CellStyle headerStyle = CellStyle(
        fontFamily: '맑은 고딕',
        fontSize: 16,
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString('#C5D9E8'),
      );

      final CellStyle titleStyle = CellStyle(
        fontFamily: '맑은 고딕',
        fontSize: 24,
        bold: true,
      );

      // [헬퍼 함수 1] 1행 제목 서식 전용 기록기
      void writeHeader(String sheetName, String cellIndex, String text) {
        var cell = excel[sheetName].cell(CellIndex.indexByString(cellIndex));
        cell.value = TextCellValue(text);
        cell.cellStyle = headerStyle;
      }

      // [헬퍼 함수 2] 데이터 행 추가 및 지정된 스타일(배경색) 적용
      void appendDataRow(String sheetName, List<CellValue> rowData, CellStyle style) {
        var sheet = excel[sheetName];
        sheet.appendRow(rowData);
        int rowIndex = sheet.maxRows - 1; // 방금 추가된 행 번호
        for (int i = 0; i < rowData.length; i++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex)).cellStyle = style;
        }
      }

      // [헬퍼 함수 3] 데이터 작성이 끝난 표에 굵은 테두리(박스) 그리기
      void applyThickBorders(String sheetName) {
        var sheet = excel[sheetName];

        int maxRow = sheet.maxRows - 1;
        int maxCol = sheet.maxColumns - 1;

        for (int r = 0; r <= maxRow; r++) {
          for (int c = 0; c <= maxCol; c++) {
            var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r));
            var currentStyle = cell.cellStyle ?? defaultStyle;

            // 기본은 안쪽 얇은 실선
            ex.Border top = ex.Border(borderStyle: ex.BorderStyle.Thin);
            ex.Border bottom = ex.Border(borderStyle: ex.BorderStyle.Thin);
            ex.Border left = ex.Border(borderStyle: ex.BorderStyle.Thin);
            ex.Border right = ex.Border(borderStyle: ex.BorderStyle.Thin);

            // 1행(제목행) 위아래 굵게
            if (r == 0) {
              top = ex.Border(borderStyle: ex.BorderStyle.Thick);
              bottom = ex.Border(borderStyle: ex.BorderStyle.Thick);
            }
            // 표 맨 아래쪽 바닥 굵게
            if (r == maxRow) bottom = ex.Border(borderStyle: ex.BorderStyle.Thick);
            // 표 맨 왼쪽 기둥 굵게
            if (c == 0) left = ex.Border(borderStyle: ex.BorderStyle.Thick);
            // 표 맨 오른쪽 기둥 굵게
            if (c == maxCol) right = ex.Border(borderStyle: ex.BorderStyle.Thick);

            // 기존 셀의 색상/글씨체는 유지하면서 테두리만 덮어씌우기
            cell.cellStyle = CellStyle(
              fontFamily: currentStyle.fontFamily,
              fontSize: currentStyle.fontSize,
              bold: currentStyle.isBold,
              backgroundColorHex: currentStyle.backgroundColor,
              horizontalAlign: currentStyle.horizontalAlignment,
              verticalAlign: currentStyle.verticalAlignment,
              leftBorder: left,
              topBorder: top,
              rightBorder: right,
              bottomBorder: bottom,
            );
          }
        }
      }

      // 누적 합계를 계산할 임시 저장소(Map)들
      Map<String, Map<String, dynamic>> dailyTotals = {};
      Map<String, Map<String, dynamic>> monthlyTotals = {};
      Map<String, Map<String, dynamic>> yearlyTotals = {};

      // 상세 시트 색상 교차를 위한 상태 추적기 (시트별로 날짜가 바뀔 때마다 색상 토글)
      Map<String, String> lastDatePerSheet = {};
      Map<String, bool> isAltColorPerSheet = {};

      // 1. 전체 데이터 순회 및 [상세 시트] 작성
      for (var row in records) {
        String dateStr = row['date'];
        DateTime date = DateTime.parse(dateStr);
        String yearStr = '${date.year}';
        String monthStr = '${date.month}월';
        String yearMonthStr = '${date.year}-${date.month.toString().padLeft(2, '0')}';

        String detailSheet = '$yearStr년_상세';
        String dailySheet = '$yearStr년_일별통계';
        String monthlySheet = '$yearStr년_월별통계';
        String yearlySheet = '전체_연도별통계';

        int adult = row['adult'];
        int child = row['child'];
        int infant = row['infant'];
        int total = adult + child + infant;

        // [상세 시트 배경색 결정 로직] - 같은 날짜는 같은 배경색, 날짜가 바뀌면 배경색 반전
        if (lastDatePerSheet[detailSheet] != dateStr) {
          lastDatePerSheet[detailSheet] = dateStr;
          // 이전 상태 반전 (첫 날짜는 기본색이 되도록 null 처리)
          isAltColorPerSheet[detailSheet] = !(isAltColorPerSheet[detailSheet] ?? true);
        }
        CellStyle detailRowStyle = isAltColorPerSheet[detailSheet]! ? altStyle : defaultStyle;

        // [상세 데이터 작성 및 1행 서식 적용]
        if (!excel.tables.keys.contains(detailSheet)) {
          writeHeader(detailSheet, "A1", '날짜');
          writeHeader(detailSheet, "B1", '월(필터용)');
          writeHeader(detailSheet, "C1", '시간대');
          writeHeader(detailSheet, "D1", '성인');
          writeHeader(detailSheet, "E1", '아동');
          writeHeader(detailSheet, "F1", '유아');
          writeHeader(detailSheet, "G1", '총합');

          // 열 너비 설정: A(16.33), B(14), C(18.67), D~G(10)
          excel[detailSheet].setColumnWidth(0, 16.33);
          excel[detailSheet].setColumnWidth(1, 14.0);
          excel[detailSheet].setColumnWidth(2, 18.67);
          for(int i = 3; i <= 6; i++) {
            excel[detailSheet].setColumnWidth(i, 10.0);
          }
        }

        appendDataRow(detailSheet, [
          TextCellValue(dateStr),
          TextCellValue(monthStr),
          TextCellValue(row['time_slot']),
          IntCellValue(adult),
          IntCellValue(child),
          IntCellValue(infant),
          IntCellValue(total)
        ], detailRowStyle); // 계산된 배경색 적용

        // 데이터 누적 처리 (일별, 월별, 연도별)
        if (!dailyTotals.containsKey(dateStr)) {
          dailyTotals[dateStr] = {'sheet': dailySheet, 'month': monthStr, 'adult': 0, 'child': 0, 'infant': 0, 'total': 0};
        }
        dailyTotals[dateStr]!['adult'] += adult; dailyTotals[dateStr]!['child'] += child; dailyTotals[dateStr]!['infant'] += infant; dailyTotals[dateStr]!['total'] += total;

        if (!monthlyTotals.containsKey(yearMonthStr)) {
          monthlyTotals[yearMonthStr] = {'sheet': monthlySheet, 'year': yearStr, 'month': monthStr, 'adult': 0, 'child': 0, 'infant': 0, 'total': 0};
        }
        monthlyTotals[yearMonthStr]!['adult'] += adult; monthlyTotals[yearMonthStr]!['child'] += child; monthlyTotals[yearMonthStr]!['infant'] += infant; monthlyTotals[yearMonthStr]!['total'] += total;

        if (!yearlyTotals.containsKey(yearStr)) {
          yearlyTotals[yearStr] = {'sheet': yearlySheet, 'year': yearStr, 'adult': 0, 'child': 0, 'infant': 0, 'total': 0};
        }
        yearlyTotals[yearStr]!['adult'] += adult; yearlyTotals[yearStr]!['child'] += child; yearlyTotals[yearStr]!['infant'] += infant; yearlyTotals[yearStr]!['total'] += total;
      }

      // 2. 누적된 [일별 통계] 시트 작성 (1줄씩 교차 배경색)
      Map<String, bool> dailyAltTracker = {};
      var sortedDates = dailyTotals.keys.toList()..sort();
      for (var dateStr in sortedDates) {
        var data = dailyTotals[dateStr]!;
        String sheet = data['sheet'];
        if (!excel.tables.keys.contains(sheet)) {
          writeHeader(sheet, "A1", '날짜');
          writeHeader(sheet, "B1", '월(필터용)');
          writeHeader(sheet, "C1", '성인 총합');
          writeHeader(sheet, "D1", '아동 총합');
          writeHeader(sheet, "E1", '유아 총합');
          writeHeader(sheet, "F1", '일일 총방문자');

          // 열 너비 설정: A(16.33), B(14), C~E(13.33), F(19.17)
          excel[sheet].setColumnWidth(0, 16.33);
          excel[sheet].setColumnWidth(1, 14.0);
          excel[sheet].setColumnWidth(2, 13.33);
          excel[sheet].setColumnWidth(3, 13.33);
          excel[sheet].setColumnWidth(4, 13.33);
          excel[sheet].setColumnWidth(5, 19.17);
        }
        bool isAlt = dailyAltTracker[sheet] ?? false;
        appendDataRow(sheet, [TextCellValue(dateStr), TextCellValue(data['month']), IntCellValue(data['adult']), IntCellValue(data['child']), IntCellValue(data['infant']), IntCellValue(data['total'])], isAlt ? altStyle : defaultStyle);
        dailyAltTracker[sheet] = !isAlt; // 다음 줄을 위해 색상 반전
      }

      // 3. 누적된 [월별 통계] 시트 작성 (1줄씩 교차 배경색)
      Map<String, bool> monthlyAltTracker = {};
      var sortedMonths = monthlyTotals.keys.toList()..sort();
      for (var ymStr in sortedMonths) {
        var data = monthlyTotals[ymStr]!;
        String sheet = data['sheet'];
        if (!excel.tables.keys.contains(sheet)) {
          writeHeader(sheet, "A1", '해당 월');
          writeHeader(sheet, "B1", '성인 총합');
          writeHeader(sheet, "C1", '아동 총합');
          writeHeader(sheet, "D1", '유아 총합');
          writeHeader(sheet, "E1", '월간 총방문자');

          // 열 너비 설정: A(15.5), B(13.33), C(18.67), D(13.33), E(19.17)
          excel[sheet].setColumnWidth(0, 15.5);
          excel[sheet].setColumnWidth(1, 13.33);
          excel[sheet].setColumnWidth(2, 18.67);
          excel[sheet].setColumnWidth(3, 13.33);
          excel[sheet].setColumnWidth(4, 19.17);
        }
        bool isAlt = monthlyAltTracker[sheet] ?? false;
        appendDataRow(sheet, [TextCellValue('${data['year']}년 ${data['month']}'), IntCellValue(data['adult']), IntCellValue(data['child']), IntCellValue(data['infant']), IntCellValue(data['total'])], isAlt ? altStyle : defaultStyle);
        monthlyAltTracker[sheet] = !isAlt;
      }

      // 4. 누적된 [연도별 통계] 마스터 시트 작성 (1줄씩 교차 배경색)
      Map<String, bool> yearlyAltTracker = {};
      var sortedYears = yearlyTotals.keys.toList()..sort();
      for (var yearStr in sortedYears) {
        var data = yearlyTotals[yearStr]!;
        String sheet = data['sheet'];
        if (!excel.tables.keys.contains(sheet)) {
          writeHeader(sheet, "A1", '연도');
          writeHeader(sheet, "B1", '성인 총합');
          writeHeader(sheet, "C1", '아동 총합');
          writeHeader(sheet, "D1", '유아 총합');
          writeHeader(sheet, "E1", '연간 총방문자');

          // 열 너비 설정: A(10), B(13.33), C(18.67), D(13.33), E(19.17)
          excel[sheet].setColumnWidth(0, 10.0);
          excel[sheet].setColumnWidth(1, 13.33);
          excel[sheet].setColumnWidth(2, 18.67);
          excel[sheet].setColumnWidth(3, 13.33);
          excel[sheet].setColumnWidth(4, 19.17);
        }
        bool isAlt = yearlyAltTracker[sheet] ?? false;
        appendDataRow(sheet, [TextCellValue('${data['year']}년'), IntCellValue(data['adult']), IntCellValue(data['child']), IntCellValue(data['infant']), IntCellValue(data['total'])], isAlt ? altStyle : defaultStyle);
        yearlyAltTracker[sheet] = !isAlt;
      }

      // 모든 데이터 입력이 끝난 후, 각 시트별로 테두리 일괄 적용
      for (var sheetName in excel.tables.keys) {
        if (sheetName != 'Sheet1') { // 아직 이름이 안 바뀐 '안내 표지'는 놔두고 적용
          applyThickBorders(sheetName);
        }
      }

      // 5. '안내 표지' 시트 서식 지정
      if (excel.tables.keys.contains('Sheet1')) {
        excel.rename('Sheet1', '보고서_안내');
        var guideSheet = excel['보고서_안내'];

        void writeGuide(String cellIndex, String text, CellStyle style) {
          var cell = guideSheet.cell(CellIndex.indexByString(cellIndex));
          cell.value = TextCellValue(text);
          cell.cellStyle = style;
        }

        // B2 열 제목 크기 확대 및 강조
        writeGuide("B2", '도서관 이용자 통계 보고서입니다.', titleStyle);

        // 나머지 본문 기본 스타일 적용
        writeGuide("B4", '하단의 탭(시트)을 클릭하여 다음 통계를 확인하세요:', defaultStyle);
        writeGuide("C5", '- 전체_연도별통계: 마스터 요약 데이터', defaultStyle);
        writeGuide("C6", '- 0000년_월별통계: 해당 연도의 월간 누적 합계', defaultStyle);
        writeGuide("C7", '- 0000년_일별통계: 해당 연도의 일간 누적 합계', defaultStyle);
        writeGuide("C8", '- 0000년_상세: 시간대별 원본 기록', defaultStyle);

        excel.setDefaultSheet('보고서_안내');
      }

      // 6. 바탕화면에 저장
      String saveDir = '';
      if (Platform.isWindows) {
        saveDir = p.join(Platform.environment['USERPROFILE']!, 'Desktop');
      } else {
        final dir = await getApplicationDocumentsDirectory();
        saveDir = dir.path;
      }

      final filePath = p.join(saveDir, '도서관_이용자_통계보고서.xlsx');
      final fileBytes = excel.save();

      if (fileBytes != null) {
        File(filePath)..createSync(recursive: true)..writeAsBytesSync(fileBytes);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('바탕화면에 엑셀 통계보고서 저장이 완료되었습니다!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final colorScheme = Theme.of(context).colorScheme;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2026),
      lastDate: DateTime(2050),
      // 1. 한국어 텍스트 커스텀
      helpText: '조회할 날짜를 선택',
      cancelText: '취소',
      confirmText: '확인',
      fieldLabelText: '날짜 직접 입력',
      errorFormatText: '올바른 날짜 형식이 아닙니다.',
      errorInvalidText: '선택할 수 없는 날짜입니다.',
      // 2. 테마 및 UI 커스텀
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            // 달력 색상 테마 덮어쓰기
            colorScheme: ColorScheme.light(
              primary: colorScheme.primary, // 상단 헤더 배경색 및 선택된 날짜 동그라미 색상
              onPrimary: Colors.white, // 상단 헤더 텍스트 및 선택된 날짜 텍스트 색상
              surface: Colors.white, // 달력 배경색
              onSurface: colorScheme.onSurface, // 달력 일반 날짜 텍스트 색상
            ),
            // 하단 버튼(취소/확인) 스타일 커스텀
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary, // 버튼 글씨색
                textStyle: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            // 팝업 창 모양 커스텀 (둥근 모서리)
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0), // 모서리를 부드럽게
              ),
              elevation: 10,
            ),
            // DatePicker 내부 텍스트 스타일 세밀 조정
            datePickerTheme: DatePickerThemeData(
              // 1. 상단 안내 문구
              headerHelpStyle: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimary.withValues(alpha: 0.9), // 약간 투명하게
              ),
              // 2. 선택된 날짜 헤더 ('3월 5일 (목)' 줄바꿈 방지)
              headerHeadlineStyle: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
          // Transform.scale을 사용해 달력 창 전체 크기를 키움
          child: Transform.scale(
            scale: 1.2, // 기본 크기 대비 1.2배(20%) 확대.
            child: child!,
          ),
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      _loadAndProcessData(); // 데이터 새로고침
    }
  }

  // 드롭박스(DropdownButton) 대체 마우스 커서 지원 커스텀 위젯
  Widget _buildCursorDropdown<T>({
    required T value,
    required List<T> items,
    required void Function(T) onChanged,
    required String Function(T) displayText,
  }) {
    return PopupMenuButton<T>(
      tooltip: '', // 기본 툴팁(팝업 메뉴) 글씨 숨기기
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40), // 버튼 바로 아래에 메뉴가 열리도록 위치 조정
      itemBuilder: (context) {
        return items.map((T item) {
          return PopupMenuItem<T>(
            value: item,
            // 1. 드롭다운 메뉴 안의 각 항목에 손가락 커서 적용
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: SizedBox(
                width: double.infinity,
                child: Text(displayText(item)),
              ),
            ),
          );
        }).toList();
      },
      // 2. 바깥쪽 메인 버튼에 손가락 커서 적용
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            // color: Colors.grey.shade200, // 필요 시 배경색 지정 가능
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(displayText(value), style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totals = _getChartTotal();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단 네비게이션 (필터링 컨트롤러)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Text('조회 기준: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),

                // 1. 조회 기준 드롭박스
                _buildCursorDropdown<String>(
                  value: viewMode,
                  items: ['일별', '월별', '연도별', '전체'],
                  displayText: (val) => val,
                  onChanged: (String newValue) {
                    setState(() => viewMode = newValue);
                    _loadAndProcessData();
                  },
                ),

                const SizedBox(width: 24),
                const SizedBox(height: 20, child: VerticalDivider(width: 1)),
                const SizedBox(width: 24),

                if (viewMode == '일별')
                  OutlinedButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(DateFormat('yyyy년 MM월 dd일').format(selectedDate)),
                  ),
                if (viewMode == '월별' || viewMode == '연도별')
                // 2. 연도 드롭박스
                  _buildCursorDropdown<int>(
                    value: selectedYear,
                    items: availableYears,
                    displayText: (val) => '$val년',
                    onChanged: (int newValue) {
                      setState(() => selectedYear = newValue);
                      _loadAndProcessData();
                    },
                  ),
                if (viewMode == '월별') ...[
                  const SizedBox(width: 16),
                  // 3. 월 드롭박스
                  _buildCursorDropdown<int>(
                    value: selectedMonth,
                    items: availableMonths,
                    displayText: (val) => '$val월',
                    onChanged: (int newValue) {
                      setState(() => selectedMonth = newValue);
                      _loadAndProcessData();
                    },
                  ),
                ],
                if (viewMode == '전체')
                  const Text('모든 연도의 누적 데이터입니다.', style: TextStyle(color: Colors.grey)),

                const Spacer(),
                FilledButton.icon(
                  onPressed: _exportToExcel,
                  icon: const Icon(Icons.download),
                  label: const Text('엑셀 다운로드'),
                  style: FilledButton.styleFrom(backgroundColor: Colors.green.shade700),
                )
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 통계 페이지 상단 요약 합계 카드 추가
          Row(
            children: [
              _buildTotalSummaryCard('성인 합계', totals['adult']!, colorScheme.primary),
              const SizedBox(width: 16),
              _buildTotalSummaryCard('아동 합계', totals['child']!, colorScheme.secondary),
              const SizedBox(width: 16),
              _buildTotalSummaryCard('유아 합계', totals['infant']!, colorScheme.tertiary),
              const SizedBox(width: 16),
              _buildTotalSummaryCard('전체 합계', totals['adult']! + totals['child']! + totals['infant']!, Colors.grey.shade800),
            ],
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.circle, color: colorScheme.primary, size: 14), const SizedBox(width: 4), const Text(' 성인  '),
              const SizedBox(width: 12),
              Icon(Icons.circle, color: colorScheme.secondary, size: 14), const SizedBox(width: 4), const Text(' 아동  '),
              const SizedBox(width: 12),
              Icon(Icons.circle, color: colorScheme.tertiary, size: 14), const SizedBox(width: 4), const Text(' 유아'),

              const Spacer(), // 오른쪽 끝으로 밀어내기

              // 차트 전환 스위치
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: '막대', icon: Icon(Icons.bar_chart), label: Text('막대')),
                  ButtonSegment(value: '선', icon: Icon(Icons.show_chart), label: Text('꺾은선')),
                ],
                selected: {chartType},
                onSelectionChanged: (newSelection) {
                  setState(() => chartType = newSelection.first);
                },
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact, // 버튼을 작고 슬림하게
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 차트 영역
          Expanded(
            child: chartDataList.isEmpty || chartDataList.every((d) => d.total == 0)
                ? const Center(child: Text('해당 기간에 기록된 데이터가 없습니다.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                : (chartType == '막대' ? _buildBarChart(colorScheme) : _buildLineChart(colorScheme)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 막대 차트 빌더
  // ---------------------------------------------------------------------------
  Widget _buildBarChart(ColorScheme colorScheme) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.grey.shade300,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              // 현재 마우스가 올라간 막대의 전체 데이터 가져오기
              final data = chartDataList[group.x.toInt()];

              return BarTooltipItem(
                '총합: ${data.total}명\n', // 맨 위에는 총합을 검은색으로 표시
                const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                children: [
                  // 그 아래에 각 항목별 이름, 수치, 테마 색상을 적용하여 표시
                  TextSpan(
                    text: '성인: ${data.adult}명\n',
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  TextSpan(
                    text: '아동: ${data.child}명\n',
                    style: TextStyle(color: colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  TextSpan(
                    text: '유아: ${data.infant}명',
                    style: TextStyle(color: colorScheme.tertiary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= chartDataList.length || value.toInt() < 0) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(chartDataList[value.toInt()].label, style: const TextStyle(fontSize: 12)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: _getLeftTitleInterval(),
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                return Text('${value.toInt()}', style: const TextStyle(fontSize: 12, color: Colors.grey));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getLeftTitleInterval(),
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(chartDataList.length, (index) {
          final data = chartDataList[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: data.total.toDouble(),
                width: viewMode == '월별' ? 12 : 32,
                borderRadius: BorderRadius.circular(4),
                rodStackItems: [
                  BarChartRodStackItem(0, data.adult.toDouble(), colorScheme.primary),
                  BarChartRodStackItem(data.adult.toDouble(), (data.adult + data.child).toDouble(), colorScheme.secondary),
                  BarChartRodStackItem((data.adult + data.child).toDouble(), data.total.toDouble(), colorScheme.tertiary),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 꺾은선 차트 빌더 (각 대상별 추세를 명확하게 보여줌)
  // ---------------------------------------------------------------------------
  Widget _buildLineChart(ColorScheme colorScheme) {
    // 각 대상별 좌표(Spot) 데이터 생성
    List<FlSpot> adultSpots = [];
    List<FlSpot> childSpots = [];
    List<FlSpot> infantSpots = [];

    for (int i = 0; i < chartDataList.length; i++) {
      adultSpots.add(FlSpot(i.toDouble(), chartDataList[i].adult.toDouble()));
      childSpots.add(FlSpot(i.toDouble(), chartDataList[i].child.toDouble()));
      infantSpots.add(FlSpot(i.toDouble(), chartDataList[i].infant.toDouble()));
    }

    return LineChart(
      LineChartData(
        // 좌우 끝에 있는 점이 벽에 딱 붙어서 잘리지 않도록 약간의 여유 공간
        minX: -0.2,
        maxX: chartDataList.length - 0.8,
        maxY: _getMaxY(),
        minY: 0,
        // 위아래 점 온전하게 보존
        clipData: const FlClipData.none(),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.grey.shade300,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                // 대상별 이름 매칭
                String title = '';
                if (touchedSpot.barIndex == 0) title = '성인';
                if (touchedSpot.barIndex == 1) title = '아동';
                if (touchedSpot.barIndex == 2) title = '유아';

                return LineTooltipItem(
                  '$title: ${touchedSpot.y.toInt()}명',
                  TextStyle(color: touchedSpot.bar.color, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                // 소수점 위치에는 라벨을 그리지 않음
                if (value % 1 != 0) return const SizedBox.shrink();
                if (value.toInt() >= chartDataList.length || value.toInt() < 0) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(chartDataList[value.toInt()].label, style: const TextStyle(fontSize: 12)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: _getLeftTitleInterval(),
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                // 정한 간격(예: 2, 4, 6)에 정확히 나눠떨어지지 않는 잉여 값(예: 8.05)은 무시
                if (value % _getLeftTitleInterval() != 0) return const SizedBox.shrink();
                return Text('${value.toInt()}', style: const TextStyle(fontSize: 12, color: Colors.grey));
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true, // 꺾은선은 세로 기준선이 있으면 보기 편합니다.
          verticalInterval: 1,
          horizontalInterval: _getLeftTitleInterval(),
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade300, strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // 1. 성인 라인
          LineChartBarData(
            spots: adultSpots,
            isCurved: true, // 곡선으로 부드럽게
            // 곡선이 0 밑으로 파고드는 현상(오버슈팅) 방지
            preventCurveOverShooting: true,
            color: colorScheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true), // 데이터 포인트에 동그라미 표시
          ),
          // 2. 아동 라인
          LineChartBarData(
            spots: childSpots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: colorScheme.secondary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
          ),
          // 3. 유아 라인
          LineChartBarData(
            spots: infantSpots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: colorScheme.tertiary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  // 1. 실제 데이터 중 가장 큰 값을 찾는 함수 (차트 종류에 따라 기준 변경)
  double _getActualMax() {
    double maxData = 0;
    for (var data in chartDataList) {
      if (chartType == '막대') {
        // 막대 그래프는 누적된 '총합(total)' 중 최대값을 기준으로 삼음
        if (data.total > maxData) maxData = data.total.toDouble();
      } else {
        // 꺾은선 그래프는 '개별 항목(성인, 아동, 유아)' 중 가장 높은 값을 기준으로 삼음
        if (data.adult > maxData) maxData = data.adult.toDouble();
        if (data.child > maxData) maxData = data.child.toDouble();
        if (data.infant > maxData) maxData = data.infant.toDouble();
      }
    }
    return maxData;
  }

  // 2. 차트의 Y축 최대 높이 설정
  double _getMaxY() {
    double maxData = _getActualMax();

    if (maxData == 0) return 5; // 데이터가 아예 없을 때의 기본 배경 높이
    if (maxData <= 5) return maxData + 1; // 5명 이하일 때는 딱 한 칸(1명) 위까지만 여유 공간 부여

    return maxData + (maxData * 0.15); // 그 외에는 위쪽 15% 여유 공간
  }

  // 3. Y축 눈금 간격 설정
  double _getLeftTitleInterval() {
    double maxData = _getActualMax();

    if (maxData <= 5) return 1;       // 최대 5명이면 1단위 (1, 2, 3, 4, 5)
    if (maxData <= 10) return 2;      // 최대 10명이면 2단위 (2, 4, 6, 8, 10)
    if (maxData <= 50) return 10;     // 50명이면 10단위
    if (maxData <= 100) return 20;    // 100명이면 20단위
    if (maxData <= 500) return 100;   // 500명이면 100단위
    if (maxData <= 1000) return 200;  // 1000명이면 200단위
    return 500;                       // 그 이상이면 500단위
  }

  // 요약 카드 빌더 위젯
  Widget _buildTotalSummaryCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text('$count명', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 초기 로딩 스플래시 화면
// -----------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 1.5초 동안 로고를 보여준 후, 메인 화면으로 부드럽게 이동
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const MainNavigationScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // 페이드-인(Fade-in) 애니메이션 적용
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800), // 스르륵 넘어가는 속도
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 도서관 앱의 메인 브랜드 컬러(짙은 파란색)를 배경으로 사용
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 등록한 로고 이미지 불러오기
            Image.asset('assets/icon/app_icon.png', width: 140, height: 140),
            const SizedBox(height: 32),
            const Text(
              '오늘의 도서관',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '방문자 집계 및 통계',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 요일별 운영 시간 설정 팝업창
// -----------------------------------------------------------------------------
class ScheduleSettingsDialog extends StatefulWidget {
  const ScheduleSettingsDialog({super.key});

  @override
  State<ScheduleSettingsDialog> createState() => _ScheduleSettingsDialogState();
}

class _ScheduleSettingsDialogState extends State<ScheduleSettingsDialog> {
  final Map<int, String> weekdayNames = {
    1: '월요일',
    2: '화요일',
    3: '수요일',
    4: '목요일',
    5: '금요일',
    6: '토요일',
    7: '일요일'
  };
  late Map<int, Map<String, int>> localHours;

  @override
  void initState() {
    super.initState();
    // LibrarySchedule의 현재 상태를 깊은 복사하여 임시 저장
    localHours = {};
    LibrarySchedule.hours.forEach((key, value) {
      localHours[key] = Map.from(value);
    });
  }

  Future<void> _saveSettings() async {
    for (int i = 1; i <= 7; i++) {
      await LibrarySchedule.updateSchedule(
        i,
        localHours[i]!['start']!,
        localHours[i]!['end']!,
        localHours[i]!['closed']!,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme
        .of(context)
        .colorScheme;

    return AlertDialog(
      title: const Text(
          '요일별 운영 시간 설정', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
          width: 430,
          child: SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16.0),
                        child: Text('체크박스를 해제하면 해당 요일은 휴관일로 처리됩니다.',
                            style: TextStyle(color: Colors.grey)),
                      ),
                      ...List.generate(7, (index) {
                        int day = index + 1;
                        bool isClosed = localHours[day]!['closed'] == 1;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              SizedBox(width: 60,
                                  child: Text(weekdayNames[day]!, style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold))),
                              Checkbox(
                                value: !isClosed,
                                activeColor: colorScheme.primary,
                                mouseCursor: SystemMouseCursors.click,
                                onChanged: (val) {
                                  setState(() {
                                    localHours[day]!['closed'] = (val == true) ? 0 : 1;
                                  });
                                },
                              ),
                              const Text('운영'),
                              const Spacer(),
                              // 고정 크기의 SizedBox로 감싸서 전환 시 흔들림(Jitter)을 원천 차단합니다.
                              SizedBox(
                                width: 240, // [드롭다운(100) + ~ (30) + 드롭다운(100)] 넉넉히 계산
                                height: 48, // 드롭다운 위젯의 높이와 일치시킵니다.
                                child: !isClosed
                                    ? Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    _buildTimeDropdown(day, 'start'),
                                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('~')),
                                    _buildTimeDropdown(day, 'end'),
                                  ],
                                )
                                    : const Center(
                                    child: Text(
                                        '휴관일',
                                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)
                                    )
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      // 공장 초기화 (Danger Zone)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('위험 구역 (Danger Zone)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                              const SizedBox(height: 4),
                              Text('프로그램 삭제 전 데이터 영구 지우기', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            ],
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('공장 초기화'),
                            onPressed: () async {
                              bool? confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('⚠️ 공장 초기화 경고', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                  content: const Text(
                                      '모든 방문자 기록과 운영 시간 설정이 영구적으로 삭제됩니다.\n'
                                          'PC에서 앱을 완전히 지우기 전에만 사용하세요.\n\n'
                                          '정말 초기화하시겠습니까? (완료 시 앱이 즉시 종료됩니다)'
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                                    FilledButton(
                                      style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('영구 삭제'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                // 1. DB 모든 데이터 날리기
                                await DatabaseHelper.instance.clearAllData();
                                // 2. 창 크기 등 SharedPreferences 설정 날리기
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.clear();
                                // 3. 앱 강제 종료 (dart:io 패키지의 exit 함수)
                                exit(0);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  )
              )
          )
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소')),
        FilledButton(onPressed: _saveSettings, child: const Text('저장')),
      ],
    );
  }

  Widget _buildTimeDropdown(int day, String type) {
    // 1. 시작 시간(0~23)과 종료 시간(1~24)의 선택지를 다르게 생성합니다.
    final timeItems = <int, String>{};
    if (type == 'start') {
      for (int i = 0; i <= 23; i++) {
        timeItems[i] = '${i.toString().padLeft(2, '0')}:00';
      }
    } else {
      for (int i = 1; i <= 24; i++) {
        timeItems[i] = '${i.toString().padLeft(2, '0')}:00';
      }
    }

    return CustomDropdown<int>(
      value: localHours[day]![type]!,
      items: timeItems,
      width: 100,
      // 시간 표시에 적절한 폭으로 조정
      maxMenuHeight: 200,
      // 메뉴의 최대 높이를 200으로 제한 (내부 스크롤 생성)
      openUp: day >= 5,
      onChanged: (val) {
        if (val != null) {
          setState(() {
            localHours[day]![type] = val;

            if (type == 'start' && val >= localHours[day]!['end']!) {
              localHours[day]!['end'] = val + 1;
              // 종료 시간이 24시를 넘지 않도록 방어
              if (localHours[day]!['end']! > 24) localHours[day]!['end'] = 24;
              // 만약 시작시간이 24시면 종료시간도 24시가 되는 문제 해결
              if (localHours[day]!['start']! >= localHours[day]!['end']!) {
                localHours[day]!['start'] = localHours[day]!['end']! - 1;
              }
            } else if (type == 'end' && val <= localHours[day]!['start']!) {
              localHours[day]!['start'] = val - 1;
              // 시작 시간이 0시보다 작아지지 않도록 방어
              if (localHours[day]!['start']! < 0) localHours[day]!['start'] = 0;
            }
          });
        }
      },
    );
  }
}

// -----------------------------------------------------------------------------
// 고도화된 커스텀 드롭다운 위젯 (높이 제한 기능 추가)
// -----------------------------------------------------------------------------
class CustomDropdown<T> extends StatefulWidget {
  final T value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;
  final double width;
  final String? hint;
  final double maxMenuHeight; // 메뉴의 최대 높이 설정
  final bool openUp; // 위로 열기 옵션

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 150,
    this.hint,
    this.maxMenuHeight = 260, // 기본 최대 높이를 260으로 설정
    this.openUp = false, // 기본값은 아래로 열림
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 바깥 영역 클릭 시 닫히도록 투명한 배경 배치
          GestureDetector(
            onTap: _closeDropdown,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            // 방향에 따라 부착 지점(Anchor)을 다르게 설정합니다.
            targetAnchor: widget.openUp ? Alignment.topLeft : Alignment.bottomLeft,
            followerAnchor: widget.openUp ? Alignment.bottomLeft : Alignment.topLeft,
            offset: Offset(0, widget.openUp ? -8 : 8), // 간격 조절
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              // 메뉴 전체 높이를 제한
              child: _CustomDropdownMenu<T>(
                items: widget.items,
                selectedValue: widget.value,
                width: widget.width,
                maxHeight: widget.maxMenuHeight, // 최대 높이 전달
                onItemSelected: (T item) {
                  widget.onChanged(item);
                  _closeDropdown();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CompositedTransformTarget(
        link: _layerLink,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _toggleDropdown,
            child: Container(
              width: widget.width,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: _isOpen ? colorScheme.primary : Colors.grey.shade300, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.items[widget.value] ?? widget.hint ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: _isOpen ? colorScheme.primary : Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),)
    );
  }
}

// 스크롤을 감싸고 높이를 제한하는 새로운 내부 위젯
class _CustomDropdownMenu<T> extends StatelessWidget {
  final Map<T, String> items;
  final T selectedValue;
  final double width;
  final double maxHeight;
  final ValueChanged<T> onItemSelected;

  const _CustomDropdownMenu({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.width,
    required this.maxHeight,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      // ConstrainedBox로 최대 높이를 제한합니다.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight, // 이 높이를 넘어가면 스크롤이 생깁니다.
        ),
        // ListView.builder를 사용하여 항목이 많아도 성능을 보장합니다.
        child: ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true, // 항목이 적을 때는 높이에 맞게 줄어듭니다.
          itemCount: items.length,
          itemBuilder: (context, index) {
            T key = items.keys.elementAt(index);
            String value = items[key]!;
            bool isSelected = key == selectedValue;

            return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onItemSelected(key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    color: isSelected ? colorScheme.primary.withAlpha(10) : Colors.transparent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? colorScheme.primary : Colors.grey.shade800,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (isSelected) Icon(Icons.check, color: colorScheme.primary, size: 18),
                      ],
                    ),
                  ),
                )
            );
          },
        ),
      ),
    );
  }
}