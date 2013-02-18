#!/bin/bash

. /usr/local/share/alexandria/alexandria.sh

path=`pwd`/$1
shift
tags=$* 

cd $ALEXANDRIA_PATH
export RAILS_ENV=production
./script/rails runner script/import.rb "${path}" $tags
