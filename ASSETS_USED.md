# ASSETS_USED — графика, шрифты, звуки (Lernzeit v0.1)

Источник графики — архив `Lernzeit_Assets_For_Claude_v0_1.zip` (авторские проектные макеты,
по описанию в архиве — сгенерированы ИИ; часть кнопок увеличена ×2 из атласа, это не нативный 4K).
Все рабочие копии создаёт скрипт `tools/prepare_assets.py` и кладёт в `lernzeit/assets/`.
Сторонняя графика из интернета не использовалась.

## Вшитый немецкий текст и как он убран

| Исходный файл | Вшитый текст | Что сделано | Файл в проекте |
|---|---|---|---|
| `home/Lernzeit_Main_Background_4K.png` | «Was möchtest du heute üben?» | Подзаголовок закрашен вертикальной интерполяцией фона; фраза выводится Label'ом (`home_prompt`). Логотип «Lernzeit» оставлен — это бренд, он не переводится. С версии 0.1.4 уменьшен до 1920×1080 (по решению заказчика, ради скорости на ТВ) | `backgrounds/main_background_1080p.png` |
| `home/Lernzeit_Button_{Mathematik,Deutsch,Lesen,Logik}.png` | Названия и подзаголовки предметов | Текст справа от разделителя стёрт (построчная интерполяция цвета), иллюстрация и разделитель сохранены; надписи DE/RU рисует Godot | `buttons/card_*.png` |
| `home/Lernzeit_Button_Progress.png` | «Mein Fortschritt» | Текст стёрт, иконка-график сохранена | `buttons/btn_progress_icon.png` |
| `home/Lernzeit_Button_Continue.png` | «Weiter üben» | Текст стёрт, кнопка Play сохранена | `buttons/btn_continue_icon.png` |
| `home/Lernzeit_Control_Hint.png` | «OK – Auswählen» | Текст стёрт, D-pad сохранён | `buttons/control_hint_icon.png` |
| `home/Lernzeit_Button_Progress.png`, `…_Continue.png`, `parents/Buttons/Parents_Button_{Backup,Reset_Progress,Save,Enter_Parents}.png`, `progress/Indicators/Lernzeit_Status_Not_Started.png` | Подписи кнопок | Из каждой сделан **«скин» кнопки без текста**: текст стёрт, чистый правый край отзеркален в левый → NinePatch/StyleBoxTexture. Используются для всех кнопок с локализованными подписями | `ui/pill_{light,blue,green,red,cyan,purple,gray}.png` |
| `progress/Indicators/Lernzeit_Progress_Bar_Blue.png` | — (иллюстративное заполнение) | Взята только пустая дорожка (отзеркалена); заполнение рисует Godot, при отсутствии данных — пусто | `ui/track_light.png` |

## Использованы без изменения содержимого (только уменьшение/обрезка прозрачных полей)

- `progress/Lernzeit_Progress_Background_4K_New.png` → `backgrounds/progress_background_1080p.png` (фон всех внутренних экранов; с 0.1.4 уменьшен до 1920×1080 ради скорости).
- `home/Lernzeit_Button_Settings.png` (шестерёнка, без текста).
- `progress/Buttons/Lernzeit_Progress_Button_{Back,Home}.png` (круглые, без текста) — подготовлены, в v0.1 не задействованы.
- `progress/Panels/*.png` → плашки статистики (уменьшены до 560 px по ширине для корректных NinePatch-углов); `Panel_Wide` → строки предметов в «Mein Fortschritt».
- `settings/Panels/Settings_Panel_Main.png` → стеклянные панели и диалоги.
- `settings/Switches/Settings_Switch_{On,Off}.png` → переключатели.
- Иконки: `settings/Icons/*`, `progress/Icons/*`, `parents/Icons/*` — обрезаны до самого изображения
  (в исходниках большие прозрачные поля и обрезки соседних спрайтов из атласа).
- Иконки предметов `icons/subject_*.png` — вырезаны из иллюстраций карточек, скруглённые углы.
- Иконка приложения и TV-баннер (`branding/icon_192.png`, `icon_adaptive_foreground_432.png`,
  `tv_banner_320x180.png`) — собраны из логотипа «Lernzeit» на главном фоне (авторского логотипа отдельно не было).

## Не использованы (и почему)

| Файл(ы) | Причина |
|---|---|
| `settings/Titles/Settings_Title_{DE,RU}.png` | Заголовки рисуются Label'ом по ключу локализации |
| `settings/Navigation/*`, `settings/Buttons/*`, `progress/Buttons/*` с текстом, `parents/Buttons/*` | Вшитый немецкий текст; вместо них — кнопки на скинах без текста + иконки + локализованные подписи |
| `settings/Language/*`, `settings/TextSize/*` | Вшитый текст; выбранное состояние рисует Godot (синий скин + галочка). Флаги DE/RU нарисованы кодом (`UiSkin.flag`) |
| `settings/Sliders/*` («70 %») | Иллюстрация с фиктивным значением; ползунок громкости рисуется Godot с реальным значением |
| `progress/Indicators/Lernzeit_Status_{Sicher,Gut,Ueben}.png`, `Progress_Bar_{Green,Orange,Pink}.png` | Статусы/заполнения появятся только с реальными результатами; в v0.1 нет данных |
| `settings/Panels/Settings_Row_*.png` | На светлой панели строки почти невидимы; строки сделаны StyleBoxFlat в той же стеклянной стилистике |
| `references/*` | Только визуальные ориентиры (макеты). В макетах есть примерные данные (имя «Max», «8 Jahre», «Klasse 3», «Version 2.4.0», «70 %», «85 %») — **в приложение не перенесены** |

## Шрифт

**Nunito** (SemiBold, Bold, ExtraBold) — © The Nunito Project Authors, **SIL Open Font License 1.1**
(текст лицензии: `lernzeit/assets/fonts/OFL.txt`). Получен из npm-пакета `@expo-google-fonts/nunito`
(те же файлы Google Fonts). Содержит кириллицу и умлауты ÄÖÜäöüß.

## Звуки

`lernzeit/assets/sounds/*.wav` (move, select, back, toggle, error) — синтезированы скриптом
`tools/make_sounds.py` (простые синусоиды с огибающей). Сторонних аудиофайлов нет.

## Комплекты графики упражнений (добавлены после v0.1.4)

Распакованы скриптом `tools/import_kits.py` из ZIP-архивов в корне репозитория. Скрипт:
- никогда не перезаписывает существующие файлы (совпадающие пропускает, отличающиеся помечает как конфликт);
- сверяет каждый PNG с `ASSET_MANIFEST.json` (размер, режим RGBA, прозрачность);
- генерирует реестр `lernzeit/scripts/data/KitAssets.gd`.

Результат проверки: 0 конфликтов, 0 расхождений с манифестами, у всех 71 спрайта настоящий альфа-канал.
Текстуры подключены как **отдельные ресурсы** (каждый PNG импортирован Godot отдельно, доступ через
`KitAssets.texture("<ключ>")`), но экраны упражнений из них ещё **не собраны** (в v0.1 упражнений нет).

| Комплект | В проект (`lernzeit/assets/`) | В `references/` (не загружается) |
|---|---|---|
| Deutsch Buchstaben v1 | `deutsch/pictures` (8 картинок: Apfel, Auto, Ball, Fisch, Haus, Maus, Sonne, Stern), `deutsch/ui/{controls, feedback, letter_buttons, panels, progress, word_tiles}` (32 элемента), `deutsch/backgrounds/Deutsch_Buchstaben_Background_1080p.png` | 6 макетов экранов, 6 концептов, 3 превью, README, манифест |
| Subtraction bis 10 v1 | `math/subtraction_10/icons` (5), `math/subtraction_10/tools` (9), `math/shared_ui` (17: кнопки ответов, круглые кнопки, обратная связь, предметы, точки прогресса, баннер, десяток), `math/subtraction_10/backgrounds/Lernzeit_Subtraction_10_Background_1080p.png` | 6 концептов, превью, README, манифест |
| Counting bis 10 (6 экранов) | — (нет отдельных спрайтов) | 6 готовых экранов со вшитым текстом — только ориентир |
| Progress UI Assets | — (побайтно совпадает с уже подключённой графикой прогресса, не дублируется) | — |

Фоны комплектов (3840×2160) уменьшены до 1920×1080 — по решению для v0.1.4 ради скорости на ТВ; оригиналы остаются в ZIP.

Замечания по качеству:
- `deutsch/ui/letter_buttons/Deutsch_Letter_Button_Focused.png`: вокруг кнопки запечён серый полупрозрачный
  прямоугольник (тень с жёсткими краями) — на фоне виден. Для фокуса лучше `Deutsch_Letter_Button_Default` +
  `Deutsch_Focus_Overlay.png` (чистая рамка) или собственное свечение Godot.
- `math/shared_ui/Feedback_Correct.png` / `Feedback_Wrong.png` и кнопки `Answer_*` — без вшитого текста, подписи рисует Godot.
- Серые «шапки» на панелях вычитания и точках прогресса — полупрозрачные блики; на светлом фоне комплекта выглядят корректно.
- Counting bis 10: для настоящего экрана «Zählen bis 10» понадобятся отдельные спрайты (кнопки ответов, точки, кубики);
  часть уже есть в `math/shared_ui` (по README вычитания они «скопированы из утверждённого counting-комплекта»).

### Addition bis 10 + Counting Extras + Deutsch Fix (`Lernzeit_Addition_10_Counting_Extras_Deutsch_Fix.zip`)

Проверено: 59 PNG = 59 записей манифеста, размеры и режимы совпадают, у спрайтов прозрачные углы.

| Куда | Что |
|---|---|
| `math/addition_10/ui/` (11) | пустые карточка ответа, панели примера и групп, поле результата, подпись шага, рамка десятка и её панель, числовая прямая; знаки «+», «=», «?» |
| `math/addition_10/backgrounds/` | фон, уменьшенный до 1920×1080 |
| `math/counting_10/dice/` (12) | кубики 1–6 и узоры точек 1–6 |
| `math/counting_10/number_cards/` (12) | карточки с цифрами 0–10 и пустая плитка (README советует пустую плитку + цифры из Godot) |
| `math/counting_10/` (2) | карточка «?» для пропущенного числа, пустая карточка в фокусе |
| `math/shared_ui/` (+4) | Balloon_Red, Butterfly_Blue, Car_Blue, Counter_Green |
| `deutsch/ui/letter_buttons/Deutsch_Letter_Button_Focused.png` | **заменён** исправленной версией без серого прямоугольника; старая копия — `references/replaced/` |
| `references/addition_10_kit_v1/` | 6 концептов, 2 превью, README, манифест |

Не скопированы — 10 файлов, по пикселям совпадающих с уже установленными (как и советует README комплекта):
`Shared_Answer_Blue/Green/Purple` = `Answer_Blue/Green/Purple`, `Shared_Answer_Orange` = `Answer_Yellow`,
`Shared_Answer_Focused` = `Answer_Selected_Blue`, `Shared_Question_Banner` = `Question_Banner`,
`Shared_Ten_Frame_Blank` = `Ten_Frame_Empty`, `Apple_Red` / `Counter_Blue` / `Star_Yellow` = `Object_*`.

Очищены при импорте (у края был кусок соседнего спрайта из атласа; размер холста не менялся):
`Counter_Green` (фиолетовый фрагмент), `Counting_Dice_3`, `Counting_Dice_5`, `Car_Blue`.
Замечание: у ранее установленного `math/shared_ui/Object_Counter_Blue.png` тоже есть небольшой обрезок слева
(244 px); файл не трогался — при необходимости очистить тем же способом.

### Используется в упражнении «Subtraktion bis 10» (v0.2.0)
`math/subtraction_10/backgrounds/…_1080p.png`, `math/shared_ui/Answer_{Yellow,Blue,Green,Purple}`,
`Question_Banner`, `Feedback_Correct/Wrong`, `Progress_Dot_Filled/Empty`, `Object_Apple_Red`, `Object_Star_Yellow`,
`Object_Counter_Blue`, `Balloon_Red`, `Butterfly_Blue`, `Car_Blue`, `math/subtraction_10/icons/Subtraction_{Minus_Red,
Equals_Blue,Cross_Red}`. Числовая прямая, десятка, поле ответа и все числа/тексты рисуются Godot (в текстурах
числовой прямой/десятки положения делений неизвестны точно — рисовать их кодом надёжнее).

### Используется в «Addition bis 10» и «Zählen bis 10» (v0.3.0)
`math/addition_10/backgrounds/…_1080p.png`, `math/addition_10/ui/Addition_Plus_Blue.png`, `math/counting_10/dice/Counting_Dice_1…6`,
плюс общие `math/shared_ui/*` (кнопки ответов, баннер, обратная связь, точки, предметы) и знак «=» из комплекта вычитания.
Для «Zählen bis 10» используется фон вычитания (у комплекта счёта своего фона нет). Плитки ряда чисел, десятка и
карточки групп рисуются Godot (цифры — живым текстом, как рекомендует README комплекта).

### Используется в немецком (v0.4.0)
`deutsch/backgrounds/…_1080p.png`, `deutsch/pictures/*` (8 картинок), `deutsch/ui/panels/{Header,Question,Content,Word}_Panel`,
`Picture_Frame`, `deutsch/ui/letter_buttons/{Default,Correct,Incorrect}` + `Deutsch_Focus_Overlay`, `deutsch/ui/word_tiles/*`,
`deutsch/ui/progress/{Dot_Done,Dot_Current,Dot_Pending,Track}`, `deutsch/ui/controls/Deutsch_Progress_Counter_Blank`,
`deutsch/ui/feedback/*`. Все буквы, слова и подсказки — живой текст Godot.

### Deutsch Alphabet 38 (`Lernzeit_Deutsch_Alphabet_38_PNG.zip`, v0.4.1)
38 картинок-слов → `lernzeit/assets/deutsch/words/` (по 2 на букву: M A O I L S E U R T N H F D W B P K + G Gans/Gabel).
Без изменений. README, манифест и превью → `references/deutsch_alphabet_38/`. Список слов для упражнений —
`lernzeit/data/deutsch_words.json` (можно дополнять: слово, первая буква, путь к картинке).

### Пакеты от 12.11 (v0.7.0): маскот, медали, наклейки, «Чтение», «Сравнение»
Распакованы `tools/import_kits.py` (проверка по манифестам; без перезаписи; 0 конфликтов).

| Архив | В проект | Где используется |
|---|---|---|
| `Lernzeit_Mascot_Owl_6_Poses_800px.zip` | `assets/mascot/owl/` (6 поз) | заставка (wave), подсказка после ошибки (thinking), итог занятия (cheer / happy), «Пора отдохнуть» (sleep), альбом наклеек (happy) |
| `Lernzeit_Mascot_Badges_12_400px.zip` | `assets/mascot/badges/` (12) | иконки 12 достижений (id совпадают) |
| `Lernzeit_Stickers_20_300px.zip` | `assets/mascot/stickers/` (20) | альбом наклеек: 1 наклейка за каждое законченное занятие (10 заданий) |
| `Lernzeit_Lesen_Words_1A/1B_10_PNG.zip` | `assets/lesen/words/` (20) | «Lesen · Silben» и «Lesen · Wörter»; слоги — `data/lesen_words.json` |
| `Lernzeit_Vergleichen_FHD.zip` | `assets/math/vergleichen_10/` (фон 1920×1080 + 23 элемента UI) | «Vergleichen bis 10»: фон, знак «?» между группами. Макеты (`Reference_Only`) → `references/vergleichen_10/` |

Кнопки ответов в «Сравнении» — общие кнопки математики (единый стиль). Картинка «Melone» — долька арбуза (Wassermelone).

### Озвучка от 13.11 (v0.8.0): `Lernzeit_DE_Nele_198_WAV.zip`
198 немецких фраз (HeyGen Voice «Nele — Friendly & Natural», подготовлены пользователем по
`docs/VOICE_PHRASES.md`). Сконвертированы в OGG Vorbis (моно, 44,1 кГц, качество 4) скриптом
`tools/convert_voice.sh` → `lernzeit/assets/voice/de/` (2,6 МБ вместо 17 МБ WAV); тексты не менялись.
В архиве нет звуков букв (`sound_*`) и подсказок `tip_de_find`, `tip_de_build`, `tip_equal`,
`tip_le_word_pic`, `tip_le_pic_word`, `tip_*` с числами — эти места остаются без голоса.

| Что звучит | Когда |
|---|---|
| вопрос задания (`*_prompt_*`) | при показе задания; в «Rechne.» — ещё и пример («sieben minus drei») |
| буква / слово к вопросу | «Finde den Buchstaben … M», «Baue das Wort … Maus»; в «Чтении» слово **не** произносится |
| `ex_correct*`, `ex_wrong*` | правильный / неправильный ответ (случайный вариант) |
| слово после ответа | «Das Wort heißt … Apfel» (Anlaute), «Super! … Banane» (слова, чтение) |
| `tip_*` | подсказка после первой ошибки — только если язык подсказок у родителей немецкий |
| `ex_streak`, `ex_done`, `ex_done_perfect` | серия правильных, конец занятия |
| `home_prompt`, `pause` | после запуска и «Пора отдохнуть» — только при немецком интерфейсе |

Выключается в Настройках → Обучение → «Aufgaben vorlesen»; громкость — общий ползунок.
Произношение (особенно буквы и слоги) автоматически не проверялось — нужно прослушать.
