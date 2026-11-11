# TelegramBGDownloader — نسخة RootHide / Relaxin

ثيك (tweak) يُبقي تنزيلات تلجرام مستمرة في الخلفية على iOS، مبني الآن لبيئة **RootHide** المستخدمة في جيلبريك **Relaxin** (وأي جيلبريك يعتمد على RootHide Bootstrap).

## ما الذي تغيّر مقارنة بنسخة Dopamine rootless؟

| العنصر | قبل (Dopamine rootless) | بعد (RootHide / Relaxin) |
| --- | --- | --- |
| نظام الحزمة | `THEOS_PACKAGE_SCHEME = rootless` | `THEOS_PACKAGE_SCHEME = roothide` |
| Theos المستخدم | `theos/theos` | `roothide/theos` (إلزامي) |
| بنية الحزمة | `iphoneos-arm64` | `iphoneos-arm64e` (يفرضها Theos تلقائياً) |
| مسار التثبيت | `/var/jb/Library/MobileSubstrate/DynamicLibraries` | داخل `jbroot` العشوائي + رابط `.jbroot` تلقائي |
| ربط المكتبات | `/var/jb/...` | `@loader_path/.jbroot/...` |
| الاعتماديات | `mobilesubstrate` | `mobilesubstrate \| ellekit` |

## لماذا لم يُعدّل الكود (Tweak.x)؟

كود الثيك لا يستخدم أي واجهة ملفات (`fopen`، `NSFileManager`، `pathForResource` …) ولا يشير إلى أي مسار مطلق داخل الجيلبريك. لذلك لا حاجة لاستخدام `jbroot()` من `roothide.h`. الثيك يعتمد فقط على:

- `UIApplicationDidEnterBackgroundNotification` و`beginBackgroundTaskWithName:`
- `AVAudioSession` + `AVAudioPlayer` لتشغيل صوت صامت (WAV مولّد داخلياً) يُبقي العملية حيّة.

كل هذه الواجهات متاحة كما هي داخل تطبيق Telegram على بيئة RootHide، لأن الحقن يتم عبر ElleKit بنفس آلية `%ctor`.

## البناء محلياً

```bash
# 1) ثبّت Theos الخاص بـ RootHide (وليس Theos الرسمي)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/roothide/theos/master/bin/install-theos)"

# 2) ابنِ الحزمة
export THEOS=~/theos
make clean
make package FINALPACKAGE=1
```

الناتج: `packages/com.yourname.telegrambgdownloader_1.1.0_iphoneos-arm64e.deb`

## البناء عبر GitHub Actions

سير العمل `.github/workflows/build.yml` يقوم تلقائياً بـ:

1. تثبيت `ldid` و`xz`.
2. استنساخ `roothide/theos` (لأن Theos الرسمي لا يحتوي وحدة `roothide`).
3. تنزيل SDKs من `theos/sdks`.
4. `make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=roothide`.
5. رفع ملف `.deb` كـ artifact باسم `TelegramBGDownloader-RootHide`.

## الرجوع إلى نسخة rootless (Dopamine)

```bash
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```

مع تغيير `Architecture` في `control` إلى `iphoneos-arm64` (أو حذف السطر ليضيفه Theos تلقائياً).

## التثبيت على Relaxin

1. ثبّت ملف `.deb` عبر Sileo / Zebra / Filza.
2. أعد تشغيل تطبيق Telegram (أو اعمل `killall Telegram`).
3. ابدأ أي تنزيل ثم اخرج من التطبيق — سيبقى التنزيل مستمراً.

> ملاحظة: RootHide يدعم أجهزة arm64e (A12 وما بعدها) فقط، وهذا قيد بيئة RootHide نفسها وليس قيد الثيك.
