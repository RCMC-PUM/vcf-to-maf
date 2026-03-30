#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <input_vcf> <output_maf_dir> [DP] [vep_path] [vep_data] [ref_fasta] [ncbi_build] [vep_forks]"
    exit 1
fi

VCF="$1"
OUT_DIR="$2"
DP_FIELD="FORMAT/DP"

# defaults
DP="${3:-10}"
VEP_PATH="${4:-/opt/miniconda3/envs/vep/bin}"
VEP_DATA="${5:-$HOME/shared/reference_data/vep_cache/vep_115/homo_sapiens/GRCh38/}"
REF_FASTA="${6:-$HOME/shared/reference_data/dragen_reference/v4_3/hg38/hg38.fa}"
NCBI_BUILD="${7:-GRCh38}"
VEP_FORKS="${8:-4}"

echo "----------------------------------------"
echo "[PARAMS]"
echo "VCF         : $VCF"
echo "OUT_DIR     : $OUT_DIR"
echo "DP field    : $DP_FIELD"
echo "DP          : $DP"
echo "VEP_PATH    : $VEP_PATH"
echo "VEP_DATA    : $VEP_DATA"
echo "REF_FASTA   : $REF_FASTA"
echo "NCBI_BUILD  : $NCBI_BUILD"
echo "VEP_FORKS   : $VEP_FORKS"
echo "----------------------------------------"

mkdir -p "$OUT_DIR"

filename=$(basename "$VCF")
sample=$(basename "$filename" | cut -d'.' -f1)

echo "----------------------------------------"
echo "[INFO: $sample] Processing input file: $filename for $sample"

TMP_VCF=$(mktemp)

# Decompress + filter PASS + DP threshold
if [[ "$VCF" == *.gz ]]; then
    echo "[INFO: $sample] decompressing and filtering"
    gzip -dc "$VCF" | bcftools view -f PASS -i "$DP_FIELD>=$DP" -Ov -o "$TMP_VCF"
else
    echo "[INFO: $sample] filtering"
    bcftools view -f PASS -i "$DP_FIELD>=$DP" "$VCF" -Ov -o "$TMP_VCF"
fi

pass_count=$(bcftools view -H "$TMP_VCF" | wc -l)
echo "[INFO: $sample] PASS variants: $pass_count"

if [[ "$pass_count" -eq 0 ]]; then
    echo "[WARN: $sample] No PASS variants, skipping"
    rm -f "$TMP_VCF"
    exit 0
fi

echo "[INFO: $sample] Running vcf2maf..."
vcf2maf.pl \
    --input-vcf "$TMP_VCF" \
    --output-maf "$OUT_DIR/${sample}.maf" \
    --vep-path "$VEP_PATH" \
    --vep-data "$VEP_DATA" \
    --ref-fasta "$REF_FASTA" \
    --tumor-id "$sample" \
    --species homo_sapiens \
    --ncbi-build "$NCBI_BUILD" \
    --vep-forks "$VEP_FORKS" \
    --verbose

rm -f "$TMP_VCF"

echo "[INFO: $sample] bgzip compressing..."
bgzip "$OUT_DIR/${sample}.maf"

echo "[INFO $sample] Done"