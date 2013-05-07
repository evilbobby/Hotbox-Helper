--
--  AppDelegate.applescript
--  HotboxHelper
--
--  Created by Christian on 5/6/13.
--  Copyright (c) 2013 Drivetime. All rights reserved.
--

script AppDelegate
	property parent : class "NSObject"
	
	on applicationWillFinishLaunching_(aNotification)
		-- Insert code here to initialize your application before any files are opened 
	end applicationWillFinishLaunching_
	
	on applicationShouldTerminate_(sender)
		-- Insert code here to do any housekeeping before your application quits 
		return current application's NSTerminateNow
	end applicationShouldTerminate_
    
    on log_event(themessage)
        set theLine to (do shell script ¬
        "date  +'%Y-%m-%d %H:%M:%S'" as string) ¬
        & " " & themessage
        do shell script "echo " & theLine & ¬
        " >> ~/Library/Logs/HotBoxHelper.log"
    end log_event
	
end script