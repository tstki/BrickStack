object DlgExport: TDlgExport
  Left = 0
  Top = 0
  Caption = 'Export'
  ClientHeight = 125
  ClientWidth = 327
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnShow = FormShow
  DesignSize = (
    327
    125)
  TextHeight = 15
  object Label1: TLabel
    Left = 8
    Top = 11
    Width = 73
    Height = 15
    Caption = 'Export format'
  end
  object LblRemoteOptions: TLabel
    Left = 8
    Top = 40
    Width = 84
    Height = 15
    Caption = 'Remote options'
  end
  object CbxExportOptions: TComboBox
    Left = 112
    Top = 8
    Width = 207
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    OnChange = CbxExportOptionsChange
    ExplicitWidth = 323
  end
  object BtnOK: TButton
    Left = 163
    Top = 92
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
    OnClick = BtnOKClick
    ExplicitLeft = 279
    ExplicitTop = 135
  end
  object BtnCancel: TButton
    Left = 244
    Top = 92
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
    ExplicitLeft = 360
    ExplicitTop = 135
  end
  object CbxRemoteOptions: TComboBox
    Left = 112
    Top = 37
    Width = 207
    Height = 23
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 3
    OnChange = CbxExportOptionsChange
  end
end
