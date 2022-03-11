export const idlFactory = ({ IDL }) => {
  const Bio = IDL.Record({ 'name' : IDL.Opt(IDL.Text) });
  const ProfileUpdate = IDL.Record({ 'bio' : Bio });
  const Error = IDL.Variant({
    'NotFound' : IDL.Null,
    'NotAuthorized' : IDL.Null,
    'AlreadyExists' : IDL.Null,
  });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : Error });
  const Profile = IDL.Record({ 'id' : IDL.Principal, 'bio' : Bio });
  const Result_1 = IDL.Variant({ 'ok' : Profile, 'err' : Error });
  return IDL.Service({
    'create' : IDL.Func([ProfileUpdate], [Result], []),
    'delete' : IDL.Func([], [Result], []),
    'read' : IDL.Func([], [Result_1], []),
    'update' : IDL.Func([ProfileUpdate], [Result], []),
  });
};
export const init = ({ IDL }) => { return []; };
