# 📚 Пошаговое руководство для новичков

Этот документ объясняет, как создан каждый компонент игры и как его модифицировать.

## Часть 1: Основная структура проекта

### Шаг 1: Структура папок

Создайте в корне проекта Godot следующие папки:

```
res://
├── scenes/        (Визуальные сцены)
├── scripts/       (Код на GDScript)
├── assets/        (Изображения, звуки)
└── data/          (Конфигурационные данные)
```

**Как создать папку в Godot:**
1. В левой панели файлов нажмите правой кнопкой
2. Выберите "New Folder"
3. Введите имя папки

### Шаг 2: Главная сцена игры

Файл: `scenes/game.tscn`

**Структура сцены:**
```
Node2D (Game Manager)
├── CanvasLayer (UI Layer)
│   ├── HealthBar
│   ├── ScoreLabel
│   └── WaveLabel
├── Player (Player Scene)
├── Enemies (Node2D - контейнер врагов)
└── Effects (Node2D - контейнер эффектов)
```

**Как создать:**
1. Создайте новую сцену (Scene → New Scene)
2. Выберите Node2D как корневой узел
3. Переименуйте его в "Game"
4. Сохраните как `scenes/game.tscn`

### Шаг 3: Персонаж (Player)

Файл: `scripts/player.gd`

**Основные параметры персонажа:**
```gdscript
# Статистика
var health: int = 100
var max_health: int = 100
var speed: float = 200.0
var damage: float = 10.0

# Позиция и направление
var position: Vector2
var direction: Vector2 = Vector2.ZERO
```

**Функции управления:**
- `_process(delta)` - обновление каждый кадр
- `move(direction)` - движение в направлении
- `take_damage(amount)` - получение урона
- `heal(amount)` - исцеление

### Шаг 4: Враги (Enemies)

Файл: `scripts/enemy.gd`

**Типы врагов:**
1. **Цзюаньцюй** - HP: 10, Speed: 150, Damage: 5
2. **Ямалуки** - HP: 25, Speed: 100, Damage: 10
3. **Кицунэ** - HP: 15, Speed: 180, Damage: 8
4. **Юйлин** - HP: 20, Speed: 120, Damage: 7

**Поведение врагов:**
- Преследуют игрока
- Атакуют при приближении
- Дают опыт и предметы при смерти

---

## Часть 2: Системы игры

### Система 1: Способности (Abilities)

Файл: `scripts/ability_system.gd`

**Типы способностей:**

#### Активные (требуют нажатия):
1. **Огненный взрыв** (Маг)
   - Урон: 50
   - Радиус: 200px
   - Кулдаун: 2 сек

2. **Боевой клич** (Монах)
   - Увеличивает скорость на 50% на 3 сек
   - Отталкивает врагов

3. **Ловушка** (Дух Лисы)
   - Замораживает врагов на 2 сек
   - 3 использования до перезарядки

4. **Землетрясение** (Воин-Демон)
   - Урон всем врагам на экране
   - Урон: 30

**Как добавить новую способность:**

```gdscript
# В scripts/ability_system.gd
func add_ability(ability_name: String):
    match ability_name:
        "new_ability":
            create_new_ability()

func create_new_ability():
    # Ваш код здесь
    pass
```

### Система 2: Пассивные способности (Passives)

Файл: `scripts/passive_system.gd`

**Примеры пассивных бонусов:**

1. **Кровавая жажда** (+5% HP восстановления при убийстве)
2. **Острая атака** (+10% урона)
3. **Боевая шкура** (+5 брони)
4. **Скорость света** (+20% скорости)
5. **Магическое усиление** (+25% урона магией)

**Синергии (комбинации):**
- Магическое усиление + Огненный взрыв = +50% урона вместо +25%
- Кровавая жажда + Боевая шкура = +10% защиты
- Скорость света + Боевой клич = +80% скорости вместо +50%

### Система 3: Система опыта и уровней

**Уровни и урон врагов:**
- Волна 1 (0-60 сек): врагов в 1.5x меньше
- Волна 2 (60-120 сек): враги сильнее на 20%
- Волна 3 (120-180 сек): враги быстрее на 30%
- Волна Босса (каждые 5 минут): спавнится босс

**Опыт за врагов:**
- Цзюаньцюй: 10 XP
- Ямалуки: 25 XP
- Кицунэ: 20 XP
- Юйлин: 15 XP
- Боссы: 500-1000 XP

---

## Часть 3: Мобильный интерфейс

### Сенсорное управление

Файл: `scripts/mobile_input.gd`

```gdscript
# Обнаружение касаний
func _input(event: InputEvent):
    if event is InputEventScreenTouch:
        if event.pressed:
            on_touch_down(event.position)
        else:
            on_touch_up(event.position)
```

### Кнопки интерфейса

**Главное меню:**
- Кнопка "Начать игру"
- Кнопка "Выбрать персонажа"
- Кнопка "Настройки"

**Во время игры:**
- D-Pad слева (движение)
- 4 кнопки способностей справа
- Кнопка паузы вверху

**Экран выбора способностей:**
- 3 варианта способностей
- Нажмите для выбора

---

## Часть 4: Добавление нового контента

### Добавление персонажа

1. Создайте новый персонаж в `scripts/characters/новый_персонаж.gd`:

```gdscript
extends CharacterBody2D

class_name NewCharacter

# Статистика персонажа
var health: int = 120
var max_health: int = 120
var speed: float = 220
var starting_abilities: Array[String] = ["ability1", "ability2"]
var starting_passives: Array[String] = ["passive1"]

func _ready():
    pass
```

2. Зарегистрируйте в `scripts/character_manager.gd`:

```gdscript
var CHARACTERS = {
    "новый_персонаж": preload("res://scripts/characters/новый_персонаж.gd")
}
```

### Добавление врага

1. Создайте враг в `scripts/enemies/новый_враг.gd`:

```gdscript
extends CharacterBody2D

class_name NewEnemy

var health: int = 30
var speed: float = 150
var damage: float = 12
var enemy_type: String = "новый_враг"

func _ready():
    pass
```

2. Добавьте в `scripts/enemy_spawner.gd`:

```gdscript
func spawn_enemy(enemy_type: String):
    match enemy_type:
        "новый_враг":
            var enemy = preload("res://scripts/enemies/новый_враг.gd").new()
            add_child(enemy)
```

### Добавление способности

В `scripts/ability_system.gd`:

```gdscript
func create_new_ability():
    var ability = {
        "name": "Новая способность",
        "damage": 40,
        "cooldown": 3.0,
        "radius": 250,
        "description": "Описание способности"
    }
    active_abilities.append(ability)
```

---

## Часть 5: Исправление ошибок

### Частые проблемы

**Ошибка: "Cannot call function on null instance"**
- Значит, объект не был создан
- Решение: проверьте, что объект создан в _ready()

**Ошибка: "Undefined identifier 'SomeClass'"**
- Класс не импортирован
- Решение: добавьте `extends SomeClass` в начало файла

**Враги не спавнятся**
- Проверьте, что EnemySpawner добавлен в сцену
- Проверьте консоль на ошибки (F6 - Debug Console)

---

## Часть 6: Запуск и тестирование

### Запуск игры:
1. Откройте `scenes/game.tscn`
2. Нажмите F5 или кнопку Play

### Тестирование на мобильном:
1. Скачайте Godot на телефон
2. Запустите проект через мобильный Godot
3. Тестируйте сенсорное управление

---

**Поздравляем!** Вы теперь понимаете структуру игры. 🎮✨

Далее в файлах кода найдёте подробные комментарии для каждой функции.
