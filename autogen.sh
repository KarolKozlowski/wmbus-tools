#!/bin/bash

APP_ROOT=/var/snap/wmbusmeters/common

log_file=${APP_ROOT}/logs/wmbusmeters.log

drop_in_dir=${APP_ROOT}/etc/wmbusmeters.d/
drop_in_dir=conf

meters=$(grep 'Received telegram from' ${log_file} |cut -d ' ' -f4 |sort -u)

function prepend() { while read line; do echo "${1}${line}"; done; }

for id in ${meters}; do
    data=$(grep -m1 "${id}" ${log_file} -A 6)
    detected_driver=$(echo "${data}" | grep driver | awk '{print $2}')
    device_type=$(echo "${data}" | grep type | awk '{print $2 "_" $3}')
    manufacturer=$(echo "${data}" | grep manufacturer | awk '{for(i=2;i<=NF;++i)printf $i""FS ; print ""}')
    device_type=$(echo "${data}" | grep type | awk '{for(i=2;i<=NF;++i)printf $i""FS ; print ""}')

    name=$(echo ${device_type} | awk '{print $1 "_" $2}' | tr '[:upper:]' '[:lower:]')_${id}

    if [ "${detected_driver}" == "unknown!" ]; then
        if [ "${manufacturer}" == "(TCH) Techem Service (0x5068) " ]; then
            if [ "${device_type}" == "Heat meter (0xc3) " ]; then
                driver=vario451
            fi
        fi
    else
        driver=${detected_driver}
    fi

    echo "# autoconf" > ${drop_in_dir}/${name}
    echo "${data}" | prepend "# " >> ${drop_in_dir}/${name}
    echo "name=${name}" >> ${drop_in_dir}/${name}
    echo "id=${id}" >> ${drop_in_dir}/${name}
    echo "driver=${driver}" >> ${drop_in_dir}/${name}
    # key
done

