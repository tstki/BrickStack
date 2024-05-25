object DlgConfig: TDlgConfig
  Left = 0
  Top = 0
  Caption = 'Options'
  ClientHeight = 151
  ClientWidth = 557
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnShow = FormShow
  DesignSize = (
    557
    151)
  TextHeight = 15
  object LblRebrickableAPIKey: TLabel
    Left = 8
    Top = 11
    Width = 39
    Height = 15
    Caption = 'API key'
  end
  object LblRebrickableBaseUrl: TLabel
    Left = 8
    Top = 40
    Width = 42
    Height = 15
    Caption = 'Base Url'
  end
  object LblLocalImageCachePath: TLabel
    Left = 8
    Top = 69
    Width = 62
    Height = 15
    Caption = 'Local cache'
  end
  object BtnCancel: TButton
    Left = 474
    Top = 119
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 0
    ExplicitLeft = 346
    ExplicitTop = 167
  end
  object BtnOK: TButton
    Left = 393
    Top = 118
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
    OnClick = BtnOKClick
    ExplicitLeft = 265
    ExplicitTop = 166
  end
  object EditRebrickableAPIKey: TEdit
    Left = 80
    Top = 8
    Width = 388
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 2
    ExplicitWidth = 233
  end
  object EditRebrickableBaseUrl: TEdit
    Left = 80
    Top = 37
    Width = 388
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 3
    ExplicitWidth = 233
  end
  object BtnRebrickableAPIInfo: TButton
    Left = 474
    Top = 8
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Info'
    TabOrder = 4
    OnClick = BtnRebrickableAPIInfoClick
    ExplicitLeft = 346
  end
  object TreeView1: TTreeView
    Left = 8
    Top = 120
    Width = 147
    Height = 68
    Indent = 19
    TabOrder = 5
  end
  object EditLocalImageCachePath: TEdit
    Left = 80
    Top = 66
    Width = 388
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 6
    ExplicitWidth = 233
  end
  object BtnSelectLocalImageCachePath: TButton
    Left = 474
    Top = 66
    Width = 75
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Select'
    TabOrder = 7
    OnClick = BtnSelectLocalImageCachePathClick
    ExplicitLeft = 346
  end
end
