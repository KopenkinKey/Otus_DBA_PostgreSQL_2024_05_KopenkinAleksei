#!/bin/bash

# Путь к каталогу резервного копирования
BACKUP_DIR="/mnt/backup/$(date +%Y%m%d_%H%M%S)"

# Создайте каталог резервного копирования
mkdir -p $BACKUP_DIR

# Выполните резервное копирование
pg_basebackup -h localhost -U repl -D $BACKUP_DIR -Ft -z -P mypassword

# Удалите старые резервные копии (например, старше 7 дней)
find /mnt/backup/* -type d -ctime +7 -exec rm -rf {} \;
