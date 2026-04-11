#!/bin/bash
set -euo pipefail

SG_ID="${1:-}"

if [[ -z "$SG_ID" ]]; then
  echo "Usage: $0 <security-group-id>"
  echo "Example: $0 sg-xxxxxxxxxxxxxxxxx"
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account -o tsv)
REGION=$(aws configure get region)
SG_NAME=$(aws ec2 describe-security-groups \
  --group-ids "$SG_ID" \
  --query "SecurityGroups[0].GroupName" -o tsv)
VPC_ID=$(aws ec2 describe-security-groups \
  --group-ids "$SG_ID" \
  --query "SecurityGroups[0].VpcId" -o tsv)
OUTPUT="sg_rules_${SG_ID}_$(date +%Y%m%d_%H%M%S).csv"

echo "--------------------------------------------"
echo "Account  : $ACCOUNT_ID"
echo "Region   : $REGION"
echo "SG ID    : $SG_ID"
echo "SG Name  : $SG_NAME"
echo "VPC ID   : $VPC_ID"
echo "--------------------------------------------"
echo "Fetching rules..."

# ── CSV Header ────────────────────────────────
echo "Account_ID,Region,VPC_ID,SG_ID,SG_Name,Direction,Protocol,From_Port,To_Port,Source_Dest_CIDR,Source_Dest_SG,Prefix_List,Rule_Description" > "$OUTPUT"

# ── Helper function ───────────────────────────
append_rules() {
  local DIRECTION="$1"
  local PERMISSION_FIELD="$2"

  aws ec2 describe-security-groups \
    --group-ids "$SG_ID" \
    --region "$REGION" \
    --query "SecurityGroups[0].${PERMISSION_FIELD}[].[
      '$ACCOUNT_ID',
      '$REGION',
      '$VPC_ID',
      '$SG_ID',
      '$SG_NAME',
      '$DIRECTION',
      IpProtocol || '',
      to_string(FromPort) || 'All',
      to_string(ToPort) || 'All',
      join(';', IpRanges[].CidrIp || \`[]\`),
      join(';', UserIdGroupPairs[].GroupId || \`[]\`),
      join(';', PrefixListIds[].PrefixListId || \`[]\`),
      join(';', IpRanges[].Description || \`[]\`)
    ]" \
    --output tsv \
    | awk 'BEGIN{FS="\t"; OFS=","} {
        for(i=1; i<=NF; i++) {
          gsub(/"/, "\"\"", $i)
          printf "%s\"%s\"", (i>1 ? OFS : ""), $i
        }
        print ""
      }' >> "$OUTPUT"
}

# ── Inbound and Outbound ──────────────────────
append_rules "Inbound"  "IpPermissions"
append_rules "Outbound" "IpPermissionsEgress"

# ── Summary ───────────────────────────────────
TOTAL=$(( $(wc -l < "$OUTPUT") - 1 ))
INBOUND=$(grep -c "Inbound" "$OUTPUT" || true)
OUTBOUND=$(grep -c "Outbound" "$OUTPUT" || true)

echo "--------------------------------------------"
echo "✅ Export complete: $OUTPUT"
echo "   Total rules  : $TOTAL"
echo "   Inbound      : $INBOUND"
echo "   Outbound     : $OUTBOUND"
echo "--------------------------------------------"
echo "To download: Actions → Download file → enter: $OUTPUT"
