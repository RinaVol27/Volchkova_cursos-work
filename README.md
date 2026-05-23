# Volchkova_cursos-work
Курсовая работа для Красниковой Ирины Николаевны

# BookShelf — Python port

## Установка

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -e ".[dev]"
copy .env.example .env
```

## Запуск

```powershell
uvicorn src.main:app --port 3000 --reload
```

При первом старте создаётся файл `bookshelf.db` со схемой и seed-данными
из `src/init.sql`. Никаких внешних служб поднимать не нужно.

Точки входа в браузере:
- <http://localhost:3000/frontend/avtorization.html> — авторизация
- <http://localhost:3000/health> — smoke

## Тесты

```powershell
pytest -v
```

29 тестов, по нескольку на каждый эндпоинт. Каждый тест работает в изолированной БД
во временном каталоге (см. [tests/conftest.py](tests/conftest.py)) — на `bookshelf.db`
они не влияют.

Полезные флаги:
```powershell
pytest -v -k login           # только тесты с "login" в имени
pytest tests/test_books.py   # один файл
pytest -x                    # стоп на первой ошибке
pytest -s                    # не глушить print() из кода
```

## Отладка и повседневная работа

### Открыть терминал в проекте

Все команды ниже подразумевают, что ты в каталоге `C:\<path>\BookShelf_app`
и venv активирован:
```powershell
.venv\Scripts\Activate.ps1
```
В приглашении должно появиться `(.venv)`. Если PowerShell ругается на политику
выполнения — один раз:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### Запуск сервера

```powershell
uvicorn src.main:app --port 3000 --reload
```

- `--reload` — авто-перезапуск при правке Python-файлов в `src/` или `tests/`.
- Логи запросов идут прямо в консоль: `POST /login HTTP/1.1 200 OK` и т.п.
- Остановить: `Ctrl+C`.

Авто-документация FastAPI (OpenAPI/Swagger) — для ручного дёрганья эндпоинтов
из браузера без curl:
- <http://localhost:3000/docs> — интерактивная Swagger-UI (кнопка «Try it out»)
- <http://localhost:3000/redoc> — альтернативный вид

### Изменения в фронте (HTML / CSS / JS в `public/`)

`--reload` следит **только** за Python-файлами. Если ты правишь `public/backend/*.js`
или `public/frontend/*.html`, сервер сам уже отдаст новый файл, но **браузер кеширует
JS жёстко**. После правки фронта обязательно:
- Ctrl+Shift+R (hard reload), либо
- DevTools (F12) → правый клик на кнопку reload → «Empty Cache and Hard Reload».

### Дёрнуть API руками

`curl.exe` в PowerShell съедает кавычки. Используй нативный `Invoke-RestMethod`:
```powershell
# регистрация
Invoke-RestMethod -Method Post -Uri http://localhost:3000/register `
  -ContentType 'application/json' `
  -Body '{"name":"A","surname":"B","lastname":"C","email":"a@b.c","password":"1234"}'

# логин
Invoke-RestMethod -Method Post -Uri http://localhost:3000/login `
  -ContentType 'application/json' `
  -Body '{"email":"a@b.c","password":"1234"}'

# список книг
Invoke-RestMethod -Uri http://localhost:3000/

# вернуть книгу
Invoke-RestMethod -Method Put -Uri http://localhost:3000/issue/5
```

### Посмотреть содержимое БД

`bookshelf.db` — обычный SQLite-файл. Самый простой способ — `sqlite3` из Python:
```powershell
python -c "import sqlite3, json; c=sqlite3.connect('bookshelf.db'); c.row_factory=sqlite3.Row; rows=[dict(r) for r in c.execute('SELECT * FROM librarians')]; print(json.dumps(rows, ensure_ascii=False, indent=2))"
```
Или одной строкой счётчик:
```powershell
python -c "import sqlite3; c=sqlite3.connect('bookshelf.db'); print('books:', c.execute('SELECT COUNT(*) FROM books').fetchone()[0])"
```

Если нужна GUI — поставь [DB Browser for SQLite](https://sqlitebrowser.org/) и
открой `bookshelf.db` оттуда.

### Сбросить БД к чистому seed

```powershell
Remove-Item bookshelf.db
```
При следующем `uvicorn` файл пересоздастся из `src/init.sql`. Все добавленные
руками библиотекари/читатели/выдачи пропадут.

### Поправить seed-данные

Открой [src/init.sql](src/init.sql), измени `INSERT`-строки, удали `bookshelf.db`,
перезапусти сервер.

### Отладка Python-кода

Поставить точку останова — просто добавь в нужное место строку:
```python
breakpoint()
```
Когда запрос дойдёт до этой строки, uvicorn остановится и в консоли откроется
pdb-промпт. Полезные команды: `n` (next), `s` (step in), `c` (continue), `p var`
(print), `l` (list source), `q` (quit).

В IDE (VS Code / PyCharm) можно настроить запуск `uvicorn src.main:app --port 3000`
в режиме Debug и расставлять брейкпоинты мышкой — без `breakpoint()`.

### Прочитать JWT

```powershell
python -c "import jwt; print(jwt.decode('PASTE_TOKEN_HERE', '123321', algorithms=['HS256']))"
```
Или вставить токен в <https://jwt.io> (вкладка Debugger) — секрет тот же.

### Сгенерировать bcrypt-хеш руками

Например, чтобы заранее заинжектить librarian с известным паролем в `init.sql`:
```powershell
python -c "import bcrypt; print(bcrypt.hashpw(b'admin123', bcrypt.gensalt(rounds=10)).decode())"
```
Скопируй вывод (начинается с `$2b$10$...`) и вставь в `INSERT INTO librarians`.

### Типовые ошибки

| Симптом | Причина | Что делать |
|---|---|---|
| `ModuleNotFoundError: No module named 'fastapi'` | venv не активирован | `.venv\Scripts\Activate.ps1` |
| `address already in use :3000` | старый uvicorn ещё жив | `Get-Process python \| Stop-Process` или другой порт |
| Фронт ведёт себя как раньше после правки JS | браузерный кеш | Ctrl+Shift+R |
| `422 Unprocessable Content` на `/register` или `/give` | сломанный JSON в теле (часто из-за `curl.exe` в PS) | использовать `Invoke-RestMethod` |
| `InsecureKeyLengthWarning` в логах | секрет JWT короткий (наследие JS) | в `.env` поставить длинный `JWT_SECRET` |
| Тесты «не видят» правку | где-то висит старый процесс uvicorn с открытой БД | прибей его |

### Посмотреть «сырой» SQL запроса в роутере

Перед `await conn().execute(...)` добавь `print(...)` с самой строкой запроса
и параметрами:
```python
sql = "SELECT * FROM books WHERE book_id = ?"
print("SQL:", sql, "params:", (book_id,))
cur = await conn().execute(sql, (book_id,))
```
В консоли uvicorn увидишь точный текст, который пошёл в SQLite.

## Перенесённые эндпоинты

| Метод | Путь | Назначение |
|---|---|---|
| POST | `/login` | вход библиотекаря |
| POST | `/register` | регистрация библиотекаря |
| DELETE | `/deletel/{id}` / `/deletelibr/{id}` | удалить библиотекаря |
| GET | `/` | список книг с автором (JOIN) |
| GET | `/oneBook/{id}` | одна книга |
| DELETE | `/delete/{id}` | удалить книгу |
| POST | `/give/{id}` | выдать книгу |
| GET | `/authors` | список авторов |
| DELETE | `/authors/{id}` | удалить автора |
| GET | `/readers` | список читателей |
| POST | `/add_reader` | добавить читателя |
| DELETE | `/delete/user/{id}` | удалить читателя |
| PUT | `/readers/add/{id}` | +1 потерянной книги |
| PUT | `/readers/subtract/{id}` | -1 потерянной книги |
| GET | `/issue` | список невозвращённых выдач |
| PUT | `/issue/{id}` | вернуть книгу |
| GET | `/librarians` | список библиотекарей |

## Известные расхождения с JS-версией

1. **БД сменилась с PostgreSQL на SQLite.** Схема адаптирована (`SERIAL`→`AUTOINCREMENT`,
   `BOOLEAN`→`INTEGER`, `DATE`→`TEXT`). Логика и форма JSON-ответов сохранены, но
   `is_returned` теперь приходит как `0/1`, а не `false/true` (фронт это поле не читает —
   видимо безразлично).

2. **SQL-инъекции исправлены.** В JS три эндпоинта подставляли `req.params.id` в SQL
   через template literal (`/readers/add/:id`, `/readers/subtract/:id`, `/issue/:id`).
   В Python везде параметризованные запросы.

3. **JWT теперь содержит корректные `userId` и `role`.** В JS `generateToken`
   вызывался с `user.user_id` и `user.role`, но в таблице `librarians` колонки
   называются `librarian_id` и `is_admin` — в токен попадали `undefined`. В Python
   токен подписывается реальными значениями.

4. **`DELETE /deletelibr/{id}` теперь существует.** В JS серверный маршрут — `/deletel/:id`,
   а фронт стучался в `/deletelibr/:id` — удаление не работало вообще. Добавлены оба
   пути; ведут к одной и той же логике.

5. **`DELETE /authors/{id}` возвращает JSON `{"message": "Author deleted successfully"}`.**
   В JS этот эндпоинт пытался обратиться к `data.rows[0]`, чего в результате
   `pg-promise.query` нет — реально возвращал 500. Фронт админки на ответ не смотрит,
   так что в проде не заметно.

6. **Seed-библиотекари по-прежнему не могут войти.** Их пароли в seed-данных хранятся
   plain text — `bcrypt.checkpw` их провалит. Это было и в JS-версии; для логина
   нужно регистрироваться через `POST /register`.

7. **FK в seed книг исправлены.** В оригинальном `BookShelf_database.sql` автор «Толстой»
   закомментирован, но `author_id` в INSERT'ах книг считали его, поэтому при
   первом запуске JS-версии все книги ссылались бы не на тех авторов. В `src/init.sql`
   ссылки выровнены под реальные `author_id`.

8. **JWT-секрет короткий (`123321`).** PyJWT выдаёт warning о небезопасной длине ключа.
   Значение взято из JS как есть; в проде вынеси в `.env` и поставь длинный случайный.

9. **CORS открыт для всех источников (`*`).** Соответствует `app.use(cors())` в JS.
   В проде сузить до конкретных origins.

10. **Брошенный абсолютный путь во фронте.** В [public/frontend/admin/issue_admin.html:49](public/frontend/admin/issue_admin.html:49)
    подключается `D:\Колледж\Курсовая\BookShelf_приложение\backend\perehod.js` —
    работает только на машине автора. Не трогал (фронт вне периметра порта).

## Структура

```
src/
├── main.py            FastAPI app, CORS, mount /frontend и /backend, lifespan
├── config.py          pydantic-settings из .env
├── db.py              aiosqlite connection + autoinit из init.sql
├── init.sql           схема + seed
├── security.py        bcrypt + PyJWT
├── schemas/           pydantic-модели запросов
└── routers/           auth, books, authors, readers, issue
tests/                 29 smoke-тестов
```

## Ручные проверки в браузере

1. Зарегистрировать сотрудника:
   ```powershell
   Invoke-RestMethod -Method Post -Uri http://localhost:3000/register -ContentType 'application/json' -Body '{"name":"A","surname":"B","lastname":"C","email":"a@b.c","password":"1234"}'
   ```
2. Открыть <http://localhost:3000/frontend/avtorization.html>, войти `a@b.c` / `1234`.
3. Пройти golden path: «КНИГИ» → «Авторы» → «Читатели» → «Выданные книги».
