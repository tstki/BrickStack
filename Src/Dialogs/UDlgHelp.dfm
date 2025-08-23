object DlgHelp: TDlgHelp
  Left = 0
  Top = 0
  Caption = 'Help'
  ClientHeight = 420
  ClientWidth = 627
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnShow = FormShow
  DesignSize = (
    627
    420)
  TextHeight = 15
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 462
    Height = 15
    Caption = 
      'Looking for help? Not sure where to start? Just click a topic be' +
      'low for more information.'
  end
  object PCHelp: TPageControl
    Left = 207
    Top = 29
    Width = 412
    Height = 352
    ActivePage = TsHelp
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabHeight = 4
    TabOrder = 0
    object TsHelp: TTabSheet
      Caption = 'Help'
      ImageIndex = 3
      object Memo2: TMemo
        Left = 3
        Top = 3
        Width = 400
        Height = 334
        BorderStyle = bsNone
        Lines.Strings = (
          
            'Welcome to BrickStack - I hope it will be a useful tool for you ' +
            'to keep '
          'around.'
          
            'It is free, and you may distribute it to your friends and family' +
            ' as you see fit.'
          
            'If you paid for it - well, donations to the creator are always w' +
            'elcome, but '
          'please do not pay others for it.'
          ''
          
            'If you can read this screen, that hopefully means you'#39've at leas' +
            't finished '
          'creating a database and imported the basic data.'
          
            'If not, well, now is as good a time as any - just hit "Help -> U' +
            'pdate '
          
            'database" from the help menu - otherwise all basic functionality' +
            ' will be '
          'grayed out.'
          ''
          
            'The point of this application is to have an infinitely expandabl' +
            'e list of '
          
            'collections with which to sort and categorize your lego collecti' +
            'on.'
          
            'Tag them with custom locations and markers as you see fit, and b' +
            'asically '
          
            'keep better part of what parts you do or don'#39't have - so that yo' +
            'u can order '
          'them, or find them in other parts of your collection.'
          ''
          
            'Feature requests are always welcome - just don'#39't expect them to ' +
            'magically '
          'be implemented unless you are willing to lend a hand.'
          ''
          'Find us at: https://github.com/tstki/BrickStack')
        TabOrder = 0
        StyleElements = [seFont, seClient]
      end
    end
    object TsBasics: TTabSheet
      Caption = 'TsBasics'
      object Memo1: TMemo
        Left = 3
        Top = 3
        Width = 400
        Height = 334
        BorderStyle = bsNone
        Lines.Strings = (
          
            'After your database is created, you can use the "Lego->Search...' +
            ' (Ctrl+F)" to '
          'look for lego sets,'
          
            'and "Lego -> Collections... (Ctrl+O)" to open your collection of' +
            ' lego.'
          ''
          
            'Be sure to name at least one set list for the collection, so you' +
            ' can start '
          'adding sets to it.')
        TabOrder = 0
        StyleElements = [seFont, seClient]
      end
    end
    object TsCollections: TTabSheet
      Caption = 'TsCollections'
      ImageIndex = 1
      object Memo3: TMemo
        Left = 3
        Top = 3
        Width = 400
        Height = 334
        BorderStyle = bsNone
        Lines.Strings = (
          'Info about collections goes here')
        TabOrder = 0
        StyleElements = [seFont, seClient]
      end
    end
    object TsSearch: TTabSheet
      Caption = 'TsSearch'
      ImageIndex = 2
      object Memo4: TMemo
        Left = 3
        Top = 3
        Width = 400
        Height = 334
        BorderStyle = bsNone
        Lines.Strings = (
          'Info about search goes here')
        TabOrder = 0
        StyleElements = [seFont, seClient]
      end
    end
  end
  object TreeView1: TTreeView
    Left = 0
    Top = 29
    Width = 201
    Height = 352
    Anchors = [akLeft, akTop, akBottom]
    Indent = 19
    TabOrder = 1
    OnChange = TreeView1Change
  end
  object BtnOK: TButton
    Left = 544
    Top = 387
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Cancel = True
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
    ExplicitTop = 408
  end
end
