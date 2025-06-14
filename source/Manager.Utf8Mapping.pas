unit Manager.Utf8Mapping;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Character, System.RegularExpressions,
  System.NetEncoding;

type
  TUtf8Mapping = record
    class function CleanTextAsUTF8(const Value: string): string; static;
  end;

implementation

{ TUtf8Mapping }

class function TUtf8Mapping.CleanTextAsUTF8(const Value: string): string;
begin
  {--- Replace NBSP (U+00A0) with a normal space }
  Result := StringReplace(Value, #$00A0, ' ', [rfReplaceAll]);

  {--- Removal of control characters (< U+0020, except #9/#10/#13) }
  Result := TRegEx.Replace(Result,
       '[\x00-\x08\x0B-\x0C\x0E-\x1F]', '', [roCompiled]);

  {--- Removes isolated surrogates and unicode noncharacters}
  var San := '';
  for var i := 1 to Length(Result) do
    begin
      var c := Result[i];
      {--- isolated surrogates }
      if (Ord(c) >= $D800) and (Ord(c) <= $DFFF) then Continue;
      {--- unicode noncharacters }
      if (Ord(c) = $FFFE) or (Ord(c) = $FFFF) then Continue;
      San := San + c;
    end;

  Result := San;
end;

end.
