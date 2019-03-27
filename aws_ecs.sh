TOKEN=$(aws ecr get-login --no-include-email --region ap-southeast-1)
ECR_ADDRESS="8216354625.dkr.ecr.ap-southeast-1.amazonaws.com"
ECR_REPO="sample_test"
Tag_Name="sample_test"
#echo "$TOKEN"
echo "AWS ECR Registry : $ECR_ADDRESS/$ECR_REPO"
#$TOKEN
docker build -t $Tag_Name .
docker tag $Tag_Name:latest $ECR_ADDRESS/$ECR_REPO:latest
docker push $ECR_ADDRESS/$ECR_REPO:latest

if [ $? != "0" ]; then
        echo "ERROR: Docker push failed"
else
       echo "Pushing successfull"
fi
