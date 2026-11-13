# Lernzeit v0.1 — приложение-оболочка для Android TV

Lernzeit — отдельное приложение для добровольных коротких тренировок по программе
1-го класса (ориентир — Бавария) для Sony BRAVIA 3 / BRAVIA BF1 (Android TV 12).
Версия 0.4 — оболочка, **математика до 10 и до 20** («Zählen», «Addition», «Subtraktion»: Математика → тема → «до 10» / «до 20»), достижения, «Выученные буквы» для родителей и **немецкий без звука** (Буквы, Первый звук, Слова, Большие и маленькие: Немецкий → тема). Версия 0.1 была **только оболочкой**: главный экран, навигация пультом, прогресс (честно пустой),
настройки, родительский раздел с PIN. **Учебных заданий пока нет**: каждая тема и уровень
ведут на экран «Noch keine Übungen verfügbar / Упражнения пока недоступны».

- Движок: Godot 4.7.2 (stable), GDScript, рендерер Compatibility, без сторонних плагинов.
- Пакет: `app.lernzeit.tv`, versionName `0.8.0`, versionCode `14`.
- Без интернета, аккаунтов, рекламы и облака. Сетевых разрешений в APK нет.

## Что в репозитории

| Путь | Что это |
|---|---|
| `release/Lernzeit_v0_1.apk` | Собранный и подписанный APK (armeabi-v7a + arm64-v8a, 73 МБ; версия 0.7.1, SHA-256 `bc7a6931…a86353`) |
| `lernzeit/` | Исходный проект Godot (открывать файл `lernzeit/project.godot`) |
| `tools/prepare_assets.py` | Подготовка графики из архива ассетов (удаление вшитого немецкого текста и т. п.) |
| `tools/make_sounds.py` | Генерация коротких UI-звуков |
| `tools/patch_android_tv.py` | Дополнения манифеста для Android TV (баннер, leanback, без тачскрина) |
| `tools/build_apk.sh` | Полная сборка APK одной командой (Linux/macOS) |
| `ASSETS_USED.md` | Какая графика использована, что изменено, лицензии |
| `TEST_REPORT.md` | Что проверено на самом деле и что — нет |
| `docs/screenshots/` | Скриншоты из автотеста (запуск на ПК, не на телевизоре) |

PNG-файлы в корне репозитория — это ранее загруженные исходники; приложение использует
подготовленные копии из `lernzeit/assets/`.

## Установка APK на телевизор (с Android-смартфона)

> Важно: на самом телевизоре Sony этот APK ещё **не проверялся** (см. `TEST_REPORT.md`).

### Подготовка телевизора (один раз)
1. Настройки → Устройство/Система → **Об устройстве** → 7 раз нажать на **«Сборка»** — включится режим разработчика.
2. Настройки → **Приложения → Безопасность и ограничения → Неизвестные источники** →
   разрешить установку для приложения, которым будете открывать APK (например, файловый менеджер
   или «Send files to TV»). Названия пунктов на разных прошивках Sony немного отличаются.

### Вариант A — по Wi-Fi через «Send files to TV» (проще всего)
1. Установите бесплатное приложение **Send files to TV** из Google Play на телефон **и** на телевизор.
2. Скачайте `release/Lernzeit_v0_1.apk` на телефон (GitHub → файл → «Download raw file»).
3. В приложении на ТВ выберите «Получить», на телефоне — «Отправить» → выберите APK.
4. На ТВ откройте полученный файл → **Установить**.

### Вариант B — через USB-флешку
Скопируйте APK на флешку (через OTG-переходник телефона или компьютер), вставьте её в ТВ,
откройте файловым менеджером (например, «File Commander» или «Files by Google» на ТВ) → Установить.

### Вариант C — ADB по сети с телефона
1. На ТВ: Настройки → Система → Для разработчиков → включить **Отладка по USB / по сети**;
   узнайте IP телевизора (Настройки → Сеть).
2. На телефоне — приложение-клиент ADB (например, «Bugjaeger» или «Remote ADB Shell»):
   `adb connect <IP-телевизора>:5555`, подтвердите запрос на ТВ, затем
   `adb install -r Lernzeit_v0_1.apk`.

После установки Lernzeit появляется в списке приложений ТВ (баннер «Lernzeit») и запускается
обычным пультом. Кнопка **Home** пульта остаётся системной; **Back** на главном экране
спрашивает подтверждение выхода.

### Обновления без потери данных
Настройки, PIN и прогресс хранятся во внутренней памяти приложения (`user://` =
`/data/data/app.lernzeit.tv/files/`). При установке новой версии **поверх** старой
(`adb install -r` или «Установить» поверх) данные сохраняются, **если APK подписан тем же ключом**.
Ключ подписи v0.1 (`lernzeit-release.keystore`) передан отдельно и **не хранится в git**.
Сохраните его: без него следующую версию придётся ставить с удалением старой (данные пропадут).

### Забыли PIN родительского раздела
Настройки ТВ → Приложения → Lernzeit → **Очистить данные**. Это сбросит всё: PIN, настройки и прогресс.

## Открыть проект Godot на Android-смартфоне
1. Установите **Godot Engine 4.7.x** для Android (Google Play «Godot Engine» или APK-редактор с godotengine.org).
2. Скопируйте папку `lernzeit/` из репозитория в память телефона (например, скачав ZIP репозитория
   на GitHub → «Code → Download ZIP» и распаковав).
3. В Godot: **Импорт** → выберите `lernzeit/project.godot` → Открыть. Проект можно просматривать,
   редактировать и запускать (кнопка ▶).

Сборка APK **с телефона** не проверялась. Android-редактор Godot не выполняет Gradle-сборку, а
TV-баннер и флаги leanback/touchscreen добавляются именно в Gradle-шаблон. Надёжный способ
собрать APK — на компьютере (ниже).

## Сборка APK на компьютере

Нужно: Godot **4.7.2** (редактор + Export Templates 4.7.2), Android SDK (platform 36,
build-tools 36.1.0, platform-tools), JDK 17 или новее, интернет при первой Gradle-сборке.

**Linux / macOS (одна команда):**
```bash
export GODOT=/путь/к/Godot_v4.7.2-stable          # исполняемый файл редактора
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH=/путь/lernzeit-release.keystore
export GODOT_ANDROID_KEYSTORE_RELEASE_USER=lernzeit
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD='пароль из lernzeit-release-password.txt'
tools/build_apk.sh            # → build/Lernzeit_v0_1.apk
```
Без переменных keystore скрипт соберёт debug-APK (он ставится, но обновлять его поверх
release-версии нельзя). В «Редактор → Настройки редактора → Export → Android» должны быть
указаны пути к Android SDK и JDK.

**Windows (через редактор):**
1. Откройте `lernzeit/project.godot` в Godot 4.7.2.
2. Меню **Проект → Установить шаблон сборки Android**.
3. Выполните `python tools/patch_android_tv.py lernzeit` (из корня репозитория, Python 3).
4. **Проект → Экспорт → Android TV** → укажите release-keystore → «Экспорт проекта» → APK.

Если графику нужно пересоздать из архива ассетов:
`python3 tools/prepare_assets.py <распакованный_Lernzeit_Assets_For_Claude_v0_1> lernzeit`.

## Автотесты
```bash
cd lernzeit
godot --headless --path . res://tests/UnitTests.tscn -- --lz-data-dir=/tmp/lz_unit
xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1920x1080 \
  res://tests/UiTest.tscn -- --lz-data-dir=/tmp/lz_ui --shots=/tmp/shots
xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1920x1080 \
  res://tests/UiTest.tscn -- --lz-data-dir=/tmp/lz_ui --phase=restart
```
`UiTest` нажимает клавиши пульта (стрелки, OK, Back, цифры) и проверяет переходы, фокус,
сохранение и PIN. На Windows/macOS можно запускать без `xvfb-run`.

## Устройство проекта
```
lernzeit/
  project.godot, export_presets.cfg
  scenes/Main.tscn (+ Main.gd: стек экранов, Back/Home, диалоги, восстановление фокуса)
  scenes/home/Home.tscn             главный экран 2×2
  scenes/subjects/SubjectMenu.tscn  темы и уровни; Unavailable.tscn — заглушка
  scenes/progress/ProgressOverview.tscn, ProgressDetail.tscn
  scenes/settings/Settings.tscn
  scenes/parents/PinGate.tscn, ParentDashboard.tscn
  scripts/autoload/  AppState, Localization, SettingsRepository, ProgressRepository, Sfx
  scripts/ui/        FocusManager, UiTheme, UiSkin, FitLabel, BaseScreen
  scripts/components/ FocusableCard, PillButton (PrimaryButton), SettingsRow, ConfirmDialog,
                      EmptyState, StatCard, ToggleSwitch, OptionGroup, VolumeSlider, ...
  scripts/data/      ProgressRecord, Curriculum, PinHasher, SafeFile
  localization/de.json, ru.json
  assets/backgrounds, buttons, icons, ui, fonts, sounds, branding
  tests/             UnitTests, UiTest
```
- Все тексты берутся по ключу из `localization/*.json`; в сценах нет немецких/русских строк.
- Настройки: `user://settings.cfg`, профиль/родительские настройки/PIN: `user://parents.cfg`,
  прогресс: `user://progress.json`. Запись безопасная (временный файл + резервная копия `.bak`);
  при повреждённом файле создаются корректные значения по умолчанию.
- PIN хранится как SHA-256 (20 000 итераций) с индивидуальной солью; после 5 ошибок — блокировка
  на 60 с (далее на 5 мин).
- `ProgressRepository` уже содержит тип записи (`subject_id, topic_id, timestamp, correct_count,
  total_count, duration_seconds, exercise_version`) и расчёт точности; UI не читает JSON напрямую.
