object DlgLogin: TDlgLogin
  Left = 0
  Top = 0
  Caption = 'Login'
  ClientHeight = 281
  ClientWidth = 468
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnShow = FormShow
  DesignSize = (
    468
    281)
  TextHeight = 15
  object LblUsername: TLabel
    Left = 8
    Top = 50
    Width = 107
    Height = 15
    Caption = 'Username (or email)'
  end
  object LblRebrickableBaseUrl: TLabel
    Left = 8
    Top = 79
    Width = 50
    Height = 15
    Caption = 'Password'
  end
  object LblHeader: TLabel
    Left = 8
    Top = 10
    Width = 452
    Height = 30
    Anchors = [akLeft, akTop, akRight]
    Caption = 
      'Authentication is required for advanced functions such as import' +
      ', export and syncing with your private collection.'
    WordWrap = True
  end
  object StoreAuthenticationTokenWarning: TLabel
    Left = 8
    Top = 131
    Width = 452
    Height = 60
    Anchors = [akLeft, akTop, akRight]
    Caption = 
      'You must log in each time unless you save the token. Your passwo' +
      'rd isn'#39't stored locally. The token never expires, so change your' +
      ' password often. Don'#39't save it on shared computers because the t' +
      'oken is saved as plain text. We'#39're not responsible for any accou' +
      'nt changes if you lose the token.'
    WordWrap = True
  end
  object EditUsername: TEdit
    Left = 121
    Top = 47
    Width = 339
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    OnChange = EditChange
  end
  object EditPassword: TEdit
    Left = 121
    Top = 76
    Width = 339
    Height = 23
    Anchors = [akLeft, akTop, akRight]
    PasswordChar = '*'
    TabOrder = 1
    OnChange = EditChange
  end
  object BtnOK: TButton
    Left = 304
    Top = 248
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    TabOrder = 3
    OnClick = BtnOKClick
    ExplicitLeft = 221
    ExplicitTop = 184
  end
  object BtnCancel: TButton
    Left = 385
    Top = 248
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 4
    ExplicitLeft = 546
    ExplicitTop = 384
  end
  object ChkStoreAuthenticationToken: TCheckBox
    Left = 121
    Top = 197
    Width = 208
    Height = 17
    Caption = 'Remember authentication token'
    TabOrder = 2
  end
end
