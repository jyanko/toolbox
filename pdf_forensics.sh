#!/bin/bash

# PDF Forensic Analysis Script
# Analyzes PDFs for signs of post-creation modification

echo "PDF Forensic Analysis Report"
echo "Generated: $(date)"
echo "=========================================="
echo ""

# Check for required tools
MISSING_TOOLS=""
command -v exiftool >/dev/null 2>&1 || MISSING_TOOLS="$MISSING_TOOLS exiftool"
command -v qpdf >/dev/null 2>&1 || MISSING_TOOLS="$MISSING_TOOLS qpdf"
command -v pdfinfo >/dev/null 2>&1 || MISSING_TOOLS="$MISSING_TOOLS pdfinfo(poppler)"

if [ -n "$MISSING_TOOLS" ]; then
    echo "WARNING: Missing tools:$MISSING_TOOLS"
    echo "Install with: brew install exiftool qpdf poppler"
    echo ""
fi

# Summary counters
TOTAL=0
UNMODIFIED=0
MODIFIED=0
HIGHLY_MODIFIED=0

# Process each PDF
for pdf in *.pdf; do
    [ -e "$pdf" ] || continue
    TOTAL=$((TOTAL + 1))
    
    echo "----------------------------------------"
    echo "FILE: $pdf"
    echo "----------------------------------------"
    
    # Count EOF markers (indicates number of saves)
    EOF_COUNT=$(grep -c -a "%%EOF" "$pdf" 2>/dev/null || echo "0")
    echo "Save Count: $EOF_COUNT EOF marker(s)"
    
    if [ "$EOF_COUNT" -eq 1 ]; then
        echo "Status: UNMODIFIED (original, never edited)"
        UNMODIFIED=$((UNMODIFIED + 1))
    elif [ "$EOF_COUNT" -eq 2 ]; then
        echo "Status: MODIFIED (edited once after creation)"
        MODIFIED=$((MODIFIED + 1))
    elif [ "$EOF_COUNT" -ge 3 ]; then
        echo "Status: HIGHLY MODIFIED (edited $((EOF_COUNT - 1)) times)"
        HIGHLY_MODIFIED=$((HIGHLY_MODIFIED + 1))
    fi
    
    # Get file timestamps
    echo ""
    echo "Filesystem Timestamps:"
    stat -f "  Created: %SB" -t "%Y-%m-%d %H:%M:%S %Z" "$pdf" 2>/dev/null
    stat -f "  Modified: %Sm" -t "%Y-%m-%d %H:%M:%S %Z" "$pdf" 2>/dev/null
    
    # Get PDF metadata if exiftool is available
    if command -v exiftool >/dev/null 2>&1; then
        echo ""
        echo "PDF Metadata:"
        
        # Extract key metadata fields
        PRODUCER=$(exiftool -s -s -s -Producer "$pdf" 2>/dev/null)
        CREATOR=$(exiftool -s -s -s -Creator "$pdf" 2>/dev/null)
        CREATE_DATE=$(exiftool -s -s -s -CreateDate "$pdf" 2>/dev/null)
        MOD_DATE=$(exiftool -s -s -s -ModDate "$pdf" 2>/dev/null)
        PDF_VERSION=$(exiftool -s -s -s -PDFVersion "$pdf" 2>/dev/null)
        TITLE=$(exiftool -s -s -s -Title "$pdf" 2>/dev/null)
        
        [ -n "$PRODUCER" ] && echo "  Producer: $PRODUCER"
        [ -n "$CREATOR" ] && echo "  Creator: $CREATOR"
        [ -n "$CREATE_DATE" ] && echo "  CreateDate: $CREATE_DATE"
        [ -n "$MOD_DATE" ] && echo "  ModifyDate: $MOD_DATE"
        [ -n "$PDF_VERSION" ] && echo "  PDF Version: $PDF_VERSION"
        [ -n "$TITLE" ] && echo "  Title: $TITLE"
        
        # Flag if no creation date
        if [ -z "$CREATE_DATE" ] && [ -z "$MOD_DATE" ]; then
            echo "  ⚠️  WARNING: No embedded creation/modification dates found"
        fi
    fi
    
    # Check for date strings in the PDF structure
    echo ""
    echo "Dates Found in PDF Structure:"
    DATE_MATCHES=$(strings "$pdf" | grep -i "date" | grep -v "update" | head -5)
    if [ -n "$DATE_MATCHES" ]; then
        echo "$DATE_MATCHES" | sed 's/^/  /'
    else
        echo "  None found"
    fi
    
    # If qpdf is available and file was modified, show incremental update info
    if [ "$EOF_COUNT" -gt 1 ] && command -v qpdf >/dev/null 2>&1; then
        echo ""
        echo "Incremental Update Analysis:"
        XREF_SECTIONS=$(qpdf --show-xref "$pdf" 2>/dev/null | grep -c "xref" || echo "0")
        echo "  Cross-reference sections: $XREF_SECTIONS"
        echo "  (Multiple sections confirm the file was incrementally updated)"
    fi
    
    # Check for suspicious patterns
    echo ""
    echo "Suspicious Indicators:"
    SUSPICIOUS=0
    
    if [ "$EOF_COUNT" -gt 1 ] && [ -z "$MOD_DATE" ]; then
        echo "  ⚠️  File was modified but has no ModDate metadata"
        SUSPICIOUS=$((SUSPICIOUS + 1))
    fi
    
    if [ -z "$PRODUCER" ] && [ -z "$CREATOR" ]; then
        echo "  ⚠️  No producer/creator information (metadata may be stripped)"
        SUSPICIOUS=$((SUSPICIOUS + 1))
    fi
    
    if [ "$SUSPICIOUS" -eq 0 ]; then
        echo "  None detected"
    fi
    
    echo ""
done

# Print summary
echo "========================================"
echo "SUMMARY"
echo "========================================"
echo "Total PDFs analyzed: $TOTAL"
echo "Unmodified (1 EOF): $UNMODIFIED"
echo "Modified once (2 EOF): $MODIFIED"
echo "Modified multiple times (3+ EOF): $HIGHLY_MODIFIED"
echo ""
echo "CONCLUSION:"
if [ "$MODIFIED" -gt 0 ] || [ "$HIGHLY_MODIFIED" -gt 0 ]; then
    echo "⚠️  $(($MODIFIED + $HIGHLY_MODIFIED)) PDF(s) show evidence of post-creation modification"
    echo ""
    echo "RECOMMENDATION:"
    echo "- Compare file modification dates with email receipt timestamps"
    echo "- Review the modified files for content changes"
    echo "- Check if modifications occurred before or after the dates they represent"
else
    echo "✓ All PDFs appear to be original, unmodified files"
fi
echo ""
echo "Email Receipt Times (from your description):"
echo "  Email 1: Oct 21, 2025 at 7:57 AM PDT"
echo "  Email 2: Oct 21, 2025 at 8:03 AM PDT"
echo ""
echo "If any file shows filesystem modification dates BEFORE the email"
echo "receipt time, this suggests the file was modified after emailing."

