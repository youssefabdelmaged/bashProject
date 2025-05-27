#! /bin/bash

# directory for storing the databases
DB_DIR="databases"

mkdir -p "$DB_DIR"

#validate the database name and the table name
validate_name(){
    local name ="$1"
    if [[ !"name" = ~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo "Invalid name: $name. Names must start with a letter and can only contain letters, numbers, and underscores."
        return 1
    fi
    return 0
}