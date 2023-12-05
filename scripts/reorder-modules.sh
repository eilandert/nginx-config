#/bin/bash

# A simple script to priotize certain nginx modules in the right order.
# 2021-12-19 Thijs Eilander <eilander@myguard.nl>

ETCPATH="/etc/nginx/modules-enabled"
MODPATH="/usr/share/nginx/modules-available"

# Don't overwrite environment variable from e.g. docker
if [ ! -n "$NGX_MODULES" ]; then
    cd ${ETCPATH}
    NGX_MODULES=$(ls *.conf)
fi
rm ${ETCPATH}/*.conf

# Remove extra spaces or delimiters from dockers environment
NGX_MODULES=$(echo "${NGX_MODULES}" | sed -e s/"[, ]"/" "/g)

for MODULE in $NGX_MODULES
do
    # Strip the .conf part
    MODULE=$(echo "${MODULE}" | sed -e s/"\.conf$"//g)
    # Preserve the filename for later user (rm)
    MODULE_OLD=${MODULE}
    # Strip existing priorities
    MODULE=$(echo "${MODULE}" | sed -e s/"[0-9][0-9]\-"//g)

    PRIO="50"   #DEFAULT
    # Determine dependencies and priority
    case ${MODULE} in
        mod-http-ndk)   PRIO="10" ;;
        mod-stream)     PRIO="15" ;;
        mod-stream-lua)
            ln -sf ${MODPATH}/mod-http-ndk.conf ${ETCPATH}/10-mod-http-ndk.conf
            ln -sf ${MODPATH}/mod-stream.conf ${ETCPATH}/15-mod-stream.conf
            ;;
        mod-stream-*)   ln -sf ${MODPATH}/mod-stream.conf ${ETCPATH}/15-mod-stream.conf ;;
        mod-http-lua)   ln -sf ${MODPATH}/mod-http-ndk.conf ${ETCPATH}/10-mod-http-ndk.conf ;;
        mod-ssl-ct)     PRIO="10" ;;
        mod-http-ssl-ct)   ln -sf ${MODPATH}/mod-ssl-ct.conf ${ETCPATH}/10-mod-ssl-ct.conf ;;
        mod-security-headers) MODULE="mod-http-security-headers"; PRIO="99" ;;
        mod-http-security-headers) PRIO="99" ;;
        mod-modsecurity) MODULE="mod-http-modsecurity" ;;
        mod-brotli) 	MODULE="mod-http-brotli" ;;
        mod-naxsi) 	MODULE="mod-http-naxsi" ;;
        mod-vts) 	MODULE="mod-http-vhost-traffic-status" ;;
    esac

    rm -f ${ETCPATH}/${MODULE_OLD}.conf

    if [ -e "${MODPATH}/${MODULE}.conf" ]; then
        ln -sf ${MODPATH}/${MODULE}.conf ${ETCPATH}/${PRIO}-${MODULE}.conf
    else
        echo "Warning: ${MODPATH}/${MODULE}.conf not found! Not making symlink"
    fi

done
