export const idlFactory = ({ IDL }) => {
	const Health = IDL.Record({
		assets_size: IDL.Int,
		heap_mb: IDL.Int,
		memory_mb: IDL.Int,
		cycles: IDL.Int
	});
	const CanisterInfo = IDL.Record({
		id: IDL.Text,
		created: IDL.Int,
		name: IDL.Text,
		parent_name: IDL.Text,
		health: IDL.Opt(Health)
	});
	const FileScalingManager = IDL.Service({
		get_canister_records: IDL.Func([], [IDL.Vec(CanisterInfo)], ['query']),
		get_current_canister: IDL.Func([], [IDL.Opt(CanisterInfo)], ['query']),
		get_file_storage_canister_id: IDL.Func([], [IDL.Text], ['query']),
		init: IDL.Func([], [IDL.Text], []),
		version: IDL.Func([], [IDL.Nat], ['query'])
	});
	return FileScalingManager;
};
