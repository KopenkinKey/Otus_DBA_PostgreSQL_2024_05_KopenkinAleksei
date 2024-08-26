# Домашнее задание
## Работа с уровнями изоляции транзакции в PostgreSQL
- Установливю WSL через магазин microsoft Store. Затем открываю WSL и создаю пользователя и пароль.\
![alt text](image-2.png)

Для подключения по SSH необходимо установить OpenSSH-Server. Обновляем репозиторий
```bash 
sudo apt-get update
```
Устанавливаю OpenSSH-Server, MC и net-tools:
```bash 
sudo apt install openssh-server mc net-tools
```
Запускаю приложение MC
```bash 
sudo mc
```
Перехожу в каталог /etc/ssh/sshd_config и нажимаю Edit.\
![alt text](image-3.png)\
включаю вход по паролю:   PasswordAuthentication yes\
в конец добавляю своего пользователя: AllowUsers alex\
и сохраняю файл\
![alt text](image-4.png)\
Смотрю состояние службы ssh, перезагружаю:
```bash
sudo service ssh status
sudo service ssh start
sudo service ssh --full-restart
```

-  **Подключяюсь к виртуальной машине по SSH (первая сессия). Открываю командную строку и ввожу имя пользователя и адрес ВМ (можно узнать адрес командой ifconfig на ВМ):**
```bash 
ssh alex@172.25.106.34
```


- **Установка PostgreSQL.** 
> Обновляю список пакетов и устанавливаю PostgreSQL:
```bash   
sudo apt-get update   
sudo apt-get install postgresql  
```

-  **Подключяюсь к виртуальной машине по SSH (вторая сессия). Открываю командную строку и ввожу имя пользователя и адрес ВМ (можно узнать адрес командой ifconfig на ВМ):**
```bash 
ssh alex@172.25.106.34
```

- **Запуск psql** 
    > В обеих сессиях вхожу в psql под пользователем postgres:

    ```bash
    sudo -u postgres psql
    ```
    > Выключаю auto commit:
    ```sql
    \set AUTOCOMMIT off
    ```
    ![alt text](image-5.png)

- **Создание и наполнение таблицы**
    > В первой сессии выполняю:
    ```SQL
    CREATE TABLE persons(id serial, first_name text, second_name text);
    INSERT INTO persons(first_name, second_name) VALUES('ivan', 'ivanov');
    INSERT INTO persons(first_name, second_name) VALUES('petr', 'petrov');
    COMMIT; 
    ```
    > Получен результат: \
    > CREATE TABLE \
    > INSERT 0 1 \
    > INSERT 0 1 \
    > COMMIT 

- **Посмотреть текущий уровень изоляции: show transaction isolation level**
    > Смотрю текущий уровень изоляции:
    ```sql
    SHOW show transaction isolation level;
    ```
    > Получен результат:
    > |transaction_isolation
    > |-----------------------
    > |read committed
    > |(1 row)

- **Начать новую транзакцию в обоих сессиях с дефолтным (не меняя) уровнем изоляции**
    > Выполняю команду
    ```sql
    BEGIN;
    ```
- **В первой сессии добавить новую запись insert into persons(first_name, second_name) values('sergey', 'sergeev');**
    ```sql
    INSERT INTO persons(first_name, second_name) VALUES('sergey', 'sergeev');
    ```
    > Получил результат:\
    > INSERT 0 1
- **Сделать select from persons во второй сессии**
    > Выполнил во второй сессии
    ```sql
    SELECT * FROM persons;
    ```
    > Получил результат:
    > |id | first_name | second_name|
    > |---|------------|------------|
    > | 1 | ivan       | ivanov     |
    > | 2 | petr       | petrov     |
    > (2 rows)
- **Видите ли вы новую запись и если да то почему?**
    > Новая запись не видна из-за уровня изоляции **read committed**.
- **Завершить первую транзакцию - commit;**
    > Выполнил в первой сессии
    ```sql
    COMMIT;
    ```
- **Сделать select from persons во второй сессии**
    > Выполнил во второй сессии
    ```sql
    SELECT * FROM persons;
    ```
    > Получил результат:
    >|id | first_name | second_name|
    >|---|------------|------------|
    >| 1 | ivan       | ivanov     |
    >| 2 | petr       | petrov     |
    >| 3 | sergey     | sergeev    |
    >(3 rows)
- **Видите ли вы новую запись и если да то почему?**
    >Теперь новая запись быть видна т.к. в первой сессии завершена транзакция добавления новой записи.
- **Завершите транзакцию во второй сессии**
    > Выполнил во второй сессии
    ```sql
    COMMIT;
    ```
- Начать новые но уже repeatable read транзации - set transaction isolation level repeatable read;
    > В обеих сессиях начинаю новые транзакции с уровнем изоляции repeatable read :
    ```sql
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    BEGIN;
    ```
- В первой сессии добавить новую запись insert into persons(first_name, second_name) values('sveta', 'svetova');
    > В первой сессии добавляю новую запись:
    ```sql
    INSERT INTO persons(first_name, second_name) VALUES('sveta', 'svetova');
    ```
- Сделать select* from persons во второй сессии*
    > Выполнил во второй сессии
    ```sql
    SELECT * FROM persons;
    ```
    > Получил результат:
    >|id | first_name | second_name|
    >|---|------------|------------|
    >| 1 | ivan       | ivanov     |
    >| 2 | petr       | petrov     |
    >| 3 | sergey     | sergeev    |
    >(3 rows)
- **Видите ли вы новую запись и если да то почему?**
    > Не видно новую запись
- Завершить первую транзакцию - commit;
    > Выполнил в первой сессии
    ```sql
    COMMIT;
    ```
- ***Сделать select from persons во второй сессии***
    > Выполнил во второй сессии
    ```sql
    SELECT * FROM persons;
    ```
    > Получил результат:
    >|id | first_name | second_name|
    >|---|------------|------------|
    >| 1 | ivan       | ivanov     |
    >| 2 | petr       | petrov     |
    >| 3 | sergey     | sergeev    |
    >(3 rows)
- Видите ли вы новую запись и если да то почему?
    > Не видно новую запись.
- Завершить вторую транзакцию
    > Выполнил во второй сессии
    ```sql
    COMMIT;
    ```
- Сделать select * from persons во второй сессии
    > Выполнил во второй сессии
    ```sql
    SELECT * FROM persons;
    ```
    > Получил результат:
    >|id | first_name | second_name|
    >|---|------------|------------|
    >| 1 | ivan       | ivanov     |
    >| 2 | petr       | petrov     |
    >| 3 | sergey     | sergeev    |
    >| 4 | sveta      | svetova    |
    >(4 rows)
- Видите ли вы новую запись и если да то почему?
    > Вижу новую запись, так как сессия работала в режиме Repeatable Read, фиксируя состояние таблицы на момент начала транзакции.

