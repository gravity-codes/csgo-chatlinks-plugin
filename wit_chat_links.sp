/*
   - v1.0.1 This first version uses commands to pass information
   - Using a menu to pass links
*/

#include <sourcemod>
#include <multicolors>

#define VERSION "1.0.1"
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
   RegConsoleCmd("sm_links", PrintLinks);

   verifyFilePath();
}

public void OnMapStart()
{
   if(!verifyFilePath())
   {
      return;
   }

   char line[256];
   while(!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line)))
   {
      if(line[0] == '/' && line[1] == '/')
      {
         continue;
      }

      char words[3][124];
      if(ExplodeString(line, "\t", words, sizeof(words), sizeof(words[]), false) == 3)
      {
         char command[124];
         strcopy(command, sizeof(command), words[0]);
         char link[124];
         strcopy(link, sizeof(link), words[1]);
         char description[124];
         strcopy(description, sizeof(description), words[2]);

         StripQuotes(command);
         StripQuotes(link);
         StripQuotes(description);

         if(!CommandExists(command))
         {
            RegConsoleCmd(command, LinkHandler, description);
            PrintToServer("[WiT] Gaming Links: Command: %s, that links to: %s, with the description: %s, was added successfully.", command, link, description);
         }
         else
         {
            PrintToServer("[WiT] Gaming Links: Command: %s, that links to: %s, with the description: %s, already exists.", command, link, description);
         }
      }
   }

   CloseHandle(file);
}

public Action LinkHandler(int client, int args)
{
   if(!verifyFilePath())
   {
      return Plugin_Stop;
   }

   char cmdname[12];
   GetCmdArg(0, cmdname, sizeof(cmdname));

   char line[256];
   while(!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line)))
   {
      if(line[0] == '/' && line[1] == '/')
      {
         continue;
      }

      char words[3][124];
      if(ExplodeString(line, "\t", words, sizeof(words), sizeof(words[]), false) == 3)
      {
         char command[124];
         strcopy(command, sizeof(command), words[0]);
         char link[124];
         strcopy(link, sizeof(link), words[1]);
         char description[124];
         strcopy(description, sizeof(description), words[2]);

         StripQuotes(command);
         StripQuotes(link);
         StripQuotes(description);

         if(StrEqual(command, cmdname, false))
         {
            CReplyToCommand(client, "{orchid}[WiT] Gaming Links: {default}%s - {olvie}Copy and paste link into a browser.", link);
            return Plugin_Handled;
         }
      }
   }

   CloseHandle(file);
   return Plugin_Continue;
}

public Action PrintLinks(int client, int args)
{
   if(!verifyFilePath())
   {
      return Plugin_Stop;
   }

   char output[126] = {"{orchid}[WiT] Gaming Links: {default}"};

   char line[256];
   while(!IsEndOfFile(file) && ReadFileLine(file, line, sizeof(line)))
   {
      if(line[0] == '/' && line[1] == '/')
      {
         continue;
      }

      char words[3][124];
      if(ExplodeString(line, "\t", words, sizeof(words), sizeof(words[]), false) == 3)
      {
         char command[124];
         strcopy(command, sizeof(command), words[0]);
         char link[124];
         strcopy(link, sizeof(link), words[1]);
         char description[124];
         strcopy(description, sizeof(description), words[2]);

         StripQuotes(command);
         StripQuotes(link);
         StripQuotes(description);

         char temp[sizeof(command) + 3];
         Format(temp, sizeof(temp), "!%s, ", command);

         if((strlen(output) + strlen(temp)) > 126)
         {
            CReplyToCommand(client, "%s", output);
            strcopy(output, sizeof(output), temp);
         }
         else
         {
            StrCat(output, sizeof(output), temp);
         }
      }
   }

   CReplyToCommand(client, "%s", output);
   CloseHandle(file);
   return Plugin_Handled;
}

public bool verifyFilePath()
{
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
