#! /bin/bash

# directory for storing the databases
DB_DIR="databases"

mkdir -p "$DB_DIR"

#validate the database name and the table name
validate_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo "Invalid name. Must start with a letter and contain only letters, numbers, or underscores."
        return 1
    fi
    return 0
}

# validate datatype in the table
validate_datatype() {
    local type="$1"
    case "$type" in
    "INT" | "STRING" | "FLOAT" | "DATE")
        return 0
        ;;
    *)
        echo "Invalid datatype: $type. Supported: INT, STRING, FLOAT, DATE"
        return 1
        ;;
    esac
}

# Function to validate data against datatype
validate_data() {
    local type="$1"
    local data="$2"
    case "$type" in
    "INT") [[ "$data" =~ ^-?[0-9]+$ ]] || {
        echo "Invalid INT value"
        return 1
    } ;;
    "FLOAT") [[ "$data" =~ ^-?[0-9]*\.?[0-9]+$ ]] || {
        echo "Invalid FLOAT value"
        return 1
    } ;;
    "DATE") [[ "$data" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || {
        echo "Invalid DATE format (YYYY-MM-DD)"
        return 1
    } ;;
    "STRING") return 0 ;;
    esac
    return 0
}

# Create Database
create_database() {
    read -p "Enter database name: " db_name
    if ! validate_name "$db_name"; then
        return 1
    fi
    if [ -d "$DB_DIR/$db_name" ]; then
        echo "Database '$db_name' already exists."
        return 1
    fi
    mkdir -p "$DB_DIR/$db_name"
    echo "Database '$db_name' created successfully."
    return 0
}

# List Databases
list_databases() {
    echo "Available Databases:"
    ls -1 "$DB_DIR" | while read -r db; do
        echo "- $db"
    done
}

# Drop Database
drop_database() {
    read -p "Enter database name to drop: " db_name
    if [ ! -d "$DB_DIR/$db_name" ]; then
        echo "Database '$db_name' does not exist."
        return 1
    fi
    read -p "Are you sure you want to drop the database '$db_name'? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        rm -rf "$DB_DIR/$db_name"
        echo "Database '$db_name' dropped successfully."
        return 0
    else
        echo "Database drop cancelled."
        return 1
    fi
}

# Create Table
create_table() {
    local db_name="$1"
    read -p "Enter table name: " table_name
    if ! validate_name "$table_name"; then
        return 1
    fi
    if [ -f "$DB_DIR/$db_name/$table_name.tbl" ]; then
        echo "Table '$table_name' already exists."
        return 1
    fi

    read -p "Enter number of columns: " num_cols
    if ! [[ "$num_cols" =~ ^[1-9][0-9]*$ ]]; then
        echo "Invalid number of columns."
        return 1
    fi

    columns=()
    data_types=()
    primary_key=""
    for ((i = 1; i <= num_cols; i++)); do
        read -p "Enter name for column $i: " col_name
        if ! validate_name "$col_name"; then
            return 1
        fi
        read -p "Enter datatype for column $i (INT, STRING, FLOAT, DATE): " col_type
        if ! validate_datatype "$col_type"; then
            return 1
        fi
        columns+=("$col_name")
        data_types+=("$col_type")
    done

    read -p "Enter primary key column name: " pk
    if [[ ! " ${columns[*]} " =~ " $pk " ]]; then
        echo "Primary key must be one of the column names."
        return 1
    fi

    # Save table schema
    echo "${columns[*]}" >"$DB_DIR/$db_name/$table_name.tbl"
    echo "${data_types[*]}" >>"$DB_DIR/$db_name/$table_name.tbl"
    echo "$pk" >>"$DB_DIR/$db_name/$table_name.tbl"
    echo "Table '$table_name' created successfully."
}

# List Tables
list_tables() {
    local db_name="$1"
    echo "Tables in database '$db_name':"
    ls -1 "$DB_DIR/$db_name" | grep ".tbl$" | sed 's/.tbl$//' | while read -r table; do
        echo "- $table"
    done
}


# Drop Table
drop_table() {
    local db_name="$1"
    read -p "Enter table name to drop: " table_name
    if [ ! -f "$DB_DIR/$db_name/$table_name.tbl" ]; then
        echo "Table '$table_name' does not exist."
        return 1
    fi
    read -p "Are you sure you want to drop '$table_name'? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        rm -f "$DB_DIR/$db_name/$table_name.tbl"
        rm -f "$DB_DIR/$db_name/$table_name.data"
        echo "Table '$table_name' dropped successfully."
    else
        echo "Operation cancelled."
    fi
}