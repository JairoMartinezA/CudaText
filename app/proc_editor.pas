(*
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.

Copyright (c) Alexey Torgashin
*)
unit proc_editor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  ATSynEdit,
  ATSynEdit_CanvasProc,
  ATSynEdit_Carets,
  ATStringProc,
  proc_globdata,
  proc_colors;

type
  TAppBookmarkOp = (bmOpClear, bmOpSet, bmOpToggle);

procedure EditorBmSet(ed: TATSynEdit; ALine, ABmKind: integer; AOp: TAppBookmarkOp);
procedure EditorBmInvertAll(ed: TATSynEdit);
procedure EditorBmClearAll(ed: TATSynEdit);
procedure EditorBmGotoNext(ed: TATSyNEdit; ANext: boolean);

procedure EditorApplyOps(Ed: TATSynEdit; const Op: TEditorOps);
function EditorSortSel(ed: TATSynEdit; Asc, ANocase: boolean; out ACount: integer): boolean;

type
  TEdSelType = (selNo, selSmall, selStream, selCol, selCarets);
function EditorGetStatusType(ed: TATSynEdit): TEdSelType;
function EditorFormatStatus(ed: TATSynEdit; const str: string): string;
procedure EditorApplyTheme(Ed: TATSynedit);

implementation

procedure EditorBmSet(ed: TATSynEdit; ALine, ABmKind: integer; AOp: TAppBookmarkOp);
var
  i: integer;
begin
  i:= ALine;
  if i<0 then
    i:= ed.Carets[0].PosY;

  case AOp of
    bmOpSet:
      ed.Strings.LinesBm[i]:= ABmKind;
    bmOpClear:
      ed.Strings.LinesBm[i]:= 0;
    bmOpToggle:
      begin
        if ed.Strings.LinesBm[i]=0 then
          ed.Strings.LinesBm[i]:= ABmKind
        else
          ed.Strings.LinesBm[i]:= 0;
      end;
  end;

  ed.Update;
end;

procedure EditorBmInvertAll(ed: TATSynEdit);
var
  i: integer;
begin
  for i:= 0 to ed.Strings.Count-1 do
  begin
    if ed.Strings.LinesBm[i]=0 then
      ed.Strings.LinesBm[i]:= 1
    else
      ed.Strings.LinesBm[i]:= 0;
  end;
  ed.Update;
end;

procedure EditorBmClearAll(ed: TATSynEdit);
var
  i: integer;
begin
  for i:= 0 to ed.Strings.Count-1 do
    ed.Strings.LinesBm[i]:= 0;
  ed.Update;
end;

procedure EditorBmGotoNext(ed: TATSyNEdit; ANext: boolean);
var
  n: integer;
begin
  n:= ed.Carets[0].PosY;
  repeat
    if ANext then Inc(n) else Dec(n);
    if not ed.Strings.IsIndexValid(n) then exit;
    if ed.Strings.LinesBm[n]>0 then
    begin
      ed.DoGotoPosEx(Point(0, n));
      exit;
    end;
  until false;
end;

procedure EditorApplyOps(Ed: TATSynEdit; const Op: TEditorOps);
begin
  Ed.Font.Name:= Op.OpFontName;
  Ed.Font.Size:= Op.OpFontSize;

  Ed.OptCharSpacingX:= Op.OpSpaceX;
  Ed.OptCharSpacingY:= Op.OpSpaceY;

  Ed.OptTabSize:= Op.OpTabSize;
  Ed.OptTabSpaces:= Op.OpTabSpaces;

  Ed.OptOverwriteSel:= Op.OpOvrSel;
  Ed.OptOverwriteAllowedOnPaste:= Op.OpOvrOnPaste;

  Ed.OptGutterVisible:= Op.OpGutterShow;
  Ed.OptGutterShowFoldAlways:= Op.OpGutterFoldAlways;
  Ed.Gutter[Ed.GutterBandBm].Visible:= Op.OpGutterBookmk;
  Ed.Gutter[Ed.GutterBandFold].Visible:= Op.OpGutterFold;
  Ed.Gutter[Ed.GutterBandNum].Visible:= Op.OpNumbersShow;
  Ed.Gutter.Update;

  Ed.OptNumbersFontSize:= Op.OpNumbersFontSize;
  if Op.OpNumbersStyle<=Ord(High(TATSynNumbersStyle)) then
    Ed.OptNumbersStyle:= TATSynNumbersStyle(Op.OpNumbersStyle);
  Ed.OptNumbersShowCarets:= Op.OpNumbersForCarets;
  if Op.OpNumbersCenter then
    Ed.OptNumbersAlignment:= taCenter
  else
    Ed.OptNumbersAlignment:= taRightJustify;

  Ed.OptRulerVisible:= Op.OpRulerShow;
  Ed.OptRulerFontSize:= Op.OpRulerFontSize;
  Ed.OptRulerSize:= Op.OpRulerSize;
  Ed.OptRulerTextIndent:= Op.OpRulerTextIndent;

  Ed.OptMinimapVisible:= Op.OpMinimapShow;
  Ed.OptMinimapShowSelAlways:= Op.OpMinimapShowSelAlways;
  Ed.OptMinimapShowSelBorder:= Op.OpMinimapShowSelBorder;
  Ed.OptMinimapCharWidth:= Op.OpMinimapCharWidth;

  Ed.OptMarginRight:= Op.OpMargin;
  Ed.OptMarginString:= Op.OpMarginString;

  Ed.OptUnprintedVisible:= Op.OpUnprintedShow;
  Ed.OptUnprintedSpaces:= Op.OpUnprintedSpaces;
  Ed.OptUnprintedEnds:= Op.OpUnprintedEnds;
  Ed.OptUnprintedEndsDetails:= Op.OpUnprintedEndDetails;
  Ed.OptUnprintedReplaceSpec:= Op.OpUnprintedReplaceSpec;

  OptUnprintedEndArrowOrDot:= Op.OpUnprintedEndArrow;
  OptUnprintedTabCharLength:= Op.OpUnprintedTabArrowLen;
  OptUnprintedSpaceDotScale:= Op.OpUnprintedSpaceDotScale;
  OptUnprintedEndDotScale:= Op.OpUnprintedEndDotScale;
  OptUnprintedEndFontScale:= Op.OpUnprintedEndFontScale;
  OptUnprintedTabPointerScale:= Op.OpUnprintedTabPointerScale;

  if Op.OpWrapMode<=Ord(High(TATSynWrapMode)) then
    Ed.OptWrapMode:= TATSynWrapMode(Op.OpWrapMode);
  Ed.OptWrapIndented:= Op.OpWrapIndented;

  Ed.OptUndoLimit:= Op.OpUndoLimit;
  Ed.OptUndoGrouped:= Op.OpUndoGrouped;
  Ed.OptUndoAfterSave:= Op.OpUndoAfterSave;

  Ed.OptCaretBlinkTime:= Op.OpCaretBlinkTime;
  Ed.OptCaretBlinkEnabled:= Op.OpCaretBlinkEn;

  if Op.OpCaretShapeNorm<=Ord(High(TATSynCaretShape)) then
    Ed.OptCaretShape:= TATSynCaretShape(Op.OpCaretShapeNorm);
  if Op.OpCaretShapeOvr<=Ord(High(TATSynCaretShape)) then
    Ed.OptCaretShapeOvr:= TATSynCaretShape(Op.OpCaretShapeOvr);
  if Op.OpCaretShapeRO<=Ord(High(TATSynCaretShape)) then
    Ed.OptCaretShapeRO:= TATSynCaretShape(Op.OpCaretShapeRO);

  Ed.OptCaretVirtual:= Op.OpCaretVirtual;
  Ed.OptCaretManyAllowed:= Op.OpCaretMulti;

  Ed.OptShowCurLine:= Op.OpShowCurLine;
  Ed.OptShowCurLineMinimal:= Op.OpShowCurLineMin;
  Ed.OptShowCurColumn:= Op.OpShowCurCol;
  Ed.OptLastLineOnTop:= Op.OpShowLastLineOnTop;
  Ed.OptShowFullSel:= Op.OpShowSelectBgFull;
  Ed.OptShowFullHilite:= Op.OpShowSyntaxBgFull;
  Ed.OptCopyLinesIfNoSel:= Op.OpCopyLineIfNoSel;
  Ed.OptCutLinesIfNoSel:= Op.OpCutLineIfNoSel;
  Ed.OptSavingTrimSpaces:= Op.OpSavingTrimSpaces;
  Ed.OptSavingForceFinalEol:= Op.OpSavingForceFinalEol;
  Ed.OptShowScrollHint:= Op.OpShowHintOnVertScroll;
  Ed.OptWordChars:= Op.OpWordChars;
  OptHexCharsUser:= Op.OpHexChars;

  Ed.OptAutoIndent:= Op.OpIndentAuto;
  if Op.OpIndentAutoKind<=Ord(High(TATAutoIndentKind)) then
    Ed.OptAutoIndentKind:= TATAutoIndentKind(Op.OpIndentAutoKind);
  Ed.OptIndentSize:= Op.OpIndentSize;
  Ed.OptIndentKeepsAlign:= Op.OpUnIndentKeepsAlign;

  Ed.OptMouse2ClickDragSelectsWords:= Op.OpMouse2ClickDragSelectsWords;
  Ed.OptMouseDragDrop:= Op.OpMouseDragDrop;
  Ed.OptMouseNiceScroll:= Op.OpMouseNiceScroll;
  Ed.OptMouseRightClickMovesCaret:= Op.OpMouseRightClickMovesCaret;
  Ed.OptMouseEnableColumnSelection:= Op.OpMouseEnableColumnSelection;
  Ed.OptMouseHideCursorOnType:= Op.OpMouseHideCursorOnType;
  Ed.OptMouseGutterClickSelectsLine:= Op.OpMouseGutterClickSelectedLine;

  Ed.OptKeyBackspaceUnindent:= Op.OpKeyBackspaceUnindent;
  Ed.OptKeyTabIndents:= Op.OpKeyTabIndents;
  Ed.OptKeyHomeToNonSpace:= Op.OpKeyHomeToNonSpace;
  Ed.OptKeyHomeEndNavigateWrapped:= Op.OpKeyHomeEndNavigateWrapped;
  Ed.OptKeyEndToNonSpace:= Op.OpKeyEndToNonSpace;
  Ed.OptKeyPageKeepsRelativePos:= Op.OpKeyPageKeepsRelativePos;
  if Op.OpKeyPageUpDownSize<=Ord(High(TATPageUpDownSize)) then
    Ed.OptKeyPageUpDownSize:= TATPageUpDownSize(Op.OpKeyPageUpDownSize);
  Ed.OptKeyUpDownKeepColumn:= Op.OpKeyUpDownKeepColumn;
  Ed.OptKeyUpDownNavigateWrapped:= Op.OpKeyUpDownNavigateWrapped;
  Ed.OptKeyLeftRightSwapSel:= Op.OpKeyLeftRightSwapSel;
  Ed.OptKeyLeftRightSwapSelAndSelect:= Op.OpKeyLeftRightSwapSelAndSelect;
end;

function SortComp(List: TStringList; Index1, Index2: Integer): Integer;
var
  s1, s2: atString;
begin
  s1:= utf8decode(List[Index1]);
  s2:= utf8decode(List[Index2]);
  Result:= UnicodeCompareStr(s1, s2);
end;

function SortCompDesc(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result:= -SortComp(List, Index1, Index2);
end;

function SortCompNocase(List: TStringList; Index1, Index2: Integer): Integer;
var
  s1, s2: atString;
begin
  s1:= utf8decode(List[Index1]);
  s2:= utf8decode(List[Index2]);
  Result:= UnicodeCompareText(s1, s2);
end;

function SortCompNocaseDesc(List: TStringList; Index1, Index2: Integer): Integer;
begin
  Result:= -SortCompNocase(List, Index1, Index2);
end;


function EditorSortSel(ed: TATSynEdit; Asc, ANocase: boolean; out
  ACount: integer): boolean;
var
  y1, y2: integer;
  i: integer;
  Str: atString;
  caret: TATcaretitem;
  list: TStringlist;
begin
  ACount:= 0;
  caret:= ed.Carets[0];
  caret.GetSelLines(y1, y2);
  if y1=y2 then
    exit(false);

  list:= TStringlist.create;
  list.Duplicates:= dupAccept;
  try
    for i:= y1 to y2 do
    begin
      str:= ed.Strings.Lines[i];
      if Trim(str)<>'' then
        list.Add(utf8encode(str));
    end;

    if not ANocase then
    begin
      if Asc then
        list.CustomSort(@SortComp)
      else
        list.CustomSort(@SortCompDesc);
    end
    else
    begin
      if Asc then
        list.CustomSort(@SortCompNocase)
      else
        list.CustomSort(@SortCompNocaseDesc);
    end;

    for i:= y2 downto y1 do
      ed.Strings.LineDelete(i);

    for i:= list.Count-1 downto 0 do
    begin
      str:= utf8decode(list[i]);
      ed.Strings.LineInsert(y1, str);
    end;

    ACount:= list.Count;
    Result:= true;
  finally
    list.free;
  end;
end;

function EditorGetSelLines(ed: TATSynEdit): integer;
var
  n1, n2, i: integer;
begin
  result:= 0;

  if not ed.IsSelRectEmpty then
  begin
    result:= ed.SelRect.Bottom-ed.SelRect.Top+1;
    exit
  end;

  for i:= 0 to ed.carets.count-1 do
  begin
    ed.carets[i].GetSelLines(n1, n2);
    if n1<0 then Continue;
    inc(result, n2-n1+1);
  end;
end;

function EditorFormatStatus(ed: TATSynEdit; const str: string): string;
var
  caret: TATCaretItem;
begin
  result:= '';
  if ed.Carets.Count=0 then exit;
  caret:= ed.Carets[0];

  result:= str;
  result:= stringreplace(result, '{x}', inttostr(caret.PosX+1), []);
  result:= stringreplace(result, '{y}', inttostr(caret.PosY+1), []);
  result:= stringreplace(result, '{count}', inttostr(ed.strings.count), []);
  result:= stringreplace(result, '{carets}', inttostr(ed.carets.count), []);
  result:= stringreplace(result, '{cols}', inttostr(ed.SelRect.Right-ed.SelRect.Left), []);
  if pos('{sel}', result)>0 then
    result:= stringreplace(result, '{sel}', inttostr(EditorGetSelLines(ed)), []);
end;

function EditorGetStatusType(ed: TATSynEdit): TEdSelType;
var
  NFrom, NTo: integer;
begin
  if not Ed.IsSelRectEmpty then
    result:= selCol
  else
  if Ed.Carets.Count>1 then
    result:= selCarets
  else
  if Ed.Carets.IsSelection then
  begin
    Ed.Carets[0].GetSelLines(NFrom, NTo);
    if NTo>NFrom then
      result:= selStream
    else
      result:= selSmall;
  end
  else
    result:= selNo;
end;


procedure EditorApplyTheme(Ed: TATSynedit);
begin
  Ed.Colors.TextFont:= GetAppColor('EdTextFont');
  Ed.Colors.TextBG:= GetAppColor('EdTextBg');
  Ed.Colors.TextSelFont:= GetAppColor('EdSelFont');
  Ed.Colors.TextSelBG:= GetAppColor('EdSelBg');

  Ed.Colors.TextDisabledFont:= GetAppColor('EdDisableFont');
  Ed.Colors.TextDisabledBG:= GetAppColor('EdDisableBg');
  Ed.Colors.Caret:= GetAppColor('EdCaret');
  Ed.Colors.CurrentLineBG:= GetAppColor('EdCurLineBg');
  Ed.Colors.IndentVertLines:= GetAppColor('EdIndentVLine');
  Ed.Colors.UnprintedFont:= GetAppColor('EdUnprintFont');
  Ed.Colors.UnprintedBG:= GetAppColor('EdUnprintBg');
  Ed.Colors.UnprintedHexFont:= GetAppColor('EdUnprintHexFont');
  Ed.Colors.MinimapBorder:= GetAppColor('EdMinimapBorder');
  Ed.Colors.MinimapSelBG:= GetAppColor('EdMinimapSelBg');
  Ed.Colors.StateChanged:= GetAppColor('EdStateChanged');
  Ed.Colors.StateAdded:= GetAppColor('EdStateAdded');
  Ed.Colors.StateSaved:= GetAppColor('EdStateSaved');
  Ed.Colors.BlockStaple:= GetAppColor('EdBlockStaple');
  Ed.Colors.BlockSepLine:= GetAppColor('EdBlockSepLine');
  Ed.Colors.LockedBG:= GetAppColor('EdLockedBg');
  Ed.Colors.ComboboxArrow:= GetAppColor('EdComboArrow');
  Ed.Colors.ComboboxArrowBG:= GetAppColor('EdComboArrowBg');
  Ed.Colors.CollapseLine:= GetAppColor('EdFoldMarkLine');
  Ed.Colors.CollapseMarkFont:= GetAppColor('EdFoldMarkFont');
  Ed.Colors.CollapseMarkBG:= GetAppColor('EdFoldMarkBg');

  Ed.Colors.GutterFont:= GetAppColor('EdGutterFont');
  Ed.Colors.GutterBG:= GetAppColor('EdGutterBg');
  Ed.Colors.GutterCaretBG:= GetAppColor('EdGutterCaretBg');

  Ed.Colors.BookmarkBG:= GetAppColor('EdBookmarkBg');
  Ed.Colors.RulerFont:= GetAppColor('EdRulerFont');
  Ed.Colors.RulerBG:= GetAppColor('EdRulerBg');

  Ed.Colors.GutterFoldLine:= GetAppColor('EdFoldLine');
  Ed.Colors.GutterFoldBG:= GetAppColor('EdFoldBg');
  Ed.Colors.GutterPlusBorder:= GetAppColor('EdFoldPlusLine');
  Ed.Colors.GutterPlusBG:= GetAppColor('EdFoldPlusBg');

  Ed.Colors.MarginRight:= GetAppColor('EdMarginFixed');
  Ed.Colors.MarginCaret:= GetAppColor('EdMarginCaret');
  Ed.Colors.MarginUser:= GetAppColor('EdMarginUser');
end;


end.

