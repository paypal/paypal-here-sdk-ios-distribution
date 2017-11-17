#!/bin/bash

#usage add-license.sh 
#Param 1=absolute path to the license file
#Param 2=the file extension to add the license to, without the .
#param 3=the command to execute ("addLicenseDir" for current directory only or addLicenseRecurse for subdirectories)
#param 4=optional, the directory to process (absolute path)
#example on windows:
# C:\PayPal\testlicense\add-license.sh C:\PayPal\testlicense\license.txt js addLicenseRecurse C:\PayPal\testlicense\js
# C:\PayPal\testlicense\add-license.sh C:\PayPal\testlicense\license.txt js addLicenseDir C:\PayPal\testlicense\js

addLicenseRecurse() {
echo "addLicenseDir $1 $2"
addLicenseDir $1 $2
echo "Look for subdirectories in ${PWD}"
for d in ./*/
do
  echo "Check if $d is a directory"
  if [ -d "$d" ]; then
    echo "Processing dir $d"
    (cd -- "$d" && addLicenseRecurse $1 $2)
  else
    echo "$d is not a directory"
  fi
done
}

addLicenseDir() {
echo "Processing addLicenseDir $1 $2 PWD: ${PWD}"
  for i in *.$2
  do
    if [ -f $i ];
    then
      echo "Processing file $i"
      if ! grep -q Copyright $i
      then
        echo "Add license to file $i"
        cat $1 $i >$i.new && mv $i.new $i
      fi
    fi
  done
}

echo "Processing $1 $2 $3 $4"
if [ -d "$4" ]; then
  echo "Processing dir $4"
  cd -- "$4"
fi
    $3 $1 $2
read -p "Press any key to continue..."