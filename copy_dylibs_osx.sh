#!/bin/bash
#
# Use for OSX deployment:
# Copies dylibs required by executable
#    and sets paths up correctly

if [ $# -eq 0 ]; then
  export appname=${PWD##*/}
else
  export appname=$1
fi

cd bin

if [ $# -eq 1 ]; then
  export libpath=$2
else
  if [ -d "${appname}.app" ]; then
    export libpath='../Frameworks/'
  else
    export libpath=''
  fi
fi

if [ ! -z "$libpath" ]; then
  # assuming appname.app exists already
  mkdir -p ${appname}.app/Contents/Frameworks

  # copy dylibs
  cd ${appname}.app/Contents/Frameworks
fi

setup_dylib()
{
  otool -L $1 | \
  sed -e "/\/usr\/local/$(echo \!)d;/${1}/d;s:^[$(printf '\t')]\(/usr/local/\([^ /]*/\)*\)\([^ ]*\).*:cp \1\3 ./\3"'\'$'\n'"sudo install_name_tool -id @executable_path/${libpath}\3 ./\3"'\'$'\n'"sudo install_name_tool -change \1\3 @executable_path/${libpath}\3 $1"'\'$'\n'"setup_dylib \3:" | \
  tr '\n' '\0' | \
  xargs -0 -I % sh -c %
}

export -f setup_dylib
setup_dylib ${appname}

cd ..
