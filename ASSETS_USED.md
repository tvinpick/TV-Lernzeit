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
