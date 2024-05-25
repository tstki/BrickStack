object DlgViewExternal: TDlgViewExternal
  Left = 0
  Top = 0
  Caption = 'Open external'
  ClientHeight = 153
  ClientWidth = 429
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  DesignSize = (
    429
    153)
  TextHeight = 15
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 356
    Height = 15
    Caption = 
      'Select where you want to view online details of the selected set' +
      '/part'
  end
  object LblSetOrPartCap: TLabel
    Left = 24
    Top = 37
    Width = 42
    Height = 15
    Caption = 'Set/part'
  end
  object Label3: TLabel
    Left = 24
    Top = 61
    Width = 42
    Height = 15
    Caption = 'View on'
  end
  object LblSetOfPartNumber: TLabel
    Left = 72
    Top = 37
    Width = 83
    Height = 15
    Caption = 'set/partnumber'
  end
  object BtnOK: TButton
    Left = 261
    Top = 120
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
    OnClick = BtnOKClick
    ExplicitLeft = 257
    ExplicitTop = 119
  end
  object BtnCancel: TButton
    Left = 342
    Top = 120
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
    ExplicitLeft = 338
    ExplicitTop = 119
  end
  object CbxOpenType: TComboBox
    Left = 72
    Top = 58
    Width = 169
    Height = 23
    Style = csDropDownList
    TabOrder = 2
  end
  object ChkOpenWhereNewDefault: TCheckBox
    Left = 72
    Top = 87
    Width = 321
    Height = 17
    Caption = 'Make default (you can change this in the settings later)'
    TabOrder = 3
  end
end
