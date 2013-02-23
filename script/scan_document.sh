#!/bin/bash

usage()
{
    cat <<EOF
    usage: $0 options
    
    Scan documents and convert them into a pdf with searchable text.
    Also imports the documents into Project Alexandria with the specified tags.
    
    Options:
    -h   Show this message
    -i   path to an image file. useful for the 'images' mode. Paths may not include spaces. I can't handle them yet.
    -t   Tag the document with this tag (there could be multiple of these)
    -m   Mode: can be 'scan' or 'images' 
    -o   name of the output pdf
    -s   skip import into Project Alexandria
EOF
}

check_error()
{
    STATUS=$1
    ERROR_MESSAGE=$2
    if test $STATUS != 0
    then
	echo $ERROR_MESSAGE
	exit 1
    fi
}

MODE="err"
TAGS=""
IMAGES=""
SKIP_ALEXANDRIA=0
while getopts "ht:m:i:o:s" OPTION
do
    case $OPTION in 
	h) 
	    usage
	    exit 0
	    ;;
	t)
	    TAGS="${TAGS} ${OPTARG}"
	    ;;
	m)
	    if test ${OPTARG} == "scan"
	    then
		MODE=$OPTARG
	    elif test ${OPTARG} == "images"
	    then
		MODE=$OPTARG
	    else
		MODE="err"
	    fi
	    ;;
	i)
	    IMAGES="${IMAGES} ${OPTARG}"
	    ;;
	o)
	    RESULT_NAME=${OPTARG}
	    ;;
	s)
	    SKIP_ALEXANDRIA=1
	    ;;
    esac
done

if test $MODE == "err"
then
    usage
    exit 1
fi

WORKING_DIR=/tmp/scanned_documents
OUTPUT_DIR=/tmp/scans
mkdir -p $WORKING_DIR
mkdir -p $OUTPUT_DIR

rm $WORKING_DIR/* > /dev/null 2>&1

if test $MODE == "scan"
then
    PAGE_NUMBER=1
    READ_ANOTHER="Y"
    IMAGES=""
    while test $READ_ANOTHER == "Y"
    do
	echo "press return to start scan"
	read
	scanimage --format=tiff --mode Color > $WORKING_DIR/page_${PAGE_NUMBER}.tiff
	check_error $? "scan error. aborting"
	IMAGES="${IMAGES} ${WORKING_DIR}/page_${PAGE_NUMBER}.tiff"
	PAGE_NUMBER=`echo "${PAGE_NUMBER}+1" | bc`
	echo "scan another page? (Y/[n])"
	read READ_ANOTHER;
    done;
fi

PAGE_NUMBER=1
SOURCE_PDFS=""

for IMAGE_NAME in $IMAGES; do 
    tesseract $IMAGE_NAME "${WORKING_DIR}/page_${PAGE_NUMBER}" -l eng hocr
    check_error $? "tesseract error. aborting."
    
    hocr2pdf -i $IMAGE_NAME -o "${WORKING_DIR}/page_${PAGE_NUMBER}.pdf" < "${WORKING_DIR}/page_${PAGE_NUMBER}.html"
    check_error  $? "hocr2pdf error. aborting."
    
    SOURCE_PDFS="${SOURCE_PDFS} ${WORKING_DIR}/page_${PAGE_NUMBER}.pdf"
    PAGE_NUMBER=`echo "${PAGE_NUMBER}+1" | bc`
done

pdfjoin --fitpaper 'true' --no-tidy --outfile $OUTPUT_DIR/$RESULT_NAME ${SOURCE_PDFS}
check_error  $? "pdfjoin error. aborting."

if test $SKIP_ALEXANDRIA != 1
then
    alexandria_import.sh $OUTPUT_DIR/$RESULT_NAME $TAGS 
fi
