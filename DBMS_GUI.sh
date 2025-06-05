#!/bin/bash

if ! command -v zenity &>/dev/null; then
    echo "Zenity is required but not installed. Please install zenity and try again."
    exit 1
fi

source ./DBMS.sh

create_database_gui() {
    db_name=$(zenity --entry --title="Create Database" --text="Enter database name:")
    if [ -z "$db_name" ]; then
        zenity --error --text="Database name cannot be empty."
        return 1
    fi
    if ! validate_name "$db_name"; then
        zenity --error --text="Invalid database name. Must start with a letter and contain only letters, numbers, or underscores."
        return 1
    fi
    if [ -d "$DB_DIR/$db_name" ]; then
        zenity --error --text="Database '$db_name' already exists."
        return 1
    fi
    mkdir -p "$DB_DIR/$db_name"
    zenity --info --text="Database '$db_name' created successfully."
}

list_databases_gui() {
    if [ ! -d "$DB_DIR" ]; then
        zenity --info --text="No databases found."
        return
    fi
    mapfile -t dbs < <(ls -1 "$DB_DIR")
    if [ ${#dbs[@]} -eq 0 ]; then
        zenity --info --text="No databases found."
        return
    fi
    zenity --list --title="Available Databases" --column="Databases" "${dbs[@]}"
}

drop_database_gui() {
    db_name=$(zenity --entry --title="Drop Database" --text="Enter database name to drop:")
    if [ -z "$db_name" ]; then
        zenity --error --text="Database name cannot be empty."
        return 1
    fi
    if [ ! -d "$DB_DIR/$db_name" ]; then
        zenity --error --text="Database '$db_name' does not exist."
        return 1
    fi
    zenity --question --text="Are you sure you want to drop the database '$db_name'?"
    if [ $? -eq 0 ]; then
        rm -rf "$DB_DIR/$db_name"
        zenity --info --text="Database '$db_name' dropped successfully."
    else
        zenity --info --text="Database drop cancelled."
    fi
}

create_table_gui() {
    db_name="$1"
    table_name=$(zenity --entry --title="Create Table" --text="Enter table name:")
    if [ -z "$table_name" ]; then
        zenity --error --text="Table name cannot be empty."
        return 1
    fi
    if ! validate_name "$table_name"; then
        zenity --error --text="Invalid table name."
        return 1
    fi
    if [ -f "$DB_DIR/$db_name/$table_name.tbl" ]; then
        zenity --error --text="Table '$table_name' already exists."
        return 1
    fi

    num_cols=$(zenity --entry --title="Create Table" --text="Enter number of columns:")
    if ! [[ "$num_cols" =~ ^[1-9][0-9]*$ ]]; then
        zenity --error --text="Invalid number of columns."
        return 1
    fi

    columns=()
    data_types=()
    for ((i = 1; i <= num_cols; i++)); do
        col_name=$(zenity --entry --title="Create Table" --text="Enter name for column $i:")
        if [ -z "$col_name" ]; then
            zenity --error --text="Column name cannot be empty."
            return 1
        fi
        if ! validate_name "$col_name"; then
            zenity --error --text="Invalid column name."
            return 1
        fi
        col_type=$(zenity --list --title="Create Table" --text="Select datatype for column $i:" --radiolist --column "Select" --column "Type" TRUE INT FALSE STRING FALSE FLOAT FALSE DATE)
        if ! validate_datatype "$col_type"; then
            zenity --error --text="Invalid datatype."
            return 1
        fi
        columns+=("$col_name")
        data_types+=("$col_type")
    done

    pk=$(zenity --entry --title="Create Table" --text="Enter primary key column name:")
    if [[ ! " ${columns[*]} " =~ " $pk " ]]; then
        zenity --error --text="Primary key must be one of the column names."
        return 1
    fi

    echo "${columns[*]}" >"$DB_DIR/$db_name/$table_name.tbl"
    echo "${data_types[*]}" >>"$DB_DIR/$db_name/$table_name.tbl"
    echo "$pk" >>"$DB_DIR/$db_name/$table_name.tbl"
    zenity --info --text="Table '$table_name' created successfully."
}

list_tables_gui() {
    db_name="$1"
    if [ ! -d "$DB_DIR/$db_name" ]; then
        zenity --info --text="Database '$db_name' does not exist."
        return
    fi
    mapfile -t tables < <(ls -1 "$DB_DIR/$db_name" | grep ".tbl$" | sed 's/.tbl$//')
    if [ ${#tables[@]} -eq 0 ]; then
        zenity --info --text="No tables found in database '$db_name'."
        return
    fi
    zenity --list --title="Tables in database '$db_name'" --column="Tables" "${tables[@]}"
}

drop_table_gui() {
    db_name="$1"
    table_name=$(zenity --entry --title="Drop Table" --text="Enter table name to drop:")
    if [ -z "$table_name" ]; then
        zenity --error --text="Table name cannot be empty."
        return 1
    fi
    if [ ! -f "$DB_DIR/$db_name/$table_name.tbl" ]; then
        zenity --error --text="Table '$table_name' does not exist."
        return 1
    fi
    zenity --question --text="Are you sure you want to drop '$table_name'?"
    if [ $? -eq 0 ]; then
        rm -f "$DB_DIR/$db_name/$table_name.tbl"
        rm -f "$DB_DIR/$db_name/$table_name.data"
        zenity --info --text="Table '$table_name' dropped successfully."
    else
        zenity --info --text="Operation cancelled."
    fi
}

insert_into_table_gui() {
    db_name="$1"
    table_name=$(zenity --entry --title="Insert Into Table" --text="Enter table name:")
    if [ -z "$table_name" ]; then
        zenity --error --text="Table name cannot be empty."
        return 1
    fi
    if [ ! -f "$DB_DIR/$db_name/$table_name.tbl" ]; then
        zenity --error --text="Table '$table_name' does not exist."
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

    pk_value=$(zenity --entry --title="Insert Into Table" --text="Enter value for primary key ($pk):")
    if [ -z "$pk_value" ]; then
        zenity --error --text="Primary key value cannot be empty."
        return 1
    fi

    if [ -f "$DB_DIR/$db_name/$table_name.data" ]; then
        while IFS='|' read -r line; do
            values=($line)
            if [[ "${values[$pk_index]}" == "$pk_value" ]]; then
                zenity --error --text="Primary key '$pk_value' already exists."
                return 1
            fi
        done <"$DB_DIR/$db_name/$table_name.data"
    fi

    values=()
    for i in "${!columns[@]}"; do
        if [[ "${columns[$i]}" == "$pk" ]]; then
            values+=("$pk_value")
        else
            value=$(zenity --entry --title="Insert Into Table" --text="Enter value for ${columns[$i]} (${datatypes[$i]}):")
            if ! validate_data "${datatypes[$i]}" "$value"; then
                zenity --error --text="Invalid value for ${columns[$i]}."
                return 1
            fi
            values+=("$value")
        fi
    done

    echo "${values[*]}" | tr ' ' '|' >>"$DB_DIR/$db_name/$table_name.data"
    zenity --info --text="Record inserted successfully."
}

select_from_table_gui() {
    db_name="$1"
    table_name=$(zenity --entry --title="Select From Table" --text="Enter table name:")
    if [ -z "$table_name" ]; then
        zenity --error --text="Table name cannot be empty."
        return 1
    fi
    if [ ! -f "$DB_DIR/$db_name/$table_name.tbl" ]; then
        zenity --error --text="Table '$table_name' does not exist."
        return 1
    fi

    read -r col_line <"$DB_DIR/$db_name/$table_name.tbl"
    columns=($col_line)

    if [ ! -f "$DB_DIR/$db_name/$table_name.data" ]; then
        zenity --info --text="No data found in table '$table_name'."
        return
    fi

    # Prepare table data for zenity list
    data=()
    while IFS='|' read -r -a values; do
        for value in "${values[@]}"; do
            data+=("$value")
        done
    done <"$DB_DIR/$db_name/$table_name.data"

    zenity --list --title="Table: $table_name" --column="${columns[@]}" "${data[@]}"
}

delete_from_table_gui() {
    db_name="$1"
    table_name=$(zenity --entry --title="Delete From Table" --text="Enter table name:")
    if [ -z "$table_name" ]; then
        zenity --error --text="Table name cannot be empty."
        return 1
    fi
    if [ ! -f "$DB_DIR/$db_name/$table_name.tbl" ]; then
        zenity --error --text="Table '$table_name' does not exist."
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

    pk_value=$(zenity --entry --title="Delete From Table" --text="Enter primary key value to delete:")
    if [ -z "$pk_value" ]; then
        zenity --error --text="Primary key value cannot be empty."
        return 1
    fi

    if [ ! -f "$DB_DIR/$db_name/$table_name.data" ]; then
        zenity --info --text="No data to delete."
        return 1
    fi

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
        zenity --info --text="Record deleted successfully."
    else
        rm "$temp_file"
        zenity --error --text="Record with primary key '$pk_value' not found."
    fi
}

update_table_gui() {
    db_name="$1"
    table_name=$(zenity --entry --title="Update Table" --text="Enter table name:")
    if [ -z "$table_name" ]; then
        zenity --error --text="Table name cannot be empty."
        return 1
    fi
    if [ ! -f "$DB_DIR/$db_name/$table_name.tbl" ]; then
        zenity --error --text="Table '$table_name' does not exist."
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

    pk_value=$(zenity --entry --title="Update Table" --text="Enter primary key value to update:")
    if [ -z "$pk_value" ]; then
        zenity --error --text="Primary key value cannot be empty."
        return 1
    fi

    if [ ! -f "$DB_DIR/$db_name/$table_name.data" ]; then
        zenity --info --text="No data to update."
        return 1
    fi

    temp_file=$(mktemp)
    found=false
    while IFS='|' read -r line; do
        values=($line)
        if [[ "${values[$pk_index]}" == "$pk_value" ]]; then
            found=true
            new_values=("${values[@]}")
            for i in "${!columns[@]}"; do
                if [[ "${columns[$i]}" != "$pk" ]]; then
                    new_value=$(zenity --entry --title="Update Table" --text="Enter new value for ${columns[$i]} (${datatypes[$i]}):")
                    if ! validate_data "${datatypes[$i]}" "$new_value"; then
                        zenity --error --text="Invalid value for ${columns[$i]}."
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
        zenity --info --text="Record updated successfully."
    else
        rm "$temp_file"
        zenity --error --text="Record with primary key '$pk_value' not found."
    fi
}

execute_sql_gui() {
    db_name="$1"
    sql_query=$(zenity --entry --title="Execute SQL" --text="Enter SQL query:")
    if [ -z "$sql_query" ]; then
        zenity --error --text="SQL query cannot be empty."
        return 1
    fi
    output=$(parse_sql "$db_name" "$sql_query" 2>&1)
    zenity --info --text="$output"
}

connect_to_database_gui() {
    db_name=$(zenity --entry --title="Connect to Database" --text="Enter database name:")
    if [ -z "$db_name" ]; then
        zenity --error --text="Database name cannot be empty."
        return 1
    fi
    if [ ! -d "$DB_DIR/$db_name" ]; then
        zenity --error --text="Database '$db_name' does not exist."
        return 1
    fi

    while true; do
        option=$(zenity --list --title="Database: $db_name" --column="Option" --column="Description" \
            1 "Create Table" \
            2 "List Tables" \
            3 "Drop Table" \
            4 "Insert into Table" \
            5 "Select From Table" \
            6 "Delete From Table" \
            7 "Update Table" \
            8 "Execute SQL" \
            9 "Back to Main Menu" \
            --height=400 --width=400)

        case $option in
        1) create_table_gui "$db_name" ;;
        2) list_tables_gui "$db_name" ;;
        3) drop_table_gui "$db_name" ;;
        4) insert_into_table_gui "$db_name" ;;
        5) select_from_table_gui "$db_name" ;;
        6) delete_from_table_gui "$db_name" ;;
        7) update_table_gui "$db_name" ;;
        8) execute_sql_gui "$db_name" ;;
        9) break ;;
        *) zenity --error --text="Invalid option." ;;
        esac
    done
}

# Main GUI loop
while true; do
    option=$(zenity --list --title="DBMS Main Menu" --column="Option" --column="Description" \
        1 "Create Database" \
        2 "List Databases" \
        3 "Connect To Database" \
        4 "Drop Database" \
        5 "Exit" \
        --height=300 --width=300)

    case $option in
    1) create_database_gui ;;
    2) list_databases_gui ;;
    3) connect_to_database_gui ;;
    4) drop_database_gui ;;
    5) exit 0 ;;
    *) zenity --error --text="Invalid option." ;;
    esac
done
