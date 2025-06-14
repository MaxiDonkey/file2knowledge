unit JSON.Resource;

interface

{$REGION  'Dev notes : JSON.Resource'}

(*
  Unit: JSON.Resource

  Purpose:
    This unit provides shared infrastructure for automated JSON serialization and deserialization of
    Delphi objects by leveraging RTTI (Run-Time Type Information).
    It abstracts the loading/saving of objects to and from JSON files, allowing any descendant class to
    be persisted with minimal boilerplate.
    The unit also introduces a “chainable” mechanism that enables dynamic and fluent runtime modification
    of any object’s public properties by property path.

  Technical details:
    - TJSONResource: Base class for any object that should support JSON persistence. It provides methods
      for saving (`Save`) and loading (`Load`) objects directly from/to JSON files, with
      intelligent default filename detection.
    - TJSONChain: Record that enables fluent property mutation via RTTI ("chainable set"), making it
      easy to modify properties dynamically at runtime, including nested and array types.
    - TJSONResourceHelper: Class helper that attaches `Chain` behavior seamlessly to any
      TJSONResource descendant.
    - All loading/writing leverages REST.Json for conversion, and System.Rtti for dynamic property
      setting, supporting camel case and both fields and public properties.
    - Throws explicit exceptions for invalid or corrupt JSON files to prevent silent data loss.

  Dependencies:
    - REST.Json, REST.Json.Types: For Delphi’s official object/JSON marshalling.
    - System.Rtti: To apply dynamic property changes and deep property paths at runtime.
    - System.JSON: Core Delphi JSON object support.
    - System.IOUtils, System.SysUtils: For file and string operations.

  Getting started:
    - Inherit from TJSONResource to make any class persistable as JSON.
    - Use the `Load` and `Save` class/methods to deserialize or serialize the object state.
    - Use `.Chain.Apply('PropertyPath', Value)` for runtime dynamic property changes on any
      TJSONResource instance, enabling fluent updates and reducing setter boilerplate.
    - DefaultFileName gives each class its own default JSON file name based on class name.

  This unit streamlines, unifies, and secures JSON object persistence for Delphi business objects,
  making it rapid and reliable to store, modify, or restore object graphs in modern cross-platform
  applications.
*)

{$ENDREGION}

uses
  System.SysUtils, System.IOUtils, System.JSON, System.Rtti, REST.Json;

type
  TFactory<T> = reference to function: T;
  TJSONResourceClass = class of TJSONResource;

  TJSONResource = class
  public
    constructor Create; virtual;
    class function DefaultFileName: string; virtual;
    class function Load(const FileName: string = ''): TJSONResource; virtual;
    procedure Save(const FileName: string = '');
  end;

  TJSONChain = record
  private
    FInstance: TJSONResource;
    procedure SetPropByPath(const APropPath: string; const AValue: TValue);
  public
    class function FromInstance(AInstance: TJSONResource): TJSONChain; static;
    function Apply(const APropPath: string; const AValue: TValue): TJSONChain; overload;
    function Apply<T>(const APropPath: string; const AValue: T): TJSONChain; overload;
    function Apply<T>(const APropPath: string; const AValue: array of T): TJSONChain; overload;
    function Apply<T>(const APropPath: string; const AValue: array of TFactory<T>): TJSONChain; overload;
    function Save(const AFileName: string = ''): TJSONChain;
    property Instance: TJSONResource read FInstance;
  end;

  TJSONResourceHelper = class helper for TJSONResource
  public
    function Chain: TJSONChain;
  end;

implementation

{ TJSONResource }

constructor TJSONResource.Create;
begin
  inherited Create;

end;

class function TJSONResource.DefaultFileName: string;
begin
  {--- Take the name of the class without its T prefix }
  Result := ClassName.Substring(1) + '.json';
end;

class function TJSONResource.Load(const FileName: string): TJSONResource;
var
  LFileName: string;
  Raw: string;
  LJSONObject: TJSONObject;
begin
  LFileName := FileName;
  if LFileName = EmptyStr then
    LFileName := DefaultFileName;

  if not TFile.Exists(LFileName) then
    {--- if no file then returns a blank instance }
    Exit(TJSONResourceClass(Self).Create);

  Raw := TFile.ReadAllText(LFileName, TEncoding.UTF8);

  {--- Parse into TJSONObject }
  LJSONObject := TJSONObject.ParseJSONValue(Raw) as TJSONObject;
  if LJSONObject = nil then
    raise Exception.CreateFmt('Invalid JSON in %s', [LFileName]);

  try
    {--- Creates the instance of the correct type (Self = calling metaclass) }
    Result := TJSONResourceClass(Self).Create;

    {--- and finally, let RTTI fill in Result }
    TJson.JsonToObject(Result, LJSONObject,
      {--- Maybe open to more properties }
      [joSerialFields, joSerialPublicProps, joIndentCaseCamel]);

  finally
    LJSONObject.Free;
  end;
end;

procedure TJSONResource.Save(const FileName: string);
var
  LFileName: string;
  JsonValue: TJSONValue;
  Formatted: string;
begin
  LFileName := FileName;
  if LFileName = EmptyStr then
    LFileName := DefaultFileName;

  JsonValue := TJson.ObjectToJsonObject(Self,
    [joSerialFields, joSerialPublicProps, joIndentCaseCamel]);
  try
    {--- Pretty formated }
    Formatted := JsonValue.Format(2);
    TFile.WriteAllText(LFileName, Formatted, TEncoding.UTF8);
  finally
    JsonValue.Free;
  end;
end;

{ TJSONChain }

{$REGION 'TJSONChain'}

function TJSONChain.Apply<T>(const APropPath: string;
  const AValue: array of T): TJSONChain;
var
  Data: TArray<T>;
begin
  SetLength(Data, Length(AValue));
  for var i := 0 to High(AValue) do
    Data[i] := AValue[i];
  Result := Apply(APropPath, TValue.From<TArray<T>>(Data));
end;

function TJSONChain.Apply<T>(const APropPath: string;
  const AValue: array of TFactory<T>): TJSONChain;
var
  Data: TArray<T>;
begin
  SetLength(Data, Length(AValue));
  for var i := 0 to High(AValue) do
    Data[i] := AValue[i]();
  Result := Apply(APropPath, TValue.From<TArray<T>>(Data));
end;

function TJSONChain.Apply<T>(const APropPath: string;
  const AValue: T): TJSONChain;
begin
  Result := Apply(APropPath, TValue.From<T>(AValue));
end;

function TJSONChain.Apply(const APropPath: string; const AValue: TValue): TJSONChain;
begin
  Result := Self;
  SetPropByPath(APropPath, AValue);
end;

class function TJSONChain.FromInstance(AInstance: TJSONResource): TJSONChain;
begin
  Result.FInstance := AInstance;
end;

function TJSONChain.Save(const AFileName: string): TJSONChain;
begin
  FInstance.Save(AFileName);
  Result := Self;
end;

procedure TJSONChain.SetPropByPath(const APropPath: string; const AValue: TValue);
var
  Ctx: TRttiContext;
  RTTIType: TRttiType;
  Prop: TRttiProperty;
  Parts: TArray<string>;
  CurrentObj: TObject;
  Last: Integer;
begin
  Parts := APropPath.Split(['.']);
  Last := High(Parts);
  CurrentObj := FInstance;

  {--- Go down to the penultimate part }
  for var i := 0 to Last - 1 do
  begin
    RTTIType := Ctx.GetType(CurrentObj.ClassType);
    Prop := RTTIType.GetProperty(Parts[i]);
    if not Assigned(Prop) then
      raise Exception.CreateFmt('Property "%s" not found on %s',
        [Parts[i], CurrentObj.ClassName]);
    CurrentObj := Prop.GetValue(CurrentObj).AsObject;
    if CurrentObj = nil then
      raise Exception.CreateFmt('The sub-property "%s" is NIL', [Parts[i]]);
  end;

  {--- Affect the last part }
  RTTIType := Ctx.GetType(CurrentObj.ClassType);
  Prop := RTTIType.GetProperty(Parts[Last]);
  if not Assigned(Prop) then
    raise Exception.CreateFmt('Property "%s" not found on %s',
      [Parts[Last], CurrentObj.ClassName]);
  Prop.SetValue(CurrentObj, AValue);
end;

{$ENDREGION}

{$REGION 'TJSONResourceHelper'}

function TJSONResourceHelper.Chain: TJSONChain;
begin
  {--- Returns a TJSONChain “attached” to Self }
  Result := TJSONChain.FromInstance(Self);
end;

{$ENDREGION}

end.
