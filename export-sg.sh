#!/bin/bash
SG_INPUT="$1"
REGION=$(aws configure get region)

if [[ $SG_INPUT == sg-* ]]; then
  GROUP_FILTER="--group-ids $SG_INPUT"
else
  GROUP_FILTER="--group-names $SG_INPUT"
fi

echo "Rule_ID,AWS_Account,Region,Server_Name_Asset,Instance_ID,VPC_ID,Subnet_ID,Security_Group_Name,Security_Group_ID,Direction,Protocol,Port_Port_Range,Source_Destination,Source_Type,Description" > sg_rules.csv

aws ec2 describe-security-groups $GROUP_FILTER --region $REGION --output json | \
jq -r "
  .SecurityGroups[0] as \$sg |
  (if \$sg.IpPermissions then \$sg.IpPermissions else [] end) as \$inbound |
  (if \$sg.IpPermissionsEgress then \$sg.IpPermissionsEgress else [] end) as \$outbound |
  [\$inbound[], \$outbound[]] | .[] |
  [
    (.SecurityGroupRuleId // empty),
    \"$(aws sts get-caller-identity --query Account --output text)\",
    \"$REGION\",
    (if \$sg.Instances[0].Tags then \$sg.Instances[0].Tags[] | select(.Key==\"Name\") | .Value else empty end),
    (\$sg.Instances[0].InstanceId // empty),
    (\$sg.VpcId // empty),
    (if \$sg.Instances[0] then \$sg.Instances[0].SubnetId else empty end),
    \$sg.GroupName,
    \$sg.GroupId,
    (if .IsEgress then \"Outbound\" else \"Inbound\" end),
    (.IpProtocol // \"all\"),
    (if .FromPort == .ToPort then .FromPort else (.FromPort + \"-\" + .ToPort) end),
    ((.CidrIpv4 // .CidrIpv6 // .ReferencedGroupInfo.GroupId) // \"0.0.0.0/0\"),
    (if .CidrIpv4 then \"CIDR\" elif .ReferencedGroupInfo then \"SG\" else \"Other\" end),
    (.Description // \$sg.Description)
  ] | @csv
" >> sg_rules.csv

echo "Exported to sg_rules.csv - ready for your workbook!"
