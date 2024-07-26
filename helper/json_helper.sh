read_json_variable() {
    local json_file=$1
    local key=$2

    if [ ! -f "$json_file" ]; then
        echo "JSON file not found: $json_file"
        return 1
    fi

    local value=$(grep -o "\"$key\": *\[[^]]*\]\|\(\"$key\": *\"[^\"]*\"\)\|\(\"$key\": *[^,}]*\)" "$json_file" | sed "s/\"$key\": *//" | tr -d '[:space:]')

    if [[ $value =~ ^\\[.*\\]$ ]]; then
        value=$(echo "$value" | sed 's/[][]//g')
    elif [[ $value =~ ^\".*\"$ ]]; then
        value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/')
    fi

    if [ -z "$value" ]; then
        echo "Failed to extract $key from $json_file"
        return 1
    fi

    echo "$value"
    return 0
}

read_json_variable_from_json() {
    local json_content=$1
    local key=$2

    json_content=$(echo "$json_content" | awk '{printf "%s__--__", $0} END {print ""}')
    local value=$(echo "$json_content" | grep -o "\"$key\": *\[[^]]*\]\|\(\"$key\": *\"[^\"]*\"\)\|\(\"$key\": *[^,}]*\)" | sed "s/\"$key\": *//")

    if [[ $value =~ ^\\[.*\\]$ ]]; then
        value=$(echo "$value" | sed 's/[][]//g')
    elif [[ $value =~ ^\".*\"$ ]]; then
        value=$(echo "$value" | sed 's/^"\(.*\)"$/\1/')
    fi

    if [ -z "$value" ]; then
        echo "Failed to extract $key from given json"
        return 1
    fi

    echo "$value" | awk '{gsub("__--__", "\n")} 1'
    return 0
}
