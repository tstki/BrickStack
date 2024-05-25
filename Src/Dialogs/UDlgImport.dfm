object DlgImport: TDlgImport
  Left = 0
  Top = 0
  Caption = 'DlgImport'
  ClientHeight = 118
  ClientWidth = 286
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object Label1: TLabel
    Left = 8
    Top = 11
    Width = 65
    Height = 15
    Caption = 'Import from'
  end
  object Label2: TLabel
    Left = 8
    Top = 40
    Width = 88
    Height = 15
    Caption = 'Local collections'
  end
  object CbxImportOptions: TComboBox
    Left = 112
    Top = 8
    Width = 169
    Height = 23
    Style = csDropDownList
    TabOrder = 0
  end
  object CbxImportLocalOptions: TComboBox
    Left = 112
    Top = 37
    Width = 169
    Height = 23
    Style = csDropDownList
    TabOrder = 1
  end
  object BtnCancel: TButton
    Left = 206
    Top = 85
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
  object BtnOK: TButton
    Left = 125
    Top = 85
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
    OnClick = BtnOKClick
  end
end
