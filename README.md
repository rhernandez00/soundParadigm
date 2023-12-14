# soundParadigm
This repository contains a sound-based paradigm to be used for an HD-DOT experiment

It will read the sounds found in the \sounds directory and generate an acquisition based on those sounds and the variables listed at the beggining of the script.

The sounds should be in a format like this:
[type]_[XX].[extension]

type: single letter that marks the type of stimuli
XX: number of stimuli within that type
extension: extension used

Example:

D_01.wav
D_02.wav
E_01.wav
E_02.wav

This would generate an experiment playing four sounds corresponding to two categories with two sounds each.

The logs will be created in a folder named /logs and will contain the information about the acquisition and what sounds where played on what order.

The script:
- shuffles the order of the sounds
- generates a full sound putting together the sounds and silence intervals (including initial and final baseline)
- sends a trigger to the HD-DOT system using the serial cable
- plays the sound
- sends a trigget marking the end of the run

To use it, clone the repository. The repository includes some sample sound files. Change the sound files in the /sounds folder, change the settings regarding the baseline and interstimuli interval as you wish.
