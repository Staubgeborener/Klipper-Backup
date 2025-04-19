backupPaths=()
configOptions=()

scriptsh_parent_path=$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    cd ..
    pwd -P
)

envpath="$scriptsh_parent_path/.env"

source "$envpath"
cp "$envpath" "$envpath.bkp"

while IFS= read -r line; do
    if [[ $line == *"empty_commit"* ]]; then
        if [[ $line == "#"* ]]; then
            if [[ $line == *"yes"* ]]; then
                line="#allow_empty_commits=true"
            else
                line="#allow_empty_commits=false"
            fi
        else
            if [[ $line == *"yes"* ]]; then
                line="allow_empty_commits=true"
            else
                line="allow_empty_commits=false"
            fi
        fi
    fi
    configOptions+="$line \n"
done < <(grep -m 1 -n "# Individual file syntax:" $envpath | cut -d ":" -f 1 | xargs -I {} expr {} - 1 | xargs -I {} head -n {} $envpath)


while IFS= read -r path; do
    # Check if path is a directory or not a file (needed for /* checking as /* treats the path as not a directory)
    if [[ -d "$HOME/$path" && ! -f "$HOME/$path" ]]; then
        # Check if path does not end in /* or /
        if [[ ! "$path" =~ /\*$ && ! "$path" =~ /$ ]]; then
            path="$path/*"
        elif [[ ! "$path" =~ \$ && ! "$path" =~ /\*$ ]]; then
            path="$path*"
        fi
    fi
    backupPaths+=("$path")
done < <(grep -v '^#' "$envpath" | grep 'path_' | sed 's/^.*=//')

newbackupPaths="backupPaths=( \\ \n"
for path in "${backupPaths[@]}"; do
    newbackupPaths+=" \"$path\" \\ \n"
done
newbackupPaths+=")"

newexclude="exclude=( \\ \n"
for extension in "${exclude[@]}"; do
    newexclude+=" \"$extension\" \\ \n"
done
newexclude+=")"

rm "$envpath"
cat >>"$envpath" <<ENVFILE
$(echo -e ${configOptions[@]})
# Backup paths
#  Note: script.sh starts its search in \$HOME which is /home/{username}/
# The array accepts folders or files like the following example
# 
#  backupPaths=( \\
#  "printer_data/config/*" \\
#  "printer_data/config/printer.cfg" \\
#  )
#
# Using the above example the script will search for /home/{username}/printer_data/config/* and /home/{username}/printer_data/config/printer.cfg
# When backing up a folder you should always have /* at the end of the path so that files inside the folder are properly searched

$(echo -e $newbackupPaths)

# Array of strings in .gitignore pattern git format https://git-scm.com/docs/gitignore#_pattern_format for files that should not be uploaded to the remote repo
# New additions must be enclosed in double quotes and should follow the pattern format as noted in the above link

$(echo -e $newexclude)
ENVFILE
