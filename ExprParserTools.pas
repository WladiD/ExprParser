unit ExprParserTools;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.Rtti,

  ExprParser;

type
  TCachedVars<T> = class
  public
    type
    TVarGetFunc = reference to function(const VarName: string; out Value: T): Boolean;
    TVarDictionary = TDictionary<string, T>;
  private
    FVars: TVarDictionary;
    FVariantVars: TDictionary<string, Variant>;
    FVarResolver: TVarGetFunc;

  protected
    function TypedVarAsVariant(const Value: T): Variant;

  public
    constructor Create(const VarResolver: TVarGetFunc);
    destructor Destroy; override;

    procedure DefineVar(const VarName: string; const Value: T);
    function HasVar(const VarName: string; out Value: T): Boolean;
    function Endpoint(Sender: TObject; const VarName: string; var Value: Variant): Boolean;

    // Warning: For read access only, do not modify the contained items.
    property Dictionary: TVarDictionary read FVars;
  end;

implementation

{ TCachedVars<T> }

constructor TCachedVars<T>.Create(const VarResolver: TVarGetFunc);
begin
  FVars := TVarDictionary.Create;
  FVariantVars := TDictionary<string, Variant>.Create;
  FVarResolver := VarResolver;
end;

destructor TCachedVars<T>.Destroy;
begin
  FVars.Free;
  FVariantVars.Free;
  inherited Destroy;
end;

procedure TCachedVars<T>.DefineVar(const VarName: string; const Value: T);
begin
  FVars.AddOrSetValue(VarName, Value);
  FVariantVars.Remove(VarName);
end;

function TCachedVars<T>.HasVar(const VarName: string; out Value: T): Boolean;
begin
  Result := FVars.TryGetValue(VarName, Value);
end;

function TCachedVars<T>.TypedVarAsVariant(const Value: T): Variant;
var
  V: TValue;
begin
  V := TValue.From<T>(Value);
  case V.Kind of
    tkEnumeration:
    begin
      if V.TypeInfo = TypeInfo(Boolean) then
        Result := V.AsBoolean
      else
        Result := V.AsOrdinal;
    end
    else
      Result := V.AsVariant;
  end;
end;

// This function can be directly or nested bounded to TExprParser.OnGetVariable
function TCachedVars<T>.Endpoint(Sender: TObject; const VarName: string;
  var Value: Variant): Boolean;
var
  TypedVar: T;
begin
  // It should be possible to call this method on an unassigned (nil) instance without an AV
  if not Assigned(Self) then
    Exit(False);

  // Performance boost, because no additional conversion to variant
  if FVariantVars.TryGetValue(VarName, Value) then
    Exit(True);

  Result := FVars.TryGetValue(VarName, TypedVar);
  if Result then
    Value := TypedVarAsVariant(TypedVar)
  else if Assigned(FVarResolver) then
  begin
    Result := FVarResolver(VarName, TypedVar);
    if Result then
    begin
      FVars.Add(VarName, TypedVar);
      Value := TypedVarAsVariant(TypedVar);
    end;
  end;

  if Result then
    FVariantVars.Add(VarName, Value);
end;

end.
