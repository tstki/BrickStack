object DlgConfig: TDlgConfig
  Left = 0
  Top = 0
  Caption = 'Options'
  ClientHeight = 316
  ClientWidth = 693
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
    693
    316)
  TextHeight = 15
  object BtnCancel: TButton
    Left = 610
    Top = 283
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
    ExplicitLeft = 624
    ExplicitTop = 317
  end
  object BtnOK: TButton
    Left = 529
    Top = 283
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
    OnClick = BtnOKClick
    ExplicitLeft = 543
    ExplicitTop = 317
  end
  object TreeView1: TTreeView
    Left = 8
    Top = 32
    Width = 147
    Height = 231
    Anchors = [akLeft, akTop, akBottom]
    Indent = 19
    TabOrder = 2
    OnChange = TreeView1Change
    ExplicitHeight = 265
  end
  object PCConfig: TPageControl
    Left = 161
    Top = 8
    Width = 524
    Height = 255
    ActivePage = TsExternal
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 3
    object TsAuthentication: TTabSheet
      Caption = 'Authentication'
      DesignSize = (
        516
        225)
      object LblRebrickableAPIKey: TLabel
        Left = 15
        Top = 34
        Width = 39
        Height = 15
        Caption = 'API key'
      end
      object LblRebrickableBaseUrl: TLabel
        Left = 15
        Top = 63
        Width = 42
        Height = 15
        Caption = 'Base Url'
      end
      object Label1: TLabel
        Left = 15
        Top = 10
        Width = 82
        Height = 15
        Caption = 'Rebrickable API'
      end
      object EditRebrickableAPIKey: TEdit
        Left = 87
        Top = 31
        Width = 345
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 0
      end
      object EditRebrickableBaseUrl: TEdit
        Left = 87
        Top = 60
        Width = 345
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 2
      end
      object BtnRebrickableAPIInfo: TButton
        Left = 438
        Top = 30
        Width = 75
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Info'
        TabOrder = 1
        OnClick = BtnRebrickableAPIInfoClick
      end
    end
    object TsExternal: TTabSheet
      Caption = 'External'
      ImageIndex = 1
      DesignSize = (
        516
        225)
      object Label3: TLabel
        Left = 15
        Top = 10
        Width = 189
        Height = 15
        Caption = 'Base urls to use with "view external"'
      end
      object Label4: TLabel
        Left = 15
        Top = 34
        Width = 61
        Height = 15
        Caption = 'Rebrickable'
      end
      object Label5: TLabel
        Left = 15
        Top = 63
        Width = 45
        Height = 15
        Caption = 'Bricklink'
      end
      object Label6: TLabel
        Left = 15
        Top = 93
        Width = 45
        Height = 15
        Caption = 'Brickowl'
      end
      object Label7: TLabel
        Left = 15
        Top = 122
        Width = 41
        Height = 15
        Caption = 'Brickset'
      end
      object Label8: TLabel
        Left = 15
        Top = 151
        Width = 33
        Height = 15
        Caption = 'LDraw'
      end
      object Label10: TLabel
        Left = 15
        Top = 180
        Width = 61
        Height = 15
        Caption = 'Sets default'
      end
      object Label11: TLabel
        Left = 234
        Top = 180
        Width = 61
        Height = 15
        Caption = 'Part default'
      end
      object EditViewRebrickableUrl: TEdit
        Left = 87
        Top = 31
        Width = 345
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 0
      end
      object EditViewBrickLinkUrl: TEdit
        Left = 87
        Top = 60
        Width = 345
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 1
      end
      object EditViewBrickOwlUrl: TEdit
        Left = 87
        Top = 90
        Width = 345
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 2
      end
      object EditViewBrickSetUrl: TEdit
        Left = 87
        Top = 119
        Width = 345
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 3
      end
      object EditViewLDrawUrl: TEdit
        Left = 87
        Top = 148
        Width = 345
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 4
      end
      object CbxViewPartDefault: TComboBox
        Left = 306
        Top = 177
        Width = 126
        Height = 23
        Style = csDropDownList
        TabOrder = 6
      end
      object CbxViewSetDefault: TComboBox
        Left = 87
        Top = 177
        Width = 126
        Height = 23
        Style = csDropDownList
        TabOrder = 5
      end
    end
    object TsLocal: TTabSheet
      Caption = 'Local'
      ImageIndex = 2
      DesignSize = (
        516
        225)
      object LblLocalImageCachePath: TLabel
        Left = 15
        Top = 34
        Width = 62
        Height = 15
        Caption = 'Local cache'
      end
      object Label2: TLabel
        Left = 15
        Top = 10
        Width = 114
        Height = 15
        Caption = 'Local storage settings'
      end
      object EditLocalImageCachePath: TEdit
        Left = 87
        Top = 31
        Width = 345
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 0
      end
      object BtnSelectLocalImageCachePath: TButton
        Left = 438
        Top = 30
        Width = 75
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Select'
        TabOrder = 1
        OnClick = BtnSelectLocalImageCachePathClick
      end
    end
    object TsCustomTags: TTabSheet
      Caption = 'Tags'
      ImageIndex = 3
      object Label9: TLabel
        Left = 15
        Top = 10
        Width = 212
        Height = 15
        Caption = 'Create custom tags to apply to your sets'
      end
    end
  end
end
