object DlgUpdateDatabase: TDlgUpdateDatabase
  Left = 0
  Top = 0
  Caption = 'Database update wizard'
  ClientHeight = 465
  ClientWidth = 785
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnShow = FormShow
  DesignSize = (
    785
    465)
  TextHeight = 15
  object BtnOK: TButton
    Left = 621
    Top = 432
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Start'
    Default = True
    TabOrder = 0
    OnClick = BtnOKClick
  end
  object BtnCancel: TButton
    Left = 702
    Top = 432
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 1
    OnClick = BtnCancelClick
  end
  object Memo2: TMemo
    Left = 595
    Top = 163
    Width = 185
    Height = 146
    TabOrder = 2
  end
  object BtnDownloadFiles: TButton
    Left = 631
    Top = 39
    Width = 113
    Height = 25
    Caption = 'DownloadFiles'
    TabOrder = 3
    OnClick = BtnDownloadFilesClick
  end
  object BtnCreateDB: TButton
    Left = 631
    Top = 8
    Width = 113
    Height = 25
    Caption = 'Create DB'
    TabOrder = 4
    OnClick = BtnCreateDBClick
  end
  object BtnExtractFiles: TButton
    Left = 631
    Top = 70
    Width = 113
    Height = 25
    Caption = 'Extract Files'
    TabOrder = 5
    OnClick = BtnExtractFilesClick
  end
  object BtnImportCSV: TButton
    Left = 631
    Top = 101
    Width = 113
    Height = 25
    Caption = 'Import CSV'
    TabOrder = 6
    OnClick = BtnImportCSVClick
  end
  object BtnCleanupImport: TButton
    Left = 631
    Top = 132
    Width = 113
    Height = 25
    Caption = 'Cleanup import'
    TabOrder = 7
    OnClick = BtnCleanupImportClick
  end
  object PCDBWizard: TPageControl
    Left = 8
    Top = 10
    Width = 581
    Height = 409
    ActivePage = TsStart
    Style = tsButtons
    TabHeight = 4
    TabOrder = 8
    object TsStart: TTabSheet
      Caption = 'TsStart'
      ImageIndex = 1
      object Memo1: TMemo
        Left = 10
        Top = 3
        Width = 560
        Height = 343
        BevelInner = bvNone
        BorderStyle = bsNone
        Lines.Strings = (
          
            'This wizard will guide you through the database creation and upd' +
            'ating process.'
          ''
          'The database is required for the search function to work.'
          'Current database versions are listed per table.'
          ''
          
            'If you have existing data, this is probably a good time to make ' +
            'a backup in case things go '
          'horribly wrong.'
          ''
          ''
          'Here'#39's what'#39's going to happen:'
          '- Create the database locally.'
          '- Create the needed SQL tables.'
          '- Download the CSV.GZ files from Rebrickable.'
          '- Unpack the .GZ files.'
          '- Read the .CSV files.'
          '- Import the data into your local database.'
          ''
          ''
          'Use the button below to start.')
        TabOrder = 0
      end
    end
    object TsTables: TTabSheet
      Caption = 'TsTables'
      object LblProgress: TLabel
        Left = 10
        Top = 10
        Width = 65
        Height = 15
        Caption = 'Current step'
      end
      object LvResults: TListView
        Left = 10
        Top = 31
        Width = 545
        Height = 346
        Columns = <
          item
            Caption = 'State'
            Width = 75
          end
          item
            Caption = 'Name'
            Width = 175
          end
          item
            Caption = 'Local'
            Width = 80
          end
          item
            Caption = 'Available'
            Width = 80
          end>
        TabOrder = 0
        ViewStyle = vsReport
      end
    end
    object TsResults: TTabSheet
      Caption = 'TsResults'
      ImageIndex = 2
      object LblResults: TLabel
        Left = 10
        Top = 10
        Width = 37
        Height = 15
        Caption = 'Results'
      end
      object ListView2: TListView
        Left = 10
        Top = 31
        Width = 545
        Height = 347
        Columns = <
          item
            Caption = 'State'
            Width = 75
          end
          item
            Caption = 'Name'
            Width = 175
          end
          item
            Caption = 'Local'
            Width = 80
          end
          item
            Caption = 'Available'
            Width = 80
          end>
        TabOrder = 0
        ViewStyle = vsReport
      end
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 500
    OnTimer = Timer1Timer
    Left = 600
    Top = 16
  end
end
