------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                               Explorer_Pkg                               --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--                            $Revision$
--                                                                          --
--                Copyright (C) 2001 Ada Core Technologies, Inc.            --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 2,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License --
-- for  more details.  You should have  received  a copy of the GNU General --
-- Public License  distributed with GNAT;  see file COPYING.  If not, write --
-- to  the Free Software Foundation,  59 Temple Place - Suite 330,  Boston, --
-- MA 02111-1307, USA.                                                      --
--                                                                          --
-- GNAT is maintained by Ada Core Technologies Inc (http://www.gnat.com).   --
--                                                                          --
------------------------------------------------------------------------------

with Glib; use Glib;
with Gtk; use Gtk;
with Gtk.Widget;      use Gtk.Widget;
with Gtk.Enums;       use Gtk.Enums;
with Callbacks_Aunit_Make_Suite; use Callbacks_Aunit_Make_Suite;
with Aunit_Make_Suite_Intl; use Aunit_Make_Suite_Intl;
with Explorer_Pkg.Callbacks; use Explorer_Pkg.Callbacks;

with GNAT.Directory_Operations; use GNAT.Directory_Operations;
with GNAT.OS_Lib; use GNAT.OS_Lib;
with Ada.Text_IO; use Ada.Text_IO;
with Gtkada.Types; use Gtkada.Types;
with Ada.Characters.Handling; use Ada.Characters.Handling;

package body Explorer_Pkg is
   --  Explorer dialog definition.  Mostly generated by Glade

   procedure Gtk_New (Explorer : out Explorer_Access) is
   begin
      Explorer := new Explorer_Record;
      Explorer_Pkg.Initialize (Explorer);
   end Gtk_New;

   procedure Initialize (Explorer : access Explorer_Record'Class) is
      pragma Suppress (All_Checks);
   begin
      Gtk.Window.Initialize (Explorer, Window_Toplevel);
      Set_Title (Explorer, -"explore");
      Set_Policy (Explorer, False, True, False);
      Set_Position (Explorer, Win_Pos_None);
      Set_Modal (Explorer, False);

      Gtk_New_Vbox (Explorer.Vbox5, False, 0);
      Add (Explorer, Explorer.Vbox5);

      Gtk_New (Explorer.Scrolledwindow3);
      Pack_Start (Explorer.Vbox5, Explorer.Scrolledwindow3, True, True, 0);
      Set_Policy
        (Explorer.Scrolledwindow3, Policy_Automatic, Policy_Automatic);

      Gtk_New (Explorer.Clist, 2);
      C_List_Callback.Connect
        (Explorer.Clist, "select_row", On_Clist_Select_Row'Access);
      Add (Explorer.Scrolledwindow3, Explorer.Clist);
      Set_Selection_Mode (Explorer.Clist, Selection_Extended);
      Set_Shadow_Type (Explorer.Clist, Shadow_In);
      Set_Show_Titles (Explorer.Clist, False);
      Set_Column_Width (Explorer.Clist, 0, 80);
      Set_Column_Width (Explorer.Clist, 1, 80);
      Set_USize (Explorer.Clist, -1, 200);

      Gtk_New (Explorer.Label3, -("label3"));
      Set_Alignment (Explorer.Label3, 0.5, 0.5);
      Set_Padding (Explorer.Label3, 0, 0);
      Set_Justify (Explorer.Label3, Justify_Center);
      Set_Line_Wrap (Explorer.Label3, False);
      Set_Column_Widget (Explorer.Clist, 0, Explorer.Label3);

      Gtk_New (Explorer.Label4, -("label4"));
      Set_Alignment (Explorer.Label4, 0.5, 0.5);
      Set_Padding (Explorer.Label4, 0, 0);
      Set_Justify (Explorer.Label4, Justify_Center);
      Set_Line_Wrap (Explorer.Label4, False);
      Set_Column_Widget (Explorer.Clist, 1, Explorer.Label4);

      Gtk_New (Explorer.Hbuttonbox2);
      Pack_Start (Explorer.Vbox5, Explorer.Hbuttonbox2, False, True, 0);
      Set_Spacing (Explorer.Hbuttonbox2, 30);
      Set_Layout (Explorer.Hbuttonbox2, Buttonbox_Spread);
      Set_Child_Size (Explorer.Hbuttonbox2, 85, 27);
      Set_Child_Ipadding (Explorer.Hbuttonbox2, 7, 0);

      Gtk_New (Explorer.Ok, -"OK");
      Set_Flags (Explorer.Ok, Can_Default);
      Button_Callback.Connect
        (Explorer.Ok, "clicked",
         Button_Callback.To_Marshaller (On_Ok_Clicked'Access));
      Add (Explorer.Hbuttonbox2, Explorer.Ok);

      Gtk_New (Explorer.Close, -"Close");
      Set_Flags (Explorer.Close, Can_Default);
      Button_Callback.Connect
        (Explorer.Close, "clicked",
         Button_Callback.To_Marshaller (On_Close_Clicked'Access));
      Add (Explorer.Hbuttonbox2, Explorer.Close);

   end Initialize;


   ----------
   -- Fill --
   ----------

   procedure Fill
     (Explorer : Explorer_Access)
   is
      --  Display suitable file and directory entries, with annotation of
      --  AUnit file kind (test_suite or test_case)

      Directory    : Dir_Type;
      Buffer       : String (1 .. 256);
      Last         : Natural;
      Dummy        : Gint;

   begin

      GNAT.Directory_Operations.Open (Directory, Explorer.Directory.all);
      Clear (Explorer.Clist);

      loop
         Read (Directory, Buffer, Last);
         exit when Last = 0;
         if Is_Directory
           (Explorer.Directory.all
            & Directory_Separator & Buffer (1 .. Last))
         then
            Insert (Explorer.Clist,
                    -1,
                    Null_Array + Buffer (1 .. Last) + "(dir)");
         else
            if Last > 4
              and then (Buffer (Last - 3 .. Last) = ".ads"
                        or else Buffer (Last - 3 .. Last) = ".adb")
            then
               declare
                  File      : File_Type;
                  Index     : Integer;
                  Index_End : Integer;
                  Line      : String (1 .. 256);
                  Line_Last : Integer;
                  Current_Name : String_Utils.String_Access;
                  Found     : Boolean := False;
                  Row_Num   : Gint;
               begin
                  Ada.Text_IO.Open (File,
                                    In_File,
                                    Explorer.Directory.all
                                    & Directory_Separator
                                    & Buffer (1 .. Last));
                  while not Found loop
                     Get_Line (File, Line, Line_Last);
                     Index_End := 1;
                     Skip_To_String (Line, Index_End, " is");
                     if Index_End < Line_Last - 1 then
                        Index := 1;
                        while Line (Index) = ' ' loop
                           Index := Index + 1;
                        end loop;
                        Skip_To_String (Line, Index, " ");
                        Index_End := Index + 1;
                        while Line (Index_End) = ' ' loop
                           Index_End := Index_End + 1;
                        end loop;
                        Skip_To_String (Line, Index_End, " ");
                        Current_Name :=
                          new String' (Line (Index + 1 .. Index_End - 1));
                        Found := True;
                     end if;
                  end loop;
                  Reset (File);
                  if Buffer (Last - 3 .. Last) = ".ads" then
                     loop
                        Get_Line (File, Line, Line_Last);
                        Index := 1;
                        Skip_To_String (To_Lower (Line), Index, "type");
                        if Index < Line_Last - 4 then
                           Index_End := Index;
                           Skip_To_String
                             (To_Lower (Line), Index_End, "test_case");
                           if Index_End < Line_Last - 9 then
                              Index := 1;
                              Skip_To_String (To_Lower (Line), Index, "type ");
                              Index_End := Index + 5;
                              Skip_To_String
                                (To_Lower (Line), Index_End, " is ");
                              Row_Num :=
                                Append
                                (Explorer.Clist,
                                 Null_Array
                                 + Buffer (1 .. Last)
                                 + ("(test) "
                                    & Line (Index + 5 .. Index_End - 1)));
                              Set (Explorer.Clist,
                                   Row_Num,
                                   Current_Name.all);
                           end if;
                        end if;
                     end loop;
                  else
                     loop
                        Get_Line (File, Line, Line_Last);
                        Index := 1;
                        Skip_To_String (To_Lower (Line), Index, "function");
                        if Index < Line_Last - 8 then
                           Index_End := Index;
                           Skip_To_String
                             (To_Lower (Line), Index_End, "access_test_suite");
                           if Index_End < Line_Last - 15 then
                              Index := 1;
                              Skip_To_String
                                (To_Lower (Line), Index, "function ");
                              Index_End := Index + 9;
                              Skip_To_String
                                (To_Lower (Line), Index_End, " return ");
                              Row_Num :=
                                Append
                                (Explorer.Clist,
                                 Null_Array
                                 + Buffer (1 .. Last)
                                 + ("(suite) "
                                    & Line (Index + 9 .. Index_End - 1)));
                              Set (Explorer.Clist,
                                   Row_Num,
                                   Current_Name.all);
                           end if;
                        end if;
                     end loop;
                  end if;
               exception
                  when End_Error =>
                     Close (File);
                     Free (Current_Name);
               end;
            end if;
         end if;
      end loop;

      Dummy := Columns_Autosize (Explorer.Clist);
   exception
      when Directory_Error =>
         null;

   end Fill;

end Explorer_Pkg;
