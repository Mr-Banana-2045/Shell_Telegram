TOKEN="bot token"
last_update_id=0
answered_messages=()
users=()
USER_FILE="users.txt"

send_message() {
    local CHAT_ID="$1"
    local message="$2"
    curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$message"
}

get_updates() {
    curl -s -X GET "https://api.telegram.org/bot$TOKEN/getUpdates?offset=$last_update_id"
}

send_welcome_message() {
    while IFS= read -r user_id; do
        send_message "$user_id" "BOT is online" &> /dev/null
        echo "sended > $user_id"
    done < "$USER_FILE"
}

process_updates() {
    updates=$(get_updates)
    if [[ "$updates" != "" ]]; then
        latest_update_id=$(echo "$updates" | jq '.result | .[-1].update_id')
        last_update_id=$((latest_update_id + 1))

        for row in $(echo "$updates" | jq -r '.result[] | @base64'); do
            _jq() {
                echo ${row} | base64 --decode | jq -r ${1}
            }
           ip=$(curl -s http://httpbin.org/ip | jq -r '.origin')
            message_text=$(_jq '.message.text')
            message_id=$(_jq '.message.message_id')
            id=$(_jq '.message.chat.id')
            username=$(_jq '.message.from.username')
            message_id=$(_jq '.message.message_id')
            usr=$(_jq '.message.chat.first_name')
            if [[ ! " ${users[@]} " =~ " ${id} " ]]; then
                users+=("$id")
                echo "$id" >> "$USER_FILE"
                send_message "$id" "online" &> /dev/null
            fi
            if [[ ! " ${answered_messages[@]} " =~ " ${message_id} " ]]; then

                json_output=$(jq -n \
                   --arg usr "$usr" \
                   --arg username "@$username" \
                   --arg chat_id "$id" \
                   --arg message "$message_text" \
                   --arg ip "$ip" \
                   '{id: $chat_id, usr: $usr, username: $username, IP: $ip, message: $message}')

                jso=$(jq -n \
                    --arg msg "$message_text" \
                    '{msg: $msg}')
                echo "$json_output" | jq -r '"Chat ID : \(.id)\nUsr: \(.usr)\nid : \(.username)\nIP : \(.IP)\ncommand : \(.message)\n_________"'
                send_message "$json_output" "$jso" &> /dev/null
                answered_messages+=("$message_id")
            fi
        done
    fi
}

if [[ -f "$USER_FILE" ]]; then
    send_welcome_message
fi

while true; do
    process_updates
done


