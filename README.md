# VCF to MAF Pipeline (vcf2maf + VEP)

Simple pipeline for:

- Filtering VCF (PASS + DP threshold)
- Converting VCF → MAF using vcf2maf + VEP
- Compressing output (bgzip)

---

## Requirements

Tools in `$PATH`:

- bcftools
- vcf2maf.pl
- VEP (with cache)
- bgzip

---

## Usage

```bash
./vcf2maf.sh <VCF> <OUT_DIR> [DP] [VEP_PATH] [VEP_DATA] [REF_FASTA] [NCBI_BUILD] [VEP_FORKS]
```

---

## Defaults

- DP = 10  
- VEP_PATH = /opt/miniconda3/envs/vep/bin  
- VEP_DATA = ~/shared/reference_data/vep_cache/...  
- REF_FASTA = ~/shared/reference_data/.../hg38.fa  
- NCBI_BUILD = GRCh38  
- VEP_FORKS = 4  

---

## Parallel execution (xargs)

Run multiple VCFs in parallel:

```bash
find <path-to-dir> -name "*vcf.gz" | xargs -P 4 -I {} ./vcf2maf.sh {} maf_output
```

With custom parameters:

```bash
find <path-to-dir> -name "*vcf.gz" | xargs -P 4 -I {} ./vcf2maf.sh {} maf_output 20
```

Notes:
- `-P 4` → number of parallel jobs  
- `-I {}` → placeholder for input file  

---

## Steps

1. Decompress (if needed)  
2. Filter variants (PASS, DP ≥ threshold)  
3. Count variants  
4. Convert to MAF (vcf2maf + VEP)  
5. Compress output (bgzip)  

---

## Output

- *.maf.gz  

Stored in:

```
OUT_DIR/
```

---

## Notes

- Uses FORMAT/DP field  
- Single-sample VCF expected  
- Skips file if no PASS variants  
- VEP cache must match reference (GRCh38)
