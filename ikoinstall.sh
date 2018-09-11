#!/bin/bash

IKIO_VERSION=0.1
IKIO_OS=`cat /etc/os-release | grep ^ID= | cut -d "=" -f 2`
IKIO_OS_VERSION=`cat /etc/os-release | grep VERSION_ID= | cut -d "=" -f 2 | cut -d "\"" -f 2`
IKIO_OS_VERSION_CODENAME=`cat /etc/os-release | grep VERSION_CODENAME= | cut -d "=" -f 2 | cut -d "\"" -f 2`



P_ODOO_VERSION=11
P_ADMIN_PASSWORD=admin
P_USERNAME=$USER
P_PASSWORD=$USER
P_LOCALE="fr_FR.UTF-8"
P_LOCALE_LANG=(${P_LOCALE//./ })
P_DEBUG=
SCRIPT_COMMAND=


#
# Test shell and exec environment compliance
#
function test_script_prerequisites {
    getopt --test > /dev/null
    if [[ $? -ne 4 ]]; then
        echo "Required getopt is not available. Execution aborted."
        exit 1
    fi
    whotest[0]="test" || (echo 'Required Arrays are not supported in this version of bash. Execution aborted.' && exit 2)
}


#
# installs all packages on ubuntu 18.04/bionic appart from postgresql
function install_packages_ubuntu_xenial {
    sudo apt-get update
    sudo apt-get install -y libsasl2-dev python-dev libldap2-dev libssl-dev
 
    sudo apt install -y libz-dev gcc
    sudo apt install -y libxml2-dev libxslt1-dev
    sudo apt install -y libpq-dev
    sudo apt install -y libldap2-dev libsasl2-dev
    sudo apt install -y libjpeg-dev libfreetype6-dev liblcms2-dev
    sudo apt install -y libopenjpeg5 libopenjpeg-dev
    sudo apt install -y libwebp5  libwebp-dev
    sudo apt install -y libtiff-dev
    sudo apt install -y libyaml-dev
    sudo apt install -y bzr mercurial git
    sudo apt install -y curl htop vim tmux
    sudo apt install -y supervisor
    sudo apt install -y libbz2-dev    
    sudo apt install -y libreadline-dev 
    sudo apt install -y libsqlite3-dev
}






#
#
function install_odoo {
    # TODO: Rework this test
    if [ -d py36 ]; then
        echo "install.sh has already been launched."
        echo "So you must either use bin/buildout to update or launch \"install.sh reset\" to remove all buildout installed items."
        exit -1
    fi
    python3 -m venv py36
    py36/bin/pip install --upgrade pip
    py36/bin/pip install --upgrade setuptools==33.1.1
    py36/bin/pip install zc.buildout==2.11.1
    py36/bin/pip install $PYPI_INDEX cython==0.26
    py36/bin/buildout

    # generate buildout.cfg
    if [ ! -f buildout.cfg ]; then    
        cat > buildout.cfg <<EOT 
[buildout]
extends = appserver.cfg

[openerp]
options.admin_passwd = ${P_ADMIN_PASSWORD}
options.db_user = ${P_USERNAME}
options.db_password = ${P_PASSWORD}
options.db_host = 127.0.0.1
options.xmlrpc_port = 8080    
EOT
    fi
    
    if [ $IKIO_OS == "Darwin" ]; then
        echo "Running on Darwin."
        py27/bin/pip install python-ldap==2.4.28 --global-option=build_ext --global-option="-I$(xcrun --show-sdk-path)/usr/include/sasl"
    fi    
    # We install pyusb here it fails with buildout
    #py36/bin/pip install $PYPI_INDEX pyusb==1.0.0
    #py36/bin/pip install $PYPI_INDEX num2words==0.5.4
    echo
    echo "Your commands are now available in ./bin"
    echo "Python is in ./py36. Don't forget to launch 'source py36/bin/activate'."
    echo 
}

##
# Removes all buildout files for a clean restart
#
function reset_odoo {
    echo "Removing all buidout generated items..."
    echo "    Not removing downloads/ and eggs/ for performance reason."
    rm -rf .installed.cfg
    rm -rf bin/
    rm -rf develop-eggs/
    rm -rf develop-src/
    rm -rf etc/
    rm -rf py36/
    rm -rf bootstrap.py
    rm -rf eggs/
    echo "    Done."
}






function print_prolog {
    echo 
    echo "ikoinstall.sh version $IKIO_VERSION"
    echo "(c) 2018 Cyril MORISSE / @cmorisse"
    echo 
}

function print_intro_message {
    echo " use ikoinstall.sh help for usage instructions."
    echo 
}

function print_help_message {
    echo "Usage: ./ikoinstall.sh {options} command"
    echo
    echo "Available options:"
    echo "  -O/--odoo-version   Odoo version to install: 8, 9, 10 or 11 (default=$P_ODOO_VERSION)"
    echo "  -A/--admin-password Odoo admin password for buildout.cfg (default=$P_USERNAME)"
    echo "  -U/--username       PostgreSQL username used in buildout.cfg (default=$P_USERNAME)"
    echo "  -W/--password       PostgreSQL password used in buildout.cfg (default=$P_PASSWORD)"
    echo "  -L/--locale         PostgreSQL Locale used (default=$P_LOCALE)"
    echo "  -D/--debug          Displays debugging information"
    echo    
    echo "Available commands:"
    echo "   help               Prints this message."
    echo "   prerequisites      Installs system prerequisites specific to \"$IKIO_OS $IKIO_OS_VERSION\""
    echo "   odoo               Installs Odoo."
    echo "   dependencies       Installs dependencies specific to this project."
    echo "   reset              Remove all buildout installed files."
    echo 
    exit
}

function parseargs {
    #
    # Defined support options and use getopts to parse parameters
    #
    OPTIONS=O:U:W:L:D
    LONG_OPTIONS=odoo-version:,username:,password:,locale:debug
    
    PARSED=$(getopt --options=$OPTIONS --longoptions=$LONG_OPTIONS --name "$0" -- "$@")
    if [[ $? -ne 0 ]]; then
        # e.g. $? == 1
        #  then getopt has complained about wrong arguments to stdout
        exit 2
    fi
    
    # 
    # process getopts recognized options until we see -- 
    #
    eval set -- "$PARSED"
    while true; do
        case "$1" in
            -O|--odoo-version)
                P_ODOO_VERSION="$2"
                shift 2
                ;;
            -U|--username)
                P_USERNAME="$2"
                P_PASSWORD="$2"
                shift 2
                ;;
            -W|--password)
                P_PASSWORD="$2"
                shift 2
                ;;
            -L|--locale)
                P_LOCALE="$2"
                P_LOCALE_LANG=(${P_LOCALE//./ })                
                shift 2
                ;;
            -D|--debug)
                P_DEBUG=true
                shift
                ;;
            --)
                shift
                break
                ;;
            *)
                echo "Script Internal Error"
                exit 3
                ;;
        esac
    done
    
    #
    # now process commands
    #
    for i in "$@" ; do
        case $i in
            #
            # Commands
            #
            help)  # Install odoo command
            SCRIPT_COMMAND=print_help_message
            shift # past argument with no value
            ;;
            odoo)  # Install odoo command
            SCRIPT_COMMAND=install_odoo
            shift # past argument with no value
            ;;
            reset)  # Reset odoo install
            SCRIPT_COMMAND=reset_odoo
            shift # past argument with no value
            ;;
            prerequisites)  # Install odoo command
            SCRIPT_COMMAND=install_prerequisites
            shift # past argument with no value
            ;;
            dependencies)  # Install odoo command
            SCRIPT_COMMAND=install_dependencies
            shift # past argument with no value
            ;;
            devtest)  # This is an undocumented command used for script writing and debugging
            SCRIPT_COMMAND=dev_test
            shift # past argument with no value
            ;;
            *)
                echo "Unrecognized command: \"$1\" aborting."
                exit 3
            ;;
        esac
    done
    
    if [ -z $SCRIPT_COMMAND ]; then # string length is 0
    #then 
        SCRIPT_COMMAND=print_intro_message
    fi

    if [ $P_DEBUG ]; then
        echo "debug: PARSED=${PARSED}"
        echo "debug: P_ODOO_VERSION     = ${P_ODOO_VERSION}"
        echo "debug: P_LOCALE           = ${P_LOCALE}"
        echo "debug: P_LOCALE_LANG      = ${P_LOCALE_LANG}"
        echo "debug: P_USERNAME         = ${P_USERNAME}"
        echo "debug: P_PASSWORD         = ${P_PASSWORD}"
        echo "debug: P_DEBUG            = ${P_DEBUG}"
        echo "debug: SCRIPT_COMMAND     = ${SCRIPT_COMMAND}"
        echo "debug: IKIO_OS            = ${IKIO_OS}"
        echo "debug: IKIO_OS_VERSION    = ${IKIO_OS_VERSION}"
    fi
}


# We need to add P_LOCALE as we will use it to install postgresql

function setup_locale {

    # Add the locale
    sudo locale-gen $P_LOCALE_LANG $P_LOCALE
    sudo update-locale    
    
    # Update bashrc with locale if needed
#    if grep -Fxq "# Added by inouk Odoo install.sh" $HOME/.bashrc ; then
#        echo "Skipping $HOME/.bashrc update"
#    else
#        cat >> /home/ubuntu/.bashrc <<EOT
#
## Added by inouk Odoo install.sh
#export LANG=fr_FR.UTF-8
#export LANGUAGE=fr_FR
#export LC_ALL=fr_FR.UTF-8
#export LC_CTYPE=fr_FR.UTF-8
#EOT
#    fi
    
}

#
# installs all packages on ubuntu 18.04/bionic appart from postgresql
function install_packages_ubuntu_bionic {
    sudo apt-get update
    sudo apt-get install -y libsasl2-dev python-dev libldap2-dev libssl-dev
 
    sudo apt install -y libz-dev gcc
    sudo apt install -y libxml2-dev libxslt1-dev
    sudo apt install -y libpq-dev
    sudo apt install -y libldap2-dev libsasl2-dev
    sudo apt install -y libjpeg-dev libfreetype6-dev liblcms2-dev
    sudo apt install -y libopenjp2-7 libopenjp2-7-dev
    sudo apt install -y libwebp5  libwebp-dev
    sudo apt install -y libtiff-dev
    sudo apt install -y libffi-dev
    sudo apt install -y libyaml-dev
    sudo apt install -y bzr mercurial git
    sudo apt install -y curl htop vim tmux
    sudo apt install -y supervisor
}

#
# installs postgresql ubuntu / debian repository
#
function install_postgresql_repository_ubuntu {
    wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -
    #TODO: test wether apr.postgresql.org is already in pgdg list
    # grep "apt.postgresql.org" /etc/apt/sources.list.d/pgdg.list
    grep "apt.postgresql.org" /etc/apt/sources.list.d/pgdg.list
    if [ $? -gt 0 ]
    then
        echo "Installing Postgresql"
        sudo sh -c "echo \"deb http://apt.postgresql.org/pub/repos/apt/ ${IKIO_OS_VERSION_CODENAME}-pgdg main\" >> /etc/apt/sources.list.d/pgdg.list"
        sudo apt-get update
    fi
    
    # Now we must delete default cluster and recreate one using provided locale
        sudo apt-get install postgresql postgresql-contrib
    
}

#
# installs postgresql on ubuntu bionic
# For bionic default postgresql version is 10
#
function install_postgresql_ubuntu_bionic {
    
    # To test wether a version is install
    # if [ -f /usr/lib/postgresql/9.5/bin/postgres ]; then
    # ...
    # fi
    
    
    # if version 10
    sudo apt-get install postgresql postgresql-contrib

    #else  
    #sudo apt-get install postgresql-9.x postgresql-9.x-contrib


    # TODO: Now we must delete default cluster and recreate one using provided locale
    
}

# installs all system prerequistes
function install_prerequisites {
    #setup_locale
    #install_packages_${IKIO_OS}_${IKIO_OS_VERSION_CODENAME}
    #install_postgresql_repository_${IKIO_OS}
    install_postgresql_${IKIO_OS}_${IKIO_OS_VERSION_CODENAME}
    
}




function dev_test {
    P_LOCALE_LANG=(${P_LOCALE//./ })
    echo "\"${P_LOCALE_LANG}\""
}





test_script_prerequisites
print_prolog
# call parseargs passing it all parameters received from 
parseargs $@
$SCRIPT_COMMAND


