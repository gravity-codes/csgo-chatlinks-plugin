/*
   - v2.0.0 Prints a menu to clients to show links in chat
*/

#include <sourcemod>
#include <multicolors>

#define VERSION "2.0.0"
#pragma newdecls required

char filepath[] = {"configs/wit_links.txt"};
Handle file;

public Plugin myinfo =
{
   name = "[WiT] Gaming Chat Links Plugin",
   description = "Plugin that dynamically adds chat commands to print links to clients about relevant [WiT] Gaming information.",
   author = "bazooka",
   version = VERSION,
   url= "https://github.com/bazooka-codes"
};

public void OnPluginStart()
{
   CreateConVar("sm_wit_links_version", VERSION, "Current build of WiT Chat links Plugin.");
   RegConsoleCmd("sm_links", ShowLinkMenu);

   //Timer repeats every 10 minutes
   CreateTimer(600.0, NotifyTimer, _, TIMER_REPEAT);

   verifyFilePath();
}

public void OnMapStart()
{
   verifyFilePath();
}

public Action NotifyTimer(Handle timer)
{
   //Advertise clients can !links
   CPrintToChatAll("{olive}Want to get in touch? {orange}Want more info? {orchid}Type {darkblue}\"!links\" {lightred}in chat to see a menu of relevant links for {lime}[WiT]!");

   return Plugin_Continue;
}

public Action ShowLinkMenu(int client, int args)
{
   if(file == null)
   {
      return Plugin_Stop;
   }

   resetSeek();

   Menu menu = new Menu(LinkMenuHandler, MENU_ACTIONS_ALL);
   menu.SetTitle("Choose Link to Display");

   int counter = 0;
   char line[256];
   while(!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line)))
   {
      //Skip this line if it starts with "//" which is comment
      if(line[0] == '/' && line[1] == '/')
      {
         counter++;
         continue;
      }

      //Split string into two words
      char words[2][124];
      if(ExplodeString(line, "\t", words, sizeof(words), sizeof(words[]), false) == 2)
      {
         //Pull the 2-d array into seperate words
         char command[124];
         strcopy(command, sizeof(command), words[0]);
         char link[124];
         strcopy(link, sizeof(link), words[1]);

         //Make sure strings are formatted correctly
         TrimString(command);
         StripQuotes(command);
         TrimString(link);
         StripQuotes(link);

         //Use line count as the id for selection
         char counterStr[32];
         IntToString(counter, counterStr, sizeof(counterStr));

         //Add the current line to the menu
         menu.AddItem(counterStr, command);
      }

      //Increment line count
      counter++;
   }

   //Display menu to client
   menu.Display(client, MENU_TIME_FOREVER);
   return Plugin_Handled;
}

public int LinkMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
   if(file == null)
   {
      return 0;
   }

   resetSeek();

   //Client "selected" a menu item
   if(action == MenuAction_Select)
   {
      //Client is first parameter of menu selection
      int client = param1;

      //Extract the line number we stored as id from other method
      char lineNumStr[32];
      menu.GetItem(param2, lineNumStr, sizeof(lineNumStr));
      int lineNum = StringToInt(lineNumStr);

      int counter = 0;
      char line[256];
      while(!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line)))
      {
         if(counter != lineNum)
         {
            //This isnt correct line number
            counter++;
            continue;
         }

         if(line[0] == '/' && line[1] == '/')
         {
            counter++;
            continue;
         }

         char words[2][124];
         if(ExplodeString(line, "\t", words, sizeof(words), sizeof(words[]), false) == 2)
         {
            //Split line into seperate strings
            char command[124];
            strcopy(command, sizeof(command), words[0]);
            char link[124];
            strcopy(link, sizeof(link), words[1]);

            //Remove messy characters
            TrimString(command);
            TrimString(link);
            StripQuotes(command);
            StripQuotes(link);

            //Print the link in the client's console and chat
            CReplyToCommand(client, "{orchid}[WiT] Gaming Links: {default}%s - {darkblue}Copy and paste link into a browser.", link);
            PrintToConsole(client, "[WiT] Gaming Links: %s - Copy and paste link into a browser.", link);
            return 0;
         }

         counter++
      }
   }

   return 0;
}

public bool verifyFilePath()
{
   //Create the filepath from local string path
   char path[PLATFORM_MAX_PATH];
   BuildPath(Path_SM, path, sizeof(path), filepath);

   if(FileExists(path, false))
   {
      file = OpenFile(path, "r");

      if(file != null)
      {
         PrintToServer("[WiT] Gaming Links: File successfully located.");
         return true;
      }
      else
      {
         PrintToServer("[WiT] Gaming Links: ERROR - File could not be opened.");
      }
   }
   else
   {
      PrintToServer("[WiT] Gaming Links: ERROR - Unable to find .txt file at path: %s.", filepath);
   }

   return false;
}

public void resetSeek()
{
   if(file == null)
   {
      return;
   }

   //Set the file reader back to the start
   FileSeek(file, 0, SEEK_SET);
}
