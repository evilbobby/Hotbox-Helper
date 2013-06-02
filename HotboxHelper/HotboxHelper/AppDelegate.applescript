--
--  AppDelegate.applescript
--  HotboxHelper
--
--  Created by Christian on 5/6/13.
--  Copyright (c) 2013 Drivetime. All rights reserved.
--

script AppDelegate
	property parent : class "NSObject"
    
    
    --pereferences window
    property savefolderlocLabel : missing value
    
    --Cache folders
    property Retrieve_folder : missing value
    property PsDroplet_folder : missing value
    property ImagePrep_folder : missing value
    property RemapTilt_folder : missing value
    property BuildSwf_folder : missing value
    property Pretransfer_folder : missing value
    property droplet_folder : missing value
    --globals
    property initializing : true
    property drop1Name : "BuildSwf"
    property drop2Name : "PsDroplet"
    property drop3Name : "RemapTilt"
    property dropletsExist : null
    --add these properties
    property LogWindow : missing value
    property drop1Indicator : missing value
    property drop2Indicator : missing value
    property drop3Indicator : missing value
    
	
    (* ======================================================================
                        Default "Application will..." Handlers
     ====================================================================== *)
    
	on applicationWillFinishLaunching_(aNotification)
		log_event("==========PROGRAM INITILIZE=========")
        
        --check the log and backup if over max line count (30,000)
        checklog()
        --Routine Check Cache folders
        checkCacheFolders_(me)
        --Check for Droplets
        checkDroplets_(me)
        
        set initializing to false
	end applicationWillFinishLaunching_
	
	on applicationShouldTerminate_(sender)
		log_event("==========PROGRAM SHUTDOWN==========")
		return current application's NSTerminateNow
	end applicationShouldTerminate_
    
    (* ======================================================================
                            Handlers for startup & shutdown!
     ====================================================================== *)
    
    --CHECK FOR CACHE FOLDERS
    on checkCacheFolders_(sender)
        log_event("Checking for Cache Folders...")
        set CacheFolderList to {"Retrieve", "PsDroplet", "ImagePrep", "RemapTilt", "BuildSwf", "Pretransfer", "Droplets"}
        set CacheFolderLoc to ((path to library folder) & "Caches:" as string) as alias
        
        --Roundhousehelper cache folder
        try
            tell application "Finder" to make new folder at CacheFolderLoc with properties {name:"HotboxHelper"}
            log_event("Cache Folder 'RoundHouseHelper' created at... " & CacheFolderLoc as string)
        end try
        set HotboxHelper_folder to (path to library folder) & "Caches:HotboxHelper:" as string
        
        --create each folder from the list
        repeat with aFolder in CacheFolderList
            try
                tell application "Finder" to make new folder at (HotboxHelper_folder as alias) with properties {name:aFolder}
                log_event("Cache Folder '" & (aFolder as string) & "' created at... " & HotboxHelper_folder as string)
            end try
        end repeat
        
        --set cache folder aliases
        set Retrieve_folder to (HotboxHelper_folder & "Retrieve:" as string) as alias
        set PsDroplet_folder to (HotboxHelper_folder & "PsDroplet:" as string) as alias
        set ImagePrep_folder to (HotboxHelper_folder & "ImagePrep:" as string) as alias
        set RemapTilt_folder to (HotboxHelper_folder & "RemapTilt:" as string) as alias
        set BuildSwf_folder to (HotboxHelper_folder & "BuildSwf:" as string) as alias
        set Pretransfer_folder to (HotboxHelper_folder & "Pretransfer:" as string) as alias
        set droplet_folder to (HotboxHelper_folder & "Droplets:" as string)
        
        log_event("Checking for Cache Folders...Finished")
    end checkCacheFolders_
    
    --CHECK FOR DROPLETS
    on checkDroplets_(sender)
        log_event("Checking for Droplets...")
        --set defaults
        set dropletsExist to {droplet1exist:false,droplet2exist:false,droplet3exist:false}
        --gets contents of droplets folder
        try
            set dropFolderCont to null
            tell Application "Finder" to set dropFolderCont to every file in (dropletFolder as alias) as string
        end try
        --update droplets exists if droplets are found
        if dropFolderCont as text contains drop1Name then
            set droplet1exist of dropletsExist to true
            set Droplet1Location to (dropletFolder & drop1Name & ".app" as string) as alias
            if initializing is true then log_event("Found " & drop1Name as string)
            tell drop1Indicator to setIntValue_(1)
        else
            tell drop1Indicator to setIntValue_(3)
        end if
        if dropFolderCont as text contains drop2Name then
            set droplet2exist of dropletsExist to true
            set Droplet2Location to (dropletFolder & drop2Name & ".app" as string) as alias
            if initializing is true then log_event("Found " & drop2Name as string)
            tell drop2Indicator to setIntValue_(1)
        else
            tell drop2Indicator to setIntValue_(3)
        end if
        if dropFolderCont as text contains drop3Name then
            set droplet3exist of dropletsExist to true
            set Droplet3Location to (dropletFolder & drop3Name & ".app" as string) as alias
            if initializing is true then log_event("Found " & drop3Name as string)
            tell drop3Indicator to setIntValue_(1)
        else
            tell drop3Indicator to setIntValue_(3)
        end if
        log_event("Checking for Droplets...Finished")
    end checkDroplets_
    
    (* ======================================================================
                            Handlers for Preferences!
     ====================================================================== *)
    
    on updateSavefolderLocLabel()
        --Update the text field containing the save folder location
        tell savefolderlocLabel
            setEditable_(1)
            setStringValue_(saveFolderloc)
            setEditable_(0)
        end tell
        log_event("Update save folder location text field...")
    end updateSavefolderLocLabel
    
    on updateRawfolderLocLabel()
        --Update the text field containing the save folder location
        tell rawFolderloclabel
            setEditable_(1)
            setStringValue_(rawFolderloc)
            setEditable_(0)
        end tell
        log_event("Update raw folder location text field...")
    end updateRawfolderLocLabel
    
    on changeSaveFolderloc_(sender)
        --Change the save folder location
        log_event("Change Save folder location...")
        set choice to (choose folder) as string
        tell defaults to setObject_forKey_(choice, "saveFolderloc")
        retrieveDefaults_(me)
        updateSavefolderLocLabel()
        log_event("Change Save folder location...Finished")
    end changeSaveFolderloc_
    
    on showSaveFolder_(sender)
        log_event("Opening Save Folder...")
        tell app "Finder"
            make new Finder window
            activate
            set target of window 1 to saveFolderloc
        end tell
        log_event("Opening Save Folder...Done")
    end showSaveFolder_
    
    on changeRawFolderloc_(sender)
        --Change the save folder location
        log_event("Change Raw folder location...")
        set choice to (choose folder) as string
        tell defaults to setObject_forKey_(choice, "rawFolderloc")
        retrieveDefaults_(me)
        updateRawfolderLocLabel()
        log_event("Change Raw folder location...Finished")
    end changeRawFolderloc_
    
    on showRawFolder_(sender)
        log_event("Opening Raw Folder...")
        tell app "Finder"
            make new Finder window
            activate
            open folder rawFolderloc
        end tell
        log_event("Opening Raw Folder...Done")
    end showRawFolder_
    
    on retrieveDefaults_(sender)
        --Read the preferences from the preferences file
        log_event("Read in Preferences...")
        tell defaults
            set saveFolderloc to objectForKey_("saveFolderloc") as string
            set rawFolderloc to objectForKey_("rawFolderloc") as string
        end tell
        log_event("Save Folder Location: " & saveFolderloc)
        log_event("Save Folder Location: " & rawFolderloc)
        log_event("Read in Preferences...Finished")
    end retrieveDefaults_
    
    on dropletButtons_(sender)
        log_event("Replace Droplet Button..." & (title of sender as string) as string)
        
        --Check for Droplets
        checkDroplets_(me)
        
        --Declare default vars
        set trueName to false
        set removeDroplet to false
        
        --Figure out what droplet we are replacing
        set buttonName to title of sender as string
        set newDropletLoc to (choose file with prompt "Choose new droplet...")
        --Get filename and remove ".app"
        tell app "Finder" to set newDropName to name of newdropletloc
        set newDropName to (text 1 thru text -5 of newDropName) as string
        --Subtract last character on new droplet location because it adds a ":" to the end of .app files
        set newDropletLoc to newDropletLoc as string
        if (the last character of newDropletLoc is ":") then set newDropletLoc to (text 1 thru -2 of newDropletLoc) as string
        
        --Check new droplet name and allow/disallow renaming of file
        if buttonName = "Droplet 1" then
            if newDropName = drop1Name then set trueName to true
            set dropName to drop1Name
            if droplet1exist of dropletsExist is true then set removeDroplet to true
            else if buttonName = "Droplet 2" then
            if newDropName = drop2Name then set trueName to true
            set dropName to drop2Name
            if droplet2exist of dropletsExist is true then set removeDroplet to true
            else if buttonName = "Droplet 3" then
            if newDropName = drop3Name then set trueName to true
            set dropName to drop3Name
            if droplet3exist of dropletsExist is true then set removeDroplet to true
        end if
        
        --delete the old droplet
        if removeDroplet is true then
            do shell script "rm -rf " & quoted form of POSIX path of (dropletFolder & dropName & ".app" as string)
            log_event("Removed old droplet...")
        end if
        
        try
            --Try to copy in new droplet
            do shell script "cp -rf " & quoted form of POSIX path of newDropletLoc & " " & quoted form of POSIX path of dropletFolder
            log_event("Copied new droplet...")
            --If name is false then change the name
            if trueName is false then
                do shell script "mv " & quoted form of POSIX path of (dropletFolder & newDropName & ".app" as string) & " " & quoted form of POSIX path of (dropletFolder & dropName & ".app" as string)
                log_event("Renamed new droplet...")
            end if
            --log change
            log_event("New Droplet successful!")
            --Check for Droplets again. Temp initializing true
            set initializing to true
            checkDroplets_(me)
            set initializing to false
            
            on error errmsg
            tell me to display dialog "Error when attempting to replace droplet"
            log_event("Add/New Droplet FAILED...")
        end try
    end dropletButtons_
    
    (* ======================================================================
                                Handler for logging!
     ====================================================================== *)
    
    on log_event(themessage)
        --Log event, then write to rolling log file.
        log themessage
        set theLine to (do shell script "date  +'%Y-%m-%d %H:%M:%S'" as string) & " " & themessage
        do shell script "echo " & theLine & " >> ~/Library/Logs/HotboxHelper.log"
        tell LogWindow
            setEditable_(1)
            insertText_(themessage & return)
            setEditable_(0)
            setSelectable_(0)
        end tell
    end log_event
    
    on checklog()
        log_event("Checking log...")
        --get the count of lines in the log file
        set thecount to (do shell script "wc -l ~/Library/Logs/HotboxHelper.log")
        --make the returned string into an integer
        set thecount to (text 1 thru ((offset of the "/" in thecount) - 1) in thecount) as integer
        if thecount > 30000 then
            log_event("Checking log...Log is over 30000 lines!")
            log_event("Checking log...Creating BACKUP of old log")
            do shell script "mv ~/Library/Logs/HotboxHelper.log ~/Library/Logs/HotboxHelper-BACKUP.log"
            delay 0.3
            log_event("==========PROGRAM INITILIZE=========")
            log_event("------BACKUP OF OLD LOG CREATED-----")
            else
            log_event("Checking log...Done!")
        end if
    end checklog
	
end script