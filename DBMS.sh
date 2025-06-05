#!/bin/bash

# Validate the database name and the table name
validate_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo "Invalid name. Must start with a letter and contain only letters, numbers, or underscores."
        return 1
    fi
    return 0
}

# Validate datatype in the table
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

# DBMS root directory
DB_DIR="./databases"

# Create DBMS directory if not exists
mkdir -p "$DB_DIR"

# Function to create a database
create_db() {
    read -p "Enter database name: " dbname
    if [[ -d "$DB_DIR/$dbname" ]]; then
        echo "Database '$dbname' already exists."
    else
        mkdir "$DB_DIR/$dbname"
        echo "Database '$dbname' created successfully."
    fi
}

# Function to list all databases
list_dbs() {
    echo "Databases:"
    ls "$DB_DIR"
}

# Function to connect to a database
connect_db() {
    read -p "Enter database name: " dbname
    if [[ -d "$DB_DIR/$dbname" ]]; then
        echo "Connected to database '$dbname'"
        db_menu "$dbname"
    else
        echo "Database '$dbname' does not exist."
    fi
}

# Function to drop a database
drop_db() {
    read -p "Enter database name to drop: " dbname
    if [[ -d "$DB_DIR/$dbname" ]]; then
        rm -r "$DB_DIR/$dbname"
        echo "Database '$dbname' dropped successfully."
    else
        echo "Database '$dbname' does not exist."
    fi
}

# Function to create a table
create_table() {
    read -p "Enter table name: " tablename
    if [[ -f "$1/$tablename" ]]; then
        echo "Table '$tablename' already exists."
        return
    fi

    read -p "Enter number of columns: " colnum
    columns=()

    for ((i = 1; i <= colnum; i++)); do
        read -p "Enter name of column $i: " colname
        read -p "Enter data type of column $i (int/str): " coltype
        columns+=("$colname:$coltype")
    done

    IFS=','
    echo "${columns[*]}" >"$1/$tablename"
    echo "Table '$tablename' created successfully."
}

# Function to list all tables
list_tables() {
    echo "Tables in database:"
    ls "$1"
}

# Function to drop a table
drop_table() {
    read -p "Enter table name to drop: " tablename
    if [[ -f "$1/$tablename" ]]; then
        rm "$1/$tablename"
        echo "Table '$tablename' dropped successfully."
    else
        echo "Table '$tablename' does not exist."
    fi
}

# Function to insert into a table
insert_into_table() {
    read -p "Enter table name: " tablename
    if [[ ! -f "$1/$tablename" ]]; then
        echo "Table '$tablename' does not exist."
        return
    fi

    IFS=',' read -ra columns <"$1/$tablename"
    values=()

    for col in "${columns[@]}"; do
        IFS=':' read -ra meta <<<"$col"
        colname=${meta[0]}
        coltype=${meta[1]}
        read -p "Enter value for $colname ($coltype): " value
        values+=("$value")
    done

    IFS=','
    echo "${values[*]}" >>"$1/$tablename"
    echo "Row inserted successfully."
}

# Function to select from a table
select_from_table() {
    read -p "Enter table name: " tablename
    if [[ ! -f "$1/$tablename" ]]; then
        echo "Table '$tablename' does not exist."
        return
    fi

    echo "Contents of table '$tablename':"
    nl "$1/$tablename"
}

# Function to delete from a table
delete_from_table() {
    read -p "Enter table name: " tablename
    if [[ ! -f "$1/$tablename" ]]; then
        echo "Table '$tablename' does not exist."
        return
    fi

    echo "Contents of table '$tablename':"
    nl "$1/$tablename"

    read -p "Enter line number to delete: " lineno
    if [[ $lineno -le 1 ]]; then
        echo "Cannot delete table header."
        return
    fi

    sed -i "${lineno}d" "$1/$tablename"
    echo "Row deleted."
}

# Function to update a table
update_table() {
    read -p "Enter table name: " tablename
    if [[ ! -f "$1/$tablename" ]]; then
        echo "Table '$tablename' does not exist."
        return
    fi

    echo "Contents of table '$tablename':"
    nl "$1/$tablename"

    read -p "Enter line number to update: " lineno
    if [[ $lineno -le 1 ]]; then
        echo "Cannot update table header."
        return
    fi

    IFS=',' read -ra columns <"$1/$tablename"
    new_values=()

    for col in "${columns[@]}"; do
        IFS=':' read -ra meta <<<"$col"
        colname=${meta[0]}
        coltype=${meta[1]}
        read -p "Enter new value for $colname ($coltype): " value
        new_values+=("$value")
    done

    IFS=',' new_line="${new_values[*]}"
    sed -i "${lineno}s/.*/$new_line/" "$1/$tablename"
    echo "Row updated."
}

# Menu for operations inside a database
db_menu() {
    dbpath="$DB_DIR/$1"
    while true; do
        echo -e "\nDatabase Menu - '$1'"
        echo "1. Create Table"
        echo "2. List Tables"
        echo "3. Drop Table"
        echo "4. Insert into Table"
        echo "5. Select from Table"
        echo "6. Delete from Table"
        echo "7. Update Table"
        echo "8. Disconnect"
        read -p "Choose an option: " choice

        case $choice in
        1) create_table "$dbpath" ;;
        2) list_tables "$dbpath" ;;
        3) drop_table "$dbpath" ;;
        4) insert_into_table "$dbpath" ;;
        5) select_from_table "$dbpath" ;;
        6) delete_from_table "$dbpath" ;;
        7) update_table "$dbpath" ;;
        8)
            echo "Disconnected from database."
            break
            ;;
        *) echo "Invalid option." ;;
        esac
    done
}

# # Main menu
# while true; do
#     echo -e "\nMain Menu"
#     echo "1. Create Database"
#     echo "2. List Databases"
#     echo "3. Connect to Database"
#     echo "4. Drop Database"
#     echo "5. Exit"
#     read -p "Choose an option: " choice

#     case $choice in
#     1) create_db ;;
#     2) list_dbs ;;
#     3) connect_db ;;
#     4) drop_db ;;
#     5)
#         echo "Exiting..."
#         break
#         ;;
#     *) echo "Invalid option." ;;
#     esac
# done
