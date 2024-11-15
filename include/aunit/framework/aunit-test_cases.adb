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

with Ada.Unchecked_Conversion;
with AUnit.Options;              use AUnit.Options;
with AUnit.Test_Filters;         use AUnit.Test_Filters;
with AUnit.Time_Measure;

package body AUnit.Test_Cases is

   package body Registration is separate;

   -----------------
   -- Add_Routine --
   -----------------

   procedure Add_Routine (T : in out Test_Case'Class; Val : Routine_Spec) is
   begin
      Routine_Lists.Append (T.Routines, Val);
   end Add_Routine;

   --------------
   -- Run_Test --
   --------------

   procedure Run_Test (Test : in out Test_Case) is
   begin
      Test.Routine.Routine (Test);
   end Run_Test;

   ----------------------
   -- Call_Set_Up_Case --
   ----------------------

   function Call_Set_Up_Case
     (Test : in out Test_Case'Class) return Test_Error_Access;

   function Call_Set_Up_Case
     (Test : in out Test_Case'Class) return Test_Error_Access is separate;

   ---------
   -- Run --
   ---------

   procedure Run
     (Test    : access Test_Case;
      Options :        AUnit.Options.AUnit_Options;
      R       : in out Result'Class;
      Outcome :    out Status)
   is
      use Routine_Lists;
      Result : Status;
      C      : Cursor;
      Set_Up_Case_Called : Boolean := False;
      Error              : Test_Error_Access := null;
   begin
      Outcome := Success;
      Routine_Lists.Clear (Test.Routines);
      Register_Tests (Test_Case'Class (Test.all));

      C := First (Test.Routines);

      while Has_Element (C) loop
         Test.Routine := Element (C);
         if Options.Filter = null
           or else Is_Active (Options.Filter.all, Test.all)
         then
            if not Set_Up_Case_Called then
               Set_Up_Case_Called := True;
               Error := Call_Set_Up_Case (Test_Case'Class (Test.all));
            end if;

            if Error = null then
               AUnit.Simple_Test_Cases.Run
                 (AUnit.Simple_Test_Cases.Test_Case (Test.all)'Access,
                  Options, R, Result);

               if Result = Failure then
                  Outcome := Failure;
               end if;
            else
               Outcome := Failure;
               Add_Error (R, Name (Test_Case'Class (Test.all)),
                          Routine_Name (Test.all), Error.all,
                          Time_Measure.Null_Time);
            end if;
         end if;

         Next (C);
      end loop;

      if Set_Up_Case_Called then
         Tear_Down_Case (Test_Case'Class (Test.all));
      end if;
   end Run;

   ------------------
   -- Routine_Name --
   ------------------

   function Routine_Name (Test : Test_Case) return Message_String is
   begin
      return Test.Routine.Routine_Name;
   end Routine_Name;

   ------------------
   --  Set_Up_Case --
   ------------------

   procedure Set_Up_Case (Test : in out Test_Case) is
      --  Default
      pragma Unreferenced (Test);
   begin
      null;
   end Set_Up_Case;

   --------------------
   -- Tear_Down_Case --
   --------------------

   procedure Tear_Down_Case (Test : in out Test_Case) is
      pragma Unreferenced (Test);
   begin
      null;
   end Tear_Down_Case;

   package body Specific_Test_Case_Registration is

      ----------------------
      -- Register_Wrapper --
      ----------------------

      procedure Register_Wrapper
        (Test    : in out Specific_Test_Case'Class;
         Routine : Specific_Test_Routine;
         Name    : String)
      is
         function Conv is
            new Ada.Unchecked_Conversion (Specific_Test_Routine, Test_Routine);
      begin
         Registration.Register_Routine
           (Test_Case'Class (Test),
            Conv (Routine),
            Name);
      end Register_Wrapper;

   end Specific_Test_Case_Registration;

end AUnit.Test_Cases;
