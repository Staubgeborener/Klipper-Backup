#!/bin/bash

shopt -s extglob  # enable extglob

color=$'\e[1;36m'
end=$'\e[0m'

Klipper-Backup-Logo() {
    echo -e "${color}
 _    _  _                           _              _                  ________
| |_ | ||_| ___  ___  ___  ___  ___ | |_  ___  ___ | |_  _ _  ___     | |____| |
| '_|| || || . || . || -_||  _||___|| . || .'||  _|| '_|| | || . |    |  (__)  |
|_,_||_||_||  _||  _||___||_|       |___||__,||___||_,_||___||  _|    |        |
           |_|  |_|                                          |_|      |________|
    ${end}"
}

installation() {
    if [ -f .env ]; then
      echo -e ".env already exists no need to copy"
    else
      cp .env.example .env
    fi
}

Klipper-Backup-Logo

echo -e "\n${color}Start installation...${end}\n"
  installation
echo -e "\n${color}Finished! Now set up the repository and edit the .env file."
