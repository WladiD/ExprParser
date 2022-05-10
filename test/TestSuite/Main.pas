unit Main;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  System.Actions,
  System.Contnrs,
  System.Diagnostics,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ActnList,

  ExprParser;

type
  TMainForm = class(TForm)
    VarMemo: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    ExprMemo: TMemo;
    Label3: TLabel;
    ResultMemo: TMemo;
    ActionList1: TActionList;
    ExecuteAction: TAction;
    Button1: TButton;
    Label4: TLabel;
    ExecNodeTreeMemo: TMemo;
    ShortCircuitEvalCheckBox: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ExecuteActionExecute(Sender: TObject);
  private
    FExprParser: TExprParser;
    FVarAccessCounter: Integer;
    FFuncAccessCounter: Integer;

    procedure DumpExecNodeTree(Strings: TStrings);
    function ExprParserGetVariable(Sender: TObject; const VarName: string;
      var Value: Variant): Boolean;
    function ExprParserFunctionExecute(Sender: TObject; const FuncName: string;
        const Args: Variant; var ResVal: Variant): Boolean;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FExprParser := TExprParser.Create;
  FExprParser.OnGetVariable := ExprParserGetVariable;
  FExprParser.OnExecuteFunction := ExprParserFunctionExecute;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FExprParser.Free;
end;

procedure TMainForm.DumpExecNodeTree(Strings: TStrings);
var
  Depth: Integer;

  procedure DumpNode(Node: TNode; NodeMeaning: string);
  var
    NodeDescription: string;
    NodeDetailsCount: Integer;

    procedure AddNodeDetails(Subject, Value: string);
    begin
      if NodeDetailsCount = 0 then
        NodeDescription := NodeDescription + ' ('
      else
        NodeDescription := NodeDescription + '; ';

      NodeDescription := NodeDescription + Subject + ': ' + Value;

      Inc(NodeDetailsCount);
    end;

    procedure DumpNodeDescription;
    begin
      if NodeDetailsCount > 0 then
        NodeDescription := NodeDescription + ')';

      Strings.AddObject(NodeDescription, Node);
    end;

  var
    NodeBin: TNodeBin absolute Node;
    NodeUnary: TNodeUnary absolute Node;
    NodeVariable: TNodeVariable absolute Node;
    NodeCValue: TNodeCValue absolute Node;
    NodeFunction: TNodeFunction absolute Node;
    cc: Integer;
  begin
    Inc(Depth);
    try
      NodeDetailsCount := 0;

      if Depth > 0 then
        NodeDescription := StringOfChar('-', Depth) + ' '
      else
        NodeDescription := '';

      NodeDescription := NodeDescription + NodeMeaning + ': ' + Node.ClassName;

      if Node is TNodeBin then
      begin
        AddNodeDetails('Operator', NodeBin.OperatorLex.Chr);
        DumpNodeDescription;
        DumpNode(NodeBin.LeftNode, 'Left');
        DumpNode(NodeBin.RightNode, 'Right');
      end
      else if Node is TNodeUnary then
      begin
        AddNodeDetails('Operator', NodeUnary.OperatorLex.Chr);
        DumpNodeDescription;
        DumpNode(NodeUnary.RightNode, 'Right');
      end
      else if Node is TNodeVariable then
      begin
        AddNodeDetails('VarName', NodeVariable.VariableLex.Str);
        DumpNodeDescription;
      end
      else if Node is TNodeCValue then
      begin
        AddNodeDetails('Constant', NodeCValue.ConstantValueLex.Str);
        DumpNodeDescription;
      end
      else if Node is TNodeFunction then
      begin
        AddNodeDetails('Name', NodeFunction.FunctionLex.Str);
          DumpNodeDescription;

        for cc := 0 to NodeFunction.Arguments.Count - 1 do
          DumpNode(TNode(NodeFunction.Arguments[cc]), 'Argument' + IntToStr(cc + 1));
      end
      else
        DumpNodeDescription;
    finally
      Dec(Depth);
    end;
  end;

begin
  Depth := -1;
  Strings.BeginUpdate;
  try
    Strings.Clear;
    DumpNode(FExprParser.Parser.RootNode, 'Root');
  finally
    Strings.EndUpdate;
  end;
end;

procedure TMainForm.ExecuteActionExecute(Sender: TObject);
var
  Watcher: TStopwatch;
begin
  FVarAccessCounter := 0;
  FFuncAccessCounter := 0;
  Watcher := TStopwatch.StartNew;

  FExprParser.FullBooleanEvaluation := not ShortCircuitEvalCheckBox.Checked;

  if FExprParser.Eval(Trim(ExprMemo.Lines.Text)) then
  begin
    Watcher.Stop;

    ResultMemo.Color := clWindow;
    ResultMemo.Lines.BeginUpdate;
    try
      ResultMemo.Lines.Clear;
      ResultMemo.Lines.Add('Result: ' + string(FExprParser.Value));
      ResultMemo.Lines.Add('Result type: ' + VarTypeAsText(VarType(FExprParser.Value)));
      ResultMemo.Lines.Add('---');
      ResultMemo.Lines.Add(Format('Exec time: %d ticks (%s)',
        [Watcher.ElapsedTicks, Watcher.Elapsed.ToString]));
      ResultMemo.Lines.Add(Format('Var access: %d times', [FVarAccessCounter]));
      ResultMemo.Lines.Add(Format('Function access: %d times', [FFuncAccessCounter]));
      ResultMemo.SelStart := 0;
      ResultMemo.SelLength := 0;
    finally
      ResultMemo.Lines.EndUpdate;
    end;

    DumpExecNodeTree(ExecNodeTreeMemo.Lines);
  end
  else
  begin
    ResultMemo.Color := clRed;
    ResultMemo.Lines.Text := FExprParser.ErrorMessage;
    ExecNodeTreeMemo.Lines.Clear;
  end;
end;

function TMainForm.ExprParserGetVariable(Sender: TObject; const VarName: string;
  var Value: Variant): Boolean;
var
  VarIndex: Integer;
begin
  Inc(FVarAccessCounter);
  VarIndex := VarMemo.Lines.IndexOfName(VarName);
  Result := VarIndex >= 0;
  if Result then
    Value := VarMemo.Lines.ValueFromIndex[VarIndex];
end;

function TMainForm.ExprParserFunctionExecute(Sender: TObject; const FuncName: string;
  const Args: Variant; var ResVal: Variant): Boolean;
var
  LFN: string;
  ArgValue: Variant;
  ArgHighBound: Integer;

  function HasArg(ArgIndex: Integer; out Value: Variant): Boolean;
  begin
    Result := VarIsArray(Args) and (ArgIndex <= ArgHighBound);
    if Result then
      Value := Args[ArgIndex]; // VarArrayGet(Args, [ArgIndex]);
  end;

begin
  Inc(FFuncAccessCounter);
  LFN := LowerCase(FuncName);
  ArgHighBound := VarArrayHighBound(Args, 1);

  if LFN = 'integer' then
  begin
    Result := HasArg(0, ArgValue);
    if Result then
      ResVal := StrToIntDef(ArgValue, 0);
  end
  else if LFN = 'boolean' then
  begin
    Result := HasArg(0, ArgValue);
    if Result then
      ResVal := ArgValue = 1;
  end
  else
    Result := FALSE;
end;

end.
