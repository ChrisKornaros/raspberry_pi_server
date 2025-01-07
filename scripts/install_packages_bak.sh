#!/bin/bash

# Convert the existing packages to just their names
cat ~/clean_packages.txt | cut -f1 | tr -d ' ' | grep -v '^$' > ~/packages_clean.txt

# Install packages
while read -r package; do
    echo "Attempting to install: $package"
    sudo apt-get install -y "$package"
done < ~/clean_packages.txt