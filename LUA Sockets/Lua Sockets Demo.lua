-- @version 1.1.2
-- @author Daniel Lumertz, Mavriq
-- @provides
--    [main] Receive Sockets Demo.lua
--    [main] Send Sockets Demo.lua
--    [main] Test with Luasocket functions.lua
--    [nomain] socket module/socket/core.dll
--    [nomain] socket module/socket/core.so
--    [nomain] socket module/*.lua
-- @changelog
--    + Initial Release


-- This is just a file for Reapack
-- In this exemple I am downloading the files for all OS. 
-- It is also possible to use like Mavriq and download just the needed .dll or .so (dll windows so for mac/linux)
--   [win64] /Various/Mavriq-Lua-Sockets/socket/core.dll
--   [darwin64] /Various/Mavriq-Lua-Sockets/socket/core.so
--   [linux64] /Various/Mavriq-Lua-Sockets/socket/core.so.linux > socket/core.so
-- The only reason I think in this case is best to download all is that some users use more than one OS and transfer All Script files between Machines