unit UDragData;

interface

uses
  System.Generics.Collections;

var
  DraggedBSSetIDs: TList<Integer> = nil; // may be empty or nil
  DraggedSetNums: TList<string> = nil;   // set numbers when BSSetID not available

procedure ClearDragData;

implementation

procedure ClearDragData;
begin
  if Assigned(DraggedBSSetIDs) then
    DraggedBSSetIDs.Clear;
  if Assigned(DraggedSetNums) then
    DraggedSetNums.Clear;
end;

initialization
  DraggedBSSetIDs := TList<Integer>.Create;
  DraggedSetNums := TList<string>.Create;

finalization
  DraggedBSSetIDs.Free;
  DraggedSetNums.Free;

end.
