object DlgImport: TDlgImport
  Left = 0
  Top = 0
  Caption = 'DlgImport'
  ClientHeight = 117
  ClientWidth = 321
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  DesignSize = (
    321
    117)
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
    Width = 201
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    ExplicitWidth = 209
  end
  object CbxImportLocalOptions: TComboBox
    Left = 112
    Top = 37
    Width = 201
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 1
    ExplicitWidth = 209
  end
  object BtnCancel: TButton
    Left = 238
    Top = 84
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
    ExplicitLeft = 246
  end
  object BtnOK: TButton
    Left = 157
    Top = 84
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
    OnClick = BtnOKClick
    ExplicitLeft = 165
  end
end
