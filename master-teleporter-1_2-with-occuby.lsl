vector home;
integer doorChan;
integer dialogChannel;
integer channelSet = FALSE;
integer listening = FALSE;

string OccTexture = "e2700a63-d524-f8d5-f602-fac51239d524";//occupied texture
string nOccTexture = "b4eb80c6-a379-284f-780f-79f6926fd028";//not occupied texture
integer signLink = 0; //link number for the occupy sign

string dialogInfo = "Where do you want to go?";
list teleportNameList = [];
list teleportPositionList = [];
key av_menu;
float tooLong;
float menuTime;
float unSitTime;
integer listenHandle;

unsit_all_avatars()
{
    integer objectPrimCount = llGetObjectPrimCount(llGetKey());
    integer currentLinkNumber = llGetNumberOfPrims();
 
    for (; objectPrimCount < currentLinkNumber; --currentLinkNumber)
        llUnSit(llGetLinkKey(currentLinkNumber));
}

default
{
    state_entry()  
    {
        llOwnerSay("hello avatar from main");
        //"Sit target is a prim property."
        llSitTarget(<0.0, 0.0, 0.1>, ZERO_ROTATION);
        string descInt = llGetObjectDesc();
        if((integer)descInt)
        {
            doorChan = (integer)descInt;
            llListen(doorChan,"","","");
            dialogChannel = -1 - (integer)("0x" + llGetSubString( (string)llGetKey(), -7, -1) );
            channelSet = TRUE;
        }
        else
        {
            llOwnerSay("Description is not an integer, can not set channel, please set a channel number to the description and reset the script.");
        }
        
    }
    listen(integer chan, string name, key id, string msg)
    {
        llOwnerSay(msg);
        if(llGetOwnerKey(id) == llGetOwner())
        {
            llOwnerSay("message hit past llgetownerkey");
            if(msg == "occupied")
            {
                llSetLinkTexture(signLink,OccTexture,ALL_SIDES);        
            }
            if(msg == "not occupied")
            {
                llSetLinkTexture(signLink,nOccTexture,ALL_SIDES);                    
            }
            if(msg == "Teleport From")
            {
                llOwnerSay("teleport from");
                string objectDetails = llGetObjectName() + "/" + (string)llGetPos();
                llRegionSay(doorChan,objectDetails);                    
            }
            if(msg == "Teleport From Child")
            {        
            llOwnerSay("teleport from child");            
                string objectDetails = llGetObjectName() + "/" + (string)llGetPos();
                llRegionSay(doorChan,objectDetails);              
            }
        }
    }
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        { 
            key av_sit = llAvatarOnSitTarget();
            if (av_sit) 
            {
                llOwnerSay("just got sat on");
                home = llGetPos();
                //Someone is on the sit target.
                state sitting;
            }
        }
    }
}
state sitting
{
    state_entry()
    {
        
            llListen(doorChan,"","","");
        llOwnerSay("entering sitting");
        if(!channelSet)
        {
            llOwnerSay("Description channel hasn't been set, please set a channel number in the description and reset the script.");
            return;
        }
        listening = TRUE;
        teleportNameList = llDeleteSubList(teleportNameList, 0, llGetListLength(teleportNameList));
        teleportPositionList = llDeleteSubList(teleportPositionList, 0, llGetListLength(teleportPositionList));
        
        llRegionSay(doorChan,"Teleport From");
        llOwnerSay("regionsay shouted");
        av_menu = llAvatarOnSitTarget();
        
        //llDialog(av_menu, "\nDo you like this example?", ["Yes", "No" ] , -99);
    }
 
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        { 
            key av_unsit = llAvatarOnSitTarget();
            if (av_unsit == NULL_KEY) 
            {
                llSetRegionPos(home);
                //No one is on the sit target.
                //"On state change all listens are removed automatically."
                state default;
            }
        }
    }
 
    listen(integer chan, string name, key id, string msg)
    {
        llOwnerSay("heard while in seated mode");
        if(llGetOwnerKey(id) == llGetOwner())
        {
            if(chan == doorChan)
            {
                    if(listening)
                    {
                        
                        list incoming = llParseStringKeepNulls(msg, ["/"],[""]); 
                        teleportNameList = teleportNameList + llList2String(incoming, 0);
                        teleportPositionList = teleportPositionList + llList2String(incoming, 1);
                        llSay(0,msg);
                        llSay(0, llList2String(incoming, 1) );
                        llSay(0, "teleportNames: " + (string) teleportNameList + " / teleport Positions: " + (string) teleportPositionList);
                        llDumpList2String(incoming, "");
                        tooLong = llGetTime() + 30;
                        unSitTime = llGetTime() + 15;
                        menuTime = llGetTime()+2;
                        
                        llSetTimerEvent(1);
                    }
                
            }
        }
        if( id == av_menu )
        {
            if( chan == dialogChannel )
            {
                integer lenth = llGetListLength(teleportNameList);
                integer l = 0;
                for(l=0; l<lenth; l++)
                {
                    if(msg == llList2String(teleportNameList, l))
                    {
                        llWhisper(0,"found a match");
                        llWhisper(0,"Coordinates: " + llList2String(teleportPositionList, l));
                        llSetRegionPos((vector)llList2String(teleportPositionList,l));
                        
                    }
                }
            }
        }
    }
    timer()
    {
        if(llGetTime()>=menuTime)
        {
            if(llGetTime()<(menuTime+1))
            {
                llDialog(av_menu, dialogInfo, teleportNameList, dialogChannel);
                listenHandle = llListen(dialogChannel,"",av_menu,"");
                llWhisper(0,"Menu should be presented");
            }
        }
        if(llGetTime() >= unSitTime)
        {
            unsit_all_avatars();
        }
        if(llGetTime()>=tooLong)
        {
            llListenRemove(listenHandle);
            llWhisper(0,"Too Much time has passed");
            llSetTimerEvent(0);
        }
    }
}
