# youtube-dl-ad-skip
This is a shell script that uses youtube-dl (https://github.com/ytdl-org/youtube-dl) to download new vidoes from a channel, and then utilises ffmpeg (https://www.ffmpeg.org) to find a known ad at the end of the video. If one of the ads is found, it creates a ComSkip (www.comskip.org) edl file to tell the video player to skip the ad. Kodi (https://kodi.tv), for example supports ComSkip files and automatically.

I have developed and tested it on linux (Debian) only.  It currently scans mp4 files (only) for ads and expects the advertisement screenshots to be png files, that simply just show any frame from the ad (something distinct is best), and expects the filename to contain the length of the ad, like "advertA (34.5 seconds long).png".

It's pretty basic, but can be easily expanded to add more basic features, or even figure out the length of the ad on its own. But for me it works perfectly to skip the ads on TYT videos, which are so very annoying.

It is currently set with a working playlist (TYT) and some advertisement screenshots. Just change the ad directory (where the ad png files are stored) and the working directory (where youtube-dl downloads your videos) and you're good to go.

This is free and unencumbered software released into the public domain.
