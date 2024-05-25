object FrmChild: TFrmChild
  Left = 197
  Top = 117
  Caption = 'MDI Child'
  ClientHeight = 168
  ClientWidth = 270
  Color = clBtnFace
  ParentFont = True
  FormStyle = fsMDIChild
  Position = poDefault
  Visible = True
  OnClose = FormClose
  TextHeight = 15
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 270
    Height = 168
    Margins.Left = 2
    Margins.Top = 2
    Margins.Right = 2
    Margins.Bottom = 2
    Align = alClient
    TabOrder = 0
    WordWrap = False
    ExplicitTop = 40
    ExplicitHeight = 128
  end
end
