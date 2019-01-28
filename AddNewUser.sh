#!/bin/bash
set -e
set -u
usage(){
cat << EOF
Usage
create_user [-u] <Username> [-c] [-p]  <Policy ARN>,...,<Policy ARN> [-t] <Key>,<Value>,<Key>,<Value> [-m] <Mail ID>
      u - Pass username
      c - Create IAM User 
      p - Use it to attach user polciy. Pass Policy ARN with comma seperated
      t - Use it to add Tags to user. Pass key,value,key,value as needed
EOF
}
while getopts u:p:t:m:cqh options; do
	case $options in 
                u) user=$OPTARG
                   ;;
		c) aws iam create-user --user-name $user
                   aws iam create-login-profile --user-name $user --password 12345678 --password-reset-required
                   ;;
		p) temp_array=$(echo $OPTARG  | sed 's/,/ /g')
                   policy_array=($temp_array)
                   for var in ${policy_array[@]}; do
 			aws iam attach-user-policy --policy-arn $var  --user-name $user
		   done
                   ;;
                t) temp_array=$(echo $OPTARG  | sed 's/,/ /g')
                   tag_array=($temp_array)
                   a=0;
                   echo ${#tag_array[*]}
                   for var in `seq 0 2 ${#tag_array[*]}`; do
		        if [ $var -lt ${#tag_array[*]}  ] 
                    	then 
                        aws iam tag-user --user-name $user   --tags Key=${tag_array[var]},Value=${tag_array[var+1]}
			fi
                done
                   ;;
                m) send_mail=$OPTARG
                   mail -s "AWS USER Details" "$send_mail"  <<EOF 
Hope,You are doing Great.		
EOF
		   ;;	
                h) usage
                   ;;
                ?) usage
                   ;;

        esac
done
