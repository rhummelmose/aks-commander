#!/bin/bash

BASE64_DECODER_PARAM="-d" # option -d for Linux base64 tool
echo AAAA | base64 -d > /dev/null 2>&1 || BASE64_DECODER_PARAM="-D" # option -D on MacOS

decode_base64_url() {
    local len=$((${#1} % 4))
    local result="$1"
    if [ $len -eq 2 ]; then result="$1"'=='
    elif [ $len -eq 3 ]; then result="$1"'='
    fi
    echo "$result" | tr '_-' '/+' | base64 $BASE64_DECODER_PARAM
}

decode_jose(){
    decode_base64_url $(echo -n $2 | cut -d "." -f $1) | jq .
}

decode_jwt_part(){
    decode_jose $1 $2 | jq 'if .iat then (.iatStr = (.iat|todate)) else . end | if .exp then (.expStr = (.exp|todate)) else . end | if .nbf then (.nbfStr = (.nbf|todate)) else . end'
}

decode_jwt(){
    decode_jwt_part 1 $1
    decode_jwt_part 2 $1
}

decode_jwt $1
