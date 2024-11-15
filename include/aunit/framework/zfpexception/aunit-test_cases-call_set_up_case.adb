------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                      A U N I T . T E S T _ C A S E S                     --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                                                                          --
--                       Copyright (C) 2000-2019, AdaCore                   --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNAT is maintained by AdaCore (http://www.adacore.com)                   --
--                                                                          --
------------------------------------------------------------------------------

with AUnit.Last_Chance_Handler; use AUnit.Last_Chance_Handler;
with AUnit.Memory.Utils;        use AUnit.Memory.Utils;

separate (AUnit.Test_Cases)
function Call_Set_Up_Case
  (Test : in out Test_Case'Class) return Test_Error_Access is
   function Alloc_Error is new Gen_Alloc (Test_Error, Test_Error_Access);

   procedure Internal_Set_Up_Case;

   procedure Internal_Set_Up_Case is
   begin
      Set_Up_Case (Test);
   end Internal_Set_Up_Case;

   function Internal_Setjmp is new Gen_Setjmp (Internal_Set_Up_Case);

   Error : Test_Error_Access := null;
begin
   if Internal_Setjmp /= 0 then
      Error := Alloc_Error;
      Error.Exception_Name    := Get_Exception_Name;
      Error.Exception_Message := Get_Exception_Message;
      Error.Traceback         := null;
   end if;
   return Error;
end Call_Set_Up_Case;
