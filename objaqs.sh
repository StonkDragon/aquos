#! /bin/bash
comp_args=$1
comp_infile=$2
comp_extras=$3

is_in_func=0
is_in_object=0
new_object_possible=1
has_struct=0

shc_installed=$(which shc)

if [ -z $shc_installed ]
then
    echo "Please install shc."
    exit 0
fi

if [ -z $comp_infile ]
then
    echo "No File specified!"
    echo "Compile failed."
    rm -f ~/.aqs/consts.txt
    exit 1
else
    if [[ $comp_args = "-"* && $comp_args == *"c"* ]] && [[ $comp_args != *"p"* ]]
    then
        file="${2%%\.*}"
        file=$file.objcaqs
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

function objecthandler() {
    cmd=${cmd:7}
    cmd=${cmd%??}
    comp_object_name=$cmd
}

function illegaloperation() {
    echo "Illegal Operation: $line"
    echo "Compile failed."
    rm -f ~/.aqs/consts.txt
    exit 1
}

function invalidsyntax() {
    echo "Invalid Syntax: $line"
    echo "Compile failed."
    rm -f ~/.aqs/consts.txt
    exit 1
}

function nomain() {
    echo "No main() Function specified. Run with --supressMainWarnings to ignore this."
    echo "Compile failed."
    rm -f ~/.aqs/consts.txt
    exit 1
}

function packhandler() {
    cmd="${cmd%%\>*}"
    cmd="${cmd:5}"
    echo "Packing $cmd"
    cmd=$(echo "$cmd" | tr '.' '/')
    if [ -f src/$cmd.objcaqs ]
    then
        echo "source $cmd.objcaqs" >> $file
    else
        echo "source $cmd.caqs" >> $file
    fi
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
    cmd=${cmd//>=/-ge}
    cmd=${cmd//<=/-le}
    cmd=${cmd//</-lt}
    cmd=${cmd//>/-gt}
    echo "if [[ $cmd ]]" >> $file
    echo "then" >> $file
}

function tryhandler() {
    cmd=${cmd:4}
    arg=${cmd%?}
    cmd="${cmd%(*}"
    cmdlen=${#cmd}
    arg=${arg:$((cmdlen+1))}
    arg=${arg//;/ }
    arg=${arg//_§1_/"\$1"}
    arg=${arg//_§2_/"\$2"}
    arg=${arg//_§3_/"\$3"}
    arg=${arg//_§4_/"\$4"}
    arg=${arg//_§5_/"\$5"}
    arg=${arg//_§6_/"\$6"}
    arg=${arg//_§7_/"\$7"}
    arg=${arg//_§8_/"\$8"}
    arg=${arg//_§9_/"\$9"}
    echo "if $cmd $arg" >> $file
    echo "then" >> $file
    echo "true" >> $file
}

function whilehandler() {
    cmd="${cmd%%\)*}"
    cmd2=${cmd%\(*}
    cmdlen=${#cmd2}
    cmd="${cmd:$((cmdlen+1))}"
    cmd=${cmd//==/-eq}
    cmd=${cmd//!=/-ne}
    cmd=${cmd//>=/-ge}
    cmd=${cmd//<=/-le}
    cmd=${cmd//</-lt}
    cmd=${cmd//>/-gt}
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
        echo "function $comp_object_name.$cmd2() {" >> $file
    else
        invalidsyntax $line
    fi
}

function structhandler() {
    cmd="${cmd%\(*}"
    cmd2=${cmd:7}
    if [[ $cmd2 != "_"* && $cmd2 != *"_" && $cmd2 == $comp_object_name ]]
    then
        echo "function $comp_object_name() {" >> $file
    else
        invalidsyntax $line
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
    cmd=${cmd//>=/-ge}
    cmd=${cmd//<=/-le}
    cmd=${cmd//</-lt}
    cmd=${cmd//>/-gt}
    echo "elif [[ $cmd ]]" >> $file
    echo "then" >> $file
}

function elsehandler() {
    echo "else" >> $file
}

function varhandler() {
    var="${cmd%=*}"
    #echo $var
    val=${#var}
    #echo $val
    val="${cmd:$((val+1))}"
    #echo $val
    if grep -Fqs "$var" ~/.aqs/consts.txt
    then
        illegaloperation $line
    else
        if [[ $val == "\""*"\"" ]]
        then
            echo $cmd >> $file
        elif [[ $val == *"("*")" ]]
        then
            arg=${cmd%?}
            cmd="${cmd%(*}"
            cmdlen=${#cmd}
            varlen=${#var}
            arg=${arg:$((cmdlen+1))}
            cmd=${cmd:$((varlen+1))}
            arg=${arg//;/ }
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
            echo "$var=\$(($val))" >> $file
        fi
    fi
}

function varadder() {
    cmd=${cmd:4}
    cmd2=$cmd
    cmd=${cmd%=*}
    cmdlen=${#cmd}
    valu=${cmd2:$((cmdlen+1))}
    if [ -z $valu ]
    then
        valu=null
    fi
    if [[ $cmd == "_"* && $cmd == *"_" && $cmd != *"§"* ]]
    then
        echo "$cmd=$valu" >> $file
    else
        illegaloperation $line
    fi
}

function constadder() {
    cmd=${cmd:6}
    cmd2=$cmd
    cmd=${cmd%=*}
    cmdlen=${#cmd}
    valu=${cmd2:$((cmdlen+1))}
    if [ -z $valu ]
    then
        valu=null
    fi
    if [[ $cmd == "_"* && $cmd == *"_" && $cmd != *"§"* ]]
    then
        echo $cmd >> ~/.aqs/consts.txt
        echo "$cmd=$valu" >> $file
    else
        invalidsyntax $line
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
        nomain
    fi

    while read line
    do
        sleep 0.1
        cmd=$line
        cmd=${cmd//_§1_/"\$1"}
        cmd=${cmd//_§2_/"\$2"}
        cmd=${cmd//_§3_/"\$3"}
        cmd=${cmd//_§4_/"\$4"}
        cmd=${cmd//_§5_/"\$5"}
        cmd=${cmd//_§6_/"\$6"}
        cmd=${cmd//_§7_/"\$7"}
        cmd=${cmd//_§8_/"\$8"}
        cmd=${cmd//_§9_/"\$9"}
        if [[ $cmd == "" ]]
        then
            true
        else
        if [[ $cmd != "#"* ]]
        then

        if [[ $cmd == "import<"*">" && $is_in_func == "0" && $is_in_object == "0" ]]
        then
            importhandler $comp_args
        elif [[ $cmd == "pack<"*">"  && $is_in_func == "0" && $is_in_object == "0" ]]
        then
            packhandler $cmd
        elif [[ $cmd == "if"* && $cmd == *"{" && $is_in_func == "1" && $is_in_object == "1" ]]
        then
            ifhandler
        elif [[ $cmd == "object"* && $cmd == *"(" && $is_in_func == "0" && $is_in_object == "0" && $new_object_possible == "1" ]]
        then
            is_in_object=1
            new_object_possible=0
            objecthandler
        elif [[ $cmd == "try "* && $is_in_func == "1" && $is_in_object == "1" ]]
        then
            tryhandler
        elif [[ $cmd == "} else if"* && $cmd == *"{" && $is_in_func == "1" && $is_in_object == "1" ]]
        then
            elifhandler
        elif [[ $cmd == "} else {" && $is_in_func == "1" && $is_in_object == "1" ]]
        then
            elsehandler
        elif [[ $cmd == "}" && $is_in_func == "1" && $is_in_object == "1" ]]
        then
            echo "fi" >> $file
        elif [[ $cmd == ")" && $is_in_func == "0" && $is_in_object == "1" ]]
        then
            is_in_object=0
        elif [[ $cmd == "while"* && $cmd == *"{{" && $is_in_func == "1" && $is_in_object == "1" ]]
        then
            whilehandler
        elif [[ $cmd == "for"* && $cmd == *"{{" && $is_in_func == "1" && $is_in_object == "1" ]]
        then
            forhandler
        elif [[ $cmd == "}}" && $is_in_func == "1" && $is_in_object == "1" ]]
        then
            echo "done" >> $file
        elif [[ $cmd == "func "* && $cmd == *"[" && $is_in_func == "0" && $is_in_object == "1" ]]
        then
            is_in_func=1
            funchandler
        elif [[ $cmd == "struct "* && $cmd == *"[" && $is_in_func == "0" && $is_in_object == "1" && $has_struct == "0" ]]
        then
            is_in_func=1
            has_struct=1
            structhandler
        elif [[ $cmd == "]" && $is_in_func == "1" && $is_in_object == "1" ]]
        then
            is_in_func=0
            echo "}" >> $file
        elif [[ $cmd == "var "* && $is_in_func == "0" && $is_in_object == "1" ]]
        then
            varadder
        elif [[ $cmd == "const "* && $is_in_func == "0" && $is_in_object == "1" ]]
        then
            constadder
        elif [[ $cmd == "_"* && $is_in_func == "1" && $is_in_object == "1" ]]
        then
            varhandler
        elif [[ $is_in_func == "1" && $is_in_object == "1" ]]
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
                arg=${arg//;/ }
                arg=${arg//_§1_/"\$1"}
                arg=${arg//_§2_/"\$2"}
                arg=${arg//_§3_/"\$3"}
                arg=${arg//_§4_/"\$4"}
                arg=${arg//_§5_/"\$5"}
                arg=${arg//_§6_/"\$6"}
                arg=${arg//_§7_/"\$7"}
                arg=${arg//_§8_/"\$8"}
                arg=${arg//_§9_/"\$9"}
                #echo $arg
                echo " $arg" >> $file
            fi
        else
            echo Is in Function: $is_in_func
            echo Is in Object: $is_in_object
            echo Has Main: $has_main
            echo Has Struct: $has_struct
            invalidsyntax $line
        fi

        fi
        fi
    done < $comp_infile
    echo $comp_object_name >> $file
    echo "$comp_infile compiled to $file with no errors."
    rm -f ~/.aqs/consts.txt
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
