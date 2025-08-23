object DlgUpdateDatabase: TDlgUpdateDatabase
  Left = 0
  Top = 0
  Caption = 'Database update wizard'
  ClientHeight = 465
  ClientWidth = 527
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnShow = FormShow
  DesignSize = (
    527
    465)
  TextHeight = 15
  object BtnOK: TButton
    Left = 365
    Top = 432
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Start'
    Default = True
    TabOrder = 0
    OnClick = BtnOKClick
    ExplicitLeft = 433
  end
  object BtnCancel: TButton
    Left = 446
    Top = 432
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'Close'
    TabOrder = 1
    OnClick = BtnCancelClick
    ExplicitLeft = 514
  end
  object PCDBWizard: TPageControl
    Left = 8
    Top = 10
    Width = 513
    Height = 409
    ActivePage = TsStart
    Anchors = [akLeft, akTop, akRight, akBottom]
    Style = tsButtons
    TabHeight = 4
    TabOrder = 2
    ExplicitWidth = 581
    object TsStart: TTabSheet
      Caption = 'TsStart'
      ImageIndex = 1
      DesignSize = (
        505
        395)
      object Memo1: TMemo
        Left = 10
        Top = 3
        Width = 489
        Height = 343
        Anchors = [akLeft, akTop, akRight, akBottom]
        BevelInner = bvNone
        BorderStyle = bsNone
        Lines.Strings = (
          'Welcome to BrickStack!'
          ''
          
            'This wizard will guide you through the database creation and upd' +
            'ating process.'
          ''
          
            'Please note that this is a mandatory step, BrickStack needs a da' +
            'tabase to work.'
          
            'This will ensure (almost) all data is available locally on your ' +
            'machine, and fast!'
          ''
          'Here'#39's what we'#39're going to do:'
          '- Create the database locally.'
          '- Download the CSV.GZ files from Rebrickable.'
          '- Unpack the .GZ files.'
          '- Read the .CSV files.'
          '- Import the data into your local database.'
          ''
          'Press the '#39'Start'#39' button to continue.')
        TabOrder = 0
        ExplicitWidth = 549
      end
    end
    object TsUpdate: TTabSheet
      Caption = 'TsUpdate'
      ImageIndex = 3
      DesignSize = (
        505
        395)
      object Memo3: TMemo
        Left = 3
        Top = 3
        Width = 490
        Height = 343
        Anchors = [akLeft, akTop, akRight, akBottom]
        BevelInner = bvNone
        BorderStyle = bsNone
        Lines.Strings = (
          'Welcome (back) to the database wizard.'
          ''
          
            'It looks like the parts, sets and related database tables are ge' +
            'tting kind of old.'
          ''
          
            'From here you can update them with a single click, just press '#39'S' +
            'tart'#39'.'
          ''
          'Here'#39's what we'#39'd need to do:'
          
            '- Drop the parts, sets and other related tables. Don'#39't worry - a' +
            'll of BrickStack'#39's tables are '
          'unaffected. Your '
          'collection will be available again after the update.'
          '- Download CSV.GZ files from Rebrickable.'
          '- Unpack the .GZ files.'
          '- Read the .CSV files.'
          '- Import thedata into your local database.'
          ''
          
            'Keep in mind this will take a little bit of time. Updating datab' +
            'ases is rarely fast.'
          'Or just click '#39'Close'#39' for now, and we'#39'll ask you again later.')
        TabOrder = 0
        ExplicitWidth = 550
      end
    end
    object TsTables: TTabSheet
      Caption = 'TsTables'
      DesignSize = (
        505
        395)
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
        Width = 485
        Height = 346
        Anchors = [akLeft, akTop, akRight, akBottom]
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
        ExplicitWidth = 545
      end
    end
    object TsResults: TTabSheet
      Caption = 'TsResults'
      ImageIndex = 2
      DesignSize = (
        505
        395)
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
        Width = 485
        Height = 347
        Anchors = [akLeft, akTop, akRight, akBottom]
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
        ExplicitWidth = 545
      end
    end
  end
  object ChkDoNotRemind: TCheckBox
    Left = 8
    Top = 440
    Width = 233
    Height = 17
    Caption = 'Don'#39't remind me for at least 30 days'
    TabOrder = 3
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 500
    OnTimer = Timer1Timer
    Left = 320
    Top = 424
  end
end
