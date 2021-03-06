#!/bin/bash -e

IMAGE="ssai_ad_insertion_ad_static"
DIR=$(dirname $(readlink -f "$0"))
SIZE=(3840x2160 2560x1440 1920x1080 1280x720 842x480 640x360)
DS=0 # display start
DE=5 # display end
DEDASH=5 # display end
FID=1.0 # fade in duration
FOD=1.0 # fade out duration
SEG=5 # segment duration
SEG_DASH=5000000 # segment duration
FR=25
MIN_H=360

case "$(cat /proc/1/sched | head -n 1)" in
*build.sh*)
    cd /mnt

    if test "$1" == "adstatic"; then
        if [ -n ${2} ]; then
            MIN_H="$(echo ${2} |grep -oE '^[[:digit:]]+')"
        fi
    else
        # $5 is the MINRESOLUTION if there are not args specified
        if [ -n ${5} ]; then
            MIN_H="$(echo ${5} |grep -oE '^[[:digit:]]+')"
        fi
    fi

    for s in "${SIZE[@]}"; do
        h=${s/*x}

        if [ ${h} -lt ${MIN_H} ]; then
          rm -f ${h}p*
          continue
        fi

        if test ! -f ${h}p_000.ts; then
            ffmpeg -f lavfi -i anullsrc=sample_rate=48000 -f lavfi -i color=c=blue:s=$s:d=$DE -vf "drawtext=text='Server-Side AD Insertion':x=(w-text_w)/2:y=(h-text_h)/2:fontsize=45:fontcolor_expr=ffffff%{eif\\\\: clip(255*(1*between(t\\, $DS + $FID\\, $DE - $FOD) + ((t - $DS)/$FID)*between(t\\, $DS\\, $DS + $FID) + (-(t - $DE)/$FOD)*between(t\\, $DE - $FOD\\, $DE) )\\, 0\\, 255) \\\\: x\\\\: 2 }" -shortest -c:a aac -c:v libx264 -g ${FR} -keyint_min ${FR} -f hls -hls_segment_filename ${h}p_%03d.ts -hls_time $SEG -y -hls_list_size $((DE/SEG)) ${h}p.m3u8
        fi
        if test ! -f ${h}p-chunk-stream1-00001.m4s; then
            ffmpeg -f lavfi -i anullsrc=sample_rate=48000 -f lavfi -i color=c=blue:s=$s:d=$DE -vf "drawtext=text='Server-Side AD Insertion':x=(w-text_w)/2:y=(h-text_h)/2:fontsize=45:fontcolor_expr=ffffff%{eif\\\\: clip(255*(1*between(t\\, $DS + $FID\\, $DE - $FOD) + ((t - $DS)/$FID)*between(t\\, $DS\\, $DS + $FID) + (-(t - $DE)/$FOD)*between(t\\, $DE - $FOD\\, $DE) )\\, 0\\, 255) \\\\: x\\\\: 2 }" -shortest -c:a aac -c:v libx264 -g ${FR} -keyint_min ${FR} -f dash -init_seg_name ${h}p-'init-stream$RepresentationID$.m4s' -media_seg_name ${h}p-'chunk-stream$RepresentationID$-$Number%05d$.m4s' -use_template 1 -min_seg_duration ${SEG_DASH} -use_timeline 0 -y ${h}p.mpd
        fi
    done
    ;;
*) 
    mkdir -p "$DIR/../../volume/ad/static"
    . "$DIR/../../script/build.sh"
    . "$DIR/shell.sh" /home/build.sh $@
    ;;
esac
