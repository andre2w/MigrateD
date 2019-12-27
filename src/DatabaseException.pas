unit DatabaseException;

interface

uses
  System.SysUtils;

type

  EDatabaseException = class(Exception)
  end;

  EDuplicatedMigration = class(Exception)
  end;

implementation

end.
