#!/usr/bin/env bash

# helper functions
show_help() {
cat << EOF

Usage: ${0##*/} [-hv] [-t TILE] [-r RESOLUTION] [-l LEVEL] OUTFILE

Download a satellite image (from the S3 bucket for Sentinel-2 mission) of a
geographic TILE at the specified RESOLUTION, storing the result in file OUTFILE.
  -h              display this help and exit
  -t TILE         name of the geographic tile to download from the Sentinel-2
                  S3 bucket (defaults to san francisco's tile)
  -r RESOLUTION   resolution of image by square meter: one of R10m, R20m, R60
                  (defaults to R60m)
  -l LEVEL        type of image by height of atmospheric reflection: one of
                  L1C, L2A (defaults to L2A)
  -o OUTDIR       directory to write files out to
  -v              verbosity, can be used multiple times for increased verbosity
  OUTFILE         filename for the final satellite image

The satellite images will be saved according to their bands: B04, the wavelength
for red; B03, the wavelength for Green; B02, the wavelength for Blue. If OUTFILE
is specified, then convert the three bands into an RGB JPEG of quality 80 using
ImageMagick
  TODO consider allowing to specify OUT_DIR, where the bands will be stored.
       will default to current dir.

You must have the AWS S3 CLI installed to run this script, and have your
credentials configured. You must also have ImageMagic installed.
WARNING running this script will incur charges to the S3 account, the Sentinel-2
S3 bucket has a policy where the "Requester Pays" for access.

TODO allow for a $MAGICK command line arg, which will be a argument string
passed into the imagemagic convert call.
EOF
}

# set variables to default

VERBOSE=0
TILE="10/S/EG/2021/2/28/0/" # san francisco
RESOLUTION="R60m"
LEVEL="L2A" # bottom of the atmospheric reflection, is a richer looking image
OUTDIR="."
OUTFILE="out.jpg" # should I put a default? (get's overriden right now anyway...)

# TODO read in command line arguments

# TODO if I want long arguments, check out this page http://mywiki.wooledge.org/BashFAQ/035#getopts
# to see how to perform custom CLI arg parsing in bash, really not that hard.

OPTIND=1 # reset OPTIND in case getopts was called before
while getopts 'hvt:r:l:' opt; do
  case $opt in
    (h) show_help; exit 0;;
    (v) ((VERBOSE++));;
    (t) TILE=$OPTARG;;
    (r) RESOLUTION=$OPTARG;;
    (l) LEVEL=$OPTARG;;
    (o) OUTDIR=$OPTARG;;
    (*) show_help >&2; exit 1;;
  esac
done
shift "$((OPTIND-1))"   # Discard the options and sentinel --
OUTFILE="$@" # TODO maybe trim this to only collect the first filename? The one
             # before a space character or end of string?

# TODO validate arguments

if ((VERBOSE > 1)); then
  printf "VERBOSE=%d\nTILE=%s\nRESOLUTION=%s\nLEVEL=%s\nOUTDIR=%s\nOUTFILE=%s\n" \
    "$VERBOSE" \
    "$TILE" \
    "$RESOLUTION" \
    "$LEVEL" \
    "$OUTDIR" \
    "$OUTFILE";
fi
if ((VERBOSE > 0)); then
  printf '%s\n' 'downloading the file XXX...';
fi
if [[ ! $OUTFILE ]]; then
  printf '%s\n' 'please specify an output filename';
  exit 1;
fi
# TODO remove trailing slash from TILE and RESOLUTION

# download the atmospheric band images

aws s3 cp s3://sentinel-s2-l2a/tiles/$TILE/$RES/B04.jp2 "$OUTDIR" --request-payer requester
aws s3 cp s3://sentinel-s2-l2a/tiles/$TILE/$RES/B03.jp2 "$OUTDIR" --request-payer requester
aws s3 cp s3://sentinel-s2-l2a/tiles/$TILE/$RES/B02.jp2 "$OUTDIR" --request-payer requester
# TODO check if this works?
aws s3 cp "s3://sentinel-s2-l2a/tiles/$TILE/$RES/B0{4,3,2}.jp2" "$OUTDIR" --request-payer requester

# combine bands into a single RGB image

convert B04.jp2 B03.jp2 B02.jp2 \
  -combine \
  -interlace plane \
  -colorspace sRGB \
  -level 0,7500 \
  -sampling-factor 4:2:2 \
  -quality 80 \
  "$OUTDIR/$OUTFILE"
