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

# Insert into Table
insert_into_table() {
    local db_name="$1"
    read -p "Enter table name: " table_name
    if [ ! -f "$DB_DIR/$db_name/$table_name.tbl" ]; then
        echo "Table '$table_name' does not exist."
        return 1
    fi

    # Read schema
    read -r col_line <"$DB_DIR/$db_name/$table_name.tbl"
    read -r type_line < <(sed -n '2p' "$DB_DIR/$db_name/$table_name.tbl")
    read -r pk < <(sed -n '3p' "$DB_DIR/$db_name/$table_name.tbl")
    columns=($col_line)
    data_types=($type_line)

    # Check if primary key value already exists
    read -p "Enter value for primary key ($pk): " pk_value
    pk_index=-1
    for i in "${!columns[@]}"; do
        if [[ "${columns[$i]}" == "$pk" ]]; then
            pk_index=$i
            break
        fi
    done
    if [ -f "$DB_DIR/$db_name/$table_name.data" ]; then
        while IFS='|' read -r line; do
            values=($line)
            if [[ "${values[$pk_index]}" == "$pk_value" ]]; then
                echo "Primary key '$pk_value' already exists."
                return 1
            fi
        done <"$DB_DIR/$db_name/$table_name.data"
    fi

    # Get values
    values=()
    for i in "${!columns[@]}"; do
        if [[ "${columns[$i]}" == "$pk" ]]; then
            values+=("$pk_value")
        else
            read -p "Enter value for ${columns[$i]} (${datatypes[$i]}): " value
            if ! validate_data "$value" "${datatypes[$i]}"; then
                return 1
            fi
            values+=("$value")
        fi
    done

    # Save data
    echo "${values[*]}" | tr ' ' '|' >>"$DB_DIR/$db_name/$table_name.data"
    echo "Record inserted successfully."
}

# Select From Table
select_from_table() {
    local db_name="$1"
    read -p "Enter table name: " table_name
    if [ ! -f "$DB_DIR/$db_name/$table_name.tbl" ]; then
        echo "Table '$table_name' does not exist."
        return 1
    fi

    # Read schema
    read -r col_line <"$DB_DIR/$db_name/$table_name.tbl"
    columns=($col_line)

    # Display header
    printf "|"
    for col in "${columns[@]}"; do
        printf " %-15s |" "$col"
    done
    echo ""
    printf "|"
    for _ in "${columns[@]}"; do
        printf "%s" "-----------------"
        printf "|"
    done
    echo ""

    # Display data
    if [ -f "$DB_DIR/$db_name/$table_name.data" ]; then
        while IFS='|' read -r -a values; do
            printf "|"
            for value in "${values[@]}"; do
                printf " %-15s |" "$value"
            done
            echo ""
        done <"$DB_DIR/$db_name/$table_name.data"
    fi
}

# Delete From Table
delete_from_table() {
    local db_name="$1"
    read -p "Enter table name: " table_name
    if [ ! -f "$DB_DIR/$db_name/$table_name.tbl" ]; then
        echo "Table '$table_name' does not exist."
        return 1
    fi

    read -r col_line <"$DB_DIR/$db_name/$table_name.tbl"
    read -r pk < <(sed -n '3p' "$DB_DIR/$db_name/$table_name.tbl")
    columns=($col_line)
    pk_index=-1
    for i in "${!columns[@]}"; do
        if [[ "${columns[$i]}" == "$pk" ]]; then
            pk_index=$i
            break
        fi
    done

    read -p "Enter primary key value to delete: " pk_value
    if [ ! -f "$DB_DIR/$db_name/$table_name.data" ]; then
        echo "No data to delete."
        return 1
    fi

    # Create temporary file for new data
    temp_file=$(mktemp)
    found=false
    while IFS='|' read -r line; do
        values=($line)
        if [[ "${values[$pk_index]}" != "$pk_value" ]]; then
            echo "$line" >>"$temp_file"
        else
            found=true
        fi
    done <"$DB_DIR/$db_name/$table_name.data"

    if $found; then
        mv "$temp_file" "$DB_DIR/$db_name/$table_name.data"
        echo "Record deleted successfully."
    else
        rm "$temp_file"
        echo "Record with primary key '$pk_value' not found."
    fi
}

# Update Table
update_table() {
    local db_name="$1"
    read -p "Enter table name: " table_name
    if [ ! -f "$DB_DIR/$db_name/$table_name.tbl" ]; then
        echo "Table '$table_name' does not exist."
        return 1
    fi

    read -r col_line <"$DB_DIR/$db_name/$table_name.tbl"
    read -r type_line < <(sed -n '2p' "$DB_DIR/$db_name/$table_name.tbl")
    read -r pk < <(sed -n '3p' "$DB_DIR/$db_name/$table_name.tbl")
    columns=($col_line)
    datatypes=($type_line)

    pk_index=-1
    for i in "${!columns[@]}"; do
        if [[ "${columns[$i]}" == "$pk" ]]; then
            pk_index=$i
            break
        fi
    done

    read -p "Enter primary key value to update: " pk_value
    if [ ! -f "$DB_DIR/$db_name/$table_name.data" ]; then
        echo "No data to update."
        return 1
    fi

    # Create temporary file
    temp_file=$(mktemp)
    found=false
    while IFS='|' read -r line; do
        values=($line)
        if [[ "${values[$pk_index]}" == "$pk_value" ]]; then
            found=true
            new_values=("${values[@]}")
            for i in "${!columns[@]}"; do
                if [[ "${columns[$i]}" != "$pk" ]]; then
                    read -p "Enter new value for ${columns[$i]} (${datatypes[$i]}): " new_value
                    if ! validate_data "$new_value" "${datatypes[$i]}"; then
                        rm "$temp_file"
                        return 1
                    fi
                    new_values[$i]="$new_value"
                fi
            done
            echo "${new_values[*]}" | tr ' ' '|' >>"$temp_file"
        else
            echo "$line" >>"$temp_file"
        fi
    done <"$DB_DIR/$db_name/$table_name.data"

    if $found; then
        mv "$temp_file" "$DB_DIR/$db_name/$table_name.data"
        echo "Record updated successfully."
    else
        rm "$temp_file"
        echo "Record with primary key '$pk_value' not found."
    fi
}

# SQL Parser (Basic)
parse_sql() {
    local db_name="$1"
    local sql="$2"

    # Enable case-insensitive matching
    shopt -s nocasematch

    if [[ "$sql" =~ ^CREATE[[:space:]]+TABLE[[:space:]]+([a-zA-Z][a-zA-Z0-9_]*)[[:space:]]*\((.*)\)[[:space:]]*(;)?$ ]]; then
        table_name="${BASH_REMATCH[1]}"
        columns_def="${BASH_REMATCH[2]}"
        if [ -f "$DB_DIR/$db_name/$table_name.tbl" ]; then
            echo "Table '$table_name' already exists."
            shopt -u nocasematch
            return 1
        fi

        columns=()
        datatypes=()
        pk=""
        IFS=',' read -ra col_defs <<<"$columns_def"
        for col_def in "${col_defs[@]}"; do
            col_def=$(echo "$col_def" | tr -s ' ' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [[ "$col_def" =~ PRIMARY[[:space:]]+KEY ]]; then
                pk=$(echo "$col_def" | cut -d' ' -f1)
                continue
            fi
            read -r col_name col_type <<<"$col_def"
            if ! validate_identifier "$col_name" || ! validate_datatype "$col_type"; then
                shopt -u nocasematch
                return 1
            fi
            columns+=("$col_name")
            datatypes+=("${col_type^^}")
        done

        if [[ -z "$pk" || ! " ${columns[*]} " =~ " $pk " ]]; then
            echo "Valid primary key must be specified."
            shopt -u nocasematch
            return 1
        fi

        echo "${columns[*]}" >"$DB_DIR/$db_name/$table_name.tbl"
        echo "${datatypes[*]}" >>"$DB_DIR/$db_name/$table_name.tbl"
        echo "$pk" >>"$DB_DIR/$db_name/$table_name.tbl"
        echo "Table '$table_name' created successfully."
        shopt -u nocasematch
        return 0
    elif [[ "$sql" =~ ^SELECT[[:space:]]+\*[[:space:]]+FROM[[:space:]]+([a-zA-Z][a-zA-Z0-9_]*)[[:space:]]*(;)?$ ]]; then
        table_name="${BASH_REMATCH[1]}"
        select_from_table "$db_name" <<<"$table_name"
        shopt -u nocasematch
        return 0
    else
        echo "Unsupported SQL command."
        shopt -u nocasematch
        return 1
    fi
}

# Connect to Database
connect_to_database() {
    read -p "Enter database name: " db_name
    if [ ! -d "$DB_DIR/$db_name" ]; then
        echo "Database '$db_name' does not exist."
        return 1
    fi

    while true; do
        echo -e "\nDatabase: $db_name"
        echo "1. Create Table"
        echo "2. List Tables"
        echo "3. Drop Table"
        echo "4. Insert into Table"
        echo "5. Select From Table"
        echo "6. Delete From Table"
        echo "7. Update Table"
        echo "8. Execute SQL"
        echo "9. Back to Main Menu"
        read -p "Select an option: " option

        case $option in
        1) create_table "$db_name" ;;
        2) list_tables "$db_name" ;;
        3) drop_table "$db_name" ;;
        4) insert_into_table "$db_name" ;;
        5) select_from_table "$db_name" ;;
        6) delete_from_table "$db_name" ;;
        7) update_table "$db_name" ;;
        8)
            read -p "Enter SQL query: " sql_query
            parse_sql "$db_name" "$sql_query"
            ;;
        9) break ;;
        *) echo "Invalid option." ;;
        esac
    done
}

# Main Menu
while true; do
    echo -e "\nDBMS Main Menu"
    echo "1. Create Database"
    echo "2. List Databases"
    echo "3. Connect To Database"
    echo "4. Drop Database"
    echo "5. Exit"
    read -p "Select an option: " option

    case $option in
    1) create_database ;;
    2) list_databases ;;
    3) connect_to_database ;;
    4) drop_database ;;
    5)
        echo "Exiting..."
        exit 0
        ;;
    *) echo "Invalid option." ;;
    esac
done