parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

#initializing
github_token=`grep 'github_token=' $parent_path/.env | sed 's/^.*=//'`
github_username=`grep 'github_username=' $parent_path/.env | sed 's/^.*=//'`
github_repository=`grep 'github_repository=' $parent_path/.env | sed 's/^.*=//'`

backup_folder=`grep 'backup_folder=' $parent_path/.env | sed 's/^.*=//'`

cd $parent_path

#check backup folder or create one
if [ ! -d "$parent_path/$backup_folder" ]; then
  mkdir $parent_path/$backup_folder
fi

#copy important files into backup folder
cp $(grep 'path_' $parent_path/.env | sed 's/^.*=//') $parent_path/$(grep 'backup_folder=' $parent_path/.env | sed 's/^.*=//')

#git
git init
git rm -rf --cached $parent_path/.env
git add $parent_path
git commit -m "new backup from $(date +"%d-%m-%y")"
git push https://"$github_token"@github.com/"$github_username"/"$github_repository".git