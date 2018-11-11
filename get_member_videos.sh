#!/usr/bin/env bash

# ==============================================================================
#      FILE: get_member_videos.sh
#   SUMMARY: get whole submitted videos of a member.
#    AUTHOR: Zach Cheung <kuroro.zhang@gmail.com>
#   VERSION: 1.0.0
#   CREATED: 11/12/2018 01:01
#  MODIFIED:
# COPYRIGHT: (c) 2018 by Zach Cheung
# ==============================================================================

show_help() {
    cat << EOF
Usage:

$0 bilibili_member_id|bilibli_member_space_url

Example:
$0 4289659
$0 "https://space.bilibili.com/4289659/#/"
EOF
}


get_member_videos_per_page() {
    local member_videos_api_url av_base_url mid page api_url api_data pages
    member_videos_api_url="https://space.bilibili.com/ajax/member/getSubmitVideos"
    av_base_url="https://www.bilibili.com/video/av"
    mid="$1"
    [[ -z $2 ]] && page=1 || page=$2
    # https://space.bilibili.com/ajax/member/getSubmitVideos?mid=4289659&pagesize=30&page=2&order=pubdate
    api_url="${member_videos_api_url}?mid=${mid}&pagesize=100&page=${page}&order=pubdate"
    api_data="$(curl -s "${api_url}")"
    pages=$(jq .data.pages <<< "${api_data}")

    echo "Requested ${page}/${pages} page." > /dev/stderr
    jq .data.vlist[].aid <<< "${api_data}" | awk -v \
        av_base_url="${av_base_url}" '{print av_base_url $0}'

    if [[ ${pages} -gt ${page} ]]; then
        ((page++))
        get_member_videos_per_page ${mid} ${page}
    fi
}


get_member_videos() {
    local tmp_file member_id
    tmp_file="$(mktemp -u)"
    member_id="$(awk '
    {
        if ($0 ~ /^[0-9]+$/) {
            member_id = $0;
        } else if ($0 ~ /^(https?:\/\/)?space\.bilibili\.com\/[0-9]+\/?.*$/) {
            member_id = gensub(/^.*space\.bilibili\.com\/([0-9]+)\/?.*$/, "\\1", "g");
        }
        printf member_id;
    }
    ' <<< "$1")"

    if [[ ${member_id} =~ ^[0-9]+$ ]]; then
        get_member_videos_per_page ${member_id} >> "${tmp_file}"
        echo "Done. Video urls file ${tmp_file} is ready."
    else
        echo "Invalid bilibili member id or member space url." > /dev/stderr
        show_help
        exit 1
    fi
}


if [[ ${BASH_SOURCE[0]} == $0 ]]; then
    if [[ $1 =~ ^(-h|--help)$ ]]; then
        show_help
    else
        get_member_videos "$1"
    fi
fi
