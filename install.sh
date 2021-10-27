if [ -f ~/.zprofile ]
then
    if grep -Fq "alias aqs='sh ~/.aqs/aqs.sh'" ~/.zprofile
    then
        true
    else
        echo "#aqs commands" >> ~/.zprofile
        echo "alias aqs='sh ~/.aqs/aqs.sh'" >> ~/.zprofile
    fi
    if grep -Fq "alias aqspc='sh ~/.aqs/aqspc.sh'" ~/.zprofile
    then
        true
    else
        echo "alias aqspc='sh ~/.aqs/aqspc.sh'" >> ~/.zprofile
    fi
elif [ -f ~/.bash_profile ]
then
    if grep -Fq "alias aqs='sh ~/.aqs/aqs.sh'" ~/.bash_profile
    then
        true
    else
        echo "#aqs commands" >> ~/.bash_profile
        echo "alias aqs='sh ~/.aqs/aqs.sh'" >> ~/.bash_profile
    fi
    if grep -Fq "alias aqspc='sh ~/.aqs/aqspc.sh'" ~/.bash_profile
    then
        true
    else
        echo "alias aqspc='sh ~/.aqs/aqspc.sh'" >> ~/.bash_profile
    fi
fi
if [ -d ~/.aqs ]
then
    rm -r ~/.aqs
    mkdir ~/.aqs
else
    mkdir ~/.aqs
fi

cp -R ./ ~/.aqs

cd ~/.aqs
rm -f install.sh
rm -rf .git/
rm -f README.md

echo "Aquos Command line Utility has been installed\nUsage: aqs -(c,n,x,p) \$infile extra-Arguments\n       aqspc \$directory"
