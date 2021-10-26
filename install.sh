if [ -f ~/.zprofile ]
then
    if grep -Fq "alias aqs='sh ~/.aqs/aqs.sh'" ~/.zprofile
    then
        true
    else
        echo "#aqs commands" >> ~/.zprofile
        echo "alias aqs='sh ~/.aqs/aqs.sh'" >> ~/.zprofile
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