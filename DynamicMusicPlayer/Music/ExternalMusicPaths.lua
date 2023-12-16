-- Specify extra directories for music from anywhere in your filesystem.

-- REMEMBER THAT THESE PATHS MUST USE / AS SEPARATORS INSTEAD OF \ WHICH IS USED BY WINDOWS
-- I take no responsibility for the app breaking down after editing this file.
-- Make sure directories specified here don't contain any unsupported files.
-- Make sure that after each directory you add a , otherwise Lua will crash.
-- If some playlist is filled with stuff from this list, it no longer needs to have any files in the apps music folders, so you can safely delete the screaming placeholders

FoldersList = {
    Waiting = {
        -- "X:/folder/folder/anotherfolder/theresmusicinthisfolder", -- example
    },
    Practice = {
        -- "X:/folder/folder/anotherfolder/theresmusicinthisfolder", -- example
    },
    Qualification = {
        -- "X:/folder/folder/anotherfolder/theresmusicinthisfolder", -- example
    },
    LowIntensity = {
        -- "X:/folder/folder/anotherfolder/theresmusicinthisfolder", -- example
    },
    HighIntensity = {
        -- "X:/folder/folder/anotherfolder/theresmusicinthisfolder", -- example
    },
    Replay = {
        -- "X:/folder/folder/anotherfolder/theresmusicinthisfolder", -- example
    },
    FinishLose = {
        -- "X:/folder/folder/anotherfolder/theresmusicinthisfolder", -- example
    },
    FinishPodium = {
        -- "X:/folder/folder/anotherfolder/theresmusicinthisfolder", -- example
    },
}

return FoldersList