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

# validate datatype in the table
validate_datatype(){
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
validate_data(){
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