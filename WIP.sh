#!/bin/bash

# Install required packages if not installed
if ! command -v zenity &> /dev/null; then
	echo "Zenity is not installed. Installing Zenity..."
	sudo apt-get install -y zenity
fi

if ! command -v mkvmerge &> /dev/null; then
	echo "MKVToolNix is not installed. Installing MKVToolNix..."
	sudo apt-get install -y mkvtoolnix
fi

if ! command -v jq &> /dev/null; then
	echo "jq is not installed. Installing jq..."
	sudo apt-get install -y jq
fi

# Prompt user to choose an MKV file
mkv_file=$(zenity --file-selection --title="Choose an MKV file" --file-filter="MKV files (*.mkv) | *.mkv" --file-filter="All files | *")

# Extract mkv file name without extension
mkv_file_noext=$(basename -- "$mkv_file" .mkv)

# Function for the audio extraction sub-menu
function run_audio() {

	# Get audio tracks information with JSON for IDs
	audio_id=$(mkvmerge -J "$mkv_file" | jq -r '.tracks[] | select(.type == "audio") | .id')

	# Check if there are audio tracks
	if [[ -z $audio_id ]]; then
		zenity --error --text="No audio tracks found in the selected MKV file."
		exit 1
	fi

	# Get audio tracks information with JSON for language, trackname and codec
	audio_language=$(mkvmerge -J "$mkv_file" | jq -r '.tracks[] | select(.type == "audio") | .properties.language')
	audio_trackname=$(mkvmerge -J "$mkv_file" | jq -r '.tracks[] | select(.type == "audio") | .properties.track_name')
	audio_codec=$(mkvmerge -J "$mkv_file" | jq -r '.tracks[] | select(.type == "audio") | .codec')

	# Create arrays for each audio track information
	mapfile -t id_array <<< "$audio_id"
	mapfile -t language_array <<< "$audio_language"
	mapfile -t codec_array <<< "$audio_codec"
	mapfile -t trackname_array <<< "$audio_trackname"

	# Create an array of options for the Zenity list dialog
	options=()
	for ((i=0; i<${#id_array[@]}; i++)); do
		options+=("False" "${id_array[i]}" "${language_array[i]}" "${codec_array[i]}" "${trackname_array[i]}")
	done

	# Show the selected array values with Zenity list dialog
	chosen_audio_ids=$(zenity --list --checklist --title="Choose an audio track" --column="Option" --column="ID" --column="Language" --column="Codec" --column="Track Name" --height=400 --width=700 "${options[@]}" --separator=",")
echo $chosen_audio_ids

	# Cancel program if user clicks "Cancel"
	if [[ $? -eq 1 ]]; then
		exit 1
	fi

	# Check if user selected an audio ID
	if [[ -z $chosen_audio_ids ]]; then
		zenity --error --text="No audio ID selected."
		exit 1
	fi

	# Extract chosen audio info for each chosen audio ID
	IFS=',' read -ra chosen_audio_ids_array <<< "$chosen_audio_ids"
	for chosen_audio_id in "${chosen_audio_ids_array[@]}"; do
		index=-1
		for ((i=0; i<${#id_array[@]}; i++)); do
			if [[ "${id_array[i]}" == "$chosen_audio_id" ]]; then
				index=$i
				break
			fi
		done

		if [[ $index -ne -1 ]]; then
			chosen_audio_codec="${codec_array[index]}"
			chosen_audio_language="${language_array[index]}"
			
			# Extract the audio track based on the chosen codec ID
			if [[ $chosen_audio_codec == "AAC" ]]; then
			
				# Append language tag and a unique number to the file name to avoid overwriting
				count=1
				filename="${mkv_file_noext}_${chosen_audio_language}.aac"
				while [[ -e $filename ]]; do
					filename="${mkv_file_noext}_${chosen_audio_language}"_"$count.aac"
					count=$((count+1))
				done

				mkvextract tracks "$mkv_file" "${chosen_audio_id}":"$filename"
				
			elif [[ $chosen_audio_codec == "Opus" ]]; then
			
				# Append language tag and a unique number to the file name to avoid overwriting
				count=1
				filename="${mkv_file_noext}_${chosen_audio_language}.opus"
				while [[ -e $filename ]]; do
					filename="${mkv_file_noext}_${chosen_audio_language}"_"$count.opus"
					count=$((count+1))
				done

				mkvextract tracks "$mkv_file" "${chosen_audio_id}":"$filename"
				
			elif [[ $chosen_audio_codec == "Vorbis" ]]; then
			
				# Append language tag and a unique number to the file name to avoid overwriting
				count=1
				filename="${mkv_file_noext}_${chosen_audio_language}.ogg"
				while [[ -e $filename ]]; do
					filename="${mkv_file_noext}_${chosen_audio_language}"_"$count.ogg"
					count=$((count+1))
				done

				mkvextract tracks "$mkv_file" "${chosen_audio_id}":"$filename"
			fi

			# Show success message
			zenity --info --text="Audio ID:$chosen_audio_id Language:$chosen_audio_language extracted successfully"
		fi
	done
}

# Function for the subtitle extraction sub-menu
function run_subtitle() {

	# Get subtitle tracks information with JSON for IDs
	subtitle_id=$(mkvmerge -J "$mkv_file" | jq -r '.tracks[] | select(.type == "subtitles") | .id')

	# Check if there are subtitle tracks
	if [[ -z $subtitle_id ]]; then
		zenity --error --text="No subtitle tracks found in the selected MKV file."
		exit 1
	fi

	# Get subtitle tracks information with JSON for language, trackname, codec and extension type
	subtitle_language=$(mkvmerge -J "$mkv_file" | jq -r '.tracks[] | select(.type == "subtitles") | .properties.language')
	subtitle_trackname=$(mkvmerge -J "$mkv_file" | jq -r '.tracks[] | select(.type == "subtitles") | .properties.track_name')
	subtitle_codec=$(mkvmerge -J "$mkv_file" | jq -r '.tracks[] | select(.type == "subtitles") | .codec')

	# Create arrays for each subtitle track information
	mapfile -t id_array <<< "$subtitle_id"
	mapfile -t language_array <<< "$subtitle_language"
	mapfile -t trackname_array <<< "$subtitle_trackname"
	mapfile -t codec_array <<< "$subtitle_codec"

	# Create an array of options for the Zenity list dialog
	options=()
	for ((i=0; i<${#id_array[@]}; i++)); do
		options+=("False" "${id_array[i]}" "${language_array[i]}" "${codec_array[i]}" "${trackname_array[i]}")
	done

	# Show the selected array values with Zenity list dialog
	chosen_subtitle_ids=$(zenity --list --checklist --title="Choose a subtitle" --column="Option" --column="ID" --column="Language" --column="Codec" --column="Track Name" --height=400 --width=700 "${options[@]}" --separator=",")

	# Cancel program if user clicks "Cancel"
	if [[ $? -eq 1 ]]; then
		exit 1
	fi

	# Check if user selected a subtitle ID
	if [[ -z $chosen_subtitle_ids ]]; then
		zenity --error --text="No subtitle ID selected."
		exit 1
	fi

	# Extract chosen subtitle info for each chosen subtitle ID
	IFS=',' read -ra chosen_subtitle_ids_array <<< "$chosen_subtitle_ids"
	for chosen_subtitle_id in "${chosen_subtitle_ids_array[@]}"; do
		index=-1
		for ((i=0; i<${#id_array[@]}; i++)); do
			if [[ "${id_array[i]}" == "$chosen_subtitle_id" ]]; then
				index=$i
				break
			fi
		done

		if [[ $index -ne -1 ]]; then
			chosen_subtitle_codec="${codec_array[index]}"
			chosen_subtitle_language="${language_array[index]}"
			
			# Extract the subtitle track based on the chosen codec ID
			if [[ $chosen_subtitle_codec == "SubStationAlpha" ]]; then
			
				# Append language tag and a unique number to the file name to avoid overwriting
				count=1
				filename="${mkv_file_noext}_${chosen_subtitle_language}.ass"
				while [[ -e $filename ]]; do
					filename="${mkv_file_noext}_${chosen_subtitle_language}_${count}.ass"
					count=$((count+1))
				done

				mkvextract tracks "$mkv_file" "${chosen_subtitle_id}":"$filename"
				
			elif [[ $chosen_subtitle_codec == "HDMV PGS" ]]; then
			
				# Append language tag and a unique number to the file name to avoid overwriting
				count=1
				filename="${mkv_file_noext}_${chosen_subtitle_language}.sup"
				while [[ -e $filename ]]; do
					filename="${mkv_file_noext}_${chosen_subtitle_language}_${count}.sup"
					count=$((count+1))
				done

				mkvextract tracks "$mkv_file" "${chosen_subtitle_id}":"$filename"
				
			elif [[ $chosen_subtitle_codec == "SubRip/SRT" ]]; then
			
				# Append language tag and a unique number to the file name to avoid overwriting
				count=1
				filename="${mkv_file_noext}_${chosen_subtitle_language}.srt"
				while [[ -e $filename ]]; do
					filename="${mkv_file_noext}_${chosen_subtitle_language}"_"$count.srt"
					count=$((count+1))
				done

				mkvextract tracks "$mkv_file" "${chosen_subtitle_id}":"$filename"

			elif [[ $chosen_subtitle_codec == "VobSub" ]]; then
			
				# Append language tag and a unique number to the file name to avoid overwriting
				count=1
				filename="${mkv_file_noext}_${chosen_subtitle_language}"
				while [[ -e $filename ]]; do
					filename="${mkv_file_noext}_${chosen_subtitle_language}"_"$count"
					count=$((count+1))
				done

				mkvextract tracks "$mkv_file" "${chosen_subtitle_id}":"$filename"
			fi

			# Show success message
			zenity --info --text="Subtitle ID:$chosen_subtitle_id Language:$chosen_subtitle_language extracted successfully"
		fi
	done
}

# Function for the attachment extraction sub-menu
function run_attachments() {

	# Get attachment tracks information with JSON for IDs
	attachment_id=$(mkvmerge -J "$mkv_file" | jq -r '.attachments[] | .id')

	# Check if there are attachments
	if [[ -z $attachment_id ]]; then
		zenity --error --text="No attachment tracks found in the selected MKV file."
		exit 1
	fi

	# Get attachment tracks information with JSON for content type and file_name
	attachment_type=$(mkvmerge -J "$mkv_file" | jq -r '.attachments[] | .content_type')
	attachment_name=$(mkvmerge -J "$mkv_file" | jq -r '.attachments[] | .file_name')

	# Create arrays for each attachment track information
	mapfile -t id_array <<< "$attachment_id"
	mapfile -t type_array <<< "$attachment_type"
	mapfile -t name_array <<< "$attachment_name"

	# Create an array of options for the Zenity list dialog
	options=()
	for ((i=0; i<${#id_array[@]}; i++)); do
		options+=("False" "${id_array[i]}" "${type_array[i]}" "${name_array[i]}")
	done

	# Show the selected array values with Zenity list dialog
	chosen_attachment_ids=$(zenity --list --checklist --title="Choose an attachment" --column="Option" --column="ID" --column="Type" --column="Name" --height=400 --width=700 "${options[@]}" --separator=",")

	# Cancel program if user clicks "Cancel"
	if [[ $? -eq 1 ]]; then
		exit 1
	fi

	# Cancel program if user clicks "Cancel" or doesn't select any attachments
	if [[ -z $chosen_attachment_ids ]]; then
		zenity --error --text="No audio ID selected."
		exit 1
	fi

	# Extract attachments for each chosen ID
	IFS=',' read -ra chosen_attachment_ids_array <<< "$chosen_attachment_ids"
	for chosen_attachment_id in "${chosen_attachment_ids_array[@]}"; do
		index=-1
		for ((i=0; i<${#id_array[@]}; i++)); do
			if [[ "${id_array[i]}" == "$chosen_attachment_id" ]]; then
				index=$i
				break
			fi
		done

		if [[ $index -ne -1 ]]; then
			chosen_name="${name_array[index]}"
			mkvextract attachments "$mkv_file" "${chosen_attachment_id}":"$chosen_name"
			
			# Show success message for each extracted attachment
			zenity --info --text="$chosen_name extracted successfully"
		fi
	done
}
# Function for the video extraction sub-menu
function run_video() {

	# Get video tracks information with JSON for IDs
	video_id=$(mkvmerge -J "$mkv_file" | jq -r '.tracks[] | select(.type == "video") | .id')

	# Check if there is video
	if [[ -z $video_id ]]; then
		zenity --error --text="No video track found in the selected MKV file."
		exit 1
	fi

	# Get video track information with JSON for content type and file_name
	video_codec=$(mkvmerge -J "$mkv_file" | jq -r '.tracks[] | select(.type == "video") | .codec')
	video_dimensions=$(mkvmerge -J "$mkv_file" | jq -r '.tracks[] | select(.type == "video") | .properties.display_dimensions')

	# Create arrays for each video track information
	mapfile -t id_array <<< "$video_id"
	mapfile -t codec_array <<< "$video_codec"
	mapfile -t dimensions_array <<< "$video_dimensions"
	
	# Create an array of options for the Zenity list dialog
	options=()
	for ((i=0; i<${#id_array[@]}; i++)); do
		options+=("False" "${id_array[i]}" "${codec_array[i]}" "${dimensions_array[i]}")
	done

	# Show the selected array values with Zenity list dialog
	chosen_video_ids=$(zenity --list --checklist --title="Choose a video track" --column="Option" --column="ID" --column="Codec" --column="Dimensions" --height=400 --width=700 "${options[@]}" --separator=",")

	# Cancel program if user clicks "Cancel"
	if [[ $? -eq 1 ]]; then
		exit 1
	fi

	# Cancel program if user clicks "Cancel" or doesn't select any video tracks
	if [[ -z $chosen_video_ids ]]; then
		zenity --error --text="No video ID selected."
		exit 1
	fi

	# Extract chosen video info for each chosen video ID
	IFS=',' read -ra chosen_video_ids_array <<< "$chosen_video_ids"
	for chosen_video_id in "${chosen_video_ids_array[@]}"; do
		index=-1
		for ((i=0; i<${#id_array[@]}; i++)); do
			if [[ "${id_array[i]}" == "$chosen_video_id" ]]; then
				index=$i
				break
			fi
		done

		if [[ $index -ne -1 ]]; then
			mkvextract tracks "$mkv_file" "${chosen_video_id}":"$mkv_file_noext.mp4"
			# Show success message for each extracted video
			
			zenity --info --text="$mkv_file_noext extracted successfully"
		fi
	done
}

# Show main menu
mainmenu_output=$(zenity --forms --title "ExtractMKV" --text "" --add-combo "Extract:" --combo-values "Video|Audio|Subtitles|Attachements|Chapters|All")
mainmenu_option=$(echo "$mainmenu_output" | awk -F'|' '{print $1}')
if [[ $mainmenu_option == "Subtitles" ]]; then
	run_subtitle
elif [[ $mainmenu_option == "Audio" ]]; then
	run_audio
elif [[ $mainmenu_option == "Attachements" ]]; then
	run_attachments
elif [[ $mainmenu_option == "Video" ]]; then
	run_video
else
	exit 0
fi
