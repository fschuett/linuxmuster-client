# turn logging on/off
LOGGING=false

# functions
log_msg() {
    logger -t "$0" "$1 $2"
}

run_hook() {
    local script="$1"
    local exit_status
    shift   # discard the first argument, then the rest are the script's

    if [ -f $script ]; then
        . $script "$@"
    fi

    if [ -n "$exit_status" ] && [ "$exit_status" -ne 0 ]; then
        logger -p daemon.err "$script returned non-zero exit status $exit_status"
        save_exit_status=$exit_status
    fi

    return $exit_status
}

run_hookdir() {
    local dir="$1"
    local exit_status
    shift   # See run_hook

    if [ -d "$dir" ]; then
        for script in $(find $dir -maxdepth 1 -type f -executable | sort); do
            run_hook $script "$@" || true
            exit_status=$?
        done
    fi

    return $exit_status
}

showinfo() {
    local file="$1"
    [ -e "$file" ] || log_msg showinfo "$file existiert nicht"
    [ -e "$file" ] && log_msg showinfo "$file existiert"
    [ -f "$file" ] && log_msg showinfo "$file existiert und ist eine normale Datei"
    [ -d "$file" ] && log_msg showinfo "$file existiert und ist ein Verzeichnis"
    [ -L "$file" ] && log_msg showinfo "$file existiert und ist ein Link"
}

verlinke() {
    local ziel="$1"
    local quelle="$2"
    local exit_status
    $LOGGING && log_msg "Entering verlinke" "quelle=$quelle ziel=$ziel"
    
    if [ -L "$ziel" ]; then
	$LOGGING && log_msg "Entferne Link" "ziel=$ziel"
	rm -f "$ziel"
    elif [ -d "$ziel" ]; then
	$LOGGING && log_msg "Verschiebe Verzeichnis" "$ziel -> ${ziel}-entfernt"
	mv "$ziel" "${ziel}-entfernt"
	rm -f "$ziel"
    elif [ -f "$ziel" ]; then 
	$LOGGING && log_msg "Verschiebe Datei" "$ziel -> ${ziel}-entfernt"
	mv "$ziel" "${ziel}-entfernt"
	rm -f "$ziel"
    fi
    if [ -e "$quelle" ]; then
	$LOGGING && log_msg verlinke "quelle=$quelle ziel=$ziel"
	ln -s "$quelle" "$ziel"
	exit_status=$?
    fi

    return $exit_status
}

entferne() {
    local ziel="$1"
    local exit_status
    $LOGGING && log_msg "Entering entferne" "ziel=$ziel"
    
    if [ -L "$ziel" ]; then
	$LOGGING && log_msg "Entferne Link" "ziel=$ziel"
	rm -f "$ziel"
	exit_status=$?
    elif [ -d "$ziel" ]; then
	$LOGGING && log_msg "Entferne Verzeichnis" "$ziel"
	rmdir "$ziel"
    elif [ -f "$ziel" ]; then 
	$LOGGING && log_msg "Entferne Datei" "$ziel"
	rm "$ziel"
    else
	$LOGGING && log_msg "Datei?!" "$ziel nicht gefunden!"
	exit_status=1
    fi

    return $exit_status
}

erzeugeLeer() {
    local ziel="$1"
    local exit_status
    $LOGGING && log_msg "Entering erzeugeLeer" "ziel=$ziel"
    if [ -L "$ziel" ]; then
	rm -f $ziel
    elif [ -f "$ziel" ]; then
	mv "$ziel" "${ziel}-entfernt"
    elif [ -d "$ziel" ]; then
	for f in `ls "$ziel"`; do
	    $LOGGING && log_msg erzeugeLeer "ziel=$ziel Entferne Datei $f aus Zielverzeichnis"
	    entferne "$ziel/$f"
	done;
    fi
    mkdir -p "$ziel"
    chmod 777 "$ziel"
    
    return $exit_status
}

# Functions for use with the linuxmuster-client-profile package
# Frank Schiebel <frank@linuxmuster.net>
# 14.04.2012
# GPL v2

get_environment() {
    USER=$1
    VOLUME=$2
    MNTPT=$3
    SERVER=$4
    OPTIONS=$5

    local TEMP=`getent passwd $USER`

    NUMUID=`echo $TEMP | cut -d: -f 3`
    NUMPRIGID=`echo $TEMP | cut -d: -f 4`
    FULLNAME=`echo $TEMP | cut -d: -f 5`
    HOMEDIR=`echo $TEMP | cut -d: -f 6`
    LOGINSHELL=`echo $TEMP | cut -d: -f 7`
}

# Reads simple config file with one value per line,
# ignoring lines starting with a '#'
#
# @arg Configfile
# @ret White space separated list of items

read_simple_config() {
    configlines=$(egrep -v '^\s*#' $1)
    return $configlines
}
