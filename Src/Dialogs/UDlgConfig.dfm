object DlgConfig: TDlgConfig
  Left = 0
  Top = 0
  Caption = 'Options'
  ClientHeight = 316
  ClientWidth = 719
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
    719
    316)
  TextHeight = 15
  object BtnCancel: TButton
    Left = 636
    Top = 283
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
    OnClick = BtnCancelClick
  end
  object BtnOK: TButton
    Left = 555
    Top = 283
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 0
    OnClick = BtnOKClick
  end
  object TreeView1: TTreeView
    Left = 8
    Top = 8
    Width = 162
    Height = 255
    Anchors = [akLeft, akTop, akBottom]
    Indent = 19
    ReadOnly = True
    RowSelect = True
    TabOrder = 2
    OnChange = TreeView1Change
  end
  object PCConfig: TPageControl
    Left = 176
    Top = 8
    Width = 535
    Height = 255
    ActivePage = TsAuthentication
    Anchors = [akLeft, akTop, akRight, akBottom]
    Style = tsButtons
    TabHeight = 4
    TabOrder = 3
    object TsAuthentication: TTabSheet
      Caption = 'Authentication'
      DesignSize = (
        527
        241)
      object LblRebrickableAPIKey: TLabel
        Left = 15
        Top = 39
        Width = 39
        Height = 15
        Caption = 'API key'
      end
      object LblRebrickableBaseUrl: TLabel
        Left = 15
        Top = 68
        Width = 42
        Height = 15
        Caption = 'Base Url'
      end
      object Label1: TLabel
        Left = 15
        Top = 10
        Width = 488
        Height = 15
        Caption = 
          'Rebrickable API - used for communication with rebrickable. Token' +
          ' is needed for user actions.'
      end
      object Label26: TLabel
        Left = 15
        Top = 97
        Width = 31
        Height = 15
        Caption = 'Token'
      end
      object EditRebrickableAPIKey: TEdit
        Left = 87
        Top = 36
        Width = 356
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 0
        OnChange = EditRebrickableAPIKeyChange
      end
      object EditRebrickableBaseUrl: TEdit
        Left = 87
        Top = 65
        Width = 356
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 2
        OnChange = EditRebrickableBaseUrlChange
      end
      object BtnRebrickableAPIInfo: TButton
        Left = 449
        Top = 35
        Width = 75
        Height = 25
        Action = ActAPIInfo
        Anchors = [akTop, akRight]
        TabOrder = 1
      end
      object EditAuthenticationToken: TEdit
        Left = 87
        Top = 94
        Width = 356
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 3
      end
      object BtnLogin: TButton
        Left = 449
        Top = 93
        Width = 75
        Height = 25
        Action = ActLogin
        Anchors = [akTop, akRight]
        TabOrder = 4
      end
      object ChkRememberAuthenticationToken: TCheckBox
        Left = 87
        Top = 123
        Width = 394
        Height = 17
        Caption = 
          'Store auth token (it is only kept in memory for this session oth' +
          'erwise)'
        TabOrder = 5
      end
    end
    object TsExternal: TTabSheet
      Caption = 'External'
      ImageIndex = 1
      DesignSize = (
        527
        241)
      object Label3: TLabel
        Left = 15
        Top = 10
        Width = 189
        Height = 15
        Caption = 'Base urls to use with "view external"'
      end
      object Label4: TLabel
        Left = 15
        Top = 39
        Width = 61
        Height = 15
        Caption = 'Rebrickable'
      end
      object Label5: TLabel
        Left = 15
        Top = 68
        Width = 45
        Height = 15
        Caption = 'Bricklink'
      end
      object Label6: TLabel
        Left = 15
        Top = 97
        Width = 45
        Height = 15
        Caption = 'Brickowl'
      end
      object Label7: TLabel
        Left = 15
        Top = 126
        Width = 41
        Height = 15
        Caption = 'Brickset'
      end
      object Label8: TLabel
        Left = 15
        Top = 155
        Width = 33
        Height = 15
        Caption = 'LDraw'
      end
      object Label10: TLabel
        Left = 15
        Top = 184
        Width = 61
        Height = 15
        Caption = 'Sets default'
      end
      object Label11: TLabel
        Left = 230
        Top = 184
        Width = 61
        Height = 15
        Caption = 'Part default'
      end
      object EditViewRebrickableUrl: TEdit
        Left = 87
        Top = 36
        Width = 356
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 0
      end
      object EditViewBrickLinkUrl: TEdit
        Left = 87
        Top = 65
        Width = 356
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 1
      end
      object EditViewBrickOwlUrl: TEdit
        Left = 87
        Top = 94
        Width = 356
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 2
      end
      object EditViewBrickSetUrl: TEdit
        Left = 87
        Top = 123
        Width = 356
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 3
      end
      object EditViewLDrawUrl: TEdit
        Left = 87
        Top = 152
        Width = 356
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        TabOrder = 4
      end
      object CbxViewPartDefault: TComboBox
        Left = 302
        Top = 181
        Width = 126
        Height = 23
        Style = csDropDownList
        TabOrder = 6
      end
      object CbxViewSetDefault: TComboBox
        Left = 87
        Top = 181
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
        527
        241)
      object LblLocalImageCachePath: TLabel
        Left = 15
        Top = 39
        Width = 67
        Height = 15
        Caption = 'Cache folder'
      end
      object Label2: TLabel
        Left = 15
        Top = 10
        Width = 114
        Height = 15
        Caption = 'Local storage settings'
      end
      object LblLocalLogsPath: TLabel
        Left = 15
        Top = 97
        Width = 59
        Height = 15
        Caption = 'Logs folder'
      end
      object Label20: TLabel
        Left = 15
        Top = 126
        Width = 59
        Height = 15
        Caption = 'DBase path'
      end
      object Label21: TLabel
        Left = 15
        Top = 155
        Width = 70
        Height = 15
        Caption = 'Import folder'
      end
      object Label22: TLabel
        Left = 15
        Top = 184
        Width = 68
        Height = 15
        Caption = 'Export folder'
      end
      object Label24: TLabel
        Left = 15
        Top = 68
        Width = 40
        Height = 15
        Caption = 'Storage'
      end
      object LblCacheFolderSize: TLabel
        Left = 89
        Top = 68
        Width = 38
        Height = 15
        Caption = 'xyz MB'
      end
      object EditLocalImageCachePath: TEdit
        Left = 87
        Top = 36
        Width = 356
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        ReadOnly = True
        TabOrder = 0
      end
      object BtnSelectLocalImageCachePath: TButton
        Left = 449
        Top = 35
        Width = 75
        Height = 25
        Action = ActSelectLocalCacheFolder
        Anchors = [akTop, akRight]
        TabOrder = 1
      end
      object EditLocalLogsPath: TEdit
        Left = 87
        Top = 94
        Width = 356
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        ReadOnly = True
        TabOrder = 2
      end
      object BtnSelectEditLocalLogsPath: TButton
        Left = 449
        Top = 93
        Width = 75
        Height = 25
        Action = ActSelectLogsFolder
        Anchors = [akTop, akRight]
        TabOrder = 3
      end
      object EditDbasePath: TEdit
        Left = 87
        Top = 123
        Width = 356
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        ReadOnly = True
        TabOrder = 4
      end
      object Button1: TButton
        Left = 449
        Top = 122
        Width = 75
        Height = 25
        Action = ActDBasePath
        Anchors = [akTop, akRight]
        TabOrder = 5
      end
      object EditImportPath: TEdit
        Left = 87
        Top = 152
        Width = 356
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        ReadOnly = True
        TabOrder = 6
      end
      object Button2: TButton
        Left = 449
        Top = 151
        Width = 75
        Height = 25
        Action = ActSelectImportFolder
        Anchors = [akTop, akRight]
        TabOrder = 7
      end
      object EditExportPath: TEdit
        Left = 87
        Top = 181
        Width = 356
        Height = 23
        Anchors = [akLeft, akTop, akRight]
        ReadOnly = True
        TabOrder = 8
      end
      object Button3: TButton
        Left = 449
        Top = 180
        Width = 75
        Height = 25
        Action = ActSelectExportFolder
        Anchors = [akTop, akRight]
        TabOrder = 9
      end
      object Button7: TButton
        Left = 449
        Top = 64
        Width = 75
        Height = 25
        Action = ActClearLocalCache
        Anchors = [akTop, akRight]
        TabOrder = 10
      end
    end
    object TsCustomSetListTags: TTabSheet
      Caption = 'Setlist Tags'
      ImageIndex = 6
      object Label27: TLabel
        Left = 15
        Top = 10
        Width = 227
        Height = 15
        Caption = 'Create custom tags to apply to your setlists'
      end
      object Label28: TLabel
        Left = 15
        Top = 39
        Width = 40
        Height = 15
        Caption = 'Label23'
      end
      object Edit1: TEdit
        Left = 80
        Top = 36
        Width = 121
        Height = 23
        TabOrder = 0
      end
      object Button8: TButton
        Left = 207
        Top = 35
        Width = 75
        Height = 25
        Caption = 'Add'
        TabOrder = 1
        OnClick = ActCreateTagExecute
      end
      object ListView1: TListView
        Left = 15
        Top = 65
        Width = 186
        Height = 136
        Columns = <
          item
            Caption = 'Name'
            Width = 150
          end>
        ReadOnly = True
        RowSelect = True
        TabOrder = 2
        ViewStyle = vsReport
      end
      object Button9: TButton
        Left = 207
        Top = 145
        Width = 75
        Height = 25
        Caption = 'Edit'
        TabOrder = 3
        OnClick = ActEditTagExecute
      end
      object Button10: TButton
        Left = 207
        Top = 176
        Width = 75
        Height = 25
        Caption = 'Delete'
        TabOrder = 4
        OnClick = ActDeleteTagExecute
      end
    end
    object TsCustomSetTags: TTabSheet
      Caption = 'Set Tags'
      ImageIndex = 3
      object Label9: TLabel
        Left = 15
        Top = 10
        Width = 212
        Height = 15
        Caption = 'Create custom tags to apply to your sets'
      end
      object Label23: TLabel
        Left = 15
        Top = 39
        Width = 40
        Height = 15
        Caption = 'Label23'
      end
      object LvCollections: TListView
        Left = 15
        Top = 65
        Width = 186
        Height = 136
        Columns = <
          item
            Caption = 'Name'
            Width = 150
          end>
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
      end
      object Edit4: TEdit
        Left = 80
        Top = 36
        Width = 121
        Height = 23
        TabOrder = 1
      end
      object Button4: TButton
        Left = 207
        Top = 35
        Width = 75
        Height = 25
        Action = ActCreateTag
        TabOrder = 2
      end
      object Button5: TButton
        Left = 207
        Top = 145
        Width = 75
        Height = 25
        Action = ActEditTag
        TabOrder = 3
      end
      object Button6: TButton
        Left = 207
        Top = 176
        Width = 75
        Height = 25
        Action = ActDeleteTag
        TabOrder = 4
      end
    end
    object TsBackup: TTabSheet
      Caption = 'Backup'
      ImageIndex = 4
      object Label12: TLabel
        Left = 15
        Top = 10
        Width = 161
        Height = 15
        Caption = 'Configure automated backups'
      end
      object Label13: TLabel
        Left = 31
        Top = 50
        Width = 39
        Height = 15
        Caption = 'interval'
      end
      object Label14: TLabel
        Left = 31
        Top = 71
        Width = 73
        Height = 15
        Caption = 'backup folder'
      end
    end
    object TsWindows: TTabSheet
      Caption = 'Windows'
      ImageIndex = 5
      DesignSize = (
        527
        241)
      object Label15: TLabel
        Left = 15
        Top = 10
        Width = 100
        Height = 15
        Caption = 'Window behaviour'
      end
      object Label16: TLabel
        Left = 55
        Top = 50
        Width = 145
        Height = 15
        Caption = 'Allow multiple set windows'
      end
      object Label17: TLabel
        Left = 55
        Top = 71
        Width = 187
        Height = 15
        Caption = 'Allow multiple collections windows'
      end
      object Label18: TLabel
        Left = 55
        Top = 92
        Width = 160
        Height = 15
        Caption = 'Allow multiple setlist windows'
      end
      object Label19: TLabel
        Left = 55
        Top = 113
        Width = 227
        Height = 15
        Caption = 'Remember all open windows and positions'
      end
      object Label25: TLabel
        Left = 15
        Top = 168
        Width = 58
        Height = 15
        Caption = 'Visual style'
      end
      object CbxVisualStyle: TComboBox
        Left = 79
        Top = 165
        Width = 207
        Height = 23
        Style = csDropDownList
        Anchors = [akLeft, akTop, akRight]
        Sorted = True
        TabOrder = 0
        OnChange = CbxVisualStyleChange
      end
    end
  end
  object ActionList1: TActionList
    Left = 24
    Top = 264
    object ActLogin: TAction
      Caption = 'Login'
      OnExecute = ActLoginExecute
    end
    object ActAPIInfo: TAction
      Caption = 'Info'
      OnExecute = ActAPIInfoExecute
    end
    object ActSelectLocalCacheFolder: TAction
      Caption = 'Select'
      OnExecute = ActSelectLocalCacheFolderExecute
    end
    object ActClearLocalCache: TAction
      Caption = 'Clear'
      OnExecute = ActClearLocalCacheExecute
    end
    object ActSelectLogsFolder: TAction
      Caption = 'Select'
      OnExecute = ActSelectLogsFolderExecute
    end
    object ActDBasePath: TAction
      Caption = 'Select'
      OnExecute = ActDBasePathExecute
    end
    object ActSelectImportFolder: TAction
      Caption = 'Select'
      OnExecute = ActSelectImportFolderExecute
    end
    object ActSelectExportFolder: TAction
      Caption = 'Select'
      OnExecute = ActSelectExportFolderExecute
    end
    object ActCreateTag: TAction
      Caption = 'Add'
      OnExecute = ActCreateTagExecute
    end
    object ActEditTag: TAction
      Caption = 'Edit'
      OnExecute = ActEditTagExecute
    end
    object ActDeleteTag: TAction
      Caption = 'Delete'
      OnExecute = ActDeleteTagExecute
    end
  end
end
