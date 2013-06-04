--
--  AppDelegate.applescript
--  HotboxHelper
--
--  Created by Christian on 5/6/13.
--  Copyright (c) 2013 Drivetime. All rights reserved.
--

script AppDelegate
	property parent : class "NSObject"
    
    --Preferences
    property defaults : missing value
    --Windows
    property MainWindow : missing value
	property MainView : missing value
    property CacheWindow : missing value
    property PreferencesWindow : missing value
    property doubleCheckWindow : missing value
    property tempWindow : missing value
    property existsWindow : missing value
    --main window
    property MainBar1 : missing value
    property MainDetail1 : missing value
    property ArchiveButton : missing value
    property mainPauseButton : missing value
    property mainRevisebutton : missing value
    property mainNewbutton : missing value
    --Cache folders
    property Retrieve_folder : null
    property PsDroplet_folder : null
    property ImagePrep_folder : null
    property RemapTilt_folder : null
    property BuildSwf_folder : null
    property Pretransfer_folder : null
    property dropletFolder : null
    property HotboxHelper_folder : null
    --Cache Window
    property cacheIndicator : missing value
    property cachecancelbutton : missing value
    property cachepausebutton : missing value
    property cachelabel : missing value
    property cancelCache : false
    property pauseCache : false
    --Preferences Window
    property savefolderlocLabel : missing value
    property rawFolderloclabel : missing value
    property drop1Indicator : missing value
    property drop2Indicator : missing value
    property drop3Indicator : missing value
    property LogWindow : missing value
    --DoubleCheckWindow
    property doubleCheckLabel : missing value
    property doubleCheckHandler : null
    --Temp Progress Window
    property tempBar1 : missing value
    property tempDetail1 : missing value
    --Master State
    property pauseUser : false
    property CacheCleared : false
    property lastTask : null
    property meFinished : false
    property requestSel : null
    property userRequest : null
    property isPaused : false
    property finishedProcessing : false
    property lastFolder : null
    --globals
    property initializing : true
    property drop1Name : "BuildSwf"
    property drop2Name : "PsDroplet"
    property drop3Name : "RemapTilt"
    property dropletsExist : null
    property saveFolderloc : null
    property rawFolderloc : null
    property clearCacheTimer : 1
    property ClearCacheCountDown : true
    property Delay1 : 0.3
    property cacheWait : 0.1
    property CurrentImageNumber : null
    property ImagePrepTimeout : 0
    property swfName : null
    property PhotoshopFile : null
    property DropletPhotoshop : null
    property DropletRemaptilt : null
    property DropletBuildswf : null
    property ImagePrep : null
    property Photoshop : "Adobe Photoshop CS6"
    property ImagePrepIndicator : missing value
    property Imageprepexists : false
    
    (* ======================================================================
                            Handlers for Processing!
     ====================================================================== *)
    
    --RESTART EVERYTHING FOR A NEW IMAGE
    on returntoStart()
        log_event("Returning to start...")
        log_event("Returning to start...Close any active sheet")
        --try to close any possible window
        try
            tell current application's NSApp to endSheet_(CacheWindow)
        end try
        try
            tell current application's NSApp to endSheet_(doubleCheckWindow)
        end try
        try
            tell current application's NSApp to endSheet_(tempWindow)
        end try
        try
            tell current application's NSApp to endSheet_(existsWindow)
        end try
        
        log_event("Returning to start...reset all window visuals")
        --reset the window detail, bar and button
        tell MainDetail1 to setStringValue_("Press Start")
        tell MainBar1 to setIndeterminate_(true)
        tell MainBar1 to stopAnimation_(me)
        tell mainPauseButton to setTitle_("Start")
        tell mainPauseButton to setEnabled_(1)
        tell ArchiveButton to setEnabled_(0)
        tell mainNewbutton to setEnabled_(0)
        tell mainRevisebutton to setEnabled_(0)
        
        log_event("Returning to start...Finished!")
    end returntoStart
    
    --USER REQUESTS "REVISE"
    on requestRevise()
        set requestSel to "R"
        set userRequest to true
        --disable buttons so the user cant press them until the request is finished
        if isPaused is true or finishedProcessing is true then quietUserRequest()
    end requestRevise
    
    --USER REQUESTS "NEW"
    on requestNew()
        set requestSel to "N"
        set userRequest to true
        --disable buttons so the user cant press them until the request is finished
        tell ArchiveButton to setEnabled_(0)
        tell mainRevisebutton to setEnabled_(0)
        tell mainNewbutton to setEnabled_(0)
        if isPaused is true or finishedProcessing is true then quietUserRequest()
    end requestNew

    --IF NOTHING IS RUNNING THEN DO THE USER REQUEST
    on quietUserRequest()
        if userRequest = true then
            performSelector_withObject_afterDelay_("doUserRequest", missing value, Delay1)
            set userRequest to false
        end if
        if isPaused is true then tell mainPauseButton to setState_(0)
        log_event("Quiet user Resume...")
    end quietUserRequest
    
    --FIGURE OUT WHAT THE USER REQUEST WAS AND EXECUTE IT
    on doUserRequest()
        if requestSel = "R" then
            log_event("User Request...Revise")
            performSelector_withObject_afterDelay_("startRevise", missing value, 0.1)
        else if requestSel = "N"
            log_event("User Request...New")
            performSelector_withObject_afterDelay_("StartClearCache", missing value, 0.2)
            returntoStart()
        end if
    end doUserRequest
    
    --OPEN THE IMAGE IN PHOTOSHOP AND ASK THE USER TO REVISE
    on startRevise()
        log_event("Revise...")
        log_event("Revise...Opening image in photoshop")
        
        set AdobePhotoshopCS6 to path to application Photoshop as alias
        tell application "Finder"
            open PhotoshopFile using AdobePhotoshopCS6
        end tell
        
        areYouSure("Do you want to process the revised image?","processRevised")
        log_event("Revise...Ask user to continue")
    end startRevise
    
    --REVISE AFTER THE USER CLICK YES!
    on processRevised()
        log_event("Revise...Process the revised Image")
        tell ArchiveButton to setEnabled_(0)
        tell mainRevisebutton to setEnabled_(0)
        showTempProgress("Preparing to Revise...",4,0)
        delay 0.5
        closeSwfPreview()
        clearcacheRevise()
        performSelector_withObject_afterDelay_("Step2fromRevise", missing value, 0.5)
    end processedRevise
    
    --CLEAR THE CACHE FOR REVISING
    on clearcacheRevise()
        log_event("Revise...Clear Cache")
        tempProgressUpdate(1,"Removing old images...Remaptilt")
        delay 0.2
        do shell script "rm -rf " & POSIX path of (HotboxHelper_folder & "Remaptilt:*" as string)
        tempProgressUpdate(1,"Removing old images...ImagePrep")
        delay 0.2
        do shell script "rm -rf " & POSIX path of (HotboxHelper_folder & "ImagePrep:*" as string)
        tempProgressUpdate(1,"Removing old images...BuildSwf")
        delay 0.2
        do shell script "rm -rf " & POSIX path of (HotboxHelper_folder & "BuildSwf:*" as string)
        tempProgressUpdate(1,"Removing old images...Done!")
        delay 1
        hideTempProgress()
    end clearcacheRevise
    
    --CLOSE THE SWF WINDOW
    on closeSwfPreview()
        log_event("Try to close the SWF safari window...")
        try
            tell application "Safari"
                close (every window whose name is swfName)
            end tell
            delay 1
        end try
    end closeSWFPreview
    
    --TRY TO OPEN THE VIEWFINDER
    on openViewfinder()
        log_event("Try to open ViewFinder app...")
        try
            set VFopen to false
            tell application "System Events"
                tell application "ViewFinder Mac 7.4.5.app"
                    try
                        activate window "Camera Files"
                        set VFopen to true
                    end try
                end tell
                if VFopen = false then
                    try
                        set visible of process ViewFinder to true
                    end try
                end if
            end tell
        end try
    end openViewfinder
    
    --TRY TO CLOSE THE VIEWFINDER
    on closeViewFinder()
        log_event("Try to close ViewFinder app...")
        tell application "System Events"
            try
                set visible of process ViewFinder to false
            end try
        end tell
    end closeViewFinder
    
    --START CLEAR CACHE
    on StartClearCache()
        --Use MyriadHelpers to show cache window as sheet
        log_event("Clear Cache...")
        tell CacheWindow to showOver_(MainWindow)
        clearCache()
    end StartClearCache
    
    --CLEAR CACHE HANDLER
    on clearCache()
        
        --Make sure the cancel button was not pressed
        if ClearCacheCountDown = true and cancelCache = false and pauseCache = false then
            --Do 5 second countdown
            log "Clear Cache..." & clearCacheTimer
            tell cacheIndicator to setIntValue_(clearCacheTimer - 1)
            tell cachelabel to setStringValue_("Preparing to Clear Cache...(" & (6 - clearCacheTimer) & ")")
            set clearCacheTimer to clearCacheTimer + 1
            if clearCacheTimer = 7 then
                set ClearCacheCountDown to false
                set clearCacheTimer to 1
            end if
            performSelector_withObject_afterDelay_("clearCache", missing value, cacheWait)
        else if ClearCacheCountDown = false and cancelCache = false and pauseCache = false then
            --After the coutdown we can now clear the cache
            set CacheFolderList to {"Retrieve", "PsDroplet", "ImagePrep", "RemapTilt", "BuildSwf", "Pretransfer"}
            tell cachelabel to setStringValue_("Clearing Cache..." & (item clearCacheTimer of CacheFolderList) as string)
            log_event("Clear Cache...Clearing " & (item clearCacheTimer of CacheFolderList) as string)
            --delete all files in folder
            do shell script "rm -rf " & POSIX path of (HotboxHelper_folder & item clearCacheTimer of CacheFolderList & ":*" as string)
            set clearCacheTimer to clearCacheTimer + 1
            if clearCacheTimer = 7 then
                set clearCacheTimer to 1
                set ClearCacheCountDown to true
                tell cachelabel to setStringValue_("Clearing Cache...Done!")
                delay 1
                --reset window
                tell current application's NSApp to endSheet_(CacheWindow)
                tell cacheIndicator to setIntValue_(0)
                set CacheCleared to true
                log_event("Clear Cache...Finished")
                --TRY TO OPEN THE VIEWFINDER APP
                openViewfinder()
            else
                performSelector_withObject_afterDelay_("clearCache", missing value, 0.1)
            end if
        else if pauseCache = true and cancelCache = false then
            --Pause clear cache
            performSelector_withObject_afterDelay_("clearCache", missing value, 1)
        else if cancelCache = true then
            --End clear Cache
            log_event("Clear Cache...CANCELED BY USER")
            set clearCacheTimer to 1
            set ClearCacheCountDown to true
            tell cachelabel to setStringValue_("Clearing Cache...Canceled!")
            set cancelCache to false
            delay 1
            --Reset window
            tell current application's NSApp to endSheet_(CacheWindow)
            tell cacheIndicator to setIntValue_(0)
            tell cachelabel to setStringValue_("Preparing to Clear Cache...")
            --try to reset the pause button
            try
                tell cachepausebutton to setState_(0)
                set pauseCache to false
            end try
            --Go back to "Start" state
            returntoStart()
        end if
        
        --When the cache is cleared, begin searching.
        if CacheCleared is true then
            performSelector_withObject_afterDelay_("prepareStart", missing value, 0.5)
            set CacheCleared to false
        end if
    end ClearCache_
    
    --CHECK IF THE FILE IS FINISHED
    on checkFileState(theFolder)
        log "Checking File State..."
        
        if theFolder is not lastFolder then
            log_event("Checking File State...")
            set lastFolder to theFolder
        end if
        
        tell application "Finder"
            try
                set folder_list to entire contents of theFolder
                delay 1
                set CheckFile to ((item 1 of folder_list as string) as alias)
                log "Checking File State...File exists!"
                set CheckFile_size1 to physical size of CheckFile
                delay 1
                set CheckFile_size2 to physical size of CheckFile
            on error errmsg
                log "Checking File State...File does NOT exist"
            end try
        end tell
        
        try
            if CheckFile_size1 = CheckFile_size2 then
                return true
                log_event("Checking File State...file is ready!")
            else
                return false
                log "Checking File State...file is NOT ready"
            end if
        on error errmsg
            return false
            log "Checking File State...Not happy..."
        end try
    end checkFileState
    
    --PREPARE TO START
    on prepareStart()
        log_event("Preparing to start...")
        --Check for droplets
        log_event("Preparing to start...Check for Droplets")
        checkDroplets_(me)
        if droplet1exist of dropletsExist is true and droplet2exist of dropletsExist is true and droplet3exist of dropletsExist is true then
            log_event("Preparing to start...Droplets ok!")
        else
            log_event("Preparing to start...DROPLETS MISSING")
            display dialog "A Droplet is missing, Please replace them in the peferences" buttons ("Ok") default button 1 with icon (stop)
            performSelector_withObject_afterDelay_("returntoStart", missing value, 0.1)
            return
        end if
        --Check for imageprep
        log_event("Preparing to start...ImagePrep")
        checkforImageprep()
        if ImagePrepexists is true then
            log_event("Preparing to start...ImagePrep OK!")
        else
            log_event("Preparing to start...IMAGEPREP MISSING")
            display dialog "ImagePrep is missing, Please make sure ImagePrep exists in the 'Applications' Folder." buttons ("Ok") default button 1 with icon (stop)
            performSelector_withObject_afterDelay_("returntoStart", missing value, 0.1)
            return
        end if
        --Check for download folders
        log_event("Preparing to start...Check Save-Raw Folders")
        retrieveDefaults_(me)
        try
            set testsave to saveFolderloc as alias
            set testraw to rawFolderloc as alias
        on error errmsg
            log_event("Preparing to start...SAVE-RAW FOLDER MISSING")
            display dialog "The Save or Raw folder appears to be missing. Please make sure the folders set in preferences exist." buttons ("Ok") default button 1 with icon (stop)
            performSelector_withObject_afterDelay_("returntoStart", missing value, 0.1)
            return
        end try
        
        log_event("Preparing to start...Done!")
        performSelector_withObject_afterDelay_("startSearch", missing value, 0.1)
    end prepareStart
    
    --START SEARCHING
    on startSearch()
        tell MainDetail1 to setStringValue_("Looking for Image...")
        tell MainBar1 to startAnimation_(me)
        tell MainBar1 to setIndeterminate_(true)
        tell mainNewbutton to setEnabled_(1)
        tell mainPauseButton to setTitle_("Pause")
        log_event("Search Start...")
        log_event("Looking for Image...")
        searchFor()
    end startSearch
    
    --WAIT FOR THE FIRST IMAGE IN CACHE
    on searchFor()
        set lastTask to "searchFor"
        set finishedProcessing to false
        log "Looking for image..."
        try
            tell MainDetail1 to setStringValue_("Looking for Image...")
            tell application "Finder" to set waitingforFirstimage to every file in Retrieve_folder
            if (item 1 of waitingforFirstimage) exists then
                set meFinished to true
                log_event("Looking for image...Found!")
            end if
            closeViewFinder()
            set meFinished to true
        end try
        
        if pauseUser = true then
            performSelector_withObject_afterDelay_("mainPause", missing value, 0.1)
            set pauseUser to false
        else if meFinished = true then
            performSelector_withObject_afterDelay_("Prepare", missing value, delay1)
            set meFinished to false
        else if userRequest is true then
            performSelector_withObject_afterDelay_("doUserRequest", missing value, delay1)
            set userRequest to false
        else
            performSelector_withObject_afterDelay_("SearchFor", missing value, 0.5)
        end if
    end searchFor
    
    --THE IMAGE HAS BEEN FOUND, PREPARE TO PROCESS IT
    on Prepare()
        log_event("Preparing...")
        
        tell MainDetail1 to setStringValue_("Preparing to Process Image...")
        tell MainBar1
            startAnimation_(me)
            setMaxValue_(12)
            setDoubleValue_(1)
            setIndeterminate_(false)
        end tell
        
        performSelector_withObject_afterDelay_("GetFilename", missing value, delay1)
        updateMain("Waiting for image to finish downloading...",1)
    end Prepare
        
    --GET THE FILENAME OF THE IMAGE AND SAVE IT
    on GetFilename()
        set lastTask to "GetFilename"
        log "Wait for image...get filename"
        
        if checkFileState(Retrieve_folder) is true then
            --Get the filename
            tell application "Finder"
                set theContents to every file of Retrieve_folder
                set theFile to name of ((item 1 of theContents) as alias)
            end tell
            set CurrentImageNumber to (text 1 thru ((offset of "." in theFile) - 1) of theFile) as string
            if meFinished is false then updateMain("Download finished, getting carnumber...",1)
            log_event("CurrentImageNumber: " & CurrentImageNumber)
            set meFinished to true
        end if
        
        if pauseUser = true then
            performSelector_withObject_afterDelay_("mainPause", missing value, 0.1)
            set pauseUser to false
        else if meFinished = true then
            performSelector_withObject_afterDelay_("Step1Photoshop", missing value, delay1)
            set meFinished to false
            updateMain("Sending the image to photoshop...",1)
        else if userRequest is true then
            performSelector_withObject_afterDelay_("doUserRequest", missing value, delay1)
            set userRequest to false
        else
            performSelector_withObject_afterDelay_("GetFilename", missing value, delay1)
        end if
    end GetFilename
        
    --OPEN THE IMAGE WITH THE PHOTOSHOP DROPLET
    on Step1Photoshop()
        log "Step1 - trying to open with photoshop"
        set lastTask to "Step1Photoshop"
        
        if checkFileState(Retrieve_folder) is true then
            --open the image in photoshop
            
            tell application "Finder"
                set theContents to every file of Retrieve_folder
                tell me to log_event("Sending Image to Photoshop...")
                open (item 1 of theContents) using DropletPhotoshop
            end tell
            set meFinished to true
        end if
        
        if pauseUser = true then
            performSelector_withObject_afterDelay_("mainPause", missing value, 0.1)
            set pauseUser to false
        else if meFinished = true then
            performSelector_withObject_afterDelay_("Step2ImagePrep", missing value, delay1)
            set meFinished to false
            updateMain("Waiting for photoshop...",1)
        else if userRequest is true then
            performSelector_withObject_afterDelay_("doUserRequest", missing value, delay1)
            set userRequest to false
        else
            performSelector_withObject_afterDelay_("Step1Photoshop", missing value, delay1)
        end if
    end Step1Photoshop
    
    --FROM STEP 2 TO STEP 3
    on Step2FromStep3()
        tell mainPauseButton to setState_(0)
        updateMain("Resuming...",null)
        set meFinished to true
        performSelector_withObject_afterDelay_("Step2ImagePrep", missing value, 0.1)
    end Step2FromStep3
    
    --FROM REVISE TO STEP 3
    on Step2fromRevise()
        tell mainNewbutton to setEnabled_(1)
        tell mainbar1 to setDoubleValue_(5)
        tell MainDetail1 to setStringValue_("Preparing to send Image to ImagePrep...")
        performSelector_withObject_afterDelay_("Step2ImagePrep", missing value, 0.1)
    end Step2fromRevise
        
    --SEND THE IMAGE TO IMAGEPREP
    on Step2ImagePrep()
        log "waiting for image from photoshop"
        set lastTask to "Step2ImagePrep"
        
        if checkFileState(PsDroplet_folder) is true then
            --open the image using imageprep
            tell application "Finder"
                set theContents to every file of PsDroplet_folder
                set PhotoshopFile to (item 1 of theContents)
                tell me to log_event("Sending image to ImagePrep...")
                open (item 1 of theContents) using ImagePrep
            end tell
            if meFinished is false then updateMain("Sending image to ImagePrep...",1)
            --try to Hide photoshop
            try
                log_event("Try to hide Photoshop...")
                tell application "System Events"
                    if process Photoshop exists then
                        set visible of process Photoshop to false
                    end if
                end tell
            end try
            if meFinished is false then updateMain("Waiting for ImagePrep...",1)
            set meFinished to true
        end if
        
        if pauseUser = true then
            performSelector_withObject_afterDelay_("mainPause", missing value, 0.1)
            set pauseUser to false
        else if meFinished = true then
            performSelector_withObject_afterDelay_("Step3WaitforIP", missing value, delay1)
            set meFinished to false
        else if userRequest is true then
            performSelector_withObject_afterDelay_("doUserRequest", missing value, delay1)
            set userRequest to false
        else
            performSelector_withObject_afterDelay_("Step2ImagePrep", missing value, delay1)
        end if
    end Step2ImagePrep
        
    --WAIT FOR THE IMAGE FROM IMAGEPREP
    on Step3WaitforIP()
        log "Step 3 - Wait for imageprep"
        set lastTask to "Step3WaitforIP"
        
        --Update is resuming
        updateMain("Waiting for ImagePrep...",null)
        
        --Check if imageprep is open
        try
            tell application "System Events"
                set ImageprepProcess to count of (every process whose name is "ImagePrep")
            end tell
            if ImageprepProcess = 1 then
                --wait 2 seconds and try again
                delay 2
                log "Image prep is still open"
            else if ImageprepProcess = 0 then
                --If it's closed look for the image
                set ImagePrepTimeout to ImagePrepTimeout + 1
                if ImagePrepTimeout = 15 then
                    --if it's taking too long ask the user to try again
                    areYouSure("No Image Found. Re-open ImagePrep?","Step2FromStep3")
                    set pauseUser to true
                    tell mainPauseButton to setState_(1)
                    set ImagePrepTimeout to 0
                else
                    --if the timeout has not been reached then look for the image
                    try
                        tell application "Finder"
                            set theContents to every file of ImagePrep_folder
                            set theFile to (item 1 of theContents)
                            set meFinished to true
                        end tell
                    end try
                end if
            end if
        end try
        
        if pauseUser = true then
            performSelector_withObject_afterDelay_("mainPause", missing value, 0.1)
            set pauseUser to false
        else if meFinished = true then
            performSelector_withObject_afterDelay_("step4RemapTilt", missing value, delay1)
            set meFinished to false
        else if userRequest is true then
            performSelector_withObject_afterDelay_("doUserRequest", missing value, delay1)
            set userRequest to false
        else
            performSelector_withObject_afterDelay_("Step3WaitforIP", missing value, delay1)
        end if
    end Step3WaitforIP
        
    --SPEND THE IMAGE TO REMAPTILT
    on step4RemapTilt()
        log "Step 4 - waiting for image from imageprep"
        set lastTask to "step4RemapTilt"
        
        if checkFileState(ImagePrep_folder) is true then
            tell application "Finder"
                set theContents to every file of ImagePrep_folder
                tell me to log_event("Sending image to Remaptilt...")
                open (item 1 of theContents) using DropletRemaptilt
            end tell
            if meFinished is false then updateMain("Sending image to RemapTilt...",1)
            set meFinished to true
        end if
        
        if pauseUser = true then
            performSelector_withObject_afterDelay_("mainPause", missing value, 0.1)
            set pauseUser to false
        else if meFinished = true then
            performSelector_withObject_afterDelay_("Step5BuildSwf", missing value, delay1)
            set meFinished to false
            updateMain("Waiting for RemapTilt...",1)
        else if userRequest is true then
            performSelector_withObject_afterDelay_("doUserRequest", missing value, delay1)
            set userRequest to false
        else
            performSelector_withObject_afterDelay_("step4RemapTilt", missing value, delay1)
        end if
    end step4RemapTilt
        
    --SEND THE IMAGE TO BUILDSWF
    on Step5BuildSwf()
        log "Step 5 - waiting for image from Remaptilt"
        set lastTask to "Step5BuildSwf"
        
        if checkFileState(RemapTilt_folder) is true then
            tell application "Finder"
                set theContents to every file of RemapTilt_folder
                tell me to log_event("Sending image to BuildSwf...")
                open (item 1 of theContents) using DropletBuildswf
            end tell
            if meFinished is false then updateMain("Sending image to Buildswf...",1)
            set meFinished to true
        end if
        
        if pauseUser = true then
            performSelector_withObject_afterDelay_("mainPause", missing value, 0.1)
            set pauseUser to false
        else if meFinished = true then
            performSelector_withObject_afterDelay_("Step6WaitforBS", missing value, delay1)
            set meFinished to false
            updateMain("Waiting Buildswf...",1)
        else if userRequest is true then
            performSelector_withObject_afterDelay_("doUserRequest", missing value, delay1)
            set userRequest to false
        else
            performSelector_withObject_afterDelay_("Step5BuildSwf", missing value, delay1)
        end if
    end Step5BuildSwf
        
    --WAIT FOR THE IMAGE FROM BUILDSWF
    on Step6WaitforBS()
        log "step 6 - waiting for image from build Swf"
        set lastTask to "Step6WaitforBS"
        
        if checkFileState(BuildSwf_folder) is true then
            tell application "Finder"
                set theContents to every file of BuildSwf_folder
                set theSwf to (item 1 of theContents)
                set swfName to name of theSwf
            end tell
            log_event("Use Safari to open Swf...")
            tell application "Safari"
                make new document with properties {URL:""}
                open theSwf
            end tell
            if meFinished is false then updateMain("Processing Finished",1)
            set meFinished to true
        end if
        
        if pauseUser = true then
            performSelector_withObject_afterDelay_("mainPause", missing value, 0.1)
            set pauseUser to false
        else if meFinished = true then
            --Now that we've finished processing enable all buttons
            set finishedProcessing to true
            tell ArchiveButton to setEnabled_(1)
            tell mainRevisebutton to setEnabled_(1)
            set meFinished to false
        else if userRequest is true then
            performSelector_withObject_afterDelay_("doUserRequest", missing value, delay1)
            set userRequest to false
        else
            performSelector_withObject_afterDelay_("Step6WaitforBS", missing value, delay1)
        end if
    end Step6WaitforBS
    
    (* ======================================================================
                                Handlers for Archiving!
     ====================================================================== *)
      
    on doArchive()
        log_event("Archiving...")
        showTempProgress("Archiving...",1,0)
        tell tempBar1 to setIndeterminate_(true)
        tell tempBar1 to startAnimation_(me)
        
        log_event("Archiving...Preparing files")
        set zippath to rawFolderloc & CurrentImageNumber & ".zip" as string
        tell application "Finder"
            set RemapTilt_ext to name extension of ((first item in RemapTilt_folder) as alias)
            set name of ((first item in RemapTilt_folder) as alias) to CurrentImageNumber & "-FullResolution." & RemapTilt_ext
            set name of ((first item in BuildSwf_folder) as alias) to CurrentImageNumber & ".swf"
            duplicate items of RemapTilt_folder to Pretransfer_folder with replacing
            duplicate items of BuildSwf_folder to Pretransfer_folder with replacing
            try
                make new folder at saveFolderloc with properties {name:CurrentImageNumber}
            end try
        end tell
        
        log_event("Archiving...Creating Zip")
        delay 0.3
        do shell script "zip -r -jr " & quoted form of POSIX path of (zippath) & " " & quoted form of POSIX path of (Pretransfer_folder)
        delay 0.3
        
        log_event("Archiving...Resizing file")
        tell application "Finder"
            set name of ((first item in RemapTilt_folder) as alias) to CurrentImageNumber & "-int.UPLOADLARGE." & RemapTilt_ext
            set resize_image to (RemapTilt_folder & CurrentImageNumber & "-int.UPLOADLARGE." & RemapTilt_ext as string) as alias
            tell application "Image Events"
                launch
                set this_image to open resize_image
                scale this_image to size 4096
                save this_image in (RemapTilt_folder & CurrentImageNumber & "-int.UPLOADLARGE.jpg" as string) as JPEG
                close this_image
            end tell
            delete resize_image
            try
                duplicate items of RemapTilt_folder to ((saveFolderloc & CurrentImageNumber as string) as alias) with replacing
            end try
        end tell
        
        hideTempProgress()
        tell tempBar1 to setIndeterminate_(false)
        log_event("Archiving...Done!")
        performSelector_withObject_afterDelay_("StartClearCache", missing value, 0.3)
    end doArchive
        
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
        --check for imageprep
        checkforImageprep()
        --Set/Get Preferences
        tell current application's NSUserDefaults to set defaults to standardUserDefaults()
        tell defaults to registerDefaults_({saveFolderloc:((path to desktop)as string),rawFolderloc:((path to desktop)as string)})
        retrieveDefaults_(me)
        --set pause button to "Start" in begining
        tell mainPauseButton to setTitle_("Start")
        
        set initializing to false
	end applicationWillFinishLaunching_
	
	on applicationShouldTerminate_(sender)
		log_event("==========PROGRAM SHUTDOWN==========")
		return current application's NSTerminateNow
	end applicationShouldTerminate_
    
    (* ======================================================================
                    Background Handlers for window/view control
     ====================================================================== *)
    
    on pauseButton_(sender)
        log_event("Main Button selected....")
        --Figure out what state the button is in
        if title of sender as string is "Start" then
            --Make sure the droplets exist
            checkDroplets_(me)
            if droplet1exist of dropletsExist = false or droplet2exist of dropletsExist = false or droplet3exist of dropletsExist = false then
                log_event("Droplet Missing!")
                tell mainPauseButton to setState_(0)
                display dialog "CAN NOT START: MISSING A DROPLET." &  "Load new droplets in the Preferences window." buttons ("Ok") default button 1 with icon (stop)
                return
            end if
            --If we still haven't started, clear cache then start searching
            tell mainPauseButton to setState_(0)
            tell mainPauseButton to setTitle_("Pause")
            StartClearCache()
        else if title of sender as string = "Pause" and state of sender as string = "1" then
            --If we started then, pause the search
            set pauseUser to true
            log_event("User Request... Pause")
        else if state of sender as string = "0" then
            --If we're paused, resume searching
            mainResume()
        end if
    end pauseButton_
    
    --RESUME THE MAIN PROCESSING
    on mainResume()
        tell MainDetail1 to setStringValue_("Resuming...")
        tell mainPauseButton to setState_(0)
        tell MainBar1 to startAnimation_(me)
        set isPaused to false
        log_event("Main Processing Resumed!")
        performSelector_withObject_afterDelay_(lastTask, missing value, delay1)
    end mainResume
    
    on mainPause()
        tell MainBar1 to stopAnimation_(me)
        tell MainDetail1 to setStringValue_("Paused")
        set isPaused to true
        log_event("Main Processing Paused!")
    end mainPause
    
    on updateMain(message,value)
        if message is not null then tell MainDetail1 to setStringValue_(message)
        if value is not null then tell MainBar1 to incrementBy_(value)
    end updateMain
    
    on OpenPreferences_(sender)
        --open preferences window
        log_event("Open Preferences...")
        updateSavefolderLocLabel()
        updateRawfolderLocLabel()
        PreferencesWindow's makeKeyAndOrderFront_(me)
        log_event("Open Preferences...Finished")
    end OpenPreferences_
    
    on CancelClearCacheButton_(sender)
        --Use MyriadHelpers to close cache sheet
        set cancelCache to true
	end ClearCacheCancelButton_
    
    on PauseClearCacheButton_(sender)
        --Pause the Clear Cache
        if pauseCache = false then
            log_event("Clear Cache...Paused")
            set pauseCache to true
        else
            log_event("Clear Cache...Resumed")
            set pauseCache to false
        end if
	end PauseCacheCancelButton_
    
    on newButtonPress_(sender)
        areYouSure("Are you sure you want to start over?","requestNew")
    end newButtonPress_
    
    on reviseButtonPress_(sender)
        areYouSure("Are you sure you want to revise the image?","requestRevise")
    end reviseButtonPress_
    
    on archiveButtonPress_(sender)
        areYouSure("Are you sure you want to archive?","doArchive")
    end archiveButtonPress_
    
    on areYouSure(message,nextHandler)
        tell doubleCheckLabel to setStringValue_(message)
        set doubleCheckHandler to nextHandler
        tell doubleCheckWindow to showOver_(MainWindow)
        log_event("Are you sure..." & nextHandler)
    end areYouSure
    
    on doubleCheckYes_(sender)
        tell current application's NSApp to endSheet_(doubleCheckWindow)
        performSelector_withObject_afterDelay_(doubleCheckHandler, missing value, 0.1)
        log_event("Are you sure...Yes")
        set doubleCheckHandler to null
    end doubleCheckYes_
    
    on doubleCheckNo_(sender)
        tell current application's NSApp to endSheet_(doubleCheckWindow)
        log_event("Are you sure...No")
        set doubleCheckHandler to null
    end doubleCheckNo_
    
    on showTempProgress(tempDetail,tempMaxValue,tempValue)
        log_event("Show Temp Progress...")
        log_event("Show Temp Progress...Detail: " & tempDetail)
        log_event("Show Temp Progress...maxValue: " & tempMaxValue & " curValue: " & tempValue)
        tell tempDetail1 to setStringValue_(tempDetail)
        tell tempBar1 to setMaxValue_(tempMaxValue)
        tell tempBar1 to setDoubleValue_(tempValue)
        tell tempWindow to showOver_(MainWindow)
        log_event("Show Temp Progress..opened")
    end showTempProgress
    
    on hideTempProgress()
        log_event("Show Temp Progress..closed")
        tell current application's NSApp to endSheet_(tempWindow)
    end hideTempProgress
    
    on tempProgressUpdate(x,message)
        if x doesn't equal null then
            tell tempBar1 to incrementBy_(x)
        end if
        if message doesn't equal null then
            tell tempDetail1 to setStringValue_(message)
        end if
    end tempProgressUpdate
    
    on nextStep_(sender)
        set meFinished to true
    end nextStep_
    
    (* ======================================================================
                            Handlers for startup & shutdown!
     ====================================================================== *)
    
    --CHECK FOR CACHE FOLDERS
    on checkCacheFolders_(sender)
        log_event("Checking for Cache Folders...")
        set CacheFolderList to {"Retrieve", "PsDroplet", "ImagePrep", "RemapTilt", "BuildSwf", "Pretransfer", "Droplets"}
        set CacheFolderLoc to ((path to library folder) & "Caches:" as string) as alias
        
        --HotboxHelper cache folder
        try
            tell application "Finder" to make new folder at CacheFolderLoc with properties {name:"HotboxHelper"}
            log_event("Cache Folder 'HotboxHelper' created at... " & CacheFolderLoc as string)
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
        set dropletFolder to (HotboxHelper_folder & "Droplets:" as string)
        
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
            --DropletBuildswf
            set DropletBuildswf to (dropletFolder & drop1Name & ".app" as string) as alias
            if initializing is true then log_event("Found " & drop1Name as string)
            tell drop1Indicator to setIntValue_(1)
        else
            set droplet1exist of dropletsExist to false
            if initializing is true then log_event("MISSING DROPLET " & drop1Name as string)
            tell drop1Indicator to setIntValue_(3)
        end if
        if dropFolderCont as text contains drop2Name then
            set droplet2exist of dropletsExist to true
            --DropletPhotoshop
            set DropletPhotoshop to (dropletFolder & drop2Name & ".app" as string) as alias
            if initializing is true then log_event("Found " & drop2Name as string)
            tell drop2Indicator to setIntValue_(1)
        else
            set droplet2exist of dropletsExist to false
            if initializing is true then log_event("MISSING DROPLET " & drop2Name as string)
            tell drop2Indicator to setIntValue_(3)
        end if
        if dropFolderCont as text contains drop3Name then
            set droplet3exist of dropletsExist to true
            --DropletRemaptilt
            set DropletRemaptilt to (dropletFolder & drop3Name & ".app" as string) as alias
            if initializing is true then log_event("Found " & drop3Name as string)
            tell drop3Indicator to setIntValue_(1)
        else
            set droplet3exist of dropletsExist to false
            if initializing is true then log_event("MISSING DROPLET " & drop3Name as string)
            tell drop3Indicator to setIntValue_(3)
        end if
        
        log_event("Checking for Droplets...Finished")
    end checkDroplets_
    
    --CHECK FOR IMAGE PREP
    on checkforImageprep()
        
        --Set imagePrep location as well
        set ImagePrepString to (path to applications folder) & "ImagePrep.app" as string
        
        try
            set ImagePrep to ((path to applications folder) & "ImagePrep.app" as string) as alias
            set ImagePrepexists to true
            log_event("Found ImagePrep Application")
            tell ImagePrepIndicator to setIntValue_(1)
        on error errmsg
            set ImagePrepexists to false
            log_event("MISSING ImagePrep Application")
            tell ImagePrepIndicator to setIntValue_(3)
        end try
        
    end checkforImagePrep
    
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
        log_event("Raw Folder Location: " & rawFolderloc)
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
        if buttonName = "BuildSwf" then
            if newDropName = drop1Name then set trueName to true
            set dropName to drop1Name
            if droplet1exist of dropletsExist is true then set removeDroplet to true
        else if buttonName = "PsDroplet" then
            if newDropName = drop2Name then set trueName to true
            set dropName to drop2Name
            if droplet2exist of dropletsExist is true then set removeDroplet to true
        else if buttonName = "RemapTilt" then
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
            tell me to display dialog "Error when attempting to replace droplet" buttons ("Ok") default button 1 with icon (stop)
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