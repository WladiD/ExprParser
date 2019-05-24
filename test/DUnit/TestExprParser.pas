unit KiwiExprParser;

interface

uses
  Classes, SysUtils, Variants,
  TestFramework,
  ExprParser;

type
  TExprFuncMethod = function(const Args: Variant): Variant of object;
  TExprFuncRecord = record
    FuncName: string;
    FuncMethod: TExprFuncMethod;
    CallCount: Integer;
  end;
  TExprFuncArray = array of TExprFuncRecord;

  TestTExprParser = class(TTestCase)
  private
    FExprParser: TExprParser;
    FStringVars: TStringList;
    FIntegerVars: TStringList;
    FBooleanVars: TStringList;
    FExprFuncs: TExprFuncArray;

    function HasVar(VarsContainer: TStringList; const VarName: string; out VarValue: string): Boolean; overload;
    function HasStringVar(const VarName: string; out VarValue: string): Boolean;
    function HasIntegerVar(const VarName: string; out VarValue: Integer): Boolean;
    function HasBooleanVar(const VarName: string; out VarValue: Boolean): Boolean;

    procedure DefVar(var VarsContainer: TStringList; const VarName, VarValue: string);
    procedure DefStringVar(const VarName, VarValue: string);
    procedure DefIntegerVar(const VarName: string; VarValue: Integer);
    procedure DefBooleanVar(const VarName: string; VarValue: Boolean);

    function ExprParserGetVariable(Sender: TObject; const VarName: string;
      var Value: Variant): Boolean;
    function ExprParserFunctionExecute(Sender: TObject; const FuncName: string;
        const Args: Variant; var ResVal: Variant): Boolean;

    function GetExprFuncIndex(const FuncName: string): Integer;
    function GetExprFuncCallCount(const FuncName: string): Integer;
    procedure ResetExprFuncCallCount(const FuncName: string);
    procedure BindExprFunc(const FuncName: string; ExprFuncMethod: TExprFuncMethod);

    function BooleanCastExprFunc(const Args: Variant): Variant;
    function SumExprFunc(const Args: Variant): Variant;

    function Execute(const Expression: string): Variant; overload;
    function Execute: Variant; overload;

    property ExprParser: TExprParser read FExprParser;

  public
    procedure SetUp; override;
    procedure TearDown; override;

  published
    procedure HelloWorld;
    procedure SimpleMath;
    procedure SimpleTypes;
    procedure ShortCercuitAndOperator;
    procedure ShortCercuitOrOperator;
    procedure MultiParamsFunctions;
    procedure LikeOperator;
    procedure NotOperator;
  end;

implementation

{ TestTExprParser }

function TestTExprParser.HasVar(VarsContainer: TStringList; const VarName: string;
  out VarValue: string): Boolean;
var
  VarIndex: Integer;
begin
  Result := Assigned(VarsContainer);
  if not Result then
    Exit;

  VarIndex := VarsContainer.IndexOfName(VarName);
  Result := VarIndex >= 0;

  if Result then
    VarValue := VarsContainer.ValueFromIndex[VarIndex];
end;

function TestTExprParser.HasStringVar(const VarName: string; out VarValue: string): Boolean;
begin
  Result := HasVar(FStringVars, VarName, VarValue);
end;

function TestTExprParser.HasIntegerVar(const VarName: string; out VarValue: Integer): Boolean;
var
  VarValueString: string;
begin
  Result := HasVar(FIntegerVars, VarName, VarValueString) and TryStrToInt(VarValueString, VarValue);
end;

function TestTExprParser.HasBooleanVar(const VarName: string; out VarValue: Boolean): Boolean;
var
  VarValueString: string;
  VarValueInteger: Integer;
begin
  Result := HasVar(FBooleanVars, VarName, VarValueString) and
    TryStrToInt(VarValueString, VarValueInteger);

  if Result then
    VarValue := VarValueInteger = 1;
end;

procedure TestTExprParser.DefVar(var VarsContainer: TStringList; const VarName, VarValue: string);
var
  VarIndex: Integer;
begin
  if not Assigned(VarsContainer) then
  begin
    VarsContainer := TStringList.Create;
    VarIndex := -1;
  end
  else
    VarIndex := VarsContainer.IndexOfName(VarName);

  if VarIndex < 0 then
    VarsContainer.Add(VarName + VarsContainer.NameValueSeparator + VarValue)
  else
    VarsContainer[VarIndex] := VarName + VarsContainer.NameValueSeparator + VarValue;
end;

procedure TestTExprParser.DefStringVar(const VarName, VarValue: string);
begin
  DefVar(FStringVars, VarName, VarValue);
end;

procedure TestTExprParser.DefIntegerVar(const VarName: string; VarValue: Integer);
begin
  DefVar(FIntegerVars, VarName, IntToStr(VarValue));
end;

procedure TestTExprParser.DefBooleanVar(const VarName: string; VarValue: Boolean);
begin
  DefVar(FBooleanVars, VarName, IntToStr(Ord(VarValue)));
end;

function TestTExprParser.ExprParserGetVariable(Sender: TObject; const VarName: string;
  var Value: Variant): Boolean;
var
  VarString: string;
  VarInteger: Integer;
  VarBoolean: Boolean;
begin
  Result := TRUE;
  if HasStringVar(VarName, VarString) then
    Value := VarString
  else if HasIntegerVar(VarName, VarInteger) then
    Value := VarInteger
  else if HasBooleanVar(VarName, VarBoolean) then
    Value := VarBoolean
  else
    Result := FALSE;
end;

function TestTExprParser.ExprParserFunctionExecute(Sender: TObject; const FuncName: string;
  const Args: Variant; var ResVal: Variant): Boolean;
var
  FuncIndex: Integer;
begin
  FuncIndex := GetExprFuncIndex(FuncName);
  Result := FuncIndex >= 0;
  if Result then
  begin
    ResVal := FExprFuncs[FuncIndex].FuncMethod(Args);
    Inc(FExprFuncs[FuncIndex].CallCount);
  end;
end;

function TestTExprParser.GetExprFuncIndex(const FuncName: string): Integer;
var
  cc: Integer;
begin
  for cc := 0 to Length(FExprFuncs) - 1 do
  begin
    if FExprFuncs[cc].FuncName = FuncName then
    begin
      Result := cc;
      Exit;
    end;
  end;

  Result := -1;
end;

function TestTExprParser.GetExprFuncCallCount(const FuncName: string): Integer;
var
  FuncIndex: Integer;
begin
  FuncIndex := GetExprFuncIndex(FuncName);
  if FuncIndex >= 0 then
    Result := FExprFuncs[FuncIndex].CallCount
  else
    Result := 0;
end;

procedure TestTExprParser.ResetExprFuncCallCount(const FuncName: string);
var
  FuncIndex: Integer;
begin
  FuncIndex := GetExprFuncIndex(FuncName);
  if FuncIndex >= 0 then
    FExprFuncs[FuncIndex].CallCount := 0;
end;

procedure TestTExprParser.BindExprFunc(const FuncName: string; ExprFuncMethod: TExprFuncMethod);
var
  EntryIndex: Integer;
begin
  EntryIndex := Length(FExprFuncs);
  SetLength(FExprFuncs, EntryIndex + 1);
  FExprFuncs[EntryIndex].FuncName := FuncName;
  FExprFuncs[EntryIndex].FuncMethod := ExprFuncMethod;
  FExprFuncs[EntryIndex].CallCount := 0;
end;

function TestTExprParser.BooleanCastExprFunc(const Args: Variant): Variant;
begin
  Result := Boolean(Args[0]);
end;

function TestTExprParser.SumExprFunc(const Args: Variant): Variant;
var
  cc: Integer;
  TotalValue: Extended;
begin
  TotalValue := 0;

  for cc := 0 to VarArrayHighBound(Args, 1) do
    TotalValue := TotalValue + Args[cc];

  Result := TotalValue;
end;

function TestTExprParser.Execute(const Expression: string): Variant;
begin
  ExprParser.Expression := Expression;
  Result := Execute;
end;

function TestTExprParser.Execute: Variant;
begin
  if not ExprParser.Eval then
    raise EExprParserError.Create(ExprParser.ErrorMessage);
  Result := ExprParser.Value;
end;

procedure TestTExprParser.SetUp;
begin
  FExprParser := TExprParser.Create;
  FExprParser.OnGetVariable := ExprParserGetVariable;
  FExprParser.OnExecuteFunction := ExprParserFunctionExecute;
end;

procedure TestTExprParser.TearDown;
begin
  FExprParser.Free;
  FreeAndNil(FStringVars);
  FreeAndNil(FIntegerVars);
  FreeAndNil(FBooleanVars);
  FExprFuncs := nil;
end;

procedure TestTExprParser.HelloWorld;
begin
  CheckEquals('hello world!', Execute('"hello world!"'));

  DefStringVar('A', 'hello');
  DefStringVar('B', 'world');
  CheckEquals('hello world!', Execute('A + " " + B + "!"'));

  DefStringVar('A', 'Hello');
  CheckEquals('Hello world!', Execute);
end;

procedure TestTExprParser.SimpleMath;
begin
  CheckEquals(66, Execute('6 + 6 * 10'));
  CheckEquals(120, Execute('(6 + 6) * 10'));
  CheckEquals(20, Execute('(((6 + 6) * 10) - 20) / 5'));

  DefIntegerVar('A', 69);
  DefIntegerVar('B', 11);

  CheckEquals(80, Execute('A + B'));
  CheckEquals(58, Execute('A - B'));
  CheckEquals(759, Execute('A * B'));
  CheckEquals(20, Execute('(A + B) / 4'));
end;

procedure TestTExprParser.SimpleTypes;
var
  VT: TVarType;
begin
  BindExprFunc('Boolean', BooleanCastExprFunc);

  VT := VarType(Execute('3.125'));
  Check(VT in [varSingle, varDouble]);

  VT := VarType(Execute('3'));
  Check(VT in [varInteger, varInt64]);

  VT := VarType(Execute('"Ich bin ein String!"'));
  Check(VT = varUString);

  VT := VarType(Execute('Boolean(1)'));
  Check(VT = varBoolean);
end;

procedure TestTExprParser.ShortCercuitAndOperator;
begin
  // Die Funktion Boolean wird hier als ein Stub gebraucht um die Anzahl der Aufrufe zählen zu können
  BindExprFunc('Boolean', BooleanCastExprFunc);

  DefBooleanVar('A', FALSE);
  DefBooleanVar('B', TRUE);
  DefBooleanVar('C', TRUE);

  ExprParser.FullBooleanEvaluation := TRUE;
  CheckEquals(FALSE, Execute('Boolean(A) and Boolean(B) and Boolean(C)'));
  // Bei vollständiger boolscher Auswertung wird die Funktion "Boolean" genauso oft aufgerufen,
  // wie oft sie im Ausdruck vorkommt...also 3 mal
  CheckEquals(3, GetExprFuncCallCount('Boolean'));
  ResetExprFuncCallCount('Boolean');

  ExprParser.FullBooleanEvaluation := FALSE;
  CheckEquals(FALSE, Execute('Boolean(A) and Boolean(B) and Boolean(C)'));
  // Bei der Kurzschlussauswertung wird die Funktion "Boolean" hingegen nur einmal aufgerufen,
  // da die Variable B FALSE ist und somit der gesamte Ausdruck schon korrekt evaluiert werden kann
  CheckEquals(1, GetExprFuncCallCount('Boolean'));
  ResetExprFuncCallCount('Boolean');

  DefBooleanVar('A', TRUE);
  DefBooleanVar('B', FALSE);
  DefBooleanVar('C', FALSE);

  CheckEquals(FALSE, Execute('Boolean(A) and Boolean(B) and Boolean(C)'));
  // Da A nun TRUE ist, wird auf B getestet und erst dann abgebrochen...somit ergeben sich 2 Aufrufe
  CheckEquals(2, GetExprFuncCallCount('Boolean'));
  ResetExprFuncCallCount('Boolean');

  DefBooleanVar('A', TRUE);
  DefBooleanVar('B', TRUE);
  DefBooleanVar('C', FALSE);

  CheckEquals(FALSE, Execute('Boolean(A) and Boolean(B) and Boolean(C)'));
  CheckEquals(3, GetExprFuncCallCount('Boolean'));
  ResetExprFuncCallCount('Boolean');

  DefBooleanVar('A', TRUE);
  DefBooleanVar('B', TRUE);
  DefBooleanVar('C', TRUE);

  CheckEquals(TRUE, Execute('Boolean(A) and Boolean(B) and Boolean(C)'));
  CheckEquals(3, GetExprFuncCallCount('Boolean'));
  ResetExprFuncCallCount('Boolean');
end;

procedure TestTExprParser.ShortCercuitOrOperator;
begin
  // Die Funktion Boolean wird hier als ein Stub gebraucht um die Anzahl der Aufrufe zählen zu können
  BindExprFunc('Boolean', BooleanCastExprFunc);

  DefBooleanVar('A', TRUE);
  DefBooleanVar('B', FALSE);
  DefBooleanVar('C', FALSE);

  ExprParser.FullBooleanEvaluation := TRUE;
  CheckEquals(TRUE, Execute('Boolean(A) or Boolean(B) or Boolean(C)'));
  // Bei vollständiger boolscher Auswertung wird die Funktion "Boolean" genauso oft aufgerufen,
  // wie oft sie im Ausdruck vorkommt...also 3 mal
  CheckEquals(3, GetExprFuncCallCount('Boolean'));
  ResetExprFuncCallCount('Boolean');

  ExprParser.FullBooleanEvaluation := FALSE;
  CheckEquals(TRUE, Execute('Boolean(A) or Boolean(B) or Boolean(C)'));
  // Bei der Kurzschlussauswertung wird die Funktion "Boolean" hingegen nur einmal aufgerufen,
  // da die Variable A TRUE ist und somit der gesamte Ausdruck schon korrekt evaluiert werden kann
  CheckEquals(1, GetExprFuncCallCount('Boolean'));
  ResetExprFuncCallCount('Boolean');

  DefBooleanVar('A', FALSE);
  DefBooleanVar('B', TRUE);
  DefBooleanVar('C', FALSE);

  CheckEquals(TRUE, Execute('Boolean(A) or Boolean(B) or Boolean(C)'));
  // Da A nun FALSE ist wird auf B getestet und erst dann abgebrochen, dies ergibt aber schon 2 Aufrufe
  CheckEquals(2, GetExprFuncCallCount('Boolean'));
  ResetExprFuncCallCount('Boolean');

  DefBooleanVar('A', FALSE);
  DefBooleanVar('B', FALSE);
  DefBooleanVar('C', FALSE);

  CheckEquals(FALSE, Execute('Boolean(A) or Boolean(B) or Boolean(C)'));
  // Auch die Kurzschlussauswertung muss komplett evaluieren, wenn alles FALSE ist
  CheckEquals(3, GetExprFuncCallCount('Boolean'));
  ResetExprFuncCallCount('Boolean');
end;

procedure TestTExprParser.MultiParamsFunctions;
begin
  BindExprFunc('Sum', SumExprFunc);
  BindExprFunc('Total', SumExprFunc);

  CheckEquals(55, Execute('Sum(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)'));
  CheckEquals(55, Execute('Total(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)'));

  DefIntegerVar('A1', 10);
  DefIntegerVar('A2', 20);
  DefIntegerVar('A3', 30);
  DefIntegerVar('A4', 40);
  DefIntegerVar('A5', 50);
  DefIntegerVar('A6', 60);
  DefIntegerVar('A7', 70);
  DefIntegerVar('A8', 80);
  DefIntegerVar('A9', 90);
  DefIntegerVar('A10', 100);

  CheckEquals(550, Execute('Sum(A1, A2, A3, A4, A5, A6, A7, A8, A9, A10)'));
  CheckEquals(550, Execute('Total(A1, A2, A3, A4, A5, A6, A7, A8, A9, A10)'));
end;

procedure TestTExprParser.LikeOperator;
begin
  // Nachfolgend ein paar Beispiele für den Like-Operator "~"
  // Der linke Operand enthält die Maske und der Rechte den zu matchenden String.

  CheckFalse(Execute('"hallo" ~ "Hallo welt"'));
  Check(Execute('"hallo*" ~ "Hallo welt"'));
  Check(Execute('"*welt" ~ "Hallo welt"'));
  Check(Execute('"H?ll?*" ~ "Hallo welt"'));

  // Simply case insensitive
  Check(Execute('"Hallo" like "hallo"'));

  DefStringVar('Subject', 'Hello World!');
  Check(Execute('"H?ll?*" like Subject'));
  DefStringVar('Subject', 'Hallo Welt!');
  Check(Execute); // Hinweis: Execute ohne Parameter führt den letzten Ausdruck erneut aus
  DefStringVar('Subject', 'Anybody in the house?');
  CheckFalse(Execute); // Hinweis: Execute ohne Parameter führt den letzten Ausdruck erneut aus
end;

procedure TestTExprParser.NotOperator;
begin
  ExprParser.FullBooleanEvaluation := True;

  DefBooleanVar('A', False);
  DefBooleanVar('B', False);

  Check(Execute('!A'));
  Check(Execute('not A'));

  Check(Execute('!A and !B'));
  Check(Execute('not A and not B'));
  Check(Execute('(not A) and (not B)'));
end;

initialization
  // Alle Testfälle beim Test-Runner registrieren
  RegisterTests('Unit: ExprParser',  [TestTExprParser.Suite]);

end.
