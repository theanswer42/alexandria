#!/bin/bash

. /usr/local/share/alexandria/alexandria.sh

if [[ $1 =~ ^\/ ]]
then
    path=$1
else
    path=`pwd`/$1
fi
shift
tags=$* 

cd $ALEXANDRIA_PATH
export RAILS_ENV=production
./script/rails runner script/import.rb "${path}" $tags
