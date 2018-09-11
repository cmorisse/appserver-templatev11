#!/bin/bash


PYPI_INDEX=""
BUILDOUT_INDEX=""

HELP=0

RUNNING_ON=$(uname) 

#
# We need bash
#
if [ -z "$BASH_VERSION" ]; then
    echo -e "Error: BASH shell is required !"
    exit 1
fi

#
# install_openerp
#
function install_openerp {
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

    
    if [ $RUNNING_ON == "Darwin" ]; then
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

function remove_buildout_files {
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




function setup_c9_aws {

    
    # Update bashrc with locale if not already done
    if grep -Fxq "# Added by appserver-templatevXX install.sh" /home/$USER/.bashrc ; then
        echo "Skipping /home/$USER/.bashrc update"
    else
        cat >> /home/ubuntu/.bashrc <<EOT
#
# Added by appserver-templatevXX install.sh
export LANG=fr_FR.UTF-8
export LANGUAGE=fr_FR
export LC_ALL=fr_FR.UTF-8
export LC_CTYPE=fr_FR.UTF-8
EOT
    fi
    
    sudo yum install -y htop
    sudo yum install -y libyaml-devel
    sudo yum install -y libxml2
    sudo yum install -y libxslt-devel
    sudo yum install -y libtiff-devel libjpeg-devel zlib-devel freetype-devel lcms2-devel libwebp-devel tcl-devel tk-devel
    sudo yum install -y postgresql96-devel.x86_64
    sudo yum install -y openldap-devel

    # lessc
    sudo npm config set registry http://registry.npmjs.org/
    sudo npm install -g less 
    sudo npm install -g less-plugin-clean-css
    sudo ln -fs /usr/lib/node_modules/less/bin/lessc /usr/bin/lessc    
    
    # wkhtmltopdf
    wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.1/wkhtmltox-0.12.1_linux-centos6-amd64.rpm
    sudo yum install -y wkhtmltox-0.12.1_linux-centos6-amd64.rpm
    rm wkhtmltox-0.12.1_linux-centos6-amd64.rpm
 
    # Install PostgreSQL 9.6
    if [ ! -f ~/.installsh.pg96 ]; then    

        sudo yum install -y postgresql96-server
        #sudo service postgresql96 initdb --locale=fr_FR.UTF-8
        sudo su - postgres -c 'initdb --locale=fr_FR.UTF8 --pgdata=/var/lib/pgsql96/data'
        sudo service postgresql96 start
        sudo chkconfig  postgresql96 on

        # sudo pg_dropcluster 9.3 main
        # sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main"
        # wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -    
        # sudo apt-get update
        # sudo apt-get install -y postgresql-9.6    
        # sudo pg_dropcluster 9.6 main
            
        # sudo pg_createcluster --locale fr_FR.UTF-8 9.6 main
        # sudo pg_ctlcluster 9.6 main start
        sudo su - postgres -c 'psql -c \"CREATE ROLE \"ec2-user\" WITH LOGIN SUPERUSER CREATEDB CREATEROLE PASSWORD 'ubuntu';\"'
        sudo su - postgres -c 'psql -c \"CREATE DATABASE \"ec2-user\";\"'

        touch ~/.installsh.pg96
    else
        echo "Skipping postgresql-9.6 install. Delete ~/.installsh.pg96 to force installation."
    fi    

    # create a basic buildout.cfg if none is found
    if [ ! -f buildout.cfg ]; then    
        cat >> buildout.cfg <<EOT 
[buildout]
extends = appserver.cfg

[openerp]
options.admin_passwd = admin
options.db_user = ec2-user
options.db_password = ec2-user
options.db_host = 127.0.0.1
options.xmlrpc_port = 8080    
EOT
    fi    

}











function setup_c9_trusty_blank_container {
    

    # Setup locale and update bashrc 
    if grep -Fxq "# Added by appserver-templatev11 install.sh" /home/$USER/.bashrc ; then
        echo "Skipping /home/$USER/.bashrc update"
    else

        # Set a UTF8 locale
        sudo locale-gen fr_FR fr_FR.UTF-8
        sudo update-locale    

        cat >> /home/ubuntu/.bashrc <<EOT
#
# Added by appserver-templatev11 install.sh
export LANG=fr_FR.UTF-8
export LANGUAGE=fr_FR
export LC_ALL=fr_FR.UTF-8
export LC_CTYPE=fr_FR.UTF-8

EOT
    fi

    # Install PostgreSQL 9.6
    if [ ! -f ~/.installsh.pg96 ]; then    

        sudo pg_dropcluster 9.3 main
        
        sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main"
        wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -    
        sudo apt-get update
        sudo apt-get install -y postgresql-9.6    
        sudo pg_dropcluster 9.6 main
            
        sudo pg_createcluster --locale fr_FR.UTF-8 9.6 main
        sudo pg_ctlcluster 9.6 main start
        sudo su - postgres -c "psql -c \"CREATE ROLE ubuntu WITH LOGIN SUPERUSER CREATEDB CREATEROLE PASSWORD 'ubuntu';\"" 
        sudo su - postgres -c "psql -c \"CREATE DATABASE ubuntu;\"" 

        touch ~/.installsh.pg96
    else
        echo "Skipping postgresql-9.6 install. Delete ~/.installsh.pg96 to force installation."
    fi    

    # create a basic buildout.cfg if none is found
    if [ ! -f buildout.cfg ]; then    
        cat >> buildout.cfg <<EOT 
[buildout]
extends = appserver.cfg

[openerp]
options.admin_passwd = admin
options.db_user = ubuntu
options.db_password = ubuntu
options.db_host = 127.0.0.1
options.xmlrpc_port = 8080    
EOT
    fi    
    
    # Node, lessc and plugin requies for Odoo
    if [ ! -f ~/.installsh.nodeplugins ]; then    
        sudo npm install -g less less-plugin-clean-css
        sudo ln -fs /usr/local/bin/lessc /usr/bin/lessc
        touch ~/.installsh.nodeplugins
    else
        echo "Skipping Odoo nodejs tools and plugins install. Delete ~/.installsh.nodeplugins to force installation."
    fi    

    # pyenv
    if [ ! -f ~/.installsh.pyenv ]; then
        git clone https://github.com/pyenv/pyenv.git ~/.pyenv
        sed -i.bak '/# If not running interactively/i #install.sh added pyenv\nexport PYENV_ROOT=\"$HOME/.pyenv\"\nexport PATH=\"$PYENV_ROOT/bin:$PATH\"\nif command -v pyenv 1>/dev/null 2>&1; then\n  eval \"$(pyenv init -)\"\nfi\n\n' ~/.bashrc
        source ~/.bashrc
        touch ~/.installsh.pyenv
    else
        echo "Skipping pyenv install. Delete ~/.installsh.pyenv to force installation."
    fi    

    # py36
    if [ ! -f ~/.installsh.py36 ]; then
        pyenv install 3.6.3
        pyenv local 3.6.3
        touch ~/.installsh.py36
        echo "Python 3.6.3 installed."
    else
        echo "Skipping Python 3.6.3 install. Delete ~/.installsh.py36 to force installation."
    fi    

    # install Cloud9's missing packages
    # sudo apt-get install -y libsasl2-dev python-dev libldap2-dev libssl-dev
    sudo apt-get install -y libldap2-dev libsasl2-dev

    echo
    echo
    echo "Reopen this Terminal and check python 3 is available by running 'python' before running ./install.sh openerp"
    echo
}


function setup_xenial {
    
    # Setup UTF8 locale
    sudo locale-gen fr_FR fr_FR.UTF-8
    sudo update-locale    
    
    # Update bashrc with locale if needed
    if grep -Fxq "# Locale setup - Added by appserver-templatevXX install.sh" /home/$USER/.bashrc ; then
        echo "Skipping /home/$USER/.bashrc update"
    else
        cat >> /home/ubuntu/.bashrc <<EOT
#
# Locale setup - Added by appserver-templatevXX install.sh
export LANG=fr_FR.UTF-8
export LANGUAGE=fr_FR
export LC_ALL=fr_FR.UTF-8
export LC_CTYPE=fr_FR.UTF-8
EOT
    fi
    
    # Refresh index and install required index
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

    # Install PostgreSQL 9.6
    if [ ! -f ~/.installsh.pg96 ]; then    

        sudo pg_dropcluster 9.3 main
        
        sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main"
        wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -    
        sudo apt-get update
        sudo apt-get install -y postgresql-9.6    
        sudo pg_dropcluster 9.6 main
            
        sudo pg_createcluster --locale fr_FR.UTF-8 9.6 main
        sudo pg_ctlcluster 9.6 main start
        sudo su - postgres -c "psql -c \"CREATE ROLE ubuntu WITH LOGIN SUPERUSER CREATEDB CREATEROLE PASSWORD 'ubuntu';\"" 
        sudo su - postgres -c "psql -c \"CREATE DATABASE ubuntu;\"" 

        touch ~/.installsh.pg96
    else
        echo "Skipping postgresql-9.6 install. Delete ~/.installsh.pg96 to force installation."
    fi    
    
    # Install virtualenv
    sudo apt-get install -y python-virtualenv

    if [ ! -f buildout.cfg ]; then    
        cat >> buildout.cfg <<EOT 
[buildout]
extends = appserver.cfg

[openerp]
options.admin_passwd = admin
options.db_user = ubuntu
options.db_password = ubuntu
options.db_host = 127.0.0.1
options.xmlrpc_port = 8080    
EOT
    fi

    # Install Odoo > v9 dependencies
    sudo apt install -y nodejs npm
    sudo ln -fs /usr/bin/nodejs /usr/bin/node    
    sudo npm install -g less less-plugin-clean-css
    sudo ln -fs /usr/local/bin/lessc /usr/bin/lessc
    sudo wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb
    sudo apt-get install -y fontconfig libxrender1 libjpeg-turbo8
    sudo dpkg -i wkhtmltox-0.12.1_linux-trusty-amd64.deb
    sudo rm wkhtmltox-0.12.1_linux-trusty-amd64.deb
}

#
# install project required dependencies
#
function install_dependencies {
    ls
    if [ -f install_dependencies.sh ]; then    
        sh install_dependencies.sh
    else
        echo "No project specific 'install_dependencies.sh' script found."
    fi
}


#
# Placeholder function used to debug snippets
#
function debug_function {
    
    if [ $RUNNING_ON==Darwin ]; then
        echo "Running on Darwin."
    fi    

}


#
# Process command line options
#
while getopts "i:h" opt; do
    case $opt in
        i)
            PYPI_INDEX="-i ${OPTARG}"
            BUILDOUT_INDEX="index = ${OPTARG}"
            ;;

        h)
            HELP=1
            ;;

        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;

        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

COMMAND=${@:$OPTIND:1}

echo
echo "install.sh - Inouk OpenERP/Odoo Buildout Installer"
echo "(c) 2013-2018 @cmorisse"

if [[ $COMMAND == "help"  ||  $HELP == 1 ]]; then
    echo "Available commands:"
    echo "  ./install.sh help              Prints this message."
    echo "  ./install.sh [-i ...] openerp  Install OpenERP using buildout (prerequisites must be installed)."
    echo "  ./install.sh dependencies      Install dependencies specific to this server."
    echo "  ./install.sh c9-aws            Install Prerequisites on an AWS Cloud9 EC2 Host (Amazon AMI)."
    echo "  ./install.sh c9-trusty         Install Prerequisites on a Cloud9 Ubuntu 14 blank container."
    echo "  ./install.sh xenial            Install Prerequisites on a fresh Ubuntu Xenial."
    echo "  ./install.sh reset             Remove all buildout installed files."
    echo 
    echo "Available options:"
    echo "  -i   Pypi Index to use (default=""). See pip install --help"
    echo "  -h   Prints this message"
    echo 
    exit
fi

if [[ $COMMAND == "reset" ]]; then
    remove_buildout_files
    exit
elif [[ $COMMAND == "openerp" ]]; then
    install_openerp
    exit
elif [[ $COMMAND == "c9-aws" ]]; then
    setup_c9_aws
    exit
elif [[ $COMMAND == "c9-trusty" ]]; then
    setup_c9_trusty_blank_container
    exit
elif [[ $COMMAND == "xenial" ]]; then
    setup_xenial
    exit
elif [[ $COMMAND == "dependencies" ]]; then
    install_dependencies
    exit
elif [[ $COMMAND == "debug" ]]; then
    debug_function
    exit
fi

echo "use ./install.sh -h for usage instructions."
