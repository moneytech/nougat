#!/bin/bash

# Nougat version 2

# All features from nougat 1
# ~/.config/nougat

saveourship(){

   echo -e  "Nougat - screenshot wrapper created to help organize screenshots\n"
   echo -e  " -h - Saves our ship.\n"
   echo     " -s - Silent. By default, nougat will output the path to the file to STDOUT."
   echo -e  "              This is to make it easier to implement into other file uploaders.\n"
   echo     " -t - Places screenshot into /tmp"
   echo -e  "      (useful if you only need a quick screenshot to send to a friend)\n"
   echo -e  " -f - Takes a full screen screenshot (default is select area)\n"
   echo -e  " -c - Puts the screenshot into your clipboard\n"
   echo     " -b - Select backend to use"
   echo -e  "              Supported backends are \`maim', \`scrot', and \`imagemagick'."
   echo -e  "              nougat will detect available backends if -b"
   echo -e  "              is not specified. nougat prefers maim to scrot and imagemagick.\n"
   echo     " -p - Cleans the link directory of Nougat based on the linking policy."
   echo     "              Particularly useful as it cleans any links that no"
   echo -e  "              longer point to a screenshot (i.e. deleted screeenshot).\n"

}

temporary=false
clean=false
silent=false
fullscreen=false
copytoclipboard=false
backend=""

backends=('maim' 'scrot' 'imagemagick')

### BACKENDS

maimbackend(){
    require maim

    maimopts=''

    [[ "$fullscreen" == false ]] && maimopts=-s
    maimopts="$maimopts --hidecursor"

    command maim $maimopts /tmp/nougat_temp.png
}

scrotbackend(){
    require scrot
    
    scrotopts=''

    [[ "$fullscreen" == false ]] && scrotopts=-s

    command scrot $scrotopts /tmp/nougat_temp.png
}

imagemagickbackend(){
    require import

    importopts=''

    if [[ "$fullscreen" == false ]]
    then
        require slop

        slop=$(command slop -qof '%wx%h+%x+%y')

        [[ -n $slop ]] && importopts="-crop $slop"
    fi

    command import -window root $importopts /tmp/nougat_temp.png
}

### END BACKENDS

nobackend(){
    if [[ -z $backend ]]
    then
        return 0
    else
        return 1
    fi
}

testfor() {
    command -v "$1" &> /dev/null
    return "$?"
}

require(){
    command -v "$1" &> /dev/null
    if [[ "$?" != 0 ]]
    then
        echo "$1 is not installed and is required"
        exit 1
    fi
}

getconfigdir(){

    CONFIG_DIR="$XDG_CONFIG_HOME"

    if [[ ! -d $CONFIG_DIR ]]
    then
        CONFIG_DIR="$HOME/.config"
    fi

    echo "$CONFIG_DIR"

}

getcanonicals(){

    read -r year month day hour minute second <<< "$(date +'%Y %B %d %H %M %S')"

    suffix=''
    if [[ "$fullscreen" == true ]]
    then
        suffix=_full
    fi

    source "$(getconfigdir)/nougat"

    ORG_FULLPATH="$NOUGAT_SCREENSHOT_DIRECTORY/$NOUGAT_ORGANIZATION_POLICY"
    [[ -n $NOUGAT_LINKING_POLICY ]] && \
      LINK_FULLPATH="$NOUGAT_SCREENSHOT_DIRECTORY/$NOUGAT_LINKING_POLICY" || \
      LINK_FULLPATH=""

    echo "$(dirname "$ORG_FULLPATH")" \
        "$(basename "$ORG_FULLPATH")" \
        "$([[ -n $LINK_FULLPATH ]] && dirname  "$LINK_FULLPATH")" \
        "$([[ -n $LINK_FULLPATH ]] && basename "$LINK_FULLPATH")"

}

init() {

    CONFIG_DIR=$(getconfigdir)

    if [[ ! -f $CONFIG_DIR/nougat ]]
    then
        mkdir -p "$CONFIG_DIR"

        if [[ -n $NOUGAT_SCREENSHOT_DIRECTORY ]]
        then
            # Support for V1 configurations
            echo 'NOUGAT_SCREENSHOT_DIRECTORY="'"$NOUGAT_SCREENSHOT_DIRECTORY"'"' > "$CONFIG_DIR/nougat"
        else
            echo 'NOUGAT_SCREENSHOT_DIRECTORY="$HOME/Screenshots"' > "$CONFIG_DIR/nougat"
        fi

        cat >> "$CONFIG_DIR/nougat" << EOF
NOUGAT_ORGANIZATION_POLICY="\${year}/\${month}/\${day}/\${hour}:\${minute}:\${second}\${suffix}"
NOUGAT_LINKING_POLICY="All/\${year}-\${month}-\${day}.\${hour}:\${minute}:\${second}\${suffix}"
EOF
    fi

    while getopts 'hstfcpu b:S:' option
    do
        case $option in
            h)
                saveourship
                exit 0
                ;;
            b)
                setbackend $OPTARG
                ;;
            # Hide cursor
            p)
                clean=true
                ;;
            s)
                silent=true
                ;;
            t)
                temp=true
                ;;
            c)
                copytoclipboard=true
                ;;
            f)
                fullscreen=true
                ;;
        esac
    done

    local exitcode; exitcode="$?"

    nobackend && \
        testfor maim && backend=maim && return "$exitcode"

    nobackend && \
        testfor scrot && backend=scrot && return "$exitcode"

    nobackend && \
        testfor import && backend=imagemagick && return "$exitcode"

}

setbackend(){

    supported=false

    for (( index=0; index<${#backends}; index++ ))
    do
        if [[ ${backends[$index]} == "$1" ]]
        then
            supported=true
            break
        fi
    done

    if [[ "$supported" == false ]]
    then
        echo "Unsupported backend $1"
        exit 1
    fi

    cmd="$1"

    [[ "$cmd" == imagemagick ]] && cmd=import

    testfor $cmd && \
        backend="$1"

}

runbackend(){
    case $backend in
        maim)
            maimbackend
            ;;
        scrot)
            scrotbackend
            ;;
        imagemagick)
            imagemagickbackend
            ;;
        *)
            echo 'No supported backend found'
            exit 1
            ;;
    esac

    [[ ! -f /tmp/nougat_temp.png ]] && exit 0
}

organize(){

    read -r fullpath filename linkpath linkname <<< "$(getcanonicals)"

    if [[ "$copytoclipboard" == true ]]
    then
        require xclip
        xclip -selection clipboard -t image/png /tmp/nougat_temp.png
    fi

    if [[ "$temp" == true ]]
    then
        [[ "$silent" == false ]] && \
            echo "/tmp/$linkname.png"
        mv /tmp/nougat_temp.png "/tmp/$linkname.png"
        exit 0
    fi

    mkdir -p "$fullpath"
    [[ -n $linkpath ]] && mkdir -p "$linkpath"

    mv /tmp/nougat_temp.png "$fullpath/$filename.png"
    [[ -n $linkpath ]] && ln -s "$fullpath/$filename.png" "$linkpath/$linkname.png"

    [[ $silent == false ]] && \
        echo "$fullpath/$filename.png"

    exit 0
}

clean(){
    source ~/.config/nougat

    linkdir=$(dirname "$NOUGAT_SCREENSHOT_DIRECTORY/$NOUGAT_LINKING_POLICY")
    [[ "$silent" = false ]] && echo "$linkdir"

    [[ ! -d $linkdir ]] || [[ $(ls -1 "$linkdir" | wc -l) -eq 0 ]] && return 0

    for file in "$linkdir/"*
    do
        link=$(readlink -f "$file")

        if [[ ! -f $link ]] ; then rm "$file"; fi

    done
}

screenshot(){
    runbackend
    organize
}

init "$@"

if [[ "$clean" == true ]]
then
    clean
    x="$?"
  
    if [[ $# -eq 1 ]]
    then
        [[ "$1" == -p ]] || [[ "$1" == -ps ]] || [[ "$1" == -sp ]] && exit "$x"
    fi
  
    if [[ $# -eq 2 ]]
    then
        if [[ "$1" == -p ]] || [[ "$1" == -s ]]
        then
            [[ "$2" == -p ]] || [[ "$2" == -s ]] && exit "$x"
        fi
    fi
fi

screenshot
