#!/bin/bash
set -euo pipefail

SG_ID="${1:-}"
REGION="${2:-}"

if [[ -z "$SG_ID" || -z "$REGION" ]]; then
  echo "Usage: $0 <security-group-id> <region>"
  echo "Example: $0 sg-xxxxxxxxxxxxxxxxx ap-south-1"
  exit 1
fi

export AWS_DEFAULT_REGION="$REGION"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
SG_NAME=$(aws ec2 describe-security-groups \
  --group-ids "$SG_ID" \
  --query "SecurityGroups[0].GroupName" --output text)
VPC_ID=$(aws ec2 describe-security-groups \
  --group-ids "$SG_ID" \
  --query "SecurityGroups[0].VpcId" --output text)
OUTPUT="sg_rules_${SG_ID}_$(date +%Y%m%d_%H%M%S).csv"

echo "--------------------------------------------"
echo "Account  : $ACCOUNT_ID"
echo "Region   : $REGION"
echo "SG ID    : $SG_ID"
echo "SG Name  : $SG_NAME"
echo "VPC ID   : $VPC_ID"
echo "--------------------------------------------"
echo "Fetching ALL rules with pagination..."

# ── CSV Header — added SG_Rule_ID as first column ──
echo "SG_Rule_ID,Account_ID,Region,VPC_ID,SG_ID,SG_Name,Direction,Protocol,From_Port,To_Port,Source_Dest_CIDR,Source_Dest_SG,Prefix_List,Rule_Description" > "$OUTPUT"

# ── Fetch all pages and write to CSV ─────────
NEXT_TOKEN=""
PAGE=1
TOTAL_FETCHED=0

while true; do
  echo "  Fetching page $PAGE..."

  if [[ -z "$NEXT_TOKEN" ]]; then
    RESPONSE=$(aws ec2 describe-security-group-rules \
      --filters "Name=group-id,Values=$SG_ID" \
      --max-results 100 \
      --region "$REGION" \
      --output json)
  else
    RESPONSE=$(aws ec2 describe-security-group-rules \
      --filters "Name=group-id,Values=$SG_ID" \
      --max-results 100 \
      --next-token "$NEXT_TOKEN" \
      --region "$REGION" \
      --output json)
  fi

  # Write rules from this page to CSV using Python
  PAGE_COUNT=$(echo "$RESPONSE" | python3 <<PYEOF
import json, sys

data  = json.loads("""$(echo "$RESPONSE" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)))")""")
rules = data.get("SecurityGroupRules", [])

ACCOUNT_ID = "$ACCOUNT_ID"
REGION     = "$REGION"
VPC_ID     = "$VPC_ID"
SG_ID      = "$SG_ID"
SG_NAME    = "$SG_NAME"

with open("$OUTPUT", "a") as out:
    for rule in rules:
        rule_id   = rule.get("SecurityGroupRuleId") or ""   # <── new field
        direction = "Outbound" if rule.get("IsEgress") else "Inbound"
        protocol  = rule.get("IpProtocol") or ""
        from_port = str(rule.get("FromPort")) if rule.get("FromPort") is not None else "All"
        to_port   = str(rule.get("ToPort"))   if rule.get("ToPort")   is not None else "All"
        cidr      = rule.get("CidrIpv4") or rule.get("CidrIpv6") or ""
        ref_sg    = (rule.get("ReferencedGroupInfo") or {}).get("GroupId") or ""
        prefix    = rule.get("PrefixListId") or ""
        desc      = rule.get("Description") or ""

        row     = [rule_id, ACCOUNT_ID, REGION, VPC_ID, SG_ID, SG_NAME,   # <── rule_id added
                   direction, protocol, from_port, to_port,
                   cidr, ref_sg, prefix, desc]
        escaped = ['"' + f.replace('"', '""') + '"' for f in row]
        out.write(",".join(escaped) + "\n")

print(len(rules))
PYEOF
  )

  TOTAL_FETCHED=$(( TOTAL_FETCHED + PAGE_COUNT ))
  echo "  Page $PAGE → $PAGE_COUNT rules fetched (running total: $TOTAL_FETCHED)"

  # Check for next page
  NEXT_TOKEN=$(echo "$RESPONSE" | python3 -c \
    "import json,sys; print(json.load(sys.stdin).get('NextToken',''))" 2>/dev/null
