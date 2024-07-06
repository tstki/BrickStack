object DlgTest: TDlgTest
  Left = 0
  Top = 0
  Caption = 'DlgTest'
  ClientHeight = 133
  ClientWidth = 324
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  TextHeight = 15
  object Image1: TImage
    Left = 213
    Top = 39
    Width = 105
    Height = 89
    Proportional = True
    Stretch = True
  end
  object Button1: TButton
    Left = 8
    Top = 8
    Width = 113
    Height = 25
    Caption = 'LoadColors'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Memo1: TMemo
    Left = 8
    Top = 39
    Width = 194
    Height = 89
    Lines.Strings = (
      'Memo1')
    TabOrder = 1
  end
  object Button2: TButton
    Left = 127
    Top = 8
    Width = 75
    Height = 25
    Caption = 'DummyText'
    TabOrder = 2
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 243
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Load Image'
    TabOrder = 3
    OnClick = Button3Click
  end
end
