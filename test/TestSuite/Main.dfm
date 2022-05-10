object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Testbench for ExprParser'
  ClientHeight = 389
  ClientWidth = 648
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    648
    389)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 8
    Width = 43
    Height = 13
    Caption = 'Variables'
  end
  object Label2: TLabel
    Left = 16
    Top = 128
    Width = 52
    Height = 13
    Caption = 'Expression'
  end
  object Label3: TLabel
    Left = 16
    Top = 237
    Width = 30
    Height = 13
    Anchors = [akLeft, akBottom]
    Caption = 'Result'
  end
  object Label4: TLabel
    Left = 272
    Top = 8
    Width = 97
    Height = 13
    Caption = 'Execution node tree'
  end
  object VarMemo: TMemo
    Left = 16
    Top = 24
    Width = 250
    Height = 89
    Lines.Strings = (
      'A=1'
      'B=1'
      'C=0')
    TabOrder = 0
  end
  object ExprMemo: TMemo
    Left = 16
    Top = 147
    Width = 250
    Height = 72
    Anchors = [akLeft, akTop, akBottom]
    Lines.Strings = (
      'Boolean(A) and Boolean(B) or Boolean(C)')
    TabOrder = 1
  end
  object ResultMemo: TMemo
    Left = 16
    Top = 256
    Width = 250
    Height = 89
    Anchors = [akLeft, akBottom]
    ScrollBars = ssBoth
    TabOrder = 2
  end
  object Button1: TButton
    Left = 16
    Top = 356
    Width = 250
    Height = 25
    Action = ExecuteAction
    Anchors = [akLeft, akBottom]
    Caption = 'Execute (F9)'
    TabOrder = 3
  end
  object ExecNodeTreeMemo: TMemo
    Left = 272
    Top = 24
    Width = 368
    Height = 321
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ScrollBars = ssBoth
    TabOrder = 4
  end
  object ShortCircuitEvalCheckBox: TCheckBox
    Left = 272
    Top = 359
    Width = 137
    Height = 17
    Anchors = [akLeft, akBottom]
    Caption = 'Short-circuit evaluation'
    Checked = True
    State = cbChecked
    TabOrder = 5
  end
  object ActionList1: TActionList
    Left = 376
    Top = 304
    object ExecuteAction: TAction
      Caption = 'Ausf'#252'hren'
      ShortCut = 120
      OnExecute = ExecuteActionExecute
    end
  end
end
