object DlgSetList: TDlgSetList
  Left = 0
  Top = 0
  Caption = 'DlgSetList'
  ClientHeight = 254
  ClientWidth = 381
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnShow = FormShow
  DesignSize = (
    381
    254)
  TextHeight = 15
  object LblName: TLabel
    Left = 8
    Top = 72
    Width = 32
    Height = 15
    Caption = 'Name'
  end
  object LblDescription: TLabel
    Left = 8
    Top = 101
    Width = 60
    Height = 15
    Caption = 'Description'
  end
  object Label1: TLabel
    Left = 8
    Top = 40
    Width = 56
    Height = 15
    Caption = 'External ID'
    Enabled = False
  end
  object Label2: TLabel
    Left = 232
    Top = 40
    Width = 68
    Height = 15
    Caption = 'External type'
    Enabled = False
  end
  object Label3: TLabel
    Left = 232
    Top = 11
    Width = 41
    Height = 15
    Caption = 'Sort tag'
  end
  object Image1: TImage
    Left = 80
    Top = 216
    Width = 43
    Height = 31
  end
  object Label4: TLabel
    Left = 8
    Top = 226
    Width = 33
    Height = 15
    Caption = 'Image'
  end
  object LblID: TLabel
    Left = 8
    Top = 11
    Width = 11
    Height = 15
    Caption = 'ID'
    Enabled = False
  end
  object EditName: TEdit
    Left = 80
    Top = 69
    Width = 289
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 4
    OnChange = OnChange
    ExplicitWidth = 297
  end
  object MemoDescription: TMemo
    Left = 80
    Top = 98
    Width = 289
    Height = 89
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 5
    ExplicitWidth = 297
  end
  object ChkUseInBuildCalc: TCheckBox
    Left = 80
    Top = 193
    Width = 225
    Height = 17
    Caption = 'Use these Sets in Build calculations?'
    TabOrder = 6
  end
  object BtnCancel: TButton
    Left = 294
    Top = 221
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 8
    ExplicitLeft = 291
    ExplicitTop = 177
  end
  object BtnOK: TButton
    Left = 213
    Top = 221
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 7
    OnClick = BtnOKClick
    ExplicitLeft = 210
    ExplicitTop = 177
  end
  object EditExternalID: TEdit
    Left = 80
    Top = 37
    Width = 137
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    ReadOnly = True
    TabOrder = 2
    ExplicitWidth = 145
  end
  object EditExternalType: TEdit
    Left = 306
    Top = 37
    Width = 63
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    ReadOnly = True
    TabOrder = 3
    ExplicitWidth = 71
  end
  object EditSortIndex: TEdit
    Left = 306
    Top = 8
    Width = 63
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 1
    OnChange = OnChange
    ExplicitWidth = 71
  end
  object EditID: TEdit
    Left = 81
    Top = 8
    Width = 137
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    ReadOnly = True
    TabOrder = 0
    ExplicitWidth = 145
  end
end
