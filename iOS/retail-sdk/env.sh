# Load this with ". env.sh", NOT by running it
if [ ! -d sdkenv ]; then
  echo "Setting up nodeenv"
  if ! type "nodeenv" > /dev/null 2>&1; then
    sudo easy_install nodeenv
  fi
  nodeenv --node=4.2.2 --with-npm --npm=3.5.1 --prebuilt sdkenv
fi
. sdkenv/bin/activate
echo "NODE `node -v` NPM `npm -v`"
