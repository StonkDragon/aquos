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
                if [[ $i == *"main.aquos" || $i == *"Main.aquos" ]]
                then
                    sh ~/.aqs/aqs.sh -cx $i
                else
                    sh ~/.aqs/aqs.sh -c $i --supressMainWarnings
                fi
            fi
        fi
    done
}

if [ -f $1/main.aquos ] || [ -f $1/Main.aquos ]
then
    loop $1
else
    echo "Please specify the Folder containing your main.aquos File!"
    exit 1
fi
