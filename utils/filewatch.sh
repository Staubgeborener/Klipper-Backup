#!/usr/bin/env bash

source "$HOME/klipper-backup/.env"
watchlist=""
for path in "${backupPaths[@]}"; do
    for file in $path; do
        if [ ! -h "$file" ]; then
            file_dir=$(dirname "$file")
            if [ "$file_dir" = "." ]; then
                watchlist+=" $HOME/$file"
            else
                watchlist+=" $HOME/$file_dir"
            fi
        fi
    done
done

watchlist=$(echo "$watchlist" | tr ' ' '\n' | sort -u | tr '\n' ' ')

# Convert exclude array to string delimitted by "|"
excludeString=$(printf "|%s" "${exclude[@]}")
excludeString="${excludeString:1}"
excludeString=$(echo "$excludeString" | sed 's/\*\./\./g')

if [ -z $extraFilewatchExclude ]; then
exclude_pattern="$excludeString"
else
exclude_pattern="$excludeString|$extraFilewatchExclude"
fi

inotifywait -mrP -e close_write -e move -e delete --exclude "$exclude_pattern" $watchlist |
while read -r path event file; do
    if [ -z "$file" ]; then
        file=$(basename "$path")
    fi
    echo "Event Type: $event, Watched Path: $path, File Name: $file"
    file="$file" /usr/bin/env bash -c "/usr/bin/env bash  $HOME/klipper-backup/script.sh -c \"\$file modified - \$(date +'%x - %X')\"" > /dev/null 2>&1
done
