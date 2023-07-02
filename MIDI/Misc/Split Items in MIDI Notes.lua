-- @version 0.1
-- @author Daniel Lumertz
-- @provides
--    [nomain] Functions/*.lua
-- @changelog
--    + release

-------------------------------
-------   User Settings -------
-------------------------------

local copy_only_notes = false -- if true wont copy CC, aftertouch etc...
local trim_at_item_edge = true -- if true will trim the notes at the item edges


-------------------------------
-------     LOAD     ----------
-------------------------------
--dofile("C:/Users/DSL/AppData/Roaming/REAPER/Scripts/Meus/Debug VS/DL Debug.lua")

function dofile_all(path)
    local i = 0
    while true do 
        local file = reaper.EnumerateFiles( path, i )
        i = i + 1
        if not file  then break end 
        dofile(path..'/'..file)
    end
end

local info = debug.getinfo(1,'S')
local ScriptPath = info.source:match[[^@?(.*[\/])[^\/]-$]] -- this script folder

local folder_name = 'Functions'

--dofile_all(script_path..'/'..folder_name)
dofile(ScriptPath .. 'Functions/Arrange Functions.lua') -- Functions for using the markov in reaper
dofile(ScriptPath .. 'Functions/General Lua Functions.lua') -- Functions for using the markov in reaper
dofile(ScriptPath .. 'Functions/REAPER Functions.lua') -- Functions for using the markov in reaper
dofile(ScriptPath .. 'Functions/MIDI Functions.lua') -- Functions for using the markov in reaper

-------------------------------
-------   SCRIPT     ----------
-------------------------------

if reaper.CountSelectedMediaItems(proj) == 0 then return end

local proj = 0

reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)

for item in enumSelectedItems(proj) do
    local item_pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local item_len = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
    
    local track = reaper.GetMediaItem_Track(item)
    for take in enumTakes(item) do
        if not reaper.BR_IsTakeMidi(take) then goto continue end
        local take_off = reaper.GetMediaItemTakeInfo_Value( take, 'D_STARTOFFS')
        local rate = reaper.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')
        local new_midi = {}
        local retval, all_midi = reaper.MIDI_GetAllEvts(take)
        for offset, offset_count, flags, msg, stringPos in IterateAllMIDI(all_midi,true) do 
            local msg_type,msg_ch,val1,val2,text = UnpackMIDIMessage(msg)
            if (copy_only_notes) or (msg_type == 8 or msg_type == 9) then -- delete
                InsertPlaceHolder(new_midi,offset,offset_count)
            else -- insert
                TableInsert(new_midi,offset,offset_count,flags,msg)
            end            
        end
        
        for selected, muted, startppqpos, endppqpos, chan, pitch, vel, noteidx in  IterateMIDINotes(take) do
            chan = chan + 1
            local new_start = reaper.MIDI_GetProjTimeFromPPQPos(take, startppqpos)
            local new_fim = reaper.MIDI_GetProjTimeFromPPQPos(take, endppqpos)
            if (new_fim <= item_pos) or (new_start >= (item_pos+item_len)) then goto skip_note end -- skip notes that happen before or after the item

            local copy_new_midi = TableDeepCopy(new_midi)
            local note_on = PackMIDIMessage(9,chan,pitch,vel)
            local note_off = PackMIDIMessage(8,chan,pitch,0)
            local flag = PackFlags(selected, muted)
            InsertMIDIUnsorted(copy_new_midi,startppqpos,note_on,flag)
            InsertMIDIUnsorted(copy_new_midi,endppqpos,note_off,flag)
            
            local new_item = reaper.CreateNewMIDIItemInProj(track, item_pos, item_len)
            local new_take = reaper.GetActiveTake(new_item)

            local new_table = PackPackedMIDITable(copy_new_midi)
            reaper.MIDI_SetAllEvts(new_take, new_table)
            reaper.MIDI_Sort(new_take)
            
            if trim_at_item_edge then -- trim start and end
                new_start = math.max(new_start,item_pos)
                new_fim = math.min(new_fim,item_pos+item_len)
            end
 
            reaper.SetMediaItemTakeInfo_Value( new_take, 'D_PLAYRATE', rate )
            reaper.SetMediaItemTakeInfo_Value( new_take, 'D_STARTOFFS', take_off + ((new_start-item_pos)*rate))

            reaper.SetMediaItemInfo_Value(new_item, 'D_POSITION', new_start)
            reaper.SetMediaItemInfo_Value(new_item, 'D_LENGTH', (new_fim - new_start))

            ::skip_note::
        end
        ::continue::
    end
end

reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.UpdateTimeline()
reaper.Undo_EndBlock2(proj, 'Split Items in MIDI Notes', -1)