#!/bin/bash

###########################
# Telegram Bot Bash v 0.0 #
########################################################################
# fork of https://github.com/topkecleon/telegram-bot-bash              #
########################################################################
# Copyright 2016 vbextreme <vbextreme.vbextreme@gmail.com>             #
#                                                                      #
# This program is free software; you can redistribute it and/or modify #
# it under the terms of the GNU General Public License as published by #
# the Free Software Foundation; either version 2 of the License, or    #
# (at your option) any later version.                                  #
#                                                                      #
# This program is distributed in the hope that it will be useful,      #
# but WITHOUT ANY WARRANTY; without even the implied warranty of       #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        #
# GNU General Public License for more details.                         #
#                                                                      #
# You should have received a copy of the GNU General Public License    #
# along with this program; if not, write to the Free Software          #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,           #
# MA 02110-1301, USA.                                                  #
#                                                                      #
########################################################################

function usage(){
	echo "unofficial telegram bash bot"
	echo "-b | --bot             ### bot name"
	echo "-a | --async           ### command as async (yes, no)"
	echo "-i | --inline          ### enable inline bot (0,1)"
	echo "-x | --file-regex      ### to allow sending files from all locations"
	echo "-m | --message		 ### send message (chat id, mode, message)"
	echo "-p | --prefix          ### change directory"
	echo "-h | --help            ### display this"
	echo ""
}

if [ ! -f "JSON.sh/JSON.sh" ]; then
	echo "missing json, http://github.com/dominictarr/JSON.sh"
	exit 1;
fi

SCRIPT_LOOP="yes"
BOT_PREFIX="../bot"
BOT_NAME=
INLINE=0
PARSE_ASYNC=yes
FILE_REGEX='~/.*'
SND_CHAT_ID=
SND_MODE="no"
SND_MESSAGE=
CORE_PID=$$

while [[ $# != 0 ]]; do
	te="$1"
	case $te in
		-h|--help)
			usage
			exit 0
		;;
		-b)
			BOT_NAME="$2"
			shift
		;;
		-a|--async)
			PARSE_ASYNC=$2
			shift
		;;
		-i|--inline)
			INLINE="$2"
			shift
		;;
		-x|--file-regex)
			FILE_REGEX="$2"
			shift
		;;
		-m|--message)
			SCRIPT_LOOP="no"
			SND_CHAT_ID="$2"
			SND_MODE="$3"
			SND_MESSAGE="$4"
			shift
			shift
			shift
		;;
		*)
			Usage
			exit 0
		;;
	esac
	shift
done

TOKEN_FILE="$BOT_PREFIX/$BOT_NAME/token"
COMMAND_SCRIPT="$BOT_PREFIX/$BOT_NAME/command"

if [ ! -f $TOKEN_FILE ]; then
	echo "no token, -h for help"
	exit 1
fi
TOKEN=$(cat "$TOKEN_FILE")

URL='https://api.telegram.org/bot'$TOKEN
SCRIPT="$0"
MSG_URL=$URL'/sendMessage'
LEAVE_URL=$URL'/leaveChat'
MEMBER_URL=$URL'/getChatMember'
GETADMIN_URL=$URL'/getChatAdministrators'
KICK_URL=$URL'/kickChatMember'
UNBAN_URL=$URL'/unbanChatMember'
PHO_URL=$URL'/sendPhoto'
AUDIO_URL=$URL'/sendAudio'
DOCUMENT_URL=$URL'/sendDocument'
STICKER_URL=$URL'/sendSticker'
VIDEO_URL=$URL'/sendVideo'
VOICE_URL=$URL'/sendVoice'
LOCATION_URL=$URL'/sendLocation'
VENUE_URL=$URL'/sendVenue'
ACTION_URL=$URL'/sendChatAction'
FORWARD_URL=$URL'/forwardMessage'
INLINE_QUERY=$URL'/answerInlineQuery'
ME_URL=$URL'/getMe'
ME=$(curl -s $ME_URL | ./JSON.sh/JSON.sh -s | egrep '\["result","username"\]' | cut -f 2 | cut -d '"' -f 2)

FILE_URL='https://api.telegram.org/file/bot'$TOKEN'/'
UPD_URL=$URL'/getUpdates?offset='
GET_URL=$URL'/getFile'
OFFSET=0
declare -A USER MESSAGE URLS CONTACT LOCATION CHAT CHATMEMBER

urlencode() {
	echo "$*" | sed 's:%:%25:g;s: :%20:g;s:<:%3C:g;s:>:%3E:g;s:#:%23:g;s:{:%7B:g;s:}:%7D:g;s:|:%7C:g;s:\\:%5C:g;s:\^:%5E:g;s:~:%7E:g;s:\[:%5B:g;s:\]:%5D:g;s:`:%60:g;s:;:%3B:g;s:/:%2F:g;s:?:%3F:g;s^:^%3A^g;s:@:%40:g;s:=:%3D:g;s:&:%26:g;s:\$:%24:g;s:\!:%21:g;s:\*:%2A:g'
}

send_message() {
	[ "$2" = "" ] && return 1
	local chat="$1"
	local text="$(echo "$2" | sed 's/ mykeyboardstartshere.*//g;s/ myfilelocationstartshere.*//g;s/ mylatstartshere.*//g;s/ mylongstartshere.*//g;s/ mytitlestartshere.*//g;s/ myaddressstartshere.*//g')"
	local arg="$3"
	[ "$3" != "safe" ] && {
		local keyboard="$(echo "$2" | sed '/mykeyboardstartshere /!d;s/.*mykeyboardstartshere //g;s/ myfilelocationstartshere.*//g;s/ mylatstartshere.*//g;s/ mylongstartshere.*//g;s/ mytitlestartshere.*//g;s/ myaddressstartshere.*//g')"

		local file="$(echo "$2" | sed '/myfilelocationstartshere /!d;s/.*myfilelocationstartshere //g;s/ mykeyboardstartshere.*//g;s/ mylatstartshere.*//g;s/ mylongstartshere.*//g;s/ mytitlestartshere.*//g;s/ myaddressstartshere.*//g')"

		local lat="$(echo "$2" | sed '/mylatstartshere /!d;s/.*mylatstartshere //g;s/ mykeyboardstartshere.*//g;s/ myfilelocationstartshere.*//g;s/ mylongstartshere.*//g;s/ mytitlestartshere.*//g;s/ myaddressstartshere.*//g')"

		local long="$(echo "$2" | sed '/mylongstartshere /!d;s/.*mylongstartshere //g;s/ mykeyboardstartshere.*//g;s/ myfilelocationstartshere.*//g;s/ mylatstartshere.*//g;s/ mytitlestartshere.*//g;s/ myaddressstartshere.*//g')"

		local title="$(echo "$2" | sed '/mytitlestartshere /!d;s/.*mylongstartshere //g;s/ mykeyboardstartshere.*//g;s/ myfilelocationstartshere.*//g;s/ mylatstartshere.*//g;s/ myaddressstartshere.*//g')"

		local address="$(echo "$2" | sed '/myaddressstartshere /!d;s/.*mylongstartshere //g;s/ mykeyboardstartshere.*//g;s/ myfilelocationstartshere.*//g;s/ mylatstartshere.*//g;s/ mytitlestartshere.*//g')"

	}
	if [ "$keyboard" != "" ]; then
		send_keyboard "$chat" "$text" "$keyboard"
		local sent=y
	fi
	if [ "$file" != "" ]; then
		send_file "$chat" "$file" "$text"
		local sent=y
	fi
	if [ "$lat" != "" -a "$long" != "" -a "$address" = "" -a "$title" = "" ]; then
		send_location "$chat" "$lat" "$long"
		local sent=y
	fi
	if [ "$lat" != "" -a "$long" != "" -a "$address" != "" -a "$title" != "" ]; then
		send_venue "$chat" "$lat" "$long" "$title" "$address"
		local sent=y
	fi
	if [ "$sent" != "y" ];then
		send_text "$chat" "$text"
	fi

}

send_text() {
	case "$2" in
		html_parse_mode*)
			send_html_message "$1" "${2//html_parse_mode}"
			;;
		markdown_parse_mode*)
			send_markdown_message "$1" "${2//markdown_parse_mode}"
			;;
		*)
			send_normal_message "$1" "$2"
			;;
	esac
}

send_normal_message() {
	text="$2"
	until [ $(echo -n "$text" | wc -m) -eq 0 ]; do
		res=$(curl -s "$MSG_URL" -d "chat_id=$1" -d "text=$(urlencode "${text:0:4096}")")
		text="${text:4096}"
	done
}

send_markdown_message() {
	text="$2"
	until [ $(echo -n "$text" | wc -m) -eq 0 ]; do
		res=$(curl -s "$MSG_URL" -d "chat_id=$1" -d "text=$(urlencode "${text:0:4096}")" -d "parse_mode=markdown" -d "disable_web_page_preview=true")
		text="${text:4096}"
	done
}

send_html_message() {
	text="$2"
	until [ $(echo -n "$text" | wc -m) -eq 0 ]; do
		res=$(curl -s "$MSG_URL" -F "chat_id=$1" -F "text=$(urlencode "${text:0:4096}")" -F "parse_mode=html")
		text="${text:4096}"
	done
}

get_chat_member() {
	res=$(curl -s "$MEMBER_URL" -F "chat_id=$1" -F "user_id=$2")
	local JS=$(echo $res | ./JSON.sh/JSON.sh)
	CHATMEMBER[OK]=$(echo $JS | tr '[' '\n' | egrep '"ok"\]' | cut -f2 -d\ )
	CHATMEMBER[ID]=$(echo $JS | tr '[' '\n' | egrep '"result","user","id"\].*' | cut -f2 -d\ )
	CHATMEMBER[FIRST_NAME]=$(echo $JS | tr '[' '\n' | egrep '"result","user","first_name"\]' | cut -f2 -d\ | sed -e 's/^"//' -e 's/"$//' )
	CHATMEMBER[USERNAME]=$(echo $JS | tr '[' '\n' | egrep '"result","user","username"\]' | cut -f2 -d\ | sed -e 's/^"//' -e 's/"$//' )
	CHATMEMBER[STATUS]=$(echo $JS | tr '[' '\n' | egrep '"result","status"\]' | cut -f2 -d\ | sed -e 's/^"//' -e 's/"$//' )
}

#get_admin_chat_member() {
#	res=$(curl -s "$GETADMIN_URL" -F "chat_id=$1" )
#	echo $res
#}

kick_chat_member() {
	res=$(curl -s "$KICK_URL" -F "chat_id=$1" -F "user_id=$2")
}

unban_chat_member() {
	res=$(curl -s "$UNBAN_URL" -F "chat_id=$1" -F "user_id=$2")
}

leave_chat() {
	res=$(curl -s "$LEAVE_URL" -F "chat_id=$1")
}

answer_inline_query() {
	case $2 in
		"article")
			InlineQueryResult='[{"type":"'$2'","id":"'$RANDOM'","title":"'$3'","message_text":"'$4'"}]'
		;;
		"photo")
			InlineQueryResult='[{"type":"'$2'","id":"'$RANDOM'","photo_url":"'$3'","thumb_url":"'$4'"}]'
		;;
		"gif")
			InlineQueryResult='[{"type":"'$2'","id":"'$RANDOM'","gif_url":"'$3'", "thumb_url":"'$4'"}]'
		;;
		"mpeg4_gif")
			InlineQueryResult='[{"type":"'$2'","id":"'$RANDOM'","mpeg4_url":"'$3'"}]'
		;;
		"video")
			InlineQueryResult='[{"type":"'$2'","id":"'$RANDOM'","video_url":"'$3'","mime_type":"'$4'","thumb_url":"'$5'","title":"'$6'"}]'
		;;
		"audio")
			InlineQueryResult='[{"type":"'$2'","id":"'$RANDOM'","audio_url":"'$3'","title":"'$4'"}]'
		;;
		"voice")
			InlineQueryResult='[{"type":"'$2'","id":"'$RANDOM'","voice_url":"'$3'","title":"'$4'"}]'
		;;
		"document")
			InlineQueryResult='[{"type":"'$2'","id":"'$RANDOM'","title":"'$3'","caption":"'$4'","document_url":"'$5'","mime_type":"'$6'"}]'
		;;
		"location")
			InlineQueryResult='[{"type":"'$2'","id":"'$RANDOM'","latitude":"'$3'","longitude":"'$4'","title":"'$5'"}]'
		;;
		"venue")
			InlineQueryResult='[{"type":"'$2'","id":"'$RANDOM'","latitude":"'$3'","longitude":"'$4'","title":"'$5'","address":"'$6'"}]'
		;;
		"contact")
			InlineQueryResult='[{"type":"'$2'","id":"'$RANDOM'","phone_number":"'$3'","first_name":"'$4'"}]'
		;;

		# Cached media stored in Telegram server

		"cached_photo")
			InlineQueryResult='[{"type":"photo","id":"'$RANDOM'","photo_file_id":"'$3'"}]'
		;;
		"cached_gif")
			InlineQueryResult='[{"type":"gif","id":"'$RANDOM'","gif_file_id":"'$3'"}]'
		;;
		"cached_mpeg4_gif")
			InlineQueryResult='[{"type":"mpeg4_gif","id":"'$RANDOM'","mpeg4_file_id":"'$3'"}]'
		;;
		"cached_sticker")
			InlineQueryResult='[{"type":"sticker","id":"'$RANDOM'","sticker_file_id":"'$3'"}]'
		;;
		"cached_document")
			InlineQueryResult='[{"type":"document","id":"'$RANDOM'","title":"'$3'","document_file_id":"'$4'"}]'
		;;
		"cached_video")
			InlineQueryResult='[{"type":"video","id":"'$RANDOM'","video_file_id":"'$3'","title":"'$4'"}]'
		;;
		"cached_voice")
			InlineQueryResult='[{"type":"voice","id":"'$RANDOM'","voice_file_id":"'$3'","title":"'$4'"}]'
		;;
		"cached_audio")
			InlineQueryResult='[{"type":"audio","id":"'$RANDOM'","audio_file_id":"'$3'"}]'
		;;

	esac

	res=$(curl -s "$INLINE_QUERY" -F "inline_query_id=$1" -F "results=$InlineQueryResult")

}

send_keyboard() {
	local chat="$1"
	local text="$2"
	shift 2
	local keyboard=init
	OLDIFS=$IFS
	IFS=$(echo -en "\"")
	for f in $*;do [ "$f" != " " ] && local keyboard="$keyboard, [\"$f\"]";done
	IFS=$OLDIFS
	local keyboard=${keyboard/init, /}
	res=$(curl -s "$MSG_URL" --header "content-type: multipart/form-data" -F "chat_id=$chat" -F "text=$text" -F "reply_markup={\"keyboard\": [$keyboard],\"one_time_keyboard\": true}")
}

get_file() {
	[ "$1" != "" ] && echo $FILE_URL$(curl -s "$GET_URL" -F "file_id=$1" | ./JSON.sh/JSON.sh -s | egrep '\["result","file_path"\]' | cut -f 2 | cut -d '"' -f 2)
}

send_file() {
	[ "$2" = "" ] && return
	local chat_id=$1
	local file=$2
	echo "$file" | grep -qE $FILE_REGEX || return
	local ext="${file##*.}"
	case $ext in
        	mp3|flac)
			CUR_URL=$AUDIO_URL
			WHAT=audio
			STATUS=upload_audio
			local CAPTION="$3"
			;;
		png|jpg|jpeg|gif)
			CUR_URL=$PHO_URL
			WHAT=photo
			STATUS=upload_photo
			local CAPTION="$3"
			;;
		webp)
			CUR_URL=$STICKER_URL
			WHAT=sticker
			STATUS=
			;;
		mp4)
			CUR_URL=$VIDEO_URL
			WHAT=video
			STATUS=upload_video
			local CAPTION="$3"
			;;

		ogg)
			CUR_URL=$VOICE_URL
			WHAT=voice
			STATUS=
			;;
		*)
			CUR_URL=$DOCUMENT_URL
			WHAT=document
			STATUS=upload_document
			local CAPTION="$3"
			;;
	esac
	send_action $chat_id $STATUS
	res=$(curl -s "$CUR_URL" -F "chat_id=$chat_id" -F "$WHAT=@$file" -F "caption=$CAPTION")
}

# typing for text messages, upload_photo for photos, record_video or upload_video for videos, record_audio or upload_audio for audio files, upload_document for general files, find_location for location

send_action() {
	[ "$2" = "" ] && return
	res=$(curl -s "$ACTION_URL" -F "chat_id=$1" -F "action=$2")
}

send_location() {
	[ "$3" = "" ] && return
	res=$(curl -s "$LOCATION_URL" -F "chat_id=$1" -F "latitude=$2" -F "longitude=$3")
}

send_venue() {
	[ "$5" = "" ] && return
	[ "$6" != "" ] add="-F \"foursquare_id=$6\""
	res=$(curl -s "$VENUE_URL" -F "chat_id=$1" -F "latitude=$2" -F "longitude=$3" -F "title=$4" -F "address=$5" $add)
}


forward() {
	[ "$3" = "" ] && return
	res=$(curl -s "$FORWARD_URL" -F "chat_id=$1" -F "from_chat_id=$2" -F "message_id=$3")
}

process_updates() {
	MAX_PROCESS_NUMBER=$(echo "$UPDATE" | sed '/\["result",[0-9]*\]/!d' | tail -1 | sed 's/\["result",//g;s/\].*//g')
	for ((PROCESS_NUMBER=0; PROCESS_NUMBER<=MAX_PROCESS_NUMBER; PROCESS_NUMBER++)); do
		if [ "$1" == "test" ]; then
			process_client "$1"
		else
			process_client "$1" &
		fi
	done
}
process_client() {
	#echo "process message"
	MESSAGE[0]=$(echo -e $(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","text"\]' | cut -f 2 | cut -d '"' -f 2) | sed 's#\\/#/#g')
	MESSAGE[ID]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","message_id"\]' | cut -f 2 | cut -d '"' -f 2)
	MESSAGE[FROM_ID]=$(echo $UPDATE | tr '[' '\n' | egrep '"result",0,"message","reply_to_message","from","id"\]' | cut -f2 -d\ )
	MESSAGE[FROM_FIRST_NAME]=$(echo $UPDATE | tr '[' '\n' | egrep '"result",0,"message","reply_to_message","from","first_name"\]' | cut -f2 -d\ | sed -e 's/^"//' -e 's/"$//')
	MESSAGE[FROM_USERNAME]=$(echo $UPDATE | tr '[' '\n' | egrep '"result",0,"message","reply_to_message","from","username"\]' | cut -f2 -d\ | sed -e 's/^"//' -e 's/"$//')
	MESSAGE[FROM_CHAT_ID]=$(echo $UPDATE | tr '[' '\n' | egrep '"result",0,"message","reply_to_message","chat","id"\]' | cut -f2 -d\ )
	MESSAGE[FROM_CHAT_TITLE]=$(echo $UPDATE | tr '[' '\n' | egrep '"result",0,"message","reply_to_message","chat","title"\]' | cut -f2 -d\ | sed -e 's/^"//' -e 's/"$//')
	MESSAGE[FROM_CHAT_USERNAME]=$(echo $UPDATE | tr '[' '\n' | egrep '"result",0,"message","reply_to_message","chat","username"\]' | cut -f2 -d\ | sed -e 's/^"//' -e 's/"$//')
	MESSAGE[FROM_CHAT_TYPE]=$(echo $UPDATE | tr '[' '\n' | egrep '"result",0,"message","reply_to_message","chat","type"\]' | cut -f2 -d\ | sed -e 's/^"//' -e 's/"$//')
	#echo "process chat"
	CHAT[ID]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","chat","id"\]' | cut -f 2)
	CHAT[FIRST_NAME]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","chat","first_name"\]' | cut -f 2 | cut -d '"' -f 2)
	CHAT[LAST_NAME]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","chat","last_name"\]' | cut -f 2 | cut -d '"' -f 2)
	CHAT[USERNAME]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","chat","username"\]' | cut -f 2 | cut -d '"' -f 2)
	CHAT[TITLE]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","chat","title"\]' | cut -f 2 | cut -d '"' -f 2)
	CHAT[TYPE]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","chat","type"\]' | cut -f 2 | cut -d '"' -f 2)
	CHAT[ALL_MEMBERS_ARE_ADMINISTRATORS]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","chat","all_members_are_administrators"\]' | cut -f 2 | cut -d '"' -f 2)
	#echo "process user"
	USER[ID]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","from","id"\]' | cut -f 2)
	USER[FIRST_NAME]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","from","first_name"\]' | cut -f 2 | cut -d '"' -f 2)
	USER[LAST_NAME]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","from","last_name"\]' | cut -f 2 | cut -d '"' -f 2)
	USER[USERNAME]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","from","username"\]' | cut -f 2 | cut -d '"' -f 2)
	#echo "process audio"
	URLS[AUDIO]=$(get_file $(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","audio","file_id"\]' | cut -f 2 | cut -d '"' -f 2))
	#echo "process document"
	URLS[DOCUMENT]=$(get_file $(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","document","file_id"\]' | cut -f 2 | cut -d '"' -f 2))
	#echo "process foto"
	URLS[PHOTO]=$(get_file $(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","photo",.*,"file_id"\]' | cut -f 2 | cut -d '"' -f 2 | sed -n '$p'))
	#echo "process sticker"
	URLS[STICKER]=$(get_file $(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","sticker","file_id"\]' | cut -f 2 | cut -d '"' -f 2))
	#echo "process Video"
	URLS[VIDEO]=$(get_file $(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","video","file_id"\]' | cut -f 2 | cut -d '"' -f 2))
	#echo "process Voice"
	URLS[VOICE]=$(get_file $(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","voice","file_id"\]' | cut -f 2 | cut -d '"' -f 2))
	#echo "process contact"
	CONTACT[NUMBER]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","contact","phone_number"\]' | cut -f 2 | cut -d '"' -f 2)
	CONTACT[FIRST_NAME]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","contact","first_name"\]' | cut -f 2 | cut -d '"' -f 2)
	CONTACT[LAST_NAME]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","contact","last_name"\]' | cut -f 2 | cut -d '"' -f 2)
	CONTACT[USER_ID]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","contact","user_id"\]' | cut -f 2 | cut -d '"' -f 2)
	#echo "process caption"
	CAPTION=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","caption"\]' | cut -f 2 | cut -d '"' -f 2)
	#echo "process location"
	LOCATION[LONGITUDE]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","location","longitude"\]' | cut -f 2 | cut -d '"' -f 2)
	LOCATION[LATITUDE]=$(echo "$UPDATE" | egrep '\["result",'$PROCESS_NUMBER',"message","location","latitude"\]' | cut -f 2 | cut -d '"' -f 2)
	NAME="$(echo ${URLS[*]} | sed 's/.*\///g')"
	
	#echo "call $COMMAND_SCRIPT"
	source $COMMAND_SCRIPT
}

# source the script with source as param to use functions in other scripts
while [ $SCRIPT_LOOP == "yes" ]; do {
	#echo "wait message"
	UPDATE=$(curl -s $UPD_URL$OFFSET | ./JSON.sh/JSON.sh)
	# Offset
	OFFSET=$(echo "$UPDATE" | egrep '\["result",[0-9]*,"update_id"\]' | tail -1 | cut -f 2)
	OFFSET=$((OFFSET+1))
	
	if [ $OFFSET != 1 ]; then
		if [ "$PARSE_ASYNC" == "no" ]; then
			process_updates "$2"
		else
			process_updates "$2" &
		fi
	fi
	
}; done

if [[ $SND_MODE != "no" ]]; then
	send_message "$SND_CHAT_ID" "$SND_MODE $SND_MESSAGE"
fi
