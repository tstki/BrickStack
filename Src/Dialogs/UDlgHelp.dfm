object DlgHelp: TDlgHelp
  Left = 0
  Top = 0
  Caption = 'Help'
  ClientHeight = 442
  ClientWidth = 628
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object PageControl1: TPageControl
    Left = 288
    Top = 56
    Width = 332
    Height = 345
    ActivePage = TabSheet3
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'TabSheet1'
    end
    object TabSheet2: TTabSheet
      Caption = 'TabSheet2'
      ImageIndex = 1
    end
    object TabSheet3: TTabSheet
      Caption = 'TabSheet3'
      ImageIndex = 2
    end
  end
  object TreeView1: TTreeView
    Left = 0
    Top = 56
    Width = 282
    Height = 345
    Indent = 19
    TabOrder = 1
  end
  object BtnOK: TButton
    Left = 545
    Top = 409
    Width = 75
    Height = 25
    Cancel = True
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
end
