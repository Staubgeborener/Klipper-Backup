## Installation
  1. Clone the github repository and copy `.env.example` to `.env`:
    ```shell
    cd ~ && git clone https://github.com/Staubgeborener/klipper-backup.git && chmod +x ./klipper-backup/script.sh && cp ./klipper-backup/.env.example ./klipper-backup/.env
    ```

  2. Create a [new](https://github.com/new) repository:
    - In the upper-right corner of any page in GitHub, select +, then click New repository.
    - Type a name for your repository, and an optional description.
    - Choose a repository visibility. (You can select either one)
    - Click Create repository.  

  3. Create your github token. You will need to get a GitHub token (classic or Fine-grained, either works) just ensure you have set access to the repository and have push/pull & commit permissions.
    For more info on classic and fine-grained PATS, see the following: [https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)    

    !!! warning "IMPORTANT"
        *Make sure you note down your access token, as once you close out of the window, you cannot retrieve it again and will have to make a new one.  

  4. Navigate into the klipper-backup folder and edit `.env`
    ```
    cd klipper-backup && nano .env
    ```  

  5. Replace `ghp_xxxxxxxxxxxxxxxxxxxx` with the token you copied from step 3.

  6. Replace `USERNAME` with your GitHub username and `REPOSITORY` with the name used in step 2.

    ```ini
    github_username=USERNAME
    github_repository=REPOSITORY
    ```

    To save the changes made in nano do: ++ctrl+"s"++ then ++ctrl+"x"++  

  7. Run your first backup!  
    Run `./script.sh` from within klipper-backup and check that you receive no errors and when
    checking the repository you should see a new commit.  

  8. Optional: now you can e.g. set a [macro](manual.md/#klipper-macro) to execute the script with a UI or use an [automated solution](automation.md). Also you can add a [moonraker entry](updating.md/#moonraker-update-manager) for future updates.