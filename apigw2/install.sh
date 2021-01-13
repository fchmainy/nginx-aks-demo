#!/bin/sh
#
# NGINX Controller Agent install script
#
# Copyright (C) Nginx, Inc.
#

#
# Set default values for all variables
#
controller_fqdn="controller.f5demolab.org"
packages_url="https://controller.f5demolab.org/packages-repository/"
package_name="nginx-controller-agent"
public_key_url="https://controller.f5demolab.org/packages-repository/nginx-signing.key"
agent_conf_path="/etc/controller-agent"
agent_conf_file="${agent_conf_path}/agent.controller.conf"
agent_service_conf_file="${agent_conf_path}/agent.conf"
agent_extension_conf_file="${agent_conf_path}/agent.configurator.conf"
API_URL="${API_URL:-"https://controller.f5demolab.org:8443"}"
VERIFY_CERT="True"
api_ping_url="${API_URL}/ping/"
api_version="1.4"
api_receiver_url="${API_URL}/${api_version}"
nginx_conf_file="/etc/nginx/nginx.conf"
controller_pid_file="/var/run/controller-agent/controller-agent.pid /tmp/controller-agent.pid"
STORE_UUID="${STORE_UUID:-False}"
location_name="unspecified"
instance_name=$(hostname -f)
upgrade_mode="False"

#
# Functions
#

title() {
    printf "\n --- NGINX Controller Agent package installer ---\n\n"
}

err_exit() {
    printf "$1"
    printf "\033[31m exiting.\033[0m\n"
    exit 1
}

print_help() {
    title
    cat <<EOF
Install or update NGINX Controller Agent.

Usage:
  $(basename "$0") [-y] [-l | --location-name <location_name>] [-i | --instance-name <instance_name>] [--insecure] [-c | --ca-bundle <ca_bundle_file>]


Options:
  -y                    Answers 'yes' to all questions to skip prompts.
  -l | --location-name  Location name.
  -i | --instance-name  Instance name.
  --insecure            Disables server certificate verification; not recommended for production.
  -c | --ca-bundle      Provide the path to the CA bundle file; can be a relative or an absolute path.
}
EOF
}

# Get OS information
get_os_name() {

    centos_flavor="centos"

    # Use lsb_release if possible
    if command -V lsb_release >/dev/null 2>&1; then
        os=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
        codename=$(lsb_release -cs | tr '[:upper:]' '[:lower:]')
        release=$(lsb_release -rs | sed 's/\..*$//')

        if [ "$os" = "redhatenterpriseserver" ] || [ "$os" = "oracleserver" ]; then
            os="centos"
            centos_flavor="red hat linux"
        fi
    # Otherwise it's getting a little bit more tricky
    else
        if ! ls /etc/*-release >/dev/null 2>&1; then
            os=$(uname -s |
                tr '[:upper:]' '[:lower:]')
        else
            os=$(cat /etc/*-release | grep '^ID=' |
                sed 's/^ID=["]*\([a-zA-Z]*\).*$/\1/' |
                tr '[:upper:]' '[:lower:]')

            if [ -z "$os" ]; then
                if grep -i "oracle linux" /etc/*-release >/dev/null 2>&1 ||
                    grep -i "red hat" /etc/*-release >/dev/null 2>&1; then
                    os="rhel"
                else
                    if grep -i "centos" /etc/*-release >/dev/null 2>&1; then
                        os="centos"
                    else
                        os="linux"
                    fi
                fi
            fi
        fi

        case "$os" in
        ubuntu)
            codename=$(cat /etc/*-release | grep '^DISTRIB_CODENAME' |
                sed 's/^[^=]*=\([^=]*\)/\1/' |
                tr '[:upper:]' '[:lower:]')
            ;;
        debian)
            codename=$(cat /etc/*-release | grep '^VERSION=' |
                sed 's/.*(\(.*\)).*/\1/' |
                tr '[:upper:]' '[:lower:]')
            ;;
        centos)
            codename=$(cat /etc/*-release | grep -i 'centos.*(' |
                sed 's/.*(\(.*\)).*/\1/' | head -1 |
                tr '[:upper:]' '[:lower:]')
            # For CentOS grab release
            release=$(cat /etc/*-release | grep -i 'centos.*[0-9]' |
                sed 's/^[^0-9]*\([0-9][0-9]*\).*$/\1/' | head -1)
            ;;
        rhel | ol)
            codename=$(cat /etc/*-release | grep -i 'red hat.*(' |
                sed 's/.*(\(.*\)).*/\1/' | head -1 |
                tr '[:upper:]' '[:lower:]')
            # For Red Hat also grab release
            release=$(cat /etc/*-release | grep -i 'red hat.*[0-9]' |
                sed 's/^[^0-9]*\([0-9][0-9]*\).*$/\1/' | head -1)

            if [ -z "$release" ]; then
                release=$(cat /etc/*-release | grep -i '^VERSION_ID=' |
                    sed 's/^[^0-9]*\([0-9][0-9]*\).*$/\1/' | head -1)
            fi

            os="centos"
            centos_flavor="red hat linux"
            ;;
        amzn)
            codename="amazon-linux-ami"

            amzn=$(rpm --eval "%{amzn}")
            if [ "${amzn}" = 1 ]; then
                release="latest"
            else
                release=${amzn}
            fi

            os="amazon"
            centos_flavor="amazon linux"
            ;;
        *)
            codename=""
            release=""
            ;;
        esac
    fi

}

download() {
    url=$1
    shift
    if command -V curl >/dev/null 2>&1; then
        if [ "$VERIFY_CERT" != "True" ]; then
            set -- -k "$@"
        fi
        if [ -n "$ca_bundle" ]; then
            set -- --cacert "$ca_bundle" "$@"
        fi
        curl -fsS "$@" "$url" 2>&1
    elif command -V wget >/dev/null 2>&1; then
        if [ "$VERIFY_CERT" != "True" ]; then
            set -- --no-check-certificate "$@"
        fi
        if [ -n "$ca_bundle" ]; then
            set -- --ca-certificate="$ca_bundle" "$@"
        fi
        wget --no-verbose -O - "$@" "$url" 2>&1
    else
        err_exit "\033[31m no curl or wget found.\033[0m\n\n"
    fi
}

# print appropriate error message based on error code
print_connectivity_error_message() {
    errcode=$1

    if command -V curl >/dev/null 2>&1; then
        # see curl manpage for exit codes explanations
        case $errcode in
        # curl networking errors
        5 | 6 | 7 | 28 | 55 | 56)
            printf "\033[31m Verify your network and firewall settings.\033[0m\n"
            ;;
        # curl SSL errors
        35 | 51 | 58 | 59 | 60 | 80 | 83 | 90 | 91)
            printf "\033[31m If NGINX Controller instance is using certificate signed by private Certificate Authority, provide --ca-bundle flag.\033[0m\n"
            printf "\033[31m To skip NGINX Controller certificate verification, use --insecure flag(not recommended).\033[0m\n"
            ;;
        # curl file errors
        37 | 77)
            printf "\033[31m Verify your certificate path and access rights.\033[0m\n"
            ;;
        *) ;;
        esac
    else
        case $errcode in
        # wget network failure
        4)
            printf "\033[31m Verify your network and firewall settings.\033[0m\n"
            ;;
        # wget SSL verification failure
        5)
            printf "\033[31m If NGINX Controller instance is using certificate signed by private Certificate Authority, provide --ca-bundle flag.\033[0m\n"
            printf "\033[31m To skip NGINX Controller certificate verification, use --insecure flag.\033[0m\n"
            ;;
        *) ;;
        esac
    fi
}

# Test connectivity to NGINX Controller
check_connectivity() {
    printf "\033[32m %s. Checking connectivity to the NGINX Controller ...\033[0m" "${step}"
    resp=$(download "${api_ping_url}")
    errcode=$?

    if [ $errcode -ne 0 ]; then
        printf "\033[31m failed to connect to the NGINX Controller\033[0m\n\n"
        printf "%s\n" "$resp"
        print_connectivity_error_message $errcode
        err_exit
    elif ! echo $resp | grep 'pong' >/dev/null 2>&1; then
        err_exit "\033[31m invalid response from NGINX Controller server.\033[0m\n\n"
    else
        printf "\033[32m ok.\033[0m\n"
    fi
}

# Compare server time with local time
check_system_time() {
    printf "\033[32m %s. Checking system time ...\033[0m" "${step}"
    if command -V curl >/dev/null 2>&1; then
        include_header_opts="-i"
    elif command -V wget >/dev/null 2>&1; then
        include_header_opts="-S"
    fi

    if ! server_date=$(download "${api_ping_url}" ${include_header_opts} 2>&1 | grep '^.*Date' | sed 's/.*Date:[ ][ ]*\(.*\)/\1/') || [ -z "${server_date}" ]; then
        printf "\033[31m failed!\033[0m\n"
        errors=$((errors + 1))
        return
    fi

    amplify_epoch=$(date --date="${server_date}" "+%s")
    agent_epoch=$(date -u '+%s')
    offset=$((amplify_epoch - agent_epoch))
    # absolute value
    offset=${offset#-}

    if [ "${offset}" -le 6 ]; then
        printf "\033[32m ok.\033[0m\n"
    else
        printf "\033[31m please adjust the system clock for proper metric collection!\033[0m\n"
        errors=$((errors + 1))
    fi
}

# POST to the agent/install-check endpoint.
post_install_check() {

    if command -V curl >/dev/null 2>&1; then
        if [ "$VERIFY_CERT" != "True" ]; then
            cert_option="-k"
        fi
        if [ -n "$ca_bundle" ]; then
            cert_option="--cacert $ca_bundle"
        fi
	resp=$(curl -fsS ${cert_option} -w '%{http_code}' -XPOST -d \
		    "{\"location_name\": \"${location_name}\", \"instance_name\": \"${instance_name}\"}" \
		    -H "Content-Type: application/json" -H "User-agent: nginx-controller-agent/${api_version}" \
		    "${api_receiver_url}/${API_KEY}/agent/install-check/" 2>&1)
	http_code=$(echo $resp | awk '{ print $NF }')
	echo "$http_code"
    elif command -V wget >/dev/null 2>&1; then
        if [ "$VERIFY_CERT" != "True" ]; then
            cert_option="--no-check-certificate"
        fi
        if [ -n "$ca_bundle" ]; then
            cert_option="--ca-certificate=${ca_bundle}"
        fi
	resp=$(wget -q --no-verbose --server-response ${cert_option} \
			 --post-data="{\"location_name\": \"${location_name}\", \"instance_name\": \"${instance_name}\"}" \
			 --header "Content-Type: application/json" --header "User-agent: nginx-controller-agent/${api_version}" \
			 "${api_receiver_url}/${API_KEY}/agent/install-check/" 2>&1)
	errcode=$?
        if [ $errcode -eq 0 -o $errcode -eq 8 ]; then
            http_code=$(echo $resp | awk '/HTTP\/1.1/ { print $2 }')
        else
            http_code="400"
        fi
        echo "$http_code"
    else
        err_exit "\033[31m no curl or wget found.\033[0m\n\n"
    fi
}

# Check instance install location
check_instance_properties() {

    printf "\033[32m\n %s. Checking instance name and location ... \033[0m" "${step}"

    pattern="(?!@)^[^A-Z\s\x00-\x1f\x60\x7f\;\*\"\[\]\{\}\\\\/%\?:=&\~\^|#<>]+(?<!@)$"
    if ! echo "$instance_name" | grep -Pq $pattern; then
        printf "\033[31m \nFailed instance name check. Check your input and try again.\033[0m\n"
        printf "\033[31m \t * do not include spaces.\033[0m\n"
        printf "\033[31m \t * do not utilize URL encoding.\033[0m\n"
        printf "\033[31m \t * cannot start or end with an @ sign.\033[0m\n"
        printf "\033[31m \t * do not use uppercase characters, for example, 'A-Z'; extended character sets are supported.\033[0m\n"
        printf "\033[31m \t * do not use the following characters: \" * : ; / \ %% ? # = & | ~ ^ { } [ ] < >.\033[0m\n"
        err_exit
    fi

    http_code=$(post_install_check)

    if [ "$http_code" -eq 200 ] || ([ "$http_code" -eq 409 ] && [ "$upgrade_mode" = "True" ]); then
        printf "\033[32m done.\033[0m\n"
    else
        if [ "$http_code" -eq 400 ]; then
            printf "\033[31m Error validating the request body for the instance name check. Check your input and try again.\033[0m\n"
        elif [ "$http_code" -eq 404 ]; then
            printf "\033[31m The location with name \"%s\" was not found.\033[0m\n" "${location_name}"
            printf "\033[31m Check the spelling or make sure the location exists, then try again.\033[0m\n"
            err_exit
        elif [ "$http_code" -eq 409 ]; then
            printf "\033[31m An instance named \"%s\" already exists at the location \"%s\".\033[0m\n" "${instance_name}" "${location_name}"
            printf "\033[31m Choose another name or remove the existing instance.\033[0m\n"
        else
            printf "\033[31m An unknown error occurred while connecting to NGINX Controller.\033[0m\n"
        fi
        errors=$((errors + 1))
    fi
}

# Add public key for package verification (Ubuntu/Debian)
add_public_key_deb() {
    printf "\033[32m %s. Adding public key ...\033[0m" "${step}"

    if ! download "${public_key_url}" | ${sudo_cmd} apt-key add - >/dev/null 2>&1; then
        err_exit "\033[31m failed.\033[0m\n\n"
    fi
    printf "\033[32m done.\033[0m\n"
}

# Add public key for package verification (CentOS/Red Hat)
add_public_key_rpm() {
    printf "\033[32m %s. Adding public key ...\033[0m" "${step}"

    if command -V rpmkeys >/dev/null 2>&1; then
        rpm_key_cmd="rpmkeys"
    else
        rpm_key_cmd="rpm"
    fi

    ${sudo_cmd} rm -f /tmp/nginx_signing.key.$$
    download "${public_key_url}" | tee /tmp/nginx_signing.key.$$ >/dev/null 2>&1

    if ! ${sudo_cmd} ${rpm_key_cmd} --import /tmp/nginx_signing.key.$$; then
        err_exit "\033[31m failed.\033[0m\n\n"
    fi
    rm -f /tmp/nginx_signing.key.$$
    printf "\033[32m done.\033[0m\n"
}

# Add repo configuration (Ubuntu/Debian)
add_repo_deb() {
    printf "\033[32m %s. Adding repository ...\033[0m" "${step}"

    controller_apt_config="/etc/apt/apt.conf.d/80controller"
    if ! test -d /etc/apt/apt.conf.d || ! ${sudo_cmd} test -w /etc/apt/apt.conf.d; then
        err_exit "\033[31m failed.\033[0m\n\n"
    fi

    verify_peer=$(echo "$VERIFY_CERT" | tr '[:upper:]' '[:lower:]')
    verify_host=$(echo "$VERIFY_CERT" | tr '[:upper:]' '[:lower:]')
    if [ -n "$ca_bundle" ]; then
        cainfo="Acquire::https::${controller_fqdn}::CAInfo ${ca_bundle};"
    fi

    if ! ${sudo_cmd} tee ${controller_apt_config} <<EOF >/dev/null 2>&1; then
Acquire::https::${controller_fqdn}::Verify-Peer ${verify_peer};
Acquire::https::${controller_fqdn}::Verify-Host ${verify_host};
${cainfo}
EOF
        err_exit "\033[31m failed.\033[0m\n\n"
    fi

    repolist=/etc/apt/sources.list.d/nginx-controller.list
    if ! test -d /etc/apt/sources.list.d || ! ${sudo_cmd} test -w /etc/apt/sources.list.d; then
        err_exit "\033[31m failed.\033[0m\n\n"
    fi

    if ! ${sudo_cmd} tee ${repolist} <<EOF >/dev/null 2>&1; then
deb ${packages_url}/${os}/ ${codename} controller
deb ${packages_url}/metrics/${os}/ ${codename} controller
EOF
        err_exit "\033[31m failed.\033[0m\n\n"
    fi
    ${sudo_cmd} chmod 644 ${repolist} >/dev/null 2>&1
    printf "\033[32m added.\033[0m\n"
}

# Add repo configuration (CentOS)
add_repo_rpm() {
    printf "\033[32m %s. Adding repository config ...\033[0m" "${step}"

    agent_repo=/etc/yum.repos.d/nginx-controller.repo
    metrics_repo=/etc/yum.repos.d/nginx-controller-metrics.repo
    if ! test -d /etc/yum.repos.d || ! ${sudo_cmd} test -w /etc/yum.repos.d; then
        err_exit "\033[31m failed.\033[0m\n\n"
    fi

    if ! ${sudo_cmd} tee ${agent_repo} <<EOF >/dev/null 2>&1; then
[nginx-controller]
name=nginx controller repo
baseurl=${packages_url}/${os}/${release}/\$basearch
gpgcheck=1
repo_gpgcheck=1
gpgkey=${public_key_url}
sslcacert=$ca_bundle
sslverify=$VERIFY_CERT
enabled=1
EOF
        err_exit "\033[31m failed.\033[0m\n\n"
    fi
    ${sudo_cmd} chmod 644 ${agent_repo} >/dev/null 2>&1

    if ! ${sudo_cmd} tee ${metrics_repo} <<EOF >/dev/null 2>&1; then
[nginx-controller-metrics]
name=nginx controller metrics repo
baseurl=${packages_url}/metrics/${os}/${release}/\$basearch
gpgcheck=1
repo_gpgcheck=1
gpgkey=${public_key_url}
sslcacert=$ca_bundle
sslverify=$VERIFY_CERT
enabled=1
EOF
        err_exit "\033[31m failed.\033[0m\n\n"
    fi
    ${sudo_cmd} chmod 644 ${metrics_repo} >/dev/null 2>&1

    printf "\033[32m added.\033[0m\n"
}

# Install package (either deb or rpm)
install_deb_or_rpm() {
    # Update repo
    printf "\033[32m %s. Updating repository ...\n\n\033[0m" "${step}"

    # shellcheck disable=SC2086
    if ! ${sudo_cmd} ${update_cmd}; then
        printf "\033[31m\n %s. Updating repository ... failed.\033[0m\n\n" "${step}"
        printf "\033[32m Please check the list of the supported systems.\033[0m\n\n"
        err_exit
    fi
    printf "\033[32m\n %s. Updating repository ... done.\033[0m\n" "${step}"

    incr_step

    # Install package(s)
    printf "\033[32m %s. Installing nginx-controller-agent package ...\033[0m\n\n" "${step}"

    # shellcheck disable=SC2086
    if ! ${sudo_cmd} ${install_cmd} ${package_name}; then
        printf "\033[31m\n %s. Installing nginx-controller-agent package ... failed.\033[0m\n\n" "${step}"
        printf "\033[32m Please check the list of the supported systems.\033[0m\n\n"
        err_exit
    fi
    printf "\033[32m\n %s. Installing nginx-controller-agent package ... done.\033[0m\n" "${step}"

    incr_step

    # Additional metrics packages, optional success or forced with REQUIRE_METRICS env var
    if ! v=$(${sudo_cmd} nginx -v 2>&1) || ! v=$(echo "$v" | grep '^nginx version:') || ! nginx_version=$(echo "$v" | awk '{print $3}' | awk -F/ '{print $2}') || [ -z "$nginx_version" ]; then
        printf "\033[31m\n %s. Installing metrics packages ... failed.\033[0m\n\n" "${step}"
        printf "\033[32m Please verify if you have NGINX Plus installed.\033[0m\n\n"
        printf "\033[32m However, only NGINX controller agent is installed successfully\033[0m\n\n"
        printf "\033[32m as a result, app-centric metrics are not available for this instance.\033[0m\n\n"
        if [ -n "$REQUIRE_METRICS" ]; then
            err_exit
        fi
        return
    fi

    if [ "${install_cmd#yum}" = "${install_cmd}" ]; then
        # not yum.. must be apt
        # example version selection for apt is:
        # nginx-plus-module-metrics=1.17.3*
        metrics_module_version="=${nginx_version}*"
    else
        # example version selection for yum is:
        # nginx-plus-module-metrics-1.17.3
        metrics_module_version="-*+${nginx_version}"
    fi

    metrics_packages="nginx-plus-module-metrics${metrics_module_version} avrd avrd-libs"
    # shellcheck disable=SC2086
    if ${sudo_cmd} ${install_cmd} ${metrics_packages}; then
        printf "\033[32m\n %s. Installing metrics packages ... done.\033[0m\n" "${step}"
    else
        printf "\033[31m\n %s. Installing metrics packages ... failed.\033[0m\n\n" "${step}"
        printf "\033[32m Please check the list of the supported systems and/or supported NGINX Plus versions.\033[0m\n\n"
        printf "\033[32m However, only NGINX controller agent is installed successfully\033[0m\n\n"
        printf "\033[32m as a result, app-centric metrics are not available for this instance.\033[0m\n\n"
        if [ -n "$REQUIRE_METRICS" ]; then
            err_exit
        fi
    fi
}

install_selinux_policy() {

    printf "\033[32m %s. Updating selinux policy ...\n\n\033[0m" "${step}"

    # check if sestatus exists. if it does not, do not install settings
    resp=$(command -V sestatus)
    errcode=$?
    if [ $errcode -ne 0 ]; then
        printf "\033[32m\n %s. Updating selinux policy ... skipping (sestatus not installed: ${resp}).\033[0m\n" "${step}"
        return 0
    fi

    # check if sestatus is disabled. if it is, do not install settings
    resp=$(sestatus | sed -n 's/SELinux status:[ ]*//p')
    errcode=$?
    if [ $errcode -ne 0 -o "$resp" = "disabled" ]; then
        printf "\033[32m\n %s. Updating selinux policy ... skipping (sestatus disabled).\033[0m\n" "${step}"
        return 0
    fi

    # check if sestatus mode is permissive/enforcing. if it is not, do not install settings
    mode=$(sestatus | sed -n 's/Current mode:[ ]*//p')
    if  [ "${mode}" != "permissive" -a "${mode}" != "enforcing" ]; then
        printf "\033[32m\n %s. Updating selinux policy ... skipping (selinux mode not permissive/enforcing).\033[0m\n" "${step}"
        return 0
    fi

    # selinux set to permissive or enforcing, install policy
    cat << EOF > nginx.te
module nginx 1.0;

require {
    type httpd_t;
    type tmp_t;
    class sock_file write;
}

#============= httpd_t ==============
allow httpd_t tmp_t:sock_file write;
EOF

    resp=$(checkmodule -M -m -o nginx.mod nginx.te)
    errcode=$?
    if [ $errcode -ne 0 ]; then
        err_exit "cannot convert required selinux permissions for nginx module: $resp"
    fi

    resp=$(semodule_package -o nginx.pp -m nginx.mod)
    errcode=$?
    if [ $errcode -ne 0 ]; then
        err_exit "cannot compile selinux policy for nginx module: $resp"
    fi

    resp=$(${sudo_cmd} semodule -i nginx.pp)
    errcode=$?
    if [ $errcode -ne 0 ]; then
        err_exit "cannot load required selinux permissions for nginx module: $resp"
    fi

    printf "\033[32m\n Updating selinux policy ... done.\033[0m\n"
}

# Detect the user for the agent to use
detect_controller_user() {
    printf "\033[32m %s. Detecting Controller user ...\n\n\033[0m" "${step}"

    if [ -f "${agent_conf_file}" ]; then
        controller_user=$(grep -v '#' ${agent_conf_file} |
            grep -A 5 -i '\[.*nginx.*\]' |
            grep -i 'user.*=' |
            awk -F= '{print $2}' |
            sed 's/ //g' |
            head -1)

        nginx_conf_file=$(grep -A 5 -i '\[.*nginx.*\]' ${agent_conf_file} |
            grep -i 'configfile.*=' |
            awk -F= '{print $2}' |
            sed 's/ //g' |
            head -1)
    fi

    if [ -f "${nginx_conf_file}" ]; then
        nginx_user=$(grep 'user[[:space:]]' "${nginx_conf_file}" |
            grep -v '[#].*user.*;' |
            grep -v '_user' |
            sed -n -e 's/.*\(user[[:space:]][[:space:]]*[^;]*\);.*/\1/p' |
            awk '{ print $2 }' | head -1)
    fi

    if [ -z "${controller_user}" ]; then
        test -n "${nginx_user}" &&
            controller_user=${nginx_user} ||
            controller_user="nginx"
    fi

    controller_group=$(id -gn ${controller_user})
}

#
# load existing configuration properties, if defined
#
load_config_properties() {
    existing_instance_name=""
    existing_location_name=""

    if [ -f "${agent_service_conf_file}" ]; then
        existing_instance_name=$(${sudo_cmd} grep -v "^#" "${agent_service_conf_file}" | ${sudo_cmd} grep -m 1 -Po "(?<=instance_name = ).*" "${agent_service_conf_file}")
        existing_location_name=$(${sudo_cmd} grep -v "^#" "${agent_service_conf_file}" | ${sudo_cmd} grep -m 1 -Po "(?<=location_name = ).*" "${agent_service_conf_file}")
        upgrade_mode="True"
    fi

    if ! [ -z "${existing_instance_name}" ]; then
        instance_name=${existing_instance_name}
    fi

    if ! [ -z "${existing_location_name}" ]; then
        location_name=${existing_location_name}
    fi
}

build_config_file() {
    # Build config file from template
    printf "\033[32m %s. Building configuration file ...\033[0m" "${step}"

    if [ ! -f "${agent_conf_file}.default" ]; then
        err_exit "\033[31m can't find %s\033[0m\n\n" "${agent_conf_file}.default"
    fi

    if [ -f "${agent_conf_file}" ]; then
        ${sudo_cmd} rm -f ${agent_conf_file}.old
        ${sudo_cmd} cp -p ${agent_conf_file} ${agent_conf_file}.old
    fi

    # ensure only Agent can update its config
    usrmask=$(umask)
    umask ug=rwx,o=

    ${sudo_cmd} rm -f ${agent_conf_file} &&
        ${sudo_cmd} sh -c "sed -e 's|api_key.*$|api_key = $API_KEY|' \
                        -e 's|^api_url.*$|api_url = $api_receiver_url|' \
                        -e 's|verify_ssl_cert.*$|verify_ssl_cert = $VERIFY_CERT|' \
                        -e 's|requests_ca_bundle.*$|requests_ca_bundle = $ca_bundle|' \
                        -e 's|location_name.*$|location_name = $location_name|' \
                        -e 's|instance_name.*$|instance_name = $instance_name|' \
                        -e 's|hostname.*$|hostname = $CONTROLLER_HOSTNAME|' \
                        -e 's|store_uuid.*$|store_uuid = $STORE_UUID|' \
            ${agent_conf_file}.default > \
            ${agent_service_conf_file}" &&
        ${sudo_cmd} chown ${controller_user} ${agent_service_conf_file} >/dev/null 2>&1

    if ! (${sudo_cmd} rm -f ${agent_extension_conf_file} &&
        ${sudo_cmd} sh -c "cat ${agent_extension_conf_file}.default > ${agent_extension_conf_file}" &&
        ${sudo_cmd} chown ${controller_user} ${agent_extension_conf_file} >/dev/null 2>&1); then
        err_exit "\033[31m failed.\033[0m\n\n"
    fi

    umask "$usrmask"
    printf "\033[32m done.\033[0m\n"
}

incr_step() {
    step=$((step + 1))
    if [ "${step}" -lt 10 ]; then
        step=" ${step}"
    fi
}

wlp_check() {
    if ! command -v waf-log-processor >/dev/null 2>&1; then
        return
    fi
    if ! ${sudo_cmd} grep -Fxq "security = True" ${agent_service_conf_file}; then
        ${sudo_cmd} sed "/\[extensions\]/a security = True" ${agent_service_conf_file} -i
    fi

    if ! ${sudo_cmd} grep -Fxq "[logger_waf-log-processor]" ${agent_service_conf_file}; then
        ${sudo_cmd} tee -a ${agent_service_conf_file} <<EOF >/dev/null 2>&1

[logger_waf-log-processor]
level = INFO
EOF
    fi
}

verify_root_or_sudo() {
    sudo_msg="\033[32m ${step}. Checking admin user ...\033[0m"

    # Check if sudo is installed
    if command -V sudo >/dev/null 2>&1; then
        sudo_found="yes"
        sudo_cmd="sudo "
    fi

    # Detect root
    if [ "$(id -u)" = "0" ]; then
        sudo_msg="${sudo_msg}\033[32m root, ok.\033[0m\n"
        sudo_cmd=""
    else
        if [ "$sudo_found" = "yes" ]; then
            sudo_msg="${sudo_msg}\033[33m you'll need sudo rights.\033[0m\n"
        else
            err_exit "${sudo_msg}\033[31m not root, sudo not found.\033[0m\n"
        fi
    fi
}

parse_args() {
    while [ "$1" != "" ]; do
        arg=$1
        case "$arg" in
        -y)
            assume_yes="-y"
            ;;
        -l | --location-name | --location)
            shift
            location_name=$1
            printf "\033[32m %s.. overriding location_name value from command line: %s ...\033[0m" "${step}" "${location_name}"
            ;;
        -i | --instance-name)
            shift
            instance_name=$1
            printf "\033[32m %s.. overriding instance_name value from command line: %s ...\033[0m" "${step}" "${instance_name}"
            ;;
        --insecure)
            VERIFY_CERT="False"
            ;;
        -c | --ca-bundle)
            shift
            ca_bundle=$(realpath -m -q -- "$1")
            ;;
        *)
            print_help
            exit 0
            ;;

        esac
        # shift to next command line option
        shift
    done
}

#====================================================================
# Main
#

step=" 1"
assume_yes=""
ca_bundle=""
errors=0
sudo_found="no"
sudo_cmd=""
sudo_msg=""

# ensure user is either root or sudo is available. Cannot continue otherwise
verify_root_or_sudo

# override script defaults with values in existing config (if defined)
load_config_properties

# set script options and allow override of script defaults
parse_args "$@"

title
printf "${sudo_msg}"
incr_step

# Add API key
printf "\033[32m %s. Checking API key ...\033[0m" "${step}"

if [ -z "$API_KEY" ]; then
    err_exit "\033[31m What's your API key? Please check the docs and the UI.\033[0m\n\n"
fi
printf "\033[32m using %s\033[0m\n" "${API_KEY}"

incr_step

# Write generated UUIDs to config if STORE_UUID is set to True

printf "\033[32m %s. Checking if uuid should be stored in the config ...\033[0m" "${step}"

if [ "$STORE_UUID" != "True" ] && [ "$STORE_UUID" != "False" ]; then
    err_exit "\033[31m STORE_UUID needs to be True or False\033[0m\n\n"
fi
printf "\033[32m %s\033[0m\n" "${STORE_UUID}"

incr_step

# Check for supported OS
printf "\033[32m %s. Checking OS compatibility ...\033[0m" "${step}"
get_os_name
printf "\033[32m %s detected.\033[0m\n" "${os}"

incr_step

# Check CA bundle file if provided
if [ -n "${ca_bundle}" ]; then
    printf "\033[32m %s. Checking CA bundle file ...\033[0m" "${step}"
    if [ -z "$(find "${ca_bundle}" -perm -444)" ]; then
        printf "\033[31m failed.\033[0m\n\n"
        printf "\033[31m Verify that CA bundle file exists and is world readable.\033[0m\n\n"
        err_exit
    fi

    printf "\033[32m ok.\033[0m\n"
    incr_step
fi

# Check connectivity to NGINX Controller
check_connectivity

incr_step

# Check if the location exists and if the instance name is not already taken.
check_instance_properties

incr_step

# Check system time
check_system_time

incr_step

# Add public key, create repo config, install package
case "$os" in
ubuntu | debian)
    # Install apt-transport-https if not found
    if ! dpkg -s apt-transport-https >/dev/null 2>&1; then
        printf "\033[32m %s. Installing apt-transport-https ...\033[0m" "${step}"

        if ! ${sudo_cmd} apt-get update >/dev/null 2>&1 ||
            ! ${sudo_cmd} apt-get -y install apt-transport-https >/dev/null 2>&1; then
            err_exit "\033[31m failed.\033[0m\n\n"
        fi
        printf "\033[32m done.\033[0m\n"

        incr_step
    fi

    # Add public key
    add_public_key_deb

    incr_step

    # Add repository configuration
    add_repo_deb

    incr_step

    # Install package
    update_cmd="apt-get ${assume_yes} update"
    install_cmd="apt-get ${assume_yes} install"

    # Configure package version
    if [ -n "${VERSION}" ]; then
        package_name="${package_name}=${VERSION}"
    fi

    install_deb_or_rpm
    ;;
centos | amazon)
    # Add public key
    add_public_key_rpm

    incr_step

    # Add repository configuration
    add_repo_rpm

    incr_step

    # Install package
    update_cmd="yum ${assume_yes} makecache"

    # Configure package version
    if [ -n "${VERSION}" ]; then
        package_name="${package_name}-${VERSION}"
    fi

    # Check if nginx packages are excluded
    if grep 'exclude.*nginx' /etc/yum.conf | grep -v '#' >/dev/null 2>&1; then
        printf "\n"
        printf "\033[32m Packages with the 'nginx' names are excluded in /etc/yum.conf - proceed with install (y/n)? \033[0m"

        read -r answer
        printf "\n"

        if [ "${answer}" != "y" ] && [ "${answer}" != "Y" ]; then
            err_exit
        fi
        install_cmd="yum ${assume_yes} --disableexcludes=main install"
    else
        install_cmd="yum ${assume_yes} install"
    fi

    install_deb_or_rpm
    ;;
*)
    if [ -n "$os" ] && [ "$os" != "linux" ]; then
        printf "\033[31m %s is currently unsupported, apologies!\033[0m\n\n" "$os"
    else
        printf "\033[31m failed.\033[0m\n\n"
    fi

    err_exit
    ;;
esac
incr_step

install_selinux_policy
incr_step

# Detect the agent's euid
detect_controller_user
incr_step

# build config file if file doesn't exist
if [ ! -f "${agent_service_conf_file}" ]; then
    build_config_file
    incr_step
elif find "${agent_service_conf_file}" -perm -o=r | ${sudo_cmd} grep -q .; then
    ${sudo_cmd} chmod o= "${agent_service_conf_file}"
fi

# Check if waf-log-processor is installed and change config accordingly
wlp_check

# Check for infrastructure section in the config file
if ! ${sudo_cmd} grep -Fxq "[infrastructure]" "${agent_service_conf_file}"; then
    # Append to the end of file
    cat <<EOF | ${sudo_cmd} tee -a "${agent_service_conf_file}" >/dev/null 2>&1

[infrastructure]
location_name = $location_name
instance_name = $instance_name
EOF
else
    # Verify if existing instance_name and location_name in config file matches with the supplied args
    existing_instance_name=$(${sudo_cmd} grep -v "^#" "${agent_service_conf_file}" | ${sudo_cmd} grep -m 1 -Po "(?<=instance_name = ).*" "${agent_service_conf_file}")
    existing_location_name=$(${sudo_cmd} grep -v "^#" "${agent_service_conf_file}" | ${sudo_cmd} grep -m 1 -Po "(?<=location_name = ).*" "${agent_service_conf_file}")

    if [ "${existing_instance_name}" != "${instance_name}" ]; then
        printf "\033[31m The new instance name \"%s\" will be used.\033[0m\n" "${instance_name}"
        ${sudo_cmd} sed -i "s/instance_name = ${existing_instance_name}/instance_name = ${instance_name}/g" "${agent_service_conf_file}"
    fi

    if [ "${existing_location_name}" != "${location_name}" ]; then
        printf "\033[31m The new location name \"%s\" will be used.\033[0m\n" "${location_name}"
        ${sudo_cmd} sed -i "s/location_name = ${existing_location_name}/location_name = ${location_name}/g" "${agent_service_conf_file}"
    fi
fi

#update old plus_url setting name in case of upgrade
if [ "$upgrade_mode" = "True" ]; then
    ${sudo_cmd} sed -i "s/^plus_url/plus_api_url/g" "${agent_service_conf_file}"
fi


if [ -n "${controller_user}" ] && controller_euid=$(id -u ${controller_user}); then
    # Check is sudo can be used for tests
    printf "\033[32m %s. Checking if %s can be used for tests ...\033[0m" "${step}" "sudo -u ${controller_user} -g ${controller_group}"

    if [ "${sudo_found}" = "yes" ]; then
        sudo_output=$(sudo -u ${controller_user} /bin/sh -c "id -un" 2>/dev/null)

        if [ "${sudo_output}" = "${controller_user}" ]; then
            printf "\033[32m done.\033[0m\n"
        else
            printf "\033[31m failed. (%s)\033[0m\n" "${sudo_output} != ${controller_user}"
            errors=$((errors + 1))
        fi
    else
        printf "\033[31m failed, sudo not found.\033[0m\n"
        errors=$((errors + 1))
    fi

    incr_step
else
    printf "\n"
    printf "\033[31m Can't detect the agent's user id, skipping some tests.\033[0m\n\n"
    errors=$((errors + 1))
fi

# Check agent capabilities
if [ "${errors}" -eq 0 ]; then
    # Check if the agent is able to use ps(1)
    printf "\033[32m %s. Checking if euid %s(%s) can find root processes ...\033[0m" "${step}" "${controller_euid}" "${controller_user}"

    if sudo -u "${controller_user}" -g "${controller_group}" /bin/sh -c "ps xao user,pid,ppid,command" 2>&1 | grep "^root" >/dev/null 2>&1; then
        printf "\033[32m ok.\033[0m\n"
    else
        printf "\033[31m agent will fail to detect nginx, ps(1) is restricted!\033[0m\n"
        errors=$((errors + 1))
    fi

    incr_step

    printf "\033[32m %s. Checking if euid %s(%s) can access I/O counters for nginx ...\033[0m" "${step}" "${controller_euid}" "${controller_user}"

    if sudo -u "${controller_user}" -g "${controller_group}" /bin/sh -c 'cat /proc/$$/io' >/dev/null 2>&1; then
        printf "\033[32m ok.\033[0m\n"
    else
        printf "\033[31m failed, /proc/<pid>/io is restricted!\033[0m\n"
        errors=$((errors + 1))
    fi

    incr_step
fi

printf "\n"

# Finalize install
if [ "$errors" -eq 0 ]; then
    printf "\033[32m OK, everything went just fine!\033[0m\n\n"
else
    printf "\033[31m A few checks have failed - please read the warnings above!\033[0m\n\n"
fi

printf "\033[32m To start and stop the Controller Agent type:\033[0m\n\n"
printf "     \033[7m%s service controller-agent { start | stop }\033[0m\n\n" "${sudo_cmd}"

printf "\033[32m Controller Agent log can be found here:\033[0m\n"
printf "     /var/log/nginx-controller/agent.log\n\n"

printf "\033[32m After the agent is launched, it takes a couple of minutes for this system to appear\033[0m\n"
printf "\033[32m in the Controller user interface.\033[0m\n\n"


# Unconditionally stop the agent service (regardless if this is install/upgrade)
# This command is allowed to fail and the output is not shown
${sudo_cmd} service controller-agent stop >/dev/null 2>&1 </dev/null

# Launch agent
printf "\033[32m Launching controller-agent ...\033[0m\n"
if ! ${sudo_cmd} service controller-agent start >/dev/null 2>&1 </dev/null; then
    err_exit "\n\033[31m Couldn't start the agent, please check /var/log/nginx-controller/agent.log\033[0m\n\n"
fi
printf "\033[32m All done.\033[0m\n\n"
exit 0