#!/bin/bash
set -euo pipefail

SG_ID="${1:-}"
REGION="${2:-$(aws configure get region)}"

if [[ -z "$SG_ID" ]]; then
  echo "Usage: $0 <security-group-id> [region]"
  echo "Example: $0 sg-xxxxxxxxxxxxxxxxx ap-south-1"
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account -o tsv)
SG_NAME=$(aws ec2 describe-security-groups \
  --group-ids "$SG_ID" \
  --query "SecurityGroups[0].GroupName" -o tsv)
OUTPUT="sg_rules_${SG_ID}_$(date +%Y%m%d_%H%M%S).csv"

echo "Fetching rules for: $SG_NAME ($SG_ID) in $REGION ..."

# ── Header ────────────────────────────────────────────────────────────────
echo "Account_ID,Region,SG_ID,SG_Name,Direction,Protocol,From_Port,To_Port,Source_Dest_CIDR,Source_Dest_SG,Prefix_List,Description" > "$OUTPUT"

# ── Helper: run query and append to CSV ───────────────────────────────────
append_rules() {
  local direction="$1"
  local permission_field="$2"

  aws ec2 describe-security-groups \
    --group-ids "$SG_ID" \
    --region "$REGION" \
    --query "SecurityGroups[0].${permission_field}[].[
      '$ACCOUNT_ID',
      '$REGION',
      '$SG_ID',
      '$SG_NAME',
      '$direction',
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

# ── Fetch Inbound and Outbound ─────────────────────────────────────────────
append_rules "Inbound"  "IpPermissions"
append_rules "Outbound" "IpPermissionsEgress"

RULE_COUNT=$(( $(wc -l < "$OUTPUT") - 1 ))
echo "✅ Exported $RULE_COUNT rules → $OUTPUT"
