object DlgAddToSetList: TDlgAddToSetList
  Left = 0
  Top = 0
  Caption = 'Add to set list'
  ClientHeight = 211
  ClientWidth = 370
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  DesignSize = (
    370
    211)
  TextHeight = 15
  object Label2: TLabel
    Left = 8
    Top = 11
    Width = 34
    Height = 15
    Caption = 'Set list'
  end
  object Label1: TLabel
    Left = 8
    Top = 40
    Width = 44
    Height = 15
    Caption = 'Amount'
  end
  object Label3: TLabel
    Left = 8
    Top = 92
    Width = 31
    Height = 15
    Caption = 'Notes'
  end
  object LblMaxNote: TLabel
    Left = 113
    Top = 166
    Width = 23
    Height = 15
    Caption = 'Max'
  end
  object CbxSetList: TComboBox
    Left = 113
    Top = 8
    Width = 249
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    OnChange = OnChange
    ExplicitWidth = 245
  end
  object BtnCancel: TButton
    Left = 287
    Top = 178
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 6
    ExplicitLeft = 283
    ExplicitTop = 177
  end
  object BtnOK: TButton
    Left = 206
    Top = 178
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 5
    OnClick = BtnOKClick
    ExplicitLeft = 202
    ExplicitTop = 177
  end
  object EditAmount: TEdit
    Left = 113
    Top = 37
    Width = 75
    Height = 23
    TabOrder = 1
    OnChange = OnChange
  end
  object ChkBuilt: TCheckBox
    Left = 113
    Top = 66
    Width = 56
    Height = 17
    Caption = 'Built'
    TabOrder = 3
  end
  object ChkSpareParts: TCheckBox
    Left = 194
    Top = 66
    Width = 120
    Height = 17
    Caption = 'Have spare parts'
    TabOrder = 2
  end
  object MemoNote: TMemo
    Left = 113
    Top = 89
    Width = 251
    Height = 71
    Anchors = [akLeft, akTop, akRight]
    MaxLength = 256
    TabOrder = 4
    OnChange = MemoNoteChange
    ExplicitWidth = 247
  end
end
