# This shell script will search all MP4 files within the working directory and compare them
# with PNG screenshots of ads that may be the single ad found at the end of the video.
# If one is found, a ComSkip EDL file will be created that instructs the video player
# (if it is a player that can recognise EDL files, such as Kodi) to skip the commercial.
# This is only meant to work to skip a single ad (one out of any number of possible ads)
# that is shown at the end any video within the working directory.

# Playlist URL:
playlist_url="http://www.youtube.com/user/TheYoungTurks/videos"
# The ad directory contains PNG files, each being a screenshot from an offending advertisment.
ad_dir="/change_to_your_podcast_directory/ads/"
# The working directory contains the MP4 video files.
working_dir="/change_to_your_podcast_directory/"
# Delete files in the working directory that are older than days_to_keep
# Set to 0 if you do not want any files to be deleted.
days_to_keep=13
# This is how far from the end of the video that ffmpeg starts searching for the video, in seconds.
maximum_ad_length=31


echo "Downloading new videos..."
# See youtube-dl.org for details on using it to download playlists.
youtube-dl --ignore-errors -f 22 -o "$working_dir""%(title)s.%(ext)s" --playlist-start 1 --playlist-end 12 --no-overwrites --datebefore now --dateafter now-2day -v "$playlist_url"

# Grab all *.png screenshots in the ad directory, and place them in the all_ads array for later use.
# The screenshot can be from any part of the ad, not only the beginning.
# Filenaming format should include the number of seconds that the ad lasts (as the only numbers in the filename)
# e.g. "NordVPN ad (20.968).png"
cd $ad_dir
all_ads=()
for ad in *.png; do
    all_ads+=("$ad")
done
cd $working_dir

# Delete files that were downloaded more than days_to_keep ago. Skip if days_to_keep is set to zero.
if [ "$days_to_keep" -gt 0 ]; then
  printf "Checking for any old files to delete..."
  find \( -name "*.edl" -or -name "*.mp4" \) -type f -mtime +$days_to_keep -delete 
  printf ".\n"
fi

# Scan all MP4 files in the working directory:
printf "Scanning videos for ads..."
for file in *.mp4; do
  base=${file%.*}
  if [ -e "${base}.edl" -a -e "${base}.mp4" ]; then
    printf "..."
  else
    for a in "${all_ads[@]}"; do
      # The ad length is grabbed as the only number in the ad screenshot's filename:
      ad_length="$(echo $a | grep -Eo '[+-]?[0-9]+([.][0-9]+)?')"
      
      printf "\n"
      echo "Checking " "$file" "against" "$a"
      
      # ffmpeg comapares the advertisement screenshot with the end of the video, starting at maximum_ad_length seconds before the end
      ffmpeg_output=$(ffmpeg -sseof -$maximum_ad_length -i "$file" -loop 1 -i "$ad_dir$a" -an -filter_complex "blend=difference:shortest=1,blackframe=99:32" -f null - 2>&1)

      # The ffmpeg_output will list the black frames if the image was found in the video
      if echo "$ffmpeg_output" | grep -q "Parsed_blackframe"; then
        echo "Removing ad..."
        
        # This creates the ComSkip EDL file, which is formatted as:
        # start time of the ad    end of the video    3 
        duration=$(ffprobe -i "$file" -show_entries format=duration -v quiet -of csv="p=0")
        comm=$(awk "BEGIN{print $duration - $ad_length}")
        endcomm="    3"
        echo $comm $duration $endcomm > "${file%.mp4}.edl"
        # Stop searching through the ads if we've found which ad the video contains:
        break        
      else  
        # Write a blank EDL file if the ad wasn't found. 
        # (A blank EDL file will be overwritten if there are more ads to check and a later match is found.)
        echo "" > "${file%.mp4}.edl"
      fi
    done
  fi  
done
printf "\n"
