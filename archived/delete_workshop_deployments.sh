#!/bin/bash
PATH=/usr/local/bin/:$PATH

read -p 'ESS Deployment Name: ' WS_NAME
if [ -z "$WS_NAME" ];
then
    exit -1;
fi

DEPLOYMENTS=(`ecctl deployment list --output json | jq -r --arg WS_NAME "$WS_NAME" '.deployments[] | select (.name | contains($WS_NAME)) | { id: .id, name: .name } | @base64'`)
n=${#DEPLOYMENTS[@]}
if [ $n -eq 0 ];
then
   echo "No deployment(s) found"
   exit -1
fi

echo -e "\nFound $n matching deployment(s):\n"
for DEPLOYMENT in ${DEPLOYMENTS[@]};
do
    echo $DEPLOYMENT | base64 --decode | jq -r '. | .name '
done

echo
read -p 'Delete deployment(s)? [Y/N] ' RESPONSE
case $RESPONSE in
    [yY])
         for DEPLOYMENT in ${DEPLOYMENTS[@]};
         do
            NAME=`echo $DEPLOYMENT | base64 --decode | jq -r '. | .name '`
            ID=`echo $DEPLOYMENT | base64 --decode | jq -r '. | .id '`
            echo -e "\nDeleting Deployment \"$NAME\" [$ID]"
            ecctl deployment shutdown $ID --force -q
         done
    ;;
esac
