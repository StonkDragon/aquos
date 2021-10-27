#!/bin/bash
function loop() {
    for i in $1/*
    do
        if [ -d $i ]
        then
            loop $i
        else
            if [[ $i == *".aquos" ]]
            then
                if [[ $i == *"main.aquos" ]]
                then
                    sh ~/.aqs/aqs.sh -cx $i
                    echo "./main.aqs" >> start.sh
                elif [[ $i == *"Main.aquos" ]]
                then
                    sh ~/.aqs/aqs.sh -cx $i
                    echo "./Main.aqs" >> start.sh
                else
                    sh ~/.aqs/aqs.sh -c $i --supressMainWarnings
                fi
            elif [[ $i == *".objaquos" ]]
            then
                sh ~/.aqs/objaqs.sh -c $i
            fi
        fi
    done
}
rm -f start.sh
touch start.sh
echo "cd src" >> start.sh
if [ -f $1/main.aquos ] || [ -f $1/Main.aquos ] && [ $1 = "src" ]
then
    loop $1
else
    echo "Please specify the 'src' Folder containing your main.aquos File!"
    exit 1
fi
