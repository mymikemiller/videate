export const idlFactory = ({ IDL }) => {
  const List = IDL.Rec();
  const Trie = IDL.Rec();
  const Bio = IDL.Record({ 'name' : IDL.Opt(IDL.Text) });
  const Profile = IDL.Record({
    'id' : IDL.Principal,
    'bio' : Bio,
    'feedKeys' : IDL.Vec(IDL.Text),
  });
  const Error = IDL.Variant({
    'NotFound' : IDL.Null,
    'NotAuthorized' : IDL.Null,
    'AlreadyExists' : IDL.Null,
  });
  const Result_1 = IDL.Variant({ 'ok' : Profile, 'err' : Error });
  const BuyNftResult = IDL.Variant({
    'Ok' : IDL.Nat64,
    'Err' : IDL.Variant({
      'MediaNotFound' : IDL.Null,
      'NotAuthorized' : IDL.Null,
      'FeedNotFound' : IDL.Null,
      'Other' : IDL.Null,
    }),
  });
  const ProfileUpdate = IDL.Record({
    'bio' : Bio,
    'feedKeys' : IDL.Vec(IDL.Text),
  });
  const Result = IDL.Variant({ 'ok' : IDL.Null, 'err' : Error });
  const Branch = IDL.Record({
    'left' : Trie,
    'size' : IDL.Nat,
    'right' : Trie,
  });
  const Hash = IDL.Nat32;
  const Key = IDL.Record({ 'key' : IDL.Principal, 'hash' : Hash });
  List.fill(IDL.Opt(IDL.Tuple(IDL.Tuple(Key, Profile), List)));
  const AssocList = IDL.Opt(IDL.Tuple(IDL.Tuple(Key, Profile), List));
  const Leaf = IDL.Record({ 'size' : IDL.Nat, 'keyvals' : AssocList });
  Trie.fill(
    IDL.Variant({ 'branch' : Branch, 'leaf' : Leaf, 'empty' : IDL.Null })
  );
  return IDL.Service({
    'addFeedKey' : IDL.Func([IDL.Text], [Result_1], []),
    'buyNft' : IDL.Func([IDL.Text, IDL.Text], [BuyNftResult], []),
    'create' : IDL.Func([ProfileUpdate], [Result], []),
    'delete' : IDL.Func([], [Result], []),
    'getAllProfiles' : IDL.Func([], [Trie], []),
    'getName' : IDL.Func([IDL.Principal], [IDL.Opt(IDL.Text)], []),
    'read' : IDL.Func([], [Result_1], []),
    'update' : IDL.Func([ProfileUpdate], [Result], []),
  });
};
export const init = ({ IDL }) => { return []; };
