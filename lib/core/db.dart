import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// اتصال قاعدة البيانات — singleton زي ما اتعودنا، ومايتقفلش أبدًا.
class AppDb {
  AppDb._();

  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    return openDatabase(
      await dbPath(),
      version: 48,
      onCreate: createSchema,
      onUpgrade: upgradeSchema,
    );
  }

  static Future<String> dbPath() async {
    final dir = await getDatabasesPath();
    return p.join(dir, 'my_assistant.db');
  }

  /// يقفل الاتصال مؤقتًا — للاستعادة من نسخة احتياطية فقط.
  static Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }

  /// يمسح كل بيانات المستخدم من كل الجداول. [keepSettings] بيحافظ على الثيم واللغة.
  static Future<void> wipeAllData({bool keepSettings = true}) async {
    final db = await instance;
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' "
        "AND name NOT LIKE 'sqlite_%' AND name != 'android_metadata'");
    final batch = db.batch();
    for (final t in tables) {
      final name = t['name'] as String;
      if (keepSettings && name == 'settings') continue;
      batch.delete(name);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> upgradeSchema(Database db, int oldV, int newV) async {
    if (oldV < 2 && newV >= 2) {
      await db.execute(
          'ALTER TABLE appointments ADD COLUMN postpone_count INTEGER NOT NULL DEFAULT 0');
      await db.execute('''
        CREATE TABLE weekly_reviews(
          week_key TEXT PRIMARY KEY,
          went_well TEXT NOT NULL DEFAULT '',
          blocked_me TEXT NOT NULL DEFAULT '',
          next_focus TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL
        )''');
    }
    if (oldV < 3 && newV >= 3) {
      for (final ddl in _v3Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 4 && newV >= 4) {
      for (final ddl in _v4Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 5 && newV >= 5) {
      for (final ddl in _v5Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 6 && newV >= 6) {
      for (final ddl in _v6Statements) {
        await db.execute(ddl);
      }
    }
    if (oldV < 7 && newV >= 7) {
      for (final ddl in _v7Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 8 && newV >= 8) {
      for (final ddl in _v8Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 9 && newV >= 9) {
      for (final ddl in _v9Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 10 && newV >= 10) {
      for (final ddl in _v10Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 11 && newV >= 11) {
      for (final ddl in _v11Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 12 && newV >= 12) {
      for (final ddl in _v12Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 13 && newV >= 13) {
      for (final ddl in _v13Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 14 && newV >= 14) {
      for (final ddl in _v14Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 15 && newV >= 15) {
      for (final ddl in _v15Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 16 && newV >= 16) {
      for (final ddl in _v16Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 17 && newV >= 17) {
      for (final ddl in _v17Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 18 && newV >= 18) {
      for (final ddl in _v18Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 19 && newV >= 19) {
      for (final ddl in _v19Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 20 && newV >= 20) {
      for (final ddl in _v20Tables) {
        await db.execute(ddl);
      }
      await db.execute(
          'ALTER TABLE appointments ADD COLUMN travel_min INTEGER NOT NULL DEFAULT 0');
    }
    if (oldV < 21 && newV >= 21) {
      for (final ddl in _v21Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 22 && newV >= 22) {
      for (final ddl in _v22Tables) {
        await db.execute(ddl);
      }
      await db.execute('ALTER TABLE expenses ADD COLUMN wallet_id INTEGER');
      await db.execute('ALTER TABLE income ADD COLUMN wallet_id INTEGER');
    }
    if (oldV < 23 && newV >= 23) {
      await db.execute(
          "ALTER TABLE appointments ADD COLUMN repeat TEXT NOT NULL DEFAULT 'none'");
    }
    if (oldV < 24 && newV >= 24) {
      for (final ddl in _v24Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 25 && newV >= 25) {
      for (final ddl in _v25Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 26 && newV >= 26) {
      await db.execute(
          "ALTER TABLE medications ADD COLUMN form TEXT NOT NULL DEFAULT ''");
      await db.execute(
          "ALTER TABLE medications ADD COLUMN unit TEXT NOT NULL DEFAULT ''");
    }
    if (oldV < 27 && newV >= 27) {
      for (final ddl in _v27Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 28 && newV >= 28) {
      // ماكروز الوجبات — بروتين/كارب/دهون + الكمية بالجرام.
      await _safeAddColumn(db, 'meals', 'protein', 'REAL');
      await _safeAddColumn(db, 'meals', 'carbs', 'REAL');
      await _safeAddColumn(db, 'meals', 'fat', 'REAL');
      await _safeAddColumn(db, 'meals', 'grams', 'REAL');
    }
    if (oldV < 29 && newV >= 29) {
      for (final ddl in _v29Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 30 && newV >= 30) {
      for (final ddl in _v30Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 31 && newV >= 31) {
      for (final ddl in _v31Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 32 && newV >= 32) {
      for (final ddl in _v32Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 33 && newV >= 33) {
      // تسجيل العلاقة (لوضع محاولة الحمل) في التسجيل اليومي.
      await _safeAddColumn(db, 'cycle_days', 'intimacy', 'INTEGER NOT NULL DEFAULT 0');
    }
    if (oldV < 34 && newV >= 34) {
      for (final ddl in _v34Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 35 && newV >= 35) {
      for (final ddl in _v35Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 36 && newV >= 36) {
      for (final ddl in _v36Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 37 && newV >= 37) {
      for (final ddl in _v37Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 38 && newV >= 38) {
      for (final ddl in _v38Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 39 && newV >= 39) {
      for (final ddl in _v39Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 40 && newV >= 40) {
      for (final ddl in _v40Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 41 && newV >= 41) {
      for (final ddl in _v41Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 42 && newV >= 42) {
      for (final ddl in _v42Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 43 && newV >= 43) {
      for (final ddl in _v43Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 44 && newV >= 44) {
      for (final ddl in _v44Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 45 && newV >= 45) {
      // تتبّع الغسيل: عمود على جدول الملابس الموجود.
      await _safeAddColumn(
          db, 'clothes', 'needs_wash', 'INTEGER NOT NULL DEFAULT 0');
    }
    if (oldV < 46 && newV >= 46) {
      // التسوق: تصنيف + سعر على العناصر + جدول الأساسيات المتكررة.
      await _safeAddColumn(
          db, 'shopping_items', 'category', "TEXT NOT NULL DEFAULT ''");
      await _safeAddColumn(
          db, 'shopping_items', 'price', 'REAL NOT NULL DEFAULT 0');
      for (final ddl in _v46Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 47 && newV >= 47) {
      for (final ddl in _v47Tables) {
        await db.execute(ddl);
      }
    }
    if (oldV < 48 && newV >= 48) {
      for (final ddl in _v48Tables) {
        await db.execute(ddl);
      }
    }
  }

  /// تتبّع المزاج + قائمة الأمنيات + قائمة المشاهدة.
  static const List<String> _v48Tables = [
    '''
      CREATE TABLE mood_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day TEXT NOT NULL,
        score INTEGER NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
    'CREATE INDEX idx_mood_day ON mood_logs(day)',
    '''
      CREATE TABLE wishlist(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL DEFAULT 0,
        priority INTEGER NOT NULL DEFAULT 1,
        note TEXT NOT NULL DEFAULT '',
        bought INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )''',
    '''
      CREATE TABLE watchlist(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        kind TEXT NOT NULL DEFAULT 'movie',
        status TEXT NOT NULL DEFAULT 'want',
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
  ];

  /// تتبّع القراءة (كتب) + مفكرة الامتنان.
  static const List<String> _v47Tables = [
    '''
      CREATE TABLE books(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL DEFAULT '',
        total_pages INTEGER NOT NULL DEFAULT 0,
        current_page INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'reading',
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
    '''
      CREATE TABLE gratitude(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day TEXT NOT NULL,
        text TEXT NOT NULL,
        created_at TEXT NOT NULL
      )''',
    'CREATE INDEX idx_gratitude_day ON gratitude(day)',
  ];

  /// الأساسيات المتكررة لقائمة التسوق (تتضاف بضغطة كل شهر).
  static const List<String> _v46Tables = [
    '''
      CREATE TABLE shopping_staples(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
  ];

  /// جرد ممتلكات البيت — للتأمين/الطوارئ.
  static const List<String> _v44Tables = [
    '''
      CREATE TABLE home_inventory(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT '',
        value REAL NOT NULL DEFAULT 0,
        location TEXT NOT NULL DEFAULT '',
        note TEXT NOT NULL DEFAULT '',
        photo TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
  ];

  /// الصيام المتقطّع (نوافذ صيام) + مخطّط الوجبات الأسبوعى.
  static const List<String> _v43Tables = [
    '''
      CREATE TABLE if_fasts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_at TEXT NOT NULL,
        end_at TEXT,
        target_hours INTEGER NOT NULL DEFAULT 16,
        created_at TEXT NOT NULL
      )''',
    '''
      CREATE TABLE meal_plan(
        weekday INTEGER NOT NULL,
        slot TEXT NOT NULL,
        text TEXT NOT NULL DEFAULT '',
        PRIMARY KEY(weekday, slot)
      )''',
  ];

  /// مفكرة الأعراض — سجل يومى لأعراض بشدّة وملاحظة.
  static const List<String> _v42Tables = [
    '''
      CREATE TABLE symptom_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day TEXT NOT NULL,
        symptom TEXT NOT NULL,
        severity INTEGER NOT NULL DEFAULT 3,
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
    'CREATE INDEX idx_symptom_day ON symptom_logs(day)',
  ];

  /// السفر (رحلات + عناصر) + التعلّم (كورسات) + الحيوانات (+أحداث) + كلمات السر.
  static const List<String> _v41Tables = [
    '''
      CREATE TABLE trips(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        destination TEXT NOT NULL DEFAULT '',
        start_day TEXT,
        end_day TEXT,
        budget REAL NOT NULL DEFAULT 0,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
    '''
      CREATE TABLE trip_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        kind TEXT NOT NULL DEFAULT 'packing',
        text TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0,
        sort INTEGER NOT NULL DEFAULT 0
      )''',
    'CREATE INDEX idx_trip_items_trip ON trip_items(trip_id)',
    '''
      CREATE TABLE courses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        provider TEXT NOT NULL DEFAULT '',
        total_units INTEGER NOT NULL DEFAULT 0,
        done_units INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
    '''
      CREATE TABLE pets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        species TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
    '''
      CREATE TABLE pet_events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pet_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        day TEXT NOT NULL,
        next_due TEXT,
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
    'CREATE INDEX idx_pet_events_pet ON pet_events(pet_id)',
    '''
      CREATE TABLE passwords(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT NOT NULL,
        username TEXT NOT NULL DEFAULT '',
        secret TEXT NOT NULL DEFAULT '',
        url TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
  ];

  /// السيارة (بيانات + أحداث صيانة/بنزين/تأمين/رخصة) + التجديدات (وثائق بتنتهى).
  static const List<String> _v40Tables = [
    '''
      CREATE TABLE cars(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        plate TEXT NOT NULL DEFAULT '',
        make TEXT NOT NULL DEFAULT '',
        model TEXT NOT NULL DEFAULT '',
        year INTEGER,
        odometer INTEGER NOT NULL DEFAULT 0,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
    '''
      CREATE TABLE car_events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        car_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        day TEXT NOT NULL,
        cost REAL NOT NULL DEFAULT 0,
        odometer INTEGER,
        liters REAL,
        next_due TEXT,
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
    'CREATE INDEX idx_car_events_car ON car_events(car_id)',
    '''
      CREATE TABLE renewals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT '',
        expiry TEXT NOT NULL,
        remind_days INTEGER NOT NULL DEFAULT 30,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
  ];

  /// المهام والمشاريع + الاشتراكات + الأهداف والمعالم.
  static const List<String> _v39Tables = [
    '''
      CREATE TABLE projects(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color INTEGER NOT NULL DEFAULT 0,
        archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )''',
    '''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        project_id INTEGER,
        title TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        due_at TEXT,
        priority INTEGER NOT NULL DEFAULT 1,
        done INTEGER NOT NULL DEFAULT 0,
        done_at TEXT,
        created_at TEXT NOT NULL
      )''',
    'CREATE INDEX idx_tasks_project ON tasks(project_id)',
    '''
      CREATE TABLE subscriptions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0,
        cycle TEXT NOT NULL DEFAULT 'monthly',
        day_of_month INTEGER NOT NULL DEFAULT 1,
        category TEXT NOT NULL DEFAULT '',
        active INTEGER NOT NULL DEFAULT 1,
        notes TEXT NOT NULL DEFAULT '',
        last_paid_month TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
    '''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        target_date TEXT,
        done INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )''',
    '''
      CREATE TABLE goal_milestones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        done INTEGER NOT NULL DEFAULT 0,
        sort INTEGER NOT NULL DEFAULT 0
      )''',
    'CREATE INDEX idx_milestones_goal ON goal_milestones(goal_id)',
  ];

  /// الوِرد اليومى — عدّاد لكل ذِكر فى يوم.
  static const List<String> _v37Tables = [
    '''
      CREATE TABLE wird_log(
        day TEXT NOT NULL,
        idx INTEGER NOT NULL,
        count INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY(day, idx)
      )''',
  ];

  /// علامات مرجعية للمصحف + الصفحات المقروءة (لمؤشّر التقدّم).
  static const List<String> _v38Tables = [
    '''
      CREATE TABLE quran_bookmarks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        page INTEGER NOT NULL,
        label TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
    '''
      CREATE TABLE quran_read_pages(
        page INTEGER PRIMARY KEY
      )''',
  ];

  /// تتبّع الأذكار (يوم/نوع) + الصيام (يوم صام فيه).
  static const List<String> _v36Tables = [
    '''
      CREATE TABLE dhikr_log(
        day TEXT NOT NULL,
        kind TEXT NOT NULL,
        PRIMARY KEY(day, kind)
      )''',
    '''
      CREATE TABLE fasting_log(
        day TEXT PRIMARY KEY
      )''',
  ];

  /// تتبّع الصلوات الخمس — صف لكل صلاة اتصلّت في يوم.
  static const List<String> _v34Tables = [
    '''
      CREATE TABLE prayer_log(
        day TEXT NOT NULL,
        prayer INTEGER NOT NULL,
        PRIMARY KEY(day, prayer)
      )''',
  ];

  /// تتبّع السنن/النوافل + ختمة القرآن.
  static const List<String> _v35Tables = [
    '''
      CREATE TABLE sunnah_log(
        day TEXT NOT NULL,
        name TEXT NOT NULL,
        PRIMARY KEY(day, name)
      )''',
    '''
      CREATE TABLE quran_khatma(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_day TEXT NOT NULL,
        total_pages INTEGER NOT NULL DEFAULT 604,
        current_page INTEGER NOT NULL DEFAULT 0,
        daily_target INTEGER NOT NULL DEFAULT 4,
        created_at TEXT NOT NULL
      )''',
    '''
      CREATE TABLE khatma_reads(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day TEXT NOT NULL,
        pages INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )''',
  ];

  /// تتبّع حبوب منع الحمل — يوم أُخذت فيه الحبة.
  static const List<String> _v32Tables = [
    '''
      CREATE TABLE pill_logs(
        day TEXT PRIMARY KEY,
        created_at TEXT NOT NULL
      )''',
  ];

  /// تسجيل يومي للدورة (مزاج/أعراض/شدة نزيف/وزن/ملاحظة).
  static const List<String> _v31Tables = [
    '''
      CREATE TABLE cycle_days(
        day TEXT PRIMARY KEY,
        mood TEXT NOT NULL DEFAULT '',
        symptoms TEXT NOT NULL DEFAULT '',
        flow TEXT NOT NULL DEFAULT '',
        weight REAL,
        note TEXT NOT NULL DEFAULT '',
        intimacy INTEGER NOT NULL DEFAULT 0
      )''',
  ];

  /// الدورة الشهرية للسيدات — تواريخ بداية كل دورة.
  static const List<String> _v30Tables = [
    '''
      CREATE TABLE cycle_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_day TEXT NOT NULL,
        period_days INTEGER NOT NULL DEFAULT 5,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
    'CREATE INDEX idx_cycle_start ON cycle_logs(start_day)',
  ];

  /// جلسات نشاط بالـGPS (مشي/جري) — مسافة ومدة وسعرات.
  static const List<String> _v29Tables = [
    '''
      CREATE TABLE activity_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'walk',
        distance_km REAL NOT NULL DEFAULT 0,
        duration_sec INTEGER NOT NULL DEFAULT 0,
        calories INTEGER NOT NULL DEFAULT 0,
        steps INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )''',
    'CREATE INDEX idx_activity_day ON activity_sessions(day)',
  ];

  /// يضيف عمود لجدول موجود فقط لو مش موجود (آمن ضد التكرار في الترقيات).
  static Future<void> _safeAddColumn(
      Database db, String table, String col, String type) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((r) => r['name'] == col);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $col $type');
    }
  }

  static const List<String> _v27Tables = [
    '''
      CREATE TABLE pharmacy_batches(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        expiry TEXT
      )''',
    'CREATE INDEX idx_pharm_batch_item ON pharmacy_batches(item_id)',
  ];

  static const List<String> _v24Tables = [
    '''
      CREATE TABLE assets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'gold',
        value REAL NOT NULL DEFAULT 0,
        note TEXT NOT NULL DEFAULT ''
      )''',
  ];

  static const List<String> _v25Tables = [
    '''
      CREATE TABLE plants(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT NOT NULL DEFAULT '',
        water_interval_days INTEGER NOT NULL DEFAULT 3,
        last_watered TEXT,
        note TEXT NOT NULL DEFAULT ''
      )''',
  ];

  static const List<String> _v22Tables = [
    '''
      CREATE TABLE wallets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'cash',
        opening_balance REAL NOT NULL DEFAULT 0
      )''',
    '''
      CREATE TABLE wallet_transfers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_wallet INTEGER NOT NULL,
        to_wallet INTEGER NOT NULL,
        amount REAL NOT NULL,
        day TEXT NOT NULL
      )''',
  ];

  static const List<String> _v21Tables = [
    '''
      CREATE TABLE diaries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day TEXT NOT NULL,
        text TEXT NOT NULL,
        created_at TEXT NOT NULL
      )''',
    '''
      CREATE TABLE recipes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        photo TEXT NOT NULL DEFAULT '',
        ingredients TEXT NOT NULL DEFAULT '',
        steps TEXT NOT NULL DEFAULT ''
      )''',
  ];

  static const List<String> _v20Tables = [
    '''
      CREATE TABLE relatives(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        interval_days INTEGER NOT NULL DEFAULT 14,
        last_contacted TEXT
      )''',
    '''
      CREATE TABLE challenges(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        days INTEGER NOT NULL DEFAULT 30
      )''',
    '''
      CREATE TABLE challenge_logs(
        challenge_id INTEGER NOT NULL,
        day TEXT NOT NULL,
        PRIMARY KEY(challenge_id, day)
      )''',
    '''
      CREATE TABLE time_capsules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT NOT NULL,
        open_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        opened INTEGER NOT NULL DEFAULT 0
      )''',
  ];

  static const List<String> _v19Tables = [
    '''
      CREATE TABLE quran_reviews(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        portion TEXT NOT NULL,
        last_reviewed TEXT,
        interval_days INTEGER NOT NULL DEFAULT 1,
        reps INTEGER NOT NULL DEFAULT 0
      )''',
    '''
      CREATE TABLE secret_notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        body TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''',
    '''
      CREATE TABLE quit_counters(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        daily_saving REAL NOT NULL DEFAULT 0
      )''',
  ];

  static const List<String> _v16Tables = [
    '''
      CREATE TABLE home_pharmacy(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        expiry TEXT,
        notes TEXT NOT NULL DEFAULT ''
      )''',
  ];

  static const List<String> _v17Tables = [
    '''
      CREATE TABLE warranties(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_name TEXT NOT NULL,
        purchase_date TEXT NOT NULL,
        warranty_months INTEGER NOT NULL,
        photo TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT ''
      )''',
  ];

  static const List<String> _v18Tables = [
    '''
      CREATE TABLE meter_readings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meter_type TEXT NOT NULL,
        reading REAL NOT NULL,
        cost REAL,
        day TEXT NOT NULL
      )''',
    'CREATE INDEX idx_meter_type_day ON meter_readings(meter_type, day)',
  ];

  static const List<String> _v15Tables = [
    '''
      CREATE TABLE social_obligations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person TEXT NOT NULL,
        type TEXT NOT NULL,
        direction TEXT NOT NULL,
        amount REAL,
        occasion TEXT NOT NULL DEFAULT '',
        day TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        reciprocated INTEGER NOT NULL DEFAULT 0
      )''',
    'CREATE INDEX idx_social_person ON social_obligations(person)',
  ];

  static const List<String> _v14Tables = [
    '''
      CREATE TABLE body_progress(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day TEXT NOT NULL,
        weight REAL,
        waist REAL,
        chest REAL,
        arms REAL,
        photo TEXT NOT NULL DEFAULT ''
      )''',
    'CREATE INDEX idx_body_progress_day ON body_progress(day)',
  ];

  static const List<String> _v13Tables = [
    '''
      CREATE TABLE savings_goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target REAL NOT NULL,
        created_at TEXT NOT NULL,
        deadline TEXT
      )''',
    '''
      CREATE TABLE savings_contributions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goal_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        day TEXT NOT NULL
      )''',
  ];

  static const List<String> _v12Tables = [
    '''
      CREATE TABLE clothes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        color TEXT NOT NULL DEFAULT '',
        season TEXT NOT NULL DEFAULT 'all',
        formality TEXT NOT NULL DEFAULT 'casual',
        photo TEXT NOT NULL DEFAULT '',
        last_worn TEXT,
        favorite INTEGER NOT NULL DEFAULT 0,
        needs_wash INTEGER NOT NULL DEFAULT 0
      )''',
  ];

  static const List<String> _v11Tables = [
    '''
      CREATE TABLE gym_sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day TEXT NOT NULL,
        program TEXT NOT NULL DEFAULT '',
        duration_min INTEGER NOT NULL DEFAULT 0,
        notes TEXT NOT NULL DEFAULT ''
      )''',
    'CREATE INDEX idx_gym_sessions_day ON gym_sessions(day)',
    '''
      CREATE TABLE gym_sets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        exercise TEXT NOT NULL,
        reps INTEGER NOT NULL DEFAULT 0,
        weight REAL NOT NULL DEFAULT 0,
        set_index INTEGER NOT NULL DEFAULT 0
      )''',
    'CREATE INDEX idx_gym_sets_session ON gym_sets(session_id)',
  ];

  static const List<String> _v10Tables = [
    '''
      CREATE TABLE medical_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        day TEXT NOT NULL,
        title TEXT NOT NULL,
        provider TEXT NOT NULL DEFAULT '',
        specialty TEXT NOT NULL DEFAULT '',
        result TEXT NOT NULL DEFAULT '',
        cost REAL NOT NULL DEFAULT 0,
        photos TEXT NOT NULL DEFAULT ''
      )''',
    'CREATE INDEX idx_medical_day ON medical_records(day)',
  ];

  static const List<String> _v8Tables = [
    '''
      CREATE TABLE fitness_logs(
        day TEXT PRIMARY KEY,
        calories INTEGER,
        distance_km REAL
      )''',
  ];

  static const List<String> _v9Tables = [
    '''
      CREATE TABLE income(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        source TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        day TEXT NOT NULL,
        wallet_id INTEGER
      )''',
    'CREATE INDEX idx_income_day ON income(day)',
    '''
      CREATE TABLE recurring_income(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        source TEXT NOT NULL,
        amount REAL NOT NULL,
        day_of_month INTEGER NOT NULL,
        last_received_month TEXT NOT NULL DEFAULT ''
      )''',
  ];

  static const List<String> _v7Tables = [
    '''
      CREATE TABLE debts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        person TEXT NOT NULL,
        amount REAL NOT NULL,
        direction TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        settled INTEGER NOT NULL DEFAULT 0
      )''',
    '''
      CREATE TABLE gameya(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        day_of_month INTEGER NOT NULL DEFAULT 1,
        total_months INTEGER NOT NULL,
        my_turn INTEGER NOT NULL,
        start_month TEXT NOT NULL
      )''',
    '''
      CREATE TABLE gameya_payments(
        gameya_id INTEGER NOT NULL,
        month_key TEXT NOT NULL,
        PRIMARY KEY(gameya_id, month_key)
      )''',
    '''
      CREATE TABLE home_maintenance(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        interval_months INTEGER NOT NULL,
        last_done TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT ''
      )''',
  ];

  static const List<String> _v6Statements = [
    '''
      CREATE TABLE inbox_notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        created_at TEXT NOT NULL
      )''',
    'ALTER TABLE medications ADD COLUMN end_date TEXT',
  ];

  static const List<String> _v5Tables = [
    '''
      CREATE TABLE recurring_bills(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        day_of_month INTEGER NOT NULL,
        category TEXT NOT NULL DEFAULT 'فواتير',
        last_paid_month TEXT NOT NULL DEFAULT ''
      )''',
  ];

  static const List<String> _v4Tables = [
    '''
      CREATE TABLE measurements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day TEXT NOT NULL,
        type TEXT NOT NULL,
        value REAL NOT NULL,
        value2 REAL,
        unit TEXT NOT NULL DEFAULT ''
      )''',
    'CREATE INDEX idx_measurements_day ON measurements(day)',
    '''
      CREATE TABLE steps_logs(
        day TEXT PRIMARY KEY,
        steps INTEGER NOT NULL
      )''',
  ];

  static const List<String> _v3Tables = [
    '''
      CREATE TABLE meals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day TEXT NOT NULL,
        slot TEXT NOT NULL,
        description TEXT NOT NULL,
        calories REAL,
        protein REAL,
        carbs REAL,
        fat REAL,
        grams REAL
      )''',
    'CREATE INDEX idx_meals_day ON meals(day)',
    '''
      CREATE TABLE shopping_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        checked INTEGER NOT NULL DEFAULT 0,
        category TEXT NOT NULL DEFAULT '',
        price REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )''',
    '''
      CREATE TABLE workout_plan(
        weekday INTEGER PRIMARY KEY,
        title TEXT NOT NULL
      )''',
    '''
      CREATE TABLE workout_logs(
        day TEXT PRIMARY KEY,
        title TEXT NOT NULL DEFAULT ''
      )''',
    '''
      CREATE TABLE occasions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        person TEXT NOT NULL DEFAULT '',
        month INTEGER NOT NULL,
        day INTEGER NOT NULL,
        remind_days INTEGER NOT NULL DEFAULT 1
      )''',
  ];

  static Future<void> createSchema(Database db, int version) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE appointments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'شخصي',
        when_at TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        remind_before_min INTEGER NOT NULL DEFAULT 60,
        done INTEGER NOT NULL DEFAULT 0,
        postpone_count INTEGER NOT NULL DEFAULT 0,
        travel_min INTEGER NOT NULL DEFAULT 0,
        repeat TEXT NOT NULL DEFAULT 'none'
      )''');
    batch.execute('''
      CREATE TABLE weekly_reviews(
        week_key TEXT PRIMARY KEY,
        went_well TEXT NOT NULL DEFAULT '',
        blocked_me TEXT NOT NULL DEFAULT '',
        next_focus TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE medications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL DEFAULT '',
        times TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        active INTEGER NOT NULL DEFAULT 1,
        end_date TEXT,
        form TEXT NOT NULL DEFAULT '',
        unit TEXT NOT NULL DEFAULT ''
      )''');
    batch.execute('''
      CREATE TABLE inbox_notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        created_at TEXT NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE med_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_id INTEGER NOT NULL,
        day TEXT NOT NULL,
        time_slot TEXT NOT NULL,
        UNIQUE(med_id, day, time_slot)
      )''');
    batch.execute('''
      CREATE TABLE water_logs(
        day TEXT PRIMARY KEY,
        glasses INTEGER NOT NULL DEFAULT 0
      )''');
    batch.execute('''
      CREATE TABLE sleep_logs(
        day TEXT PRIMARY KEY,
        hours REAL NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        day TEXT NOT NULL,
        wallet_id INTEGER
      )''');
    batch.execute('''
      CREATE TABLE documents(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        image_path TEXT NOT NULL DEFAULT '',
        expiry TEXT,
        remind_days INTEGER NOT NULL DEFAULT 30,
        notes TEXT NOT NULL DEFAULT ''
      )''');
    batch.execute('''
      CREATE TABLE habits(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE habit_logs(
        habit_id INTEGER NOT NULL,
        day TEXT NOT NULL,
        PRIMARY KEY(habit_id, day)
      )''');
    batch.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )''');
    batch.execute('CREATE INDEX idx_appointments_when ON appointments(when_at)');
    batch.execute('CREATE INDEX idx_expenses_day ON expenses(day)');
    batch.execute('CREATE INDEX idx_med_logs_day ON med_logs(day)');
    batch.execute('CREATE INDEX idx_habit_logs_day ON habit_logs(day)');
    for (final ddl in _v3Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v4Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v5Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v7Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v8Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v9Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v10Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v11Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v12Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v13Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v14Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v15Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v16Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v17Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v18Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v19Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v20Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v21Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v22Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v24Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v25Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v27Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v29Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v30Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v31Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v32Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v34Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v35Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v36Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v37Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v38Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v39Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v40Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v41Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v42Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v43Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v44Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v46Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v47Tables) {
      batch.execute(ddl);
    }
    for (final ddl in _v48Tables) {
      batch.execute(ddl);
    }
    await batch.commit(noResult: true);
  }

  /// للاختبارات فقط: يركّب قاعدة في الذاكرة بدل الملف.
  static void useForTests(Database db) => _db = db;
  static void reset() => _db = null;
}
