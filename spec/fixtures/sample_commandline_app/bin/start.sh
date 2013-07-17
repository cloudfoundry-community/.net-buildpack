#!/usr/bin/env bash 

BASE_DIR=$(cd $(dirname $0); cd ..; pwd) # absolute path to "root" folder of app

mono $BASE_DIR/bin/SampleCommandLineApp.exe