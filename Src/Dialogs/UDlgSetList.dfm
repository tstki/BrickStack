object DlgSetList: TDlgSetList
  Left = 0
  Top = 0
  Caption = 'DlgSetList'
  ClientHeight = 207
  ClientWidth = 374
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  TextHeight = 15
  object LblName: TLabel
    Left = 8
    Top = 11
    Width = 32
    Height = 15
    Caption = 'Name'
  end
  object LblDescription: TLabel
    Left = 8
    Top = 40
    Width = 60
    Height = 15
    Caption = 'Description'
  end
  object EditName: TEdit
    Left = 80
    Top = 8
    Width = 273
    Height = 23
    TabOrder = 0
  end
  object MemoDescription: TMemo
    Left = 80
    Top = 37
    Width = 273
    Height = 89
    TabOrder = 1
  end
  object ChkUseInBuildCalc: TCheckBox
    Left = 80
    Top = 132
    Width = 225
    Height = 17
    Caption = 'Use these Sets in Build calculations?'
    TabOrder = 2
  end
  object BtnCancel: TButton
    Left = 291
    Top = 172
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
    OnClick = BtnCancelClick
  end
  object BtnOK: TButton
    Left = 210
    Top = 172
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 3
    OnClick = BtnOKClick
  end
end
