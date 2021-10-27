#! /bin/bash
comp_args=$1
comp_infile=$2
comp_extras=$3

is_in_func=0
rm -f ~/.aqs/.defints
rm -f ~/.aqs/.defstrings

shc_installed=$(which shc)

if [ -z $shc_installed ]
then
    echo "Please install shc."
    exit 0
fi

if [ -z $comp_infile ]
then
    echo "No File specified!"
    rm -f ~/.aqs/.defints
    rm -f ~/.aqs/.defstrings
    echo "Compile failed."
    exit 1
else
    if [[ $comp_args = "-"* && $comp_args == *"c"* ]] && [[ $comp_args != *"p"* ]]
    then
        file="${2%%\.*}"
        file=$file.caqs
        rm -f $file
        touch $file
        echo "#!/bin/bash" >> $file
    elif [[ $comp_args = "-"* && $comp_args == *"p"* ]] && [[ $comp_args != *"c"* ]]
    then
        sh ~/.aqs/aqspc.sh $comp_infile
        sleep 0.5
        rm -f start.sh
        touch start.sh
        echo "cd $comp_infile" >> start.sh
        if [ -f $comp_infile/main.aqs ]
        then
            echo "./main.aqs \"\$1\" \"\$2\" \"\$3\" \"\$4\" \"\$5\" \"\$6\" \"\$7\" \"\$8\" \"\$9\"" >> start.sh
        elif [ -f $comp_infile/Main.aqs ]
        then
            echo "./Main.aqs \"\$1\" \"\$2\" \"\$3\" \"\$4\" \"\$5\" \"\$6\" \"\$7\" \"\$8\" \"\$9\"" >> start.sh
        fi
        echo "Created Launch Script start.sh"
        exit 0
    elif [[ $comp_args == *"p"* ]] && [[ $comp_args == *"c"* ]]
    then
        echo "The -c and -p Arguments are mutually exclusive and can't be used together."
        exit 1
    fi
fi

# FUNCTIONS DO NOT TOUCH

function packhandler() {
    cmd="${cmd%%\>*}"
    cmd="${cmd:5}"
    echo "Packing $cmd"
    cmd=$(echo "$cmd" | tr '.' '/')
    echo "source $cmd.caqs" >> $file
}

function importhandler() {
    cmd="${cmd%%\>*}"
    cmd="${cmd:7}"
    cmd=$(echo "$cmd" | tr '.' '/')
    if [[ $1 != *"n"* ]]
    then
        if [ -f ~/.aqs/sources/$cmd.asrc ]
        then
            echo "source ~/.aqs/sources/$cmd.asrc" >> $file
        else
            echo "\"$cmd\" is not a source file."
        fi
    elif [[ $1 == *"n"* ]]
    then
        if [ -f ~/.aqs/sources/$cmd.asrc ]
        then
            echo "Sourcing '$cmd'"
            waittime=$(stat -f%z ~/.aqs/sources/$cmd.asrc)
            #echo $waittime
            sleep $((waittime/100))
            echo Took $((waittime/100)) Seconds.
            #defsource=$(cat ~/.aqs/sources/$cmd.asrc)
            #echo "$defsource" >> $file
            while read -r defsource
            do
                echo "$defsource" >> $file
            done < ~/.aqs/sources/$cmd.asrc
        else
            echo "\"$cmd\" is not a source file."
        fi
    fi
}

function ifhandler() {
    cmd="${cmd%%\)*}"
    cmd2=${cmd%\(*}
    cmdlen=${#cmd2}
    #echo "$cmdlen"
    cmd="${cmd:$((cmdlen+1))}"
    cmd=${cmd//==/-eq}
    cmd=${cmd//!=/-ne}
    cmd=${cmd//>/-gt}
    cmd=${cmd//>=/-ge}
    cmd=${cmd//</-lt}
    cmd=${cmd//<=/-le}
    echo "if [[ $cmd ]]" >> $file
    echo "then" >> $file

}

function whilehandler() {
    cmd="${cmd%%\)*}"
    cmd2=${cmd%\(*}
    cmdlen=${#cmd2}
    cmd="${cmd:$((cmdlen+1))}"
    cmd=${cmd//==/-eq}
    cmd=${cmd//!=/-ne}
    cmd=${cmd//>/-gt}
    cmd=${cmd//>=/-ge}
    cmd=${cmd//</-lt}
    cmd=${cmd//<=/-le}
    echo "while [ $cmd ]" >> $file
    echo "do" >> $file
}

function forhandler() {
    cmd="${cmd%%\)*}"
    cmd2=${cmd%\(*}
    cmdlen=${#cmd2}
    cmd="${cmd:$((cmdlen+1))}"
    echo "for $cmd" >> $file
    echo "do" >> $file
}

function funchandler() {
    cmd="${cmd%\(*}"
    cmd2=${cmd:5}
    cmdlen=${#cmd2}
    if [[ $cmd2 != "_"* && $cmd2 != *"_" ]]
    then
        echo "function $cmd2() {" >> $file
    else
        echo "$cmd2 is not a secure Label."
        rm -f ~/.aqs/.defints
        rm -f ~/.aqs/.defstrings
        echo "Compile failed."
        exit 1
    fi
}

function elifhandler() {
    cmd="${cmd%%\)*}"
    cmd2=${cmd%\(*}
    cmdlen=${#cmd2}
    #echo "$cmdlen"
    cmd="${cmd:$((cmdlen+1))}"
    cmd=${cmd//==/-eq}
    cmd=${cmd//!=/-ne}
    cmd=${cmd//>/-gt}
    cmd=${cmd//>=/-ge}
    cmd=${cmd//</-lt}
    cmd=${cmd//<=/-le}
    echo "elif [[ $cmd ]]" >> $file
    echo "then" >> $file
}

function elsehandler() {
    echo "else" >> $file
}

function varhandler() {
    var="${cmd%=*}"
    val=${#var}
    val="${cmd:$((val+1))}"
    if [[ $val =~ [^[:digit:]] ]]
    then
        if grep -Fqs "$var" ~/.aqs/.defstrings || [[ $val == null ]]
        then
            if [[ $cmd == *"("*")" ]]
            then
                arg=${cmd%?}
                cmd="${cmd%(*}"
                cmdlen=${#cmd}
                varlen=${#var}
                arg=${arg:$((cmdlen+1))}
                cmd=${cmd:$((varlen+1))}
                arg=$(echo "$arg" | tr ',' ' ')
                arg=$(echo "$arg" | tr '\q' ',')
                arg=${arg//__args1__/"\$1"}
                arg=${arg//__args2__/"\$2"}
                arg=${arg//__args3__/"\$3"}
                arg=${arg//__args4__/"\$4"}
                arg=${arg//__args5__/"\$5"}
                arg=${arg//__args6__/"\$6"}
                arg=${arg//__args7__/"\$7"}
                arg=${arg//__args8__/"\$8"}
                arg=${arg//__args9__/"\$9"}
                echo "$var=\$($cmd $arg)" >> $file
            else
                echo "$var=$val" >> $file
            fi
        else
            echo "Variable $var has not been defined as a String."
            rm -f ~/.aqs/.defints
            rm -f ~/.aqs/.defstrings
            echo "Compile failed."
            exit 1
        fi
    else
        if grep -Fqs "$var" ~/.aqs/.defints || [[ $val == null ]]
        then
            if [[ $cmd == *"("*")" ]]
            then
                arg=${cmd%?}
                cmd="${cmd%(*}"
                cmdlen=${#cmd}
                varlen=${#var}
                arg=${arg:$((cmdlen+1))}
                cmd=${cmd:$((varlen+1))}
                arg=$(echo "$arg" | tr ',' ' ')
                arg=$(echo "$arg" | tr '\q' ',')
                echo "$var=\$($cmd $arg)" >> $file
            else
                echo "$cmd" >> $file
            fi
        else
            echo "Variable $var has not been defined as an Integer."
            rm -f ~/.aqs/.defints
            rm -f ~/.aqs/.defstrings
            echo "Compile failed."
            exit 1
        fi
    fi
}

function intadder() {
    cmd=${cmd:4}
    if [[ $cmd == "_"* && $cmd == *"_" && $cmd != *"!"* && $cmd != *"="* && $cmd != *";"* ]]
    then
        echo $cmd >> ~/.aqs/.defints
        echo "$cmd=null" >> $file
    else
        echo "$cmd is not a secure Label."
        rm -f ~/.aqs/.defints
        rm -f ~/.aqs/.defstrings
        echo "Compile failed."
        exit 1
    fi
}

function stringadder() {
    cmd=${cmd:7}
    if [[ $cmd == "_"* && $cmd == *"_" && $cmd != *"!"* && $cmd != *"="* && $cmd != *";"* ]]
    then
        echo $cmd >> ~/.aqs/.defstrings
        echo "$cmd=null" >> $file
    else
        echo "$cmd is not a secure Label."
        rm -f ~/.aqs/.defints
        rm -f ~/.aqs/.defstrings
        echo "Compile failed."
        exit 1
    fi
}

if [[ $comp_args == "-"* && $comp_args == *"c"* ]]
then
    lastchar=$(tail -c -1 $comp_infile | head -1)
    #echo $lastchar
    if [ -z $lastchar ]
    then
        true
    else
        echo "" >> $comp_infile
    fi

    while read line
    do
        if [[ $line == "func main() [" && $has_main != 1 ]]
        then
            has_main=1
        fi
    done < $comp_infile

    if [[ $has_main != 1 && $comp_extras != "--supressMainWarnings" ]]
    then
        echo "No main() Function specified!"
        rm -f ~/.aqs/.defints
        rm -f ~/.aqs/.defstrings
        echo "Compile failed."
        exit 1
    fi

    while read line
    do
        sleep 0.1
        cmd=$line
        if [[ $cmd == "" ]]
        then
            true
        else
        if [[ $cmd != "#"* ]]
        then

        if [[ $cmd == "import<"*">" && $is_in_func == "0" ]]
        then
            importhandler $comp_args
        elif [[ $cmd == "pack<"*">"  && $is_in_func == "0" ]]
        then
            packhandler $cmd
        elif [[ $cmd == "if"* && $cmd == *"{" && $is_in_func == "1" ]]
        then
            ifhandler
        elif [[ $cmd == "} else if"* && $cmd == *"{" && $is_in_func == "1" ]]
        then
            elifhandler
        elif [[ $cmd == "} else {" && $is_in_func == "1" ]]
        then
            elsehandler
        elif [[ $cmd == "}" && $is_in_func == "1" ]]
        then
            echo "fi" >> $file

        elif [[ $cmd == "while"* && $cmd == *"{{" && $is_in_func == "1" ]]
        then
            whilehandler
        elif [[ $cmd == "for"* && $cmd == *"{{" && $is_in_func == "1" ]]
        then
            forhandler
        elif [[ $cmd == "}}" && $is_in_func == "1" ]]
        then
            echo "done" >> $file
        elif [[ $cmd == "func "* && $cmd == *"[" && $is_in_func == "0" ]]
        then
            is_in_func=1
            funchandler
        elif [[ $cmd == "]" && $is_in_func == "1" ]]
        then
            is_in_func=0
            echo "}" >> $file
        elif [[ $cmd == "int "* && $is_in_func == "0" ]]
        then
            intadder
        elif [[ $cmd == "string "* && $is_in_func == "0" ]]
        then
            stringadder
        elif [[ $cmd == "_"* && $is_in_func == "1" ]]
        then
            varhandler
        elif [[ $is_in_func == "1" ]]
        then
            if [[ $cmd == *"("*")" ]]
            then
                #echo $cmd
                arg=${cmd%?}
                cmd="${cmd%(*}"
                #echo $cmd
                cmdlen=${#cmd}
                #echo $cmdlen
                arg=${arg:$((cmdlen+1))}
                echo "$cmd\c" >> $file
                arg=$(echo "$arg" | tr ',' ' ')
                arg=$(echo "$arg" | tr '\q' ',')
                arg=${arg//__args1__/"\$1"}
                arg=${arg//__args2__/"\$2"}
                arg=${arg//__args3__/"\$3"}
                arg=${arg//__args4__/"\$4"}
                arg=${arg//__args5__/"\$5"}
                arg=${arg//__args6__/"\$6"}
                arg=${arg//__args7__/"\$7"}
                arg=${arg//__args8__/"\$8"}
                arg=${arg//__args9__/"\$9"}
                #echo $arg
                echo " $arg" >> $file
            fi
        fi

        fi
        fi
    done < $comp_infile
    if [[ $comp_extras != "--supressMainWarnings" ]]
    then
        echo "main \$1 \$2 \$3 \$4 \$5 \$6 \$7 \$8 \$9" >> $file
    fi
    echo "$comp_infile compiled to $file with no errors."
    rm -f ~/.aqs/.defints
    rm -f ~/.aqs/.defstrings
    if [[ $comp_args == *"x"* ]]
    then
        infile=$file
        outfile=${file%.*}
        outfile=$outfile.aqs
        if shc -r -o $outfile -f $infile
        then
            echo "$infile compiled to $outfile."
        else
            echo "Error compiling $infile."
        fi
    fi
fi
