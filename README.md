A launcher script for Counter Strike 2 to simplify ussage of stretched 4:3 (and more) aspect ratio output while using windowed fullscreen mode.

# Installation
1. Download [QRes](https://www.majorgeeks.com/files/details/qres.html) and place it in the same directory as CSStretch.exe, or add it to your PATH environment variable.
2. Setup scaling in your GPU driver.
   1. NVIDIA:
      1. NVIDIA Control Panel -> "Adjust desktop size and position"
         1. Scaling mode: Full-screen
         2. Perform scaling on: GPU
         3. Override the scaling mode set by games and programs: Yes
   2. AMD:
      1. TBD
3. In CS2 video settings, chose "Fullscreen Windowed"

# Configuration
The script defaults to using the highest-resolution 4:3 aspect ratio and highest supported refresh rate. To override this behavior, set the following environment variables:
- `CSSTRETCH_NO_REFRESH_RATE`: Set to 1 to disable refresh rate modifications
- `CSSTRETCH_ASPECT`: Set to `width / height` for the desired aspect ratio
   - e.g. for 16:10 -> `CSSTRETCH_ASPECT=1.6`
