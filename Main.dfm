object Form1: TForm1
  Left = 0
  Top = 0
  AlphaBlend = True
  AlphaBlendValue = 0
  Caption = 'Wrapper Assistant'
  ClientHeight = 691
  ClientWidth = 1159
  Color = clWindow
  Ctl3D = False
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnResize = FormResize
  OnShow = FormShow
  TextHeight = 20
  object Panel9: TPanel
    Left = 0
    Top = 0
    Width = 1159
    Height = 662
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object Panel2: TPanel
      Left = 0
      Top = 0
      Width = 350
      Height = 662
      Align = alLeft
      BevelOuter = bvNone
      DoubleBuffered = True
      ParentBackground = False
      ParentDoubleBuffered = False
      TabOrder = 0
      object Panel6: TPanel
        Left = 0
        Top = 0
        Width = 350
        Height = 50
        Align = alTop
        BevelOuter = bvNone
        Color = 1710618
        ParentBackground = False
        TabOrder = 0
        StyleElements = [seFont, seBorder]
        object Button4: TButton
          Left = 4
          Top = 8
          Width = 35
          Height = 33
          Caption = #57791
          DoubleBuffered = True
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'Segoe MDL2 Assets'
          Font.Style = []
          ParentDoubleBuffered = False
          ParentFont = False
          TabOrder = 0
          Visible = False
        end
        object Button6: TButton
          Left = 310
          Top = 8
          Width = 35
          Height = 33
          Caption = #62851
          DoubleBuffered = True
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -19
          Font.Name = 'Segoe MDL2 Assets'
          Font.Style = []
          ParentDoubleBuffered = False
          ParentFont = False
          TabOrder = 1
          Visible = False
        end
      end
      object Panel7: TPanel
        Left = 0
        Top = 50
        Width = 350
        Height = 612
        Align = alClient
        BevelOuter = bvNone
        Caption = 'Panel7'
        ParentBackground = False
        TabOrder = 1
        object Panel8: TPanel
          Left = 0
          Top = 0
          Width = 10
          Height = 612
          Align = alLeft
          BevelOuter = bvNone
          Color = 1710618
          ParentBackground = False
          TabOrder = 0
          StyleElements = [seFont, seBorder]
        end
        object ScrollBox1: TScrollBox
          Left = 10
          Top = 0
          Width = 340
          Height = 612
          HorzScrollBar.Visible = False
          Align = alClient
          BorderStyle = bsNone
          Color = 1710618
          ParentColor = False
          TabOrder = 1
          StyleElements = [seBorder]
        end
      end
    end
    object Panel1: TPanel
      Left = 350
      Top = 0
      Width = 459
      Height = 662
      Align = alClient
      BevelOuter = bvNone
      Color = 2565927
      DoubleBuffered = True
      ParentBackground = False
      ParentDoubleBuffered = False
      ShowCaption = False
      TabOrder = 1
      object Panel3: TPanel
        Left = 0
        Top = 538
        Width = 459
        Height = 124
        Align = alBottom
        BevelOuter = bvNone
        DoubleBuffered = True
        ParentBackground = False
        ParentDoubleBuffered = False
        TabOrder = 0
        object Panel12: TPanel
          Left = 49
          Top = 0
          Width = 410
          Height = 124
          Align = alClient
          BevelOuter = bvNone
          FullRepaint = False
          ParentBackground = False
          TabOrder = 0
          object Panel11: TPanel
            Left = 0
            Top = 3
            Width = 361
            Height = 118
            BevelOuter = bvNone
            Color = 2039583
            Ctl3D = True
            ParentBackground = False
            ParentCtl3D = False
            TabOrder = 0
            StyleElements = [seFont, seBorder]
            DesignSize = (
              361
              118)
            object SpeedButton6: TSpeedButton
              Left = 318
              Top = 80
              Width = 33
              Height = 33
              Anchors = [akTop, akRight]
              Caption = #60004
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -21
              Font.Name = 'Segoe MDL2 Assets'
              Font.Style = []
              ParentFont = False
              ExplicitLeft = 462
            end
            object SpeedButton3: TSpeedButton
              Left = 13
              Top = 80
              Width = 33
              Height = 33
              Hint = 'Enable Web Search'
              AllowAllUp = True
              GroupIndex = 2
              Caption = #60225
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 5592405
              Font.Height = -21
              Font.Name = 'Segoe MDL2 Assets'
              Font.Pitch = fpFixed
              Font.Style = []
              Font.Quality = fqAntialiased
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
              StyleElements = [seClient, seBorder]
            end
            object SpeedButton4: TSpeedButton
              Left = 64
              Top = 80
              Width = 33
              Height = 33
              Hint = 'Disable File_search tool'
              AllowAllUp = True
              GroupIndex = 3
              Caption = #57847
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 5592405
              Font.Height = -21
              Font.Name = 'Segoe MDL2 Assets'
              Font.Style = []
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
              StyleElements = [seClient, seBorder]
            end
            object SpeedButton5: TSpeedButton
              Left = 97
              Top = 80
              Width = 33
              Height = 33
              Hint = 'Enable Reasoning'#13#10'File_search disable'
              AllowAllUp = True
              GroupIndex = 3
              Caption = #60049
              Font.Charset = DEFAULT_CHARSET
              Font.Color = 5592405
              Font.Height = -21
              Font.Name = 'Segoe MDL2 Assets'
              Font.Style = []
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
              StyleElements = [seClient, seBorder]
            end
            object RichEdit1: TRichEdit
              AlignWithMargins = True
              Left = 11
              Top = 9
              Width = 337
              Height = 70
              Margins.Left = 8
              Margins.Right = 8
              Anchors = [akLeft, akTop, akRight, akBottom]
              BevelInner = bvNone
              BevelOuter = bvNone
              BorderStyle = bsNone
              Color = 2039583
              EditMargins.Left = 16
              EditMargins.Right = 8
              EnableURLs = True
              Font.Charset = ANSI_CHARSET
              Font.Color = clWhite
              Font.Height = -16
              Font.Name = 'Segoe UI'
              Font.Style = []
              HideSelection = False
              MaxLength = 2000000000
              ParentFont = False
              ParentShowHint = False
              ScrollBars = ssVertical
              ShowHint = False
              SpellChecking = True
              TabOrder = 0
              WantReturns = False
            end
          end
        end
        object Panel13: TPanel
          Left = 0
          Top = 0
          Width = 49
          Height = 124
          Align = alLeft
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 1
        end
      end
      object Panel5: TPanel
        Left = 0
        Top = 0
        Width = 459
        Height = 50
        Align = alTop
        BevelOuter = bvNone
        ParentBackground = False
        TabOrder = 1
        object Panel23: TPanel
          Left = 87
          Top = 0
          Width = 372
          Height = 50
          Align = alClient
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 0
          object Label14: TLabel
            AlignWithMargins = True
            Left = 18
            Top = 3
            Width = 38
            Height = 44
            Margins.Left = 18
            Align = alLeft
            Caption = 'Title'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -19
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            Layout = tlCenter
            ExplicitHeight = 25
          end
        end
        object Panel24: TPanel
          Left = 0
          Top = 0
          Width = 87
          Height = 50
          Align = alLeft
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 1
          object Button3: TButton
            Left = 4
            Top = 8
            Width = 35
            Height = 33
            Caption = #57792
            DoubleBuffered = True
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -19
            Font.Name = 'Segoe MDL2 Assets'
            Font.Style = []
            ParentDoubleBuffered = False
            ParentFont = False
            TabOrder = 0
          end
          object Button7: TButton
            Left = 47
            Top = 8
            Width = 35
            Height = 33
            Caption = #62851
            DoubleBuffered = True
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -19
            Font.Name = 'Segoe MDL2 Assets'
            Font.Style = []
            ParentDoubleBuffered = False
            ParentFont = False
            TabOrder = 1
          end
        end
      end
      object Panel14: TPanel
        Left = 0
        Top = 50
        Width = 459
        Height = 488
        Align = alClient
        BevelOuter = bvNone
        Color = 2565927
        ParentBackground = False
        TabOrder = 2
        object Panel15: TPanel
          Left = 0
          Top = 0
          Width = 49
          Height = 488
          Align = alLeft
          BevelOuter = bvNone
          ParentBackground = False
          TabOrder = 0
        end
        object Panel16: TPanel
          Left = 49
          Top = 0
          Width = 410
          Height = 488
          Align = alClient
          BevelOuter = bvNone
          Color = 2565927
          ParentBackground = False
          TabOrder = 1
          object EdgeBrowser1: TEdgeBrowser
            Left = 0
            Top = 0
            Width = 361
            Height = 488
            Align = alLeft
            TabOrder = 0
            AllowSingleSignOnUsingOSPrimaryAccount = False
            TargetCompatibleBrowserVersion = '117.0.2045.28'
            UserDataFolder = '%LOCALAPPDATA%\bds.exe.WebView2'
          end
        end
      end
    end
    object Panel4: TPanel
      Left = 809
      Top = 0
      Width = 350
      Height = 662
      Align = alRight
      BevelOuter = bvNone
      Ctl3D = False
      DoubleBuffered = True
      FullRepaint = False
      ParentBackground = False
      ParentCtl3D = False
      ParentDoubleBuffered = False
      TabOrder = 2
      object PageControl1: TPageControl
        Left = 0
        Top = 50
        Width = 350
        Height = 488
        ActivePage = HistorySheet
        Align = alClient
        Style = tsButtons
        TabOrder = 0
        object HistorySheet: TTabSheet
          Caption = 'Chat History'
          ImageIndex = 1
          TabVisible = False
          object Panel18: TPanel
            Left = 0
            Top = 0
            Width = 342
            Height = 478
            Align = alClient
            BevelOuter = bvNone
            Color = 2039583
            Ctl3D = False
            FullRepaint = False
            ParentBackground = False
            ParentCtl3D = False
            ShowCaption = False
            TabOrder = 0
            StyleElements = []
            object ListView1: TListView
              Left = 0
              Top = 0
              Width = 342
              Height = 419
              Align = alClient
              BevelInner = bvNone
              BevelOuter = bvNone
              BorderStyle = bsNone
              Color = 2039583
              Columns = <>
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWhite
              Font.Height = -13
              Font.Name = 'Segoe UI'
              Font.Style = []
              TileOptions.SizeType = tstFixedSize
              RowSelect = True
              ParentFont = False
              TabOrder = 0
              ViewStyle = vsList
            end
            object Panel20: TPanel
              Left = 0
              Top = 419
              Width = 342
              Height = 59
              Align = alBottom
              BevelOuter = bvNone
              Color = 2039583
              ParentBackground = False
              TabOrder = 1
              StyleElements = [seFont, seBorder]
              object SpeedButton1: TSpeedButton
                Left = 24
                Top = 19
                Width = 97
                Height = 22
                Caption = '&Ok'
                StyleElements = [seFont, seBorder]
              end
              object SpeedButton2: TSpeedButton
                Left = 208
                Top = 19
                Width = 97
                Height = 22
                Caption = '&Cancel'
                Transparent = False
                StyleElements = [seFont, seBorder]
              end
            end
          end
        end
        object FileSearchSheet: TTabSheet
          Caption = 'File Search'
          TabVisible = False
          object Panel17: TPanel
            Left = 0
            Top = 0
            Width = 342
            Height = 478
            Align = alClient
            BevelOuter = bvNone
            Color = 3487029
            ParentBackground = False
            TabOrder = 0
            object Memo1: TMemo
              Left = 0
              Top = 0
              Width = 342
              Height = 478
              Align = alClient
              BorderStyle = bsNone
              EditMargins.Left = 6
              EditMargins.Right = 6
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clSilver
              Font.Height = -13
              Font.Name = 'Segoe UI'
              Font.Style = []
              ParentFont = False
              ReadOnly = True
              ScrollBars = ssVertical
              TabOrder = 0
              StyleElements = [seClient, seBorder]
            end
          end
        end
        object WebSearchSheet: TTabSheet
          Caption = 'Web Search'
          ImageIndex = 3
          TabVisible = False
          object Memo2: TMemo
            Left = 0
            Top = 0
            Width = 342
            Height = 478
            Align = alClient
            BorderStyle = bsNone
            EditMargins.Left = 6
            EditMargins.Right = 6
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clSilver
            Font.Height = -13
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            ReadOnly = True
            ScrollBars = ssVertical
            TabOrder = 0
            StyleElements = [seClient, seBorder]
          end
        end
        object ReasoningSheet: TTabSheet
          Caption = 'Reasoning'
          ImageIndex = 2
          TabVisible = False
          object Memo3: TMemo
            Left = 0
            Top = 0
            Width = 342
            Height = 478
            Align = alClient
            BorderStyle = bsNone
            EditMargins.Left = 6
            EditMargins.Right = 6
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clSilver
            Font.Height = -13
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            ReadOnly = True
            ScrollBars = ssVertical
            TabOrder = 0
            StyleElements = [seClient, seBorder]
          end
        end
        object VectorStoreSheet: TTabSheet
          Caption = 'Vector Store'
          ImageIndex = 5
          TabVisible = False
          object ScrollBox3: TScrollBox
            Left = 0
            Top = 0
            Width = 342
            Height = 433
            Align = alClient
            BevelInner = bvNone
            BevelOuter = bvNone
            BorderStyle = bsNone
            Color = 2039583
            ParentColor = False
            TabOrder = 0
            StyleElements = [seFont, seBorder]
            object Image1: TImage
              Left = 8
              Top = 8
              Width = 75
              Height = 75
              Picture.Data = {
                0954506E67496D61676589504E470D0A1A0A0000000D49484452000000960000
                00960802000000B363E6B5000000097048597300004EBD00004EBD01736A6814
                000006BD69545874584D4C3A636F6D2E61646F62652E786D7000000000003C3F
                787061636B657420626567696E3D22EFBBBF222069643D2257354D304D704365
                6869487A7265537A4E54637A6B633964223F3E203C783A786D706D6574612078
                6D6C6E733A783D2261646F62653A6E733A6D6574612F2220783A786D70746B3D
                2241646F626520584D5020436F726520392E312D633030322037392E61316364
                3132662C20323032342F31312F31312D31393A30383A34362020202020202020
                223E203C7264663A52444620786D6C6E733A7264663D22687474703A2F2F7777
                772E77332E6F72672F313939392F30322F32322D7264662D73796E7461782D6E
                7323223E203C7264663A4465736372697074696F6E207264663A61626F75743D
                222220786D6C6E733A786D703D22687474703A2F2F6E732E61646F62652E636F
                6D2F7861702F312E302F2220786D6C6E733A64633D22687474703A2F2F707572
                6C2E6F72672F64632F656C656D656E74732F312E312F2220786D6C6E733A7068
                6F746F73686F703D22687474703A2F2F6E732E61646F62652E636F6D2F70686F
                746F73686F702F312E302F2220786D6C6E733A786D704D4D3D22687474703A2F
                2F6E732E61646F62652E636F6D2F7861702F312E302F6D6D2F2220786D6C6E73
                3A73744576743D22687474703A2F2F6E732E61646F62652E636F6D2F7861702F
                312E302F73547970652F5265736F757263654576656E74232220786D703A4372
                6561746F72546F6F6C3D2241646F62652050686F746F73686F702032362E3420
                2857696E646F7773292220786D703A437265617465446174653D22323032352D
                30352D32305430353A33393A31352B30323A30302220786D703A4D6F64696679
                446174653D22323032352D30352D32305430353A34323A34392B30323A303022
                20786D703A4D65746164617461446174653D22323032352D30352D3230543035
                3A34323A34392B30323A3030222064633A666F726D61743D22696D6167652F70
                6E67222070686F746F73686F703A436F6C6F724D6F64653D22332220786D704D
                4D3A496E7374616E636549443D22786D702E6969643A33623361303066312D35
                3138312D393934342D626638622D6435393534363636383061392220786D704D
                4D3A446F63756D656E7449443D2261646F62653A646F6369643A70686F746F73
                686F703A65376336663633662D323335352D643234312D613762652D39386438
                35626466323133392220786D704D4D3A4F726967696E616C446F63756D656E74
                49443D22786D702E6469643A35333431316132652D383838612D383634642D38
                3265342D323765663263616465643635223E203C70686F746F73686F703A5465
                78744C61796572733E203C7264663A4261673E203C7264663A6C692070686F74
                6F73686F703A4C617965724E616D653D224E4F20494D414745222070686F746F
                73686F703A4C61796572546578743D224E4F20494D414745222F3E203C2F7264
                663A4261673E203C2F70686F746F73686F703A546578744C61796572733E203C
                786D704D4D3A486973746F72793E203C7264663A5365713E203C7264663A6C69
                2073744576743A616374696F6E3D2263726561746564222073744576743A696E
                7374616E636549443D22786D702E6969643A35333431316132652D383838612D
                383634642D383265342D323765663263616465643635222073744576743A7768
                656E3D22323032352D30352D32305430353A33393A31352B30323A3030222073
                744576743A736F6674776172654167656E743D2241646F62652050686F746F73
                686F702032362E34202857696E646F777329222F3E203C7264663A6C69207374
                4576743A616374696F6E3D22636F6E766572746564222073744576743A706172
                616D65746572733D2266726F6D206170706C69636174696F6E2F766E642E6164
                6F62652E70686F746F73686F7020746F20696D6167652F706E67222F3E203C72
                64663A6C692073744576743A616374696F6E3D22736176656422207374457674
                3A696E7374616E636549443D22786D702E6969643A33623361303066312D3531
                38312D393934342D626638622D64353935343636363830613922207374457674
                3A7768656E3D22323032352D30352D32305430353A34323A34392B30323A3030
                222073744576743A736F6674776172654167656E743D2241646F62652050686F
                746F73686F702032362E34202857696E646F777329222073744576743A636861
                6E6765643D222F222F3E203C2F7264663A5365713E203C2F786D704D4D3A4869
                73746F72793E203C2F7264663A4465736372697074696F6E3E203C2F7264663A
                5244463E203C2F783A786D706D6574613E203C3F787061636B657420656E643D
                2272223F3E952E98180000071A4944415478DAED9A6D6857551CC7AF6F5C2F52
                A369DAE6B46D5463CBD290981149BA82528CB4A00C8AD90B4B280B7AA2B01749
                D113940596448EA24C3205D1F9C2993D495658CE6AD2037B706D4BD0305CB8CD
                57FDE0C48FDFCE39F7EEFEFFAEB62F7C3F2FE4FEAFF7DEF3F039BFDF39F7DC4D
                78FBFD2D0941660215A24385F050213C54080F15C24385F050213C54080F15C2
                4385F050213C54080F15C24385F050213C54080F15C24385F050213C54080F15
                C24385F050213C54080F15C24385F050213C54080F15C24385F050213C54080F
                15C24385F050213C54080F15C24385F050213C54080F15C24385F050213C5408
                0F15C24385F050213C54080F15C24385F050213C54080F15C24385F050213C54
                080F15C24385F050213C54080F15C24385F050213C54084F010A9F5FF7B41E4F
                9A3C79F5DA87274E2CB117ECFC785BDB915677FCD4FAE7A20FF9E5E8D1639D1D
                3DDDDDC7FB7AE567DD55732F2E2FAFBD62CEF99326155A075B842D5AA8BAF4B2
                3BEFB9D7BBB7ABA37D4BD3667BA6F1FE35527A58CA1FBDBD4D6F6DB467962E5F
                71E5BCABB3EB76F6ECD0CF6D6DC7FBFAB475AE26179696CEAEAC2AAFA8B06DB4
                0D8992D68121452A8CB62A5BE19F274FEEDCF691B6CD234F1F25E90A37BFB9D1
                7BF2438F3FE90D8B2FF67F72E0D3FDF64C9AC26F0F7EB56F4FB33D33BF7EC14D
                4B966654EC87C3DF7FBEAFA5FFF4E9B40BBCB2C685C2301033148ABF2D4DEF64
                B450B8EE8645D72F5A9CBF0EB688B04756DC75F7E5B5B5F6CC1B2FBFE855204D
                E1D6F7DEEDF8EDD79C7D2AC1B763EBD6F0FAECDBC785C224E8F43485D2C84D1B
                5EB3DD27837A4659D95FA74E1DF9EE903D3F622CE657E8D54DC6D0A60DAF7AD7
                849A85BFFBFB5F7FE905772C6950DDAC6C5C7549557558A5D0F78CB2F2D269D3
                FE2DF7C409490F325FDC7AFB1D690D91FF0D1FEB5D9FC139294C86E7AB348536
                8349ECAE6CBCAF74EA54F7D31BC2D12936AD0E5185DAE9F2A8071F7B422FD0DC
                68AD44478CCCD6DB3FFCC01D8B633D6EB865C9350BAEF52E96FCB97BC776FD29
                0F5FB8B8C18B6C1913434343DAE4EC861441310A65D4A82A3BD8A30AEDA04E62
                03DFBB203B10A32D9771F0CAFA67DDB1C4F7A1AF0FBAE3D56B1FD18ED3581113
                3ACF45CBDADBBCDB3DC18D277DB2C4D6AA07D6D82BBDEC12865A9ECE4CC644A1
                F4C24FADADBA7CD0408C2AB4E334EC05870DD3EC8E88B6DC2E20C58A16A786EC
                28917CA8EBD2A8429D325D4D6C9EF49648B66923E68F3C0D298E22A3B0A6B64E
                338C066254A13D19CD4549B0DCCF68521E859DEDEDAE445D466A6E7489CE5EEC
                29B453A6FB5FBB3AF5AED7784DF2ADC5466C487114A9F0E665CB6C0E71C333AA
                D02EF7D35604361326C31360A10A6591F97BF731D7E93A1D6A94CB18AA98355B
                2F0E5F156C60B9DADAE1E55D6F9BE64D103268868606BDCA5BFDD92BD2827272
                910AA500DB5A3706A30A6D5DD316F1C55D96A650FA4E3BDD8D06ED6BB1525272
                9E5E1CF6944D9B8FAE7B4612A337BCD296C15E9DBDAD86EC7BC74CA137994B83
                3F6B69D1C4F27F2AB48349EE95E0D3994F82A3BCA2427FCA2DD6B7D753D696DD
                DFB15E6D228157980C5F86C83C21FF6A576A75ED0B75CE441A6EAC14A450BA52
                C34E32E7942917B889D0A541BBB4F17ACACB9973E6CE73C73FB61ED6A169A773
                5B192F9116A4307C2F942644170DA3AFD07687AC36E7D7D7870A6D63D25E18CE
                7139132AD4B1E5F660DDD4A8A5870D71843B7021363A6DD3D2963379F622C666
                39A32DB7DD67DF9AA3FD1BDD7D4E86EF4916F152618B70939F7D3DD75A6970EB
                43BCD7FF70A3358A3EC7563BEDA5024061B879E655CBDBD90AE739EF09D14DAF
                EC96DBC5BD3BE96D1724C35F49A30F89EEC045D11A7AB744071F80C224D8640A
                AB6513CE7FB1C136E2CB4C923E8745433994618BB0AF16E147AEA5B72D4FFBA8
                347E154603D1562B1CE06E9B7B7070F09B035FDA1BD3D63BD92D8F2AF426B6B4
                9564CE39DBDB88D1F41BFD02A3DBDC0367CED81DF0FCCB19A1A6B62E231B8DB2
                C2241688DEC8B293531A457F6C8A2AF44A1C3102ECC9706F21633AC8D3B4EC3A
                44C9F90135192D85612086C9419ABAB77957F493A18CEB850D3716FDC9D7E6CC
                E8F6BAB7AB62DF739C2DBB24F6D6388A2DC5DB2914C12D7B9A0BFA6438EE1426
                412046F3BBFBD384CEF6F6EECE0EE944E9AC59955595D5D5357575393788B303
                C8EB7D59E60C0C0C244152B251EBE2C9AE2DD33ED0DBCC9CF6871DDD5D5D7D3D
                3D766A9706CAF32F9A3EBD6CE64CDBC6B15148C62754080F15C24385F050213C
                54080F15C24385F050213C54080F15C24385F050213C54080F15C24385F05021
                3C54080F15C24385F050213C54080F15C24385F050213C54080F15C24385F050
                213C54080F15C24385F050213C54080F15C24385F050213C54080F15C24385F0
                50213C54080F15C24385F050213C54080F15C24385F050213C54080F15C24385
                F050213C54080F15C24385F050213C54080F15C24385F050213C54080F15C243
                85F050213CFF00109B2D1F3C2FA7520000000049454E44AE426082}
              Proportional = True
            end
            object Label15: TLabel
              Left = 8
              Top = 274
              Width = 29
              Height = 20
              Caption = 'Files'
            end
            object SpeedButton9: TSpeedButton
              Left = 103
              Top = 469
              Width = 31
              Height = 26
              Caption = #57607
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -19
              Font.Name = 'Segoe MDL2 Assets'
              Font.Style = []
              ParentFont = False
            end
            object Label16: TLabel
              Left = 8
              Top = 472
              Width = 79
              Height = 20
              Caption = 'Vector store'
            end
            object Label17: TLabel
              Left = 8
              Top = 190
              Width = 54
              Height = 20
              Caption = 'GitHub :'
            end
            object Label18: TLabel
              Left = 8
              Top = 220
              Width = 39
              Height = 20
              Caption = 'Getit :'
            end
            object Label19: TLabel
              Left = 8
              Top = 500
              Width = 20
              Height = 20
              Caption = 'Id :'
            end
            object Label20: TLabel
              Left = 8
              Top = 117
              Width = 83
              Height = 20
              Caption = 'Description :'
            end
            object SpeedButton10: TSpeedButton
              Left = 143
              Top = 469
              Width = 31
              Height = 26
              Caption = #59258
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -19
              Font.Name = 'Segoe MDL2 Assets'
              Font.Style = []
              ParentFont = False
            end
            object MaskEdit3: TMaskEdit
              Left = 96
              Top = 34
              Width = 225
              Height = 26
              BorderStyle = bsNone
              TabOrder = 0
              Text = ''
              TextHint = 'name'
            end
            object MaskEdit4: TMaskEdit
              Left = 8
              Top = 140
              Width = 314
              Height = 26
              BorderStyle = bsNone
              TabOrder = 1
              Text = ''
              TextHint = 'description'
            end
            object MaskEdit5: TMaskEdit
              Left = 66
              Top = 190
              Width = 256
              Height = 26
              BorderStyle = bsNone
              TabOrder = 2
              Text = ''
              TextHint = 'github'
            end
            object MaskEdit6: TMaskEdit
              Left = 51
              Top = 220
              Width = 270
              Height = 26
              BorderStyle = bsNone
              TabOrder = 3
              Text = ''
              TextHint = 'getit'
            end
            object ListView2: TListView
              Left = 8
              Top = 300
              Width = 313
              Height = 141
              Columns = <>
              TabOrder = 4
            end
            object MaskEdit7: TMaskEdit
              Left = 32
              Top = 500
              Width = 290
              Height = 26
              BorderStyle = bsNone
              ReadOnly = True
              TabOrder = 5
              Text = ''
              TextHint = 'vector store'
            end
            object Panel26: TPanel
              Left = 30
              Top = 352
              Width = 265
              Height = 41
              BevelOuter = bvNone
              Caption = 'Please wait ...'
              Color = 2506465
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -16
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentBackground = False
              ParentFont = False
              TabOrder = 6
              StyleElements = [seFont, seBorder]
            end
          end
          object Panel25: TPanel
            Left = 0
            Top = 433
            Width = 342
            Height = 45
            Align = alBottom
            BevelOuter = bvNone
            Color = 2039583
            ParentBackground = False
            TabOrder = 1
            StyleElements = [seFont, seBorder]
            object SpeedButton12: TSpeedButton
              Left = 32
              Top = 8
              Width = 97
              Height = 22
              Caption = '&Apply'
              Transparent = False
              StyleElements = [seFont, seBorder]
            end
            object SpeedButton13: TSpeedButton
              Left = 208
              Top = 6
              Width = 97
              Height = 22
              Caption = '&Cancel'
              Transparent = False
              StyleElements = [seFont, seBorder]
            end
          end
        end
        object SettingsSheet: TTabSheet
          Caption = 'Settings'
          ImageIndex = 4
          TabVisible = False
          object ScrollBox2: TScrollBox
            Left = 0
            Top = 0
            Width = 342
            Height = 478
            HorzScrollBar.Visible = False
            Align = alClient
            BevelInner = bvNone
            BevelOuter = bvNone
            BorderStyle = bsNone
            Color = 2039583
            ParentColor = False
            TabOrder = 0
            StyleElements = [seFont, seBorder]
            object Label5: TLabel
              Left = 8
              Top = 8
              Width = 120
              Height = 20
              Caption = 'Delphi Proficiency'
            end
            object Label6: TLabel
              Left = 8
              Top = 84
              Width = 105
              Height = 20
              Caption = 'Preferred Name'
            end
            object Label7: TLabel
              Left = 8
              Top = 37
              Width = 313
              Height = 20
              Alignment = taRightJustify
              AutoSize = False
              Caption = 'Label7'
              Color = 2039583
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clGray
              Font.Height = -13
              Font.Name = 'Segoe UI'
              Font.Style = []
              ParentColor = False
              ParentFont = False
              StyleElements = [seClient, seBorder]
            end
            object Label8: TLabel
              Left = 8
              Top = 124
              Width = 78
              Height = 20
              Caption = 'OpenAI Key'
            end
            object Label9: TLabel
              Left = 24
              Top = 258
              Width = 91
              Height = 20
              Hint = 'Models that support both the file_search and web_search tools.'
              Caption = 'Search Model'
              ParentShowHint = False
              ShowHint = True
            end
            object Label10: TLabel
              Left = 24
              Top = 383
              Width = 93
              Height = 20
              Hint = 'Models that support both the file_search and web_search tools.'
              Caption = 'o-serie model'
              ParentShowHint = False
              ShowHint = True
            end
            object Label11: TLabel
              Left = 8
              Top = 225
              Width = 318
              Height = 20
              AutoSize = False
              Caption = 'Label11'
              Color = 2039583
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clGray
              Font.Height = -13
              Font.Name = 'Segoe UI'
              Font.Style = []
              ParentColor = False
              ParentFont = False
              StyleElements = [seClient, seBorder]
            end
            object Label12: TLabel
              Left = 8
              Top = 345
              Width = 313
              Height = 20
              AutoSize = False
              Caption = 'Label12'
              Color = 2039583
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clGray
              Font.Height = -13
              Font.Name = 'Segoe UI'
              Font.Style = []
              ParentColor = False
              ParentFont = False
              StyleElements = [seClient, seBorder]
            end
            object Label21: TLabel
              Left = 24
              Top = 423
              Width = 37
              Height = 20
              Caption = 'Effort'
              ParentShowHint = False
              ShowHint = True
            end
            object Label22: TLabel
              Left = 24
              Top = 463
              Width = 62
              Height = 20
              Caption = 'Summary'
              ParentShowHint = False
              ShowHint = True
            end
            object Label23: TLabel
              Left = 24
              Top = 573
              Width = 80
              Height = 20
              Caption = 'Context size'
              ParentShowHint = False
              ShowHint = True
            end
            object Label24: TLabel
              Left = 8
              Top = 320
              Width = 93
              Height = 25
              Hint = 'Models that support both the file_search and web_search tools.'
              Caption = 'Reasoning'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -19
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
            end
            object Label25: TLabel
              Left = 8
              Top = 200
              Width = 303
              Height = 25
              Caption = 'Flagship && Cost-optimized models'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -19
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
            end
            object Label26: TLabel
              Left = 8
              Top = 530
              Width = 101
              Height = 25
              Caption = 'Web search'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -19
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
            end
            object Label27: TLabel
              Left = 24
              Top = 612
              Width = 51
              Height = 20
              Caption = 'Country'
              ParentShowHint = False
              ShowHint = True
            end
            object Label28: TLabel
              Left = 24
              Top = 652
              Width = 25
              Height = 20
              Caption = 'City'
              ParentShowHint = False
              ShowHint = True
            end
            object Label29: TLabel
              Left = 8
              Top = 825
              Width = 74
              Height = 25
              Caption = 'Timeout'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -19
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
            end
            object Label30: TLabel
              Left = 24
              Top = 872
              Width = 63
              Height = 20
              Caption = 'Response'
              ParentShowHint = False
              ShowHint = True
            end
            object Label31: TLabel
              Left = 8
              Top = 961
              Width = 305
              Height = 65
              Alignment = taCenter
              AutoSize = False
              Caption = 
                'The proposed models and all available configurations are designe' +
                'd to be fully compatible with the v1/responses endpoint. Additio' +
                'nal parameters will be added to this list as OpenAI introduces n' +
                'ew capabilities to this endpoint.'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clGray
              Font.Height = -12
              Font.Name = 'Segoe UI'
              Font.Style = []
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
              Layout = tlCenter
              WordWrap = True
              StyleElements = [seClient, seBorder]
            end
            object SpeedButton11: TSpeedButton
              Left = 169
              Top = 930
              Width = 145
              Height = 25
              Caption = 'Clear Response Id'
            end
            object Label32: TLabel
              Left = 24
              Top = 933
              Width = 127
              Height = 20
              Cursor = crHandPoint
              Caption = 'Dashboard OpenAI'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clGray
              Font.Height = -15
              Font.Name = 'Segoe UI'
              Font.Style = [fsUnderline]
              ParentFont = False
              StyleElements = [seClient, seBorder]
            end
            object Label33: TLabel
              Left = 8
              Top = 719
              Width = 124
              Height = 25
              Caption = 'Gpt-5 options'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clWindowText
              Font.Height = -19
              Font.Name = 'Segoe UI'
              Font.Style = [fsBold]
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
            end
            object Label34: TLabel
              Left = 32
              Top = 762
              Width = 61
              Height = 20
              Caption = 'Verbosity'
              ParentShowHint = False
              ShowHint = True
            end
            object ComboBox2: TComboBox
              Left = 148
              Top = 4
              Width = 173
              Height = 30
              Style = csOwnerDrawFixed
              DropDownCount = 5
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clYellow
              Font.Height = -15
              Font.Name = 'Segoe UI'
              Font.Style = []
              ItemHeight = 24
              ItemIndex = 2
              ParentFont = False
              TabOrder = 0
              Text = #57619#57619#57619
              StyleElements = [seClient, seBorder]
              Items.Strings = (
                #57619
                #57619#57619
                #57619#57619#57619
                #57619#57619#57619#57619
                #57619#57619#57619#57619#57619)
            end
            object MaskEdit1: TMaskEdit
              Left = 148
              Top = 82
              Width = 173
              Height = 26
              TabOrder = 1
              Text = ''
              TextHint = 'Your screen name'
            end
            object MaskEdit2: TMaskEdit
              Left = 148
              Top = 122
              Width = 173
              Height = 26
              TabOrder = 2
              Text = ''
              TextHint = 'Your OpenAI key'
            end
            object ComboBox3: TComboBox
              Left = 148
              Top = 255
              Width = 173
              Height = 28
              Hint = 'Models that support both the file_search and web_search tools.'
              Style = csOwnerDrawFixed
              DropDownCount = 5
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clYellow
              Font.Height = -15
              Font.Name = 'Segoe UI'
              Font.Style = []
              ItemHeight = 22
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
              TabOrder = 3
            end
            object ComboBox4: TComboBox
              Left = 148
              Top = 380
              Width = 173
              Height = 28
              Hint = 'Models that support both the file_search and web_search tools.'
              Style = csOwnerDrawFixed
              DropDownCount = 5
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clYellow
              Font.Height = -15
              Font.Name = 'Segoe UI'
              Font.Style = []
              ItemHeight = 22
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
              TabOrder = 4
            end
            object ComboBox5: TComboBox
              Left = 148
              Top = 420
              Width = 173
              Height = 28
              Hint = 'Models that support both the file_search and web_search tools.'
              Style = csOwnerDrawFixed
              DropDownCount = 5
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clYellow
              Font.Height = -15
              Font.Name = 'Segoe UI'
              Font.Style = []
              ItemHeight = 22
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
              TabOrder = 5
            end
            object ComboBox6: TComboBox
              Left = 149
              Top = 460
              Width = 173
              Height = 28
              Hint = 'Models that support both the file_search and web_search tools.'
              Style = csOwnerDrawFixed
              DropDownCount = 5
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clYellow
              Font.Height = -15
              Font.Name = 'Segoe UI'
              Font.Style = []
              ItemHeight = 22
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
              TabOrder = 6
            end
            object ComboBox7: TComboBox
              Left = 149
              Top = 570
              Width = 173
              Height = 28
              Hint = 'Models that support both the file_search and web_search tools.'
              Style = csOwnerDrawFixed
              DropDownCount = 5
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clYellow
              Font.Height = -15
              Font.Name = 'Segoe UI'
              Font.Style = []
              ItemHeight = 22
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
              TabOrder = 7
            end
            object MaskEdit8: TMaskEdit
              Left = 148
              Top = 610
              Width = 173
              Height = 26
              TabOrder = 8
              Text = ''
              TextHint = 'e.g. GB, US or FR'
            end
            object MaskEdit9: TMaskEdit
              Left = 148
              Top = 650
              Width = 173
              Height = 26
              TabOrder = 9
              Text = ''
              TextHint = 'e.g. Paris'
            end
            object ComboBox8: TComboBox
              Left = 149
              Top = 869
              Width = 173
              Height = 28
              Hint = 'Models that support both the file_search and web_search tools.'
              Style = csOwnerDrawFixed
              DropDownCount = 5
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clYellow
              Font.Height = -15
              Font.Name = 'Segoe UI'
              Font.Style = []
              ItemHeight = 22
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
              TabOrder = 10
            end
            object ComboBox9: TComboBox
              Left = 149
              Top = 759
              Width = 173
              Height = 28
              Hint = 'Models that support both the file_search and web_search tools.'
              Style = csOwnerDrawFixed
              DropDownCount = 5
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clYellow
              Font.Height = -15
              Font.Name = 'Segoe UI'
              Font.Style = []
              ItemHeight = 22
              ParentFont = False
              ParentShowHint = False
              ShowHint = True
              TabOrder = 11
            end
          end
        end
      end
      object Panel19: TPanel
        Left = 0
        Top = 0
        Width = 350
        Height = 50
        Align = alTop
        BevelOuter = bvNone
        Color = 2039583
        ParentBackground = False
        TabOrder = 1
        StyleElements = [seFont, seBorder]
        DesignSize = (
          350
          50)
        object Label4: TLabel
          Left = 182
          Top = 8
          Width = 95
          Height = 21
          Alignment = taRightJustify
          Anchors = [akTop, akRight]
          Caption = 'Chat History'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -16
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          ExplicitLeft = 132
        end
        object ComboBox1: TComboBox
          Left = 290
          Top = -1
          Width = 60
          Height = 52
          AutoCloseUp = True
          Style = csOwnerDrawFixed
          Anchors = [akTop, akRight, akBottom]
          Ctl3D = False
          DropDownCount = 6
          DropDownWidth = 60
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -33
          Font.Name = 'Segoe MDL2 Assets'
          Font.Style = []
          ItemHeight = 46
          ParentCtl3D = False
          ParentFont = False
          TabOrder = 0
        end
      end
      object Panel21: TPanel
        Left = 0
        Top = 538
        Width = 350
        Height = 124
        Align = alBottom
        BevelOuter = bvNone
        Color = 2039583
        ParentBackground = False
        TabOrder = 2
        StyleElements = [seFont, seBorder]
        object Memo4: TMemo
          Left = 0
          Top = 33
          Width = 350
          Height = 91
          Margins.Left = 8
          Margins.Right = 8
          Margins.Bottom = 6
          Align = alClient
          BorderStyle = bsNone
          EditMargins.Left = 8
          EditMargins.Right = 8
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clSilver
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          Lines.Strings = (
            'Un exemple')
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
          StyleElements = [seClient, seBorder]
        end
        object Panel22: TPanel
          Left = 0
          Top = 0
          Width = 350
          Height = 33
          Align = alTop
          BevelOuter = bvNone
          Color = 2039583
          ParentBackground = False
          TabOrder = 1
          StyleElements = [seFont, seBorder]
          object Label13: TLabel
            AlignWithMargins = True
            Left = 8
            Top = 3
            Width = 90
            Height = 27
            Margins.Left = 8
            Align = alLeft
            Caption = 'Prompt  3/7 '
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -15
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
            Layout = tlCenter
            ExplicitHeight = 20
          end
          object SpeedButton7: TSpeedButton
            Left = 313
            Top = 2
            Width = 33
            Height = 33
            Caption = #59758
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -19
            Font.Name = 'Segoe MDL2 Assets'
            Font.Style = []
            ParentFont = False
          end
          object SpeedButton8: TSpeedButton
            Left = 279
            Top = 2
            Width = 33
            Height = 33
            Caption = #59757
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -19
            Font.Name = 'Segoe MDL2 Assets'
            Font.Style = []
            ParentFont = False
          end
        end
      end
    end
  end
  object Panel10: TPanel
    Left = 0
    Top = 662
    Width = 1159
    Height = 29
    Align = alBottom
    BevelOuter = bvNone
    Color = 1710618
    ParentBackground = False
    TabOrder = 1
    StyleElements = [seFont, seBorder]
    DesignSize = (
      1159
      29)
    object Label1: TLabel
      Left = 13
      Top = 6
      Width = 179
      Height = 20
      Caption = 'v1.0.7 '#721' @2025 Maxidonkey'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 10724259
      Font.Height = -15
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      StyleElements = [seClient, seBorder]
    end
    object Label2: TLabel
      Left = 1049
      Top = 6
      Width = 98
      Height = 20
      Cursor = crHandPoint
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      Caption = 'Star on GitHub'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 12369084
      Font.Height = -15
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      StyleElements = [seClient, seBorder]
      OnClick = Label2Click
      ExplicitLeft = 1082
    end
    object Label3: TLabel
      Left = 1027
      Top = 9
      Width = 15
      Height = 15
      Cursor = crHandPoint
      Anchors = [akTop, akRight]
      Caption = #57619
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clYellow
      Font.Height = -15
      Font.Name = 'Segoe MDL2 Assets'
      Font.Style = []
      ParentFont = False
      StyleElements = [seClient, seBorder]
      OnClick = Label2Click
      ExplicitLeft = 1060
    end
  end
end
